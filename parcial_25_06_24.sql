USE GD2015C1
/*
	Sabiendo que si un producto no es vendido en un depósito determinado entonces no
	posee registros en él
	Se requiere una consulta SQL que para todos los productos que se quedaron sin stock
	en un depósito (cantidad 0 o nula) y poseen un stock mayor al punto de resposición en otro
	depósito, devuelva:
		- Código de producto
		- Detalle del producto
		- Domicilio del depósito sin stock
		- Cantidad de depósitos con un stock superior aL punto de reposición
	La consulta debe ser ordenada por código de producto
*/

SELECT 
p.prod_codigo [Código de producto],
p.prod_detalle [Detalle del producto],
d.depo_domicilio [Domicilio del depósito sin stock],
ISNULL(COUNT(distinct s2.stoc_deposito),0) [Cantidad de depósitos con un stock superior aL punto de reposición]
FROM STOCK s 
    JOIN DEPOSITO d on d.depo_codigo=s.stoc_deposito
    JOIN Producto p on p.prod_codigo=s.stoc_producto
    LEFT JOIN STOCK s2 on s2.stoc_producto=s.stoc_producto
                    and s2.stoc_deposito != s.stoc_deposito
                    and s2.stoc_cantidad > s.stoc_punto_reposicion
WHERE (s.stoc_cantidad = 0 or s.stoc_cantidad is null)
GROUP BY p.prod_codigo,p.prod_detalle,d.depo_domicilio
ORDER BY p.prod_codigo

/*
	Dado el contexto inflacionario se tiene que aplicar un control en el cual nunca se 
	permita vender un producto a un precio que no est� entre 0%-5% del precio de venta
	del producto el mes anterior, ni tampoco que est� en m�s de un 50% el precio del mismo
	producto que hace 12 meses atr�s. Aquellos productos nuevos, o que no tuvieron ventas en 
	meses anteriores no debe considerar esta regla ya que no hay precio de referencia
*/


CREATE TRIGGER validacion_precio
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Item_Factura (item_sucursal,item_tipo,item_numero,item_producto,item_precio,item_cantidad)
    SELECT i.item_sucursal, i.item_tipo,i.item_numero,i.item_producto,i.item_precio,i.item_cantidad
    FROM inserted i JOIN Factura f on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
    WHERE 
    (not exists
        (select 1
        from Item_Factura i1 join Factura f1 on i1.item_sucursal+i1.item_tipo+i1.item_numero=f1.fact_sucursal+f1.fact_tipo+f1.fact_numero
        where f1.fact_fecha = dateadd(month,-1,f.fact_fecha) and i1.item_producto=i.item_producto and i.item_precio > i1.item_precio*1.05)
    and
    not exists
        (select 1
        from Item_Factura i2 join Factura f2 on i2.item_sucursal+i2.item_tipo+i2.item_numero=f2.fact_sucursal+f2.fact_tipo+f2.fact_numero
        where f2.fact_fecha=DATEADD(year,-1,f.fact_fecha) and i2.item_producto=i.item_producto and i.item_precio > i2.item_precio*1.5)
    )
END
GO
