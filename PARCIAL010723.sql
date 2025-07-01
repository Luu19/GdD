USE [GD2015C1]
--PARCIAL 01 07 23
/*Implementar una regla de negocio para mantener siempre consistente
(actualizada bajo cualquier circunstancia) una nueva tabla llamada PRODUCTOS_VENDIDOS.
En esta tabla debe registrar el periodo (YYYYMM), el codigo de producto, el precio
maximo de venta y las unidades vendidas. Toda esta informacion debe estar por 
periodo (YYYYMM)*/

CREATE TABLE PRODUCTOS_VENDIDOS(
    Periodo INT NOT NULL,
    Codigo_Producto char(8) NOT NULL,
    Precio_Maximo  decimal(12,2),
    Unidades_Vendidas decimal(12,2)
)

ALTER TABLE PRODUCTOS_VENDIDOS
ADD CONSTRAINT PK_PROD_VENDIDOS PRIMARY KEY (Periodo, Codigo_Producto)

select *from Item_Factura

--select FORMAT(fact_fecha,'yyyyMM') from Factura
GO


CREATE TRIGGER actualizar_productos_vendidos
ON Item_Factura
FOR INSERT
AS
BEGIN
   MERGE PRODUCTOS_VENDIDOS AS DESTINO
   USING (select item_producto, item_cantidad, item_precio, format(fact_fecha,'yyyyMM') as periodo
          from inserted 
          join Factura on item_sucursal+item_tipo+item_numero=fact_sucursal+fact_tipo+fact_numero) AS ORIGEN
   ON DESTINO.Codigo_Producto = ORIGEN.item_producto AND DESTINO.Periodo = ORIGEN.periodo

   WHEN NOT MATCHED THEN
        INSERT (Periodo, Codigo_Producto, Precio_Maximo, Unidades_Vendidas)
        VALUES (ORIGEN.periodo, ORIGEN.item_producto, ORIGEN.item_precio, ORIGEN.item_cantidad)
   
   WHEN MATCHED THEN UPDATE SET
        DESTINO.Precio_Maximo = (CASE WHEN DESTINO.Precio_Maximo < ORIGEN.item_precio THEN ORIGEN.item_precio
                                    ELSE DESTINO.Precio_Maximo END),
        DESTINO.Unidades_Vendidas += ORIGEN.item_cantidad;
END


