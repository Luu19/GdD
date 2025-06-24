-- Parcial 2024 05 25
/*
	Dada la crisis que atraviesa la empresa, el directorio solicita un informe especial para poder
	analizar y definir la nueva estrategia a adoptar.
	Este informe consta de un listado de aquellos productos cuyas ventas de lo que va del año 2012
	fueron superiores al 15% del promedio de ventas de los productos vendidos entre los años 2010 y 2011.
	En base a lo solicitado, armar una consulta SQL que retorne la siguiente informacion:
		1. Detalle del producto
		2. Mostrar la leyenda "Popular" si dicho producto figura en más de 100 facturas realizadas
		en el 2012. Caso contrario, mostrar una leyenda "Sin interes"
		3. Cantidad de facturas en las que aparece el producto en el año 2012
		4. Codigo de cliente que mas compro dicho producto en el 2012 (en caso de existir más de un cliente, mostrar
		solamente el de menor codigo)
*/

SELECT 
p.prod_detalle,
(CASE
    WHEN COUNT(distinct f.fact_sucursal+f.fact_tipo+f.fact_numero) > 100 THEN 'Popular'
    ELSE 'Sin interes'
END) [Estatus],
COUNT(distinct f.fact_sucursal+f.fact_tipo+f.fact_numero) [Facturas en las que aparece],
(SELECT TOP 1 f2.fact_cliente
FROM Factura f2 
    JOIN Item_Factura i2 on f2.fact_sucursal+f2.fact_tipo+f2.fact_numero=i2.item_sucursal+i2.item_tipo+i2.item_numero
WHERE YEAR(f2.fact_fecha)=2012 and i2.item_producto=i.item_producto
GROUP BY f2.fact_cliente
ORDER BY SUM(i2.item_cantidad) desc, f2.fact_cliente ASC) [Cliente que mas compro]
FROM Producto p 
    JOIN Item_Factura i on i.item_producto=p.prod_codigo
    JOIN Factura f on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
WHERE YEAR(f.fact_fecha)=2012
GROUP BY p.prod_detalle,p.prod_codigo,i.item_producto
HAVING AVG(i.item_cantidad*i.item_precio) > (select AVG(i1.item_cantidad*i1.item_precio)*0.15
                                                                        from Item_Factura i1 
                                                                        JOIN Factura f1 on f1.fact_sucursal+f1.fact_tipo+f1.fact_numero=i1.item_sucursal+i1.item_tipo+i1.item_numero
                                                                        WHERE (YEAR(f1.fact_fecha)=2010 or YEAR(f1.fact_fecha)=2011) and i1.item_producto=p.prod_codigo
                                                                        )

/*
	Realizar el o los objetos de la base de datos necesarios para que dado un código de producto
	y una fecha y devuelva la mayor cantidad de días consecutivos a partir de esa fecha que el
	producto tuvo al menos la venta de una unidad en el día, el sistema de ventas online está habilitado
	24/7 por lo que se deben evaluar todos los dias incluyendo domingos y feriados
*/

go
CREATE PROC mayor_venta_consecutiva
(@prod_codigo CHAR(8), @fecha SMALLDATETIME)
AS
BEGIN
    DECLARE @fact_fecha SMALLDATETIME;
    DECLARE @fecha_anterior SMALLDATETIME = @fecha;
    DECLARE @racha INT = 1;
    DECLARE @max_racha INT = 1;

    DECLARE cursor_dias_consecutivos CURSOR 
    FOR 
    SELECT DISTINCT fact_fecha
    FROM Item_Factura 
    JOIN Factura 
        ON item_sucursal = fact_sucursal 
       AND item_tipo = fact_tipo 
       AND item_numero = fact_numero
    WHERE fact_fecha >= @fecha AND item_producto = @prod_codigo
    ORDER BY fact_fecha ASC;

    OPEN cursor_dias_consecutivos;

    FETCH NEXT FROM cursor_dias_consecutivos INTO @fact_fecha;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Si es un día consecutivo, incrementa la racha
        IF DATEDIFF(DAY, @fecha_anterior, @fact_fecha) = 1
        BEGIN
            SET @racha += 1;
        END
        ELSE
        BEGIN
            -- Si no es consecutivo, actualiza el máximo y reinicia la racha
            IF @racha > @max_racha
                SET @max_racha = @racha;

            SET @racha = 1; -- Reinicia la racha para incluir el nuevo día
        END

        -- Actualiza la fecha anterior
        SET @fecha_anterior = @fact_fecha;

        FETCH NEXT FROM cursor_dias_consecutivos INTO @fact_fecha;
    END

    -- Verifica si la última racha es la mayor
    IF @racha > @max_racha
        SET @max_racha = @racha;

    CLOSE cursor_dias_consecutivos;
    DEALLOCATE cursor_dias_consecutivos;

    -- Devuelve la racha máxima
    PRINT @max_racha;
END;
GO

