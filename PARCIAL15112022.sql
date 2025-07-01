USE GD2015C1
--PARCIAL15112022
/*Implementar una regla de negocio en linea que al realizar una venta (SOLO INSERCION) permita
componer los productos descompuestos, es decir, si se guardan en la factura 2 hamb. 2 papas 2 gaseosas
se debera guardar en la factura 2 (DOS) COMBO1, si 1 COMBO1 equivale a 1 hamb. 1 papa y una gaseosa*/
GO

CREATE TRIGGER componer_prod_descompuestos
ON Item_Factura 
INSTEAD OF INSERT
AS
BEGIN
   --recorro por factura 
   --por cada prod compuesto tengo que ver si me alcanza para hacer al menos un combo
   --componente me sirve para ver los componentes y la cantidad
   declare @sucursal char(4)
   declare @tipo char(1)
   declare @numero char(8)

   DECLARE cursor_facturas CURSOR 
   FOR select item_sucursal, item_tipo, item_numero
        from inserted
    
    OPEN cursor_facturas

    FETCH NEXT FROM cursor_facturas INTO @sucursal, @tipo, @numero

    WHILE @@FETCH_STATUS = 0
    BEGIN
        declare @items_factura TABLE (
            item_producto CHAR(8),
            item_cantidad decimal(12,2)
        )
        INSERT INTO @items_factura
        --productos que pertenecen a la factura
        SELECT item_producto, item_cantidad
        FROM inserted
        WHERE item_sucursal=@sucursal and item_tipo=@tipo and item_numero=@numero

        --para cada prod compuesto ver cuantos combos se pueden hacer
        --itero por cada combo en composicion

        declare @combo char(8)
        declare @cantidad_combos_posibles int
        declare @precio decimal(12,2)

        DECLARE cursor_combos CURSOR
        FOR select distinct com.comp_producto
            from Composicion com;

        OPEN cursor_combos

        FETCH NEXT FROM cursor_combos INTO @combo
        WHILE @@FETCH_STATUS=0
        BEGIN

            declare @detalle_combo TABLE(
                deta_componente char(8),
                deta_cant_necesaria decimal(12,2),
                deta_cant_disponible decimal(12,2),
                deta_combos_posibles int
            )
            INSERT INTO @detalle_combo
            SELECT c.comp_componente, c.comp_cantidad, ISNULL(f.item_cantidad, 0), ISNULL(f.item_cantidad, 0) / c.comp_cantidad
            FROM Composicion c
                LEFT JOIN @items_factura f on c.comp_componente=f.item_producto
            WHERE c.comp_producto=@combo

            SELECT @cantidad_combos_posibles=MIN(deta_combos_posibles) FROM @detalle_combo;

            IF @cantidad_combos_posibles>=1
            BEGIN
                SELECT @precio=prod_precio FROM Producto where prod_codigo=@combo
                --insertar combos
                INSERT INTO Item_Factura(item_sucursal,item_tipo,item_numero,item_cantidad,item_precio,item_producto)
                VALUES(@sucursal,@tipo,@numero,@cantidad_combos_posibles,@precio,@combo)

                --actualizar cantidades
                UPDATE @items_factura
                SET item_cantidad = item_cantidad-d.deta_cant_necesaria*d.deta_combos_posibles
                FROM @items_factura f join @detalle_combo d on f.item_producto=d.deta_componente
            END

            FETCH NEXT FROM cursor_combos INTO @combo
        END

        CLOSE cursor_combos
        DEALLOCATE cursor_combos

        --insertar los items restantes
        INSERT INTO Item_Factura(item_producto, item_cantidad, item_tipo, item_numero, item_sucursal, item_precio)
        SELECT f.item_producto, f.item_cantidad, @tipo, @numero, @sucursal, p.prod_precio
        FROM @items_factura f join Producto p on f.item_producto = p.prod_codigo
        WHERE f.item_cantidad > 0

        FETCH NEXT FROM cursor_facturas INTO @sucursal, @tipo, @numero
    END

    CLOSE cursor_facturas
    DEALLOCATE cursor_facturas

END




