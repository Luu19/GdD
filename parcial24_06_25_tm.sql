USE GD2015C1
--PARCIAL 24 06 25 TM
/*Realizar una consulta sql que retorne para el ultimo año, los 5 vendedores con menos clientes asignados, 
que mas vendieron en pesos (si hay varios con menos clientes asignados debe traerl el que mas vendio), 
solo deben considerarse las facturas que tengan mas de dos items facturados:
    1) apellido y nombre del vendedor
    2) total de unidades de producto vendidas
    3) monto promedio de venta por factura
    4) monto total de ventas
El resultado debera mostrar ordenado la cantidad de ventas ascendente, en caso
de igualdad de cantidades, ordenar por codigo de vendedor*/

SELECT
rtrim(e.empl_apellido) + ', ' + rtrim(e.empl_nombre) [Vendedor],
SUM(i.item_cantidad) [Unidades vendidas],
(SUM(i.item_cantidad*i.item_precio) / count(distinct f.fact_tipo+f.fact_sucursal+f.fact_numero))  [Promedio de venta por factura], 
SUM(i.item_cantidad*i.item_precio) [Total ventas]
FROM Empleado e
    JOIN Factura f on f.fact_vendedor=e.empl_codigo
    JOIN Item_Factura i on i.item_sucursal+i.item_tipo+i.item_numero=f.fact_sucursal+f.fact_tipo+f.fact_numero
WHERE e.empl_codigo in (SELECT TOP 5 clie_vendedor
                        FROM Cliente
                        WHERE clie_vendedor is not null
                        GROUP BY clie_vendedor
                        ORDER BY COUNT(*) ASC, (SELECT sum(f2.fact_total)
                                                FROM Factura f2 
                                                WHERE f2.fact_vendedor=clie_vendedor and year(f2.fact_fecha)=(SELECT MAX(YEAR(f1.fact_fecha)) 
                              FROM Factura f1)
                                                    and f2.fact_sucursal+f2.fact_tipo+f2.fact_numero in (SELECT i1.item_sucursal+i1.item_tipo+i1.item_numero
                                                                                                        FROM Item_Factura i1
                                                                                                        GROUP BY i1.item_sucursal,i1.item_tipo,i1.item_numero
                                                                                                        HAVING COUNT(*)>2)))
    AND YEAR(f.fact_fecha) = (SELECT MAX(YEAR(f1.fact_fecha)) 
                              FROM Factura f1)
    AND f.fact_sucursal+f.fact_tipo+f.fact_numero in (SELECT i1.item_sucursal+i1.item_tipo+i1.item_numero
                                                      FROM Item_Factura i1
                                                      GROUP BY i1.item_sucursal,i1.item_tipo,i1.item_numero
                                                      HAVING COUNT(*)>2)
GROUP BY e.empl_codigo, e.empl_apellido, e.empl_nombre
ORDER BY COUNT(f.fact_sucursal+f.fact_tipo+f.fact_numero) ASC, e.empl_codigo

/*
	Dado el contexto inflacionario se tiene que aplicar un control en el cual nunca se 
	permita vender un producto a un precio que no est� entre 0%-5% del precio de venta
	del producto el mes anterior, ni tampoco que est� en m�s de un 50% el precio del mismo
	producto que hace 12 meses atr�s. Aquellos productos nuevos, o que no tuvieron ventas en 
	meses anteriores no debe considerar esta regla ya que no hay precio de referencia
*/
go
CREATE TRIGGER trigger_inflacion
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Item_Factura (item_cantidad,item_numero,item_precio,item_producto,item_sucursal,item_tipo)
    SELECT itd.item_cantidad,itd.item_numero,itd.item_precio,itd.item_producto,itd.item_sucursal,itd.item_tipo
    FROM inserted itd 
         JOIN Factura f on itd.item_sucursal+itd.item_tipo+itd.item_numero=f.fact_sucursal+f.fact_tipo+f.fact_numero
    WHERE not exists (SELECT 1
                    FROM Item_Factura i1
                    JOIN Factura f1 on f1.fact_sucursal+f1.fact_tipo+f1.fact_numero=i1.item_sucursal+i1.item_tipo+i1.item_numero
                    WHERE f1.fact_fecha = DATEADD(MONTH,-1,f.fact_fecha) 
                        and i1.item_producto=itd.item_producto
                        AND itd.item_precio > i1.item_precio*1.05)
        AND not exists (SELECT 1
                        FROM Item_Factura i2
                        JOIN Factura f2 on f2.fact_sucursal+f2.fact_tipo+f2.fact_numero=i2.item_sucursal+i2.item_tipo+i2.item_numero
                        WHERE f2.fact_fecha = DATEADD(YEAR,-1,f.fact_fecha)
                        and i2.item_producto=itd.item_producto
                        AND itd.item_precio > i2.item_precio*1.5)
END

