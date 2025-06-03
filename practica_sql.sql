/*1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.*/
select clie_codigo,clie_razon_social from Cliente
where clie_limite_credito>=1000
order by clie_codigo
/*2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/
select prod_codigo,prod_detalle,SUM(item_cantidad) as cant_vendida
from Item_Factura join Producto on item_producto=prod_codigo 
                  join Factura on fact_tipo=item_tipo and fact_numero=item_numero and fact_sucursal=item_sucursal
where year(fact_fecha)=2012
group by prod_codigo,prod_detalle
order by cant_vendida
/*3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.*/
select prod_codigo,prod_detalle,sum(isnull(stoc_cantidad,0)) as stock_total from Producto left join STOCK on prod_codigo=stoc_producto
group by prod_codigo,prod_detalle
order by 2
/*4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.*/
select prod_codigo,prod_detalle,COUNT(distinct comp_componente) as cant_componentes,AVG(stoc_cantidad) stoc_promedio
from Producto left join Composicion on prod_codigo=comp_producto join STOCK on prod_codigo=stoc_producto --inner join porque tiene que estar en la columna stock para que tenga sentido
group by prod_codigo,prod_detalle
having AVG(stoc_cantidad) >100
order by 3 DESC 
/*5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.*/ --codigo,detalle,cant ventas de ese art en 2012
select prod_codigo,prod_detalle, SUM(item_cantidad) as total_egresos
from Item_Factura join Producto on item_producto=prod_codigo
                  join Factura on item_tipo+item_numero+item_sucursal=fact_tipo+fact_numero+fact_sucursal
where year(fact_fecha)=2012
group by prod_codigo,prod_detalle
having SUM(item_cantidad) > (select SUM(item_cantidad)
                            from Item_Factura join Factura on item_tipo+item_numero+item_sucursal=fact_tipo+fact_numero+fact_sucursal
                            where year(fact_fecha)=2011 and item_producto=prod_codigo)
/*6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/

---------------------------------------MAL HECHO-------------------------------------------------------------------------
select rubr_id,rubr_detalle,SUM(isnull(stoc_cantidad,0)) as stock_total,count(distinct prod_codigo) as cant_articulos 
from Rubro left join Producto on rubr_id=prod_rubro
            left join STOCK on prod_codigo=stoc_producto
group by rubr_id,rubr_detalle
having SUM(isnull(stoc_cantidad,0))> (select stoc_cantidad from STOCK where stoc_producto='00000000' and stoc_deposito='00')
--lo del having esta mal porque lo que me esta comparando no es el stock de cada producto, sino el stock de cada rubro, y eso no es lo que piden
order by rubr_id

--siempre que haya un left join, si hago count tiene que ser de una columna que no este en la tabla left, por si hay valores en null
--ojo cuando hago el join con stock porque no lo estoy haciendo con una pk, eso nos cambia todo el universo
/*for(!eof rubro) 31
    for(!eof producto) 2190
        for(!eof stock) 5500*/
--left join por stock porque si no solo me agarra aquellos productos que tienen stock, y yo quiero todos los productos.

---------------------------------------BIEN HECHO-------------------------------------------------------------------------
select rubr_id, rubr_detalle, count(distinct prod_codigo), sum(isnull(stoc_cantidad,0))
from rubro left join Producto on prod_codigo in (select stoc_producto from stock group by stoc_producto
                    having sum(isnull(stoc_cantidad,0)) > 
                    (select stoc_Cantidad from stock where stoc_producto = '00000000' and stoc_Deposito = '00'))
 and rubr_id = prod_rubro left join stock on stoc_producto = prod_codigo 
group by rubr_id, rubr_detalle
order by rubr_id

/*7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.*/

select prod_codigo,prod_detalle,max(prod_precio) as mayor_precio,min(prod_precio) as menor_precio, ((max(prod_precio)-min(prod_precio))*100/min(prod_precio)) as diferencia_precios_porcentaje
from Producto join Item_Factura on prod_codigo=item_producto
group by prod_codigo,prod_detalle
having prod_codigo in (select stoc_producto from STOCK where stoc_cantidad>0) --esto en el where porque si no primero procesa el join y despues lo filtra, siempre que pueda condicionar antes es mejor
order by prod_codigo

--resolucion reinosa
select prod_codigo,prod_detalle,max(prod_precio) as mayor_precio,min(prod_precio) as menor_precio, ((max(prod_precio)-min(prod_precio))*100/min(prod_precio)) as diferencia_precios_porcentaje
from Producto join Item_Factura on prod_codigo=item_producto
where prod_codigo in (select stoc_producto from STOCK where stoc_cantidad>0)
order by prod_codigo

/*8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.*/
select prod_detalle,max(stoc_cantidad) from Producto join STOCK on prod_codigo=stoc_producto
group by prod_detalle
having count(stoc_deposito) = (select COUNT(depo_codigo) from DEPOSITO) -- va un * en cada count
order by prod_detalle

--resolucion reinosa
select prod_detalle,max(stoc_cantidad) from Producto join STOCK on prod_codigo=stoc_producto
group by prod_detalle
having count(*) = (select COUNT(*) from DEPOSITO)
order by prod_detalle

/*9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.*/ --sumar los depositos del empleado y del jefe

--resolucion reinosa
select empl_jefe,empl_codigo,empl_nombre,count(*) from Empleado join DEPOSITO on empl_codigo=depo_encargado or empl_jefe=depo_encargado --la clave esta en el or
group by empl_jefe,empl_codigo,empl_nombre

/*10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.*/
select prod_codigo,prod_detalle,(select top 1 fact_cliente
                                from Factura join Item_Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
                                where prod_codigo = item_producto
                                group by fact_cliente order by sum(item_cantidad) desc)  
from Producto
where prod_codigo in (select top 10 item_producto from Item_Factura
                     group by item_producto
                     order by SUM(item_cantidad) desc)
                  or prod_codigo in (select top 10 item_producto from Item_Factura
                                    group by item_producto
                                    order by sum(item_cantidad))


select prod_codigo,(select top 1 fact_cliente
                                from Factura join Item_Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
                                where prod_codigo = item_producto
                                group by fact_cliente order by sum(item_cantidad) desc) from Producto
where prod_codigo in (select TOP 10 item_producto from Item_Factura
                        group by item_producto
                        order by 1 desc) 
union all 
select prod_codigo from Producto
where prod_codigo in (select TOP 10 item_producto from Item_Factura
                        group by item_producto
                        order by 1) --el union all si quiero los 10 mas vendidos primero y los 10 menos vendidos despues, si no podia hacerlo con un or

--resolucion reinosa
select prod_codigo, prod_detalle, (select top 1 fact_cliente 
                   from factura join item_factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
                   where prod_codigo = item_producto group by fact_cliente order by sum(item_cantidad) desc) 
 from producto
where prod_codigo in 
    (select top 10 item_producto
    from item_factura
    group by item_producto
    order by sum(item_cantidad) desc) 
or prod_codigo in 
    (select top 10 item_producto
    from item_factura
    group by item_producto
    order by sum(item_cantidad))

/*11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.*/
select fami_detalle,count(distinct item_producto),sum(isnull(item_cantidad*item_precio,0)) from Familia join Producto on fami_id=prod_familia join Item_Factura on prod_codigo=item_producto
group by fami_detalle,fami_id
having fami_id in (select prod_familia 
                    from Producto join Item_Factura on prod_codigo=item_producto join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
                    where year(fact_fecha) = 2012
                    group by prod_familia
                    having sum(isnull(item_cantidad*item_precio,0)) > 20000) 
order by 2

select prod_familia 
from Producto join Item_Factura on prod_codigo=item_producto join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where year(fact_fecha) = 2012
group by prod_familia
having sum(isnull(item_cantidad*item_precio,0)) > 20000
--en donde esta lo que me piden
--las funciones de agregacion se resuelven despues del group by 
--resolucion reinosa
select fami_detalle, count(distinct prod_codigo), sum(isnull(item_precio*item_cantidad,0))
from familia join Producto on fami_id = prod_familia join Item_Factura on prod_codigo = item_producto
group by fami_id, fami_detalle
having fami_id in 
(select prod_familia from producto join item_factura on item_producto = prod_codigo
                   join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where year(fact_fecha) = 2012 
group by prod_familia
having sum(item_cantidad*item_precio) > 20000)
order by 2

/*12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.*/
select prod_detalle, 
       count(distinct fact_cliente) as cant_clientes, 
       avg(item_precio) as promedio_pagado, 
       --count(distinct stoc_deposito) as cant_depos_con_stock, 
       (select count(distinct stoc_deposito) from STOCK where prod_codigo=stoc_producto and stoc_cantidad>0) as cant_depos_con_stock,
       --sum(stoc_cantidad) stock_total
       (select sum(isnull(stoc_cantidad,0)) from STOCK where prod_codigo=stoc_producto) as stock_actual
from Producto join Item_Factura on prod_codigo=item_producto 
              join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero 
              --join STOCK on stoc_producto=prod_codigo
where YEAR(fact_fecha)=2012 
group by prod_detalle,prod_codigo
--having prod_codigo in (select item_producto from Item_Factura join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero 
                       --where year(fact_fecha) = 2012)  
order by sum(isnull(item_cantidad*item_precio,0)) desc

select item_producto from Item_Factura join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero 
where year(fact_fecha) = 2012

--resolucion guia
SELECT P.prod_detalle
	,COUNT(DISTINCT F.fact_cliente) AS [Cantidad Clientes que compraron el prod]
	,AVG(IFACT.item_precio) [Importe Promedio]
	,(
		SELECT COUNT(DISTINCT stoc_deposito) 
		FROM STOCK
		WHERE P.prod_codigo = stoc_producto 
			AND ISNULL(stoc_cantidad,0)>0
	) AS [Cantidad de Depositos en los que hay stock]
	,(
		SELECT SUM(stoc_cantidad)
		FROM STOCK
		WHERE P.prod_codigo = stoc_producto
	) AS [Stock Actual en todos los depositos]
FROM Producto P
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_tipo = IFACT.item_tipo AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_numero = IFACT.item_numero
	/*INNER JOIN STOCK S
		ON P.prod_codigo = S.stoc_producto*/
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM(IFACT.item_cantidad * IFACT.item_precio) DESC

/*13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.*/
select prod_detalle,prod_precio,sum((select prod_precio from Producto where prod_codigo=comp_producto)*comp_cantidad) 
from Composicion join Producto on comp_producto=prod_codigo
group by prod_detalle,prod_precio
having count(comp_componente)>2
order by count(comp_componente) desc

select prod_codigo,prod_precio from Producto where prod_codigo in (select comp_componente from Composicion)
--(select prod_codigo,prod_precio from Producto where prod_codigo=comp_producto)

select comp_producto,prod_detalle,comp_componente,prod_precio,comp_cantidad from Composicion join Producto on comp_componente=prod_codigo

select comp_producto,prod_detalle from Composicion join Producto on comp_producto=prod_codigo

--mi respuesta final
select p1.prod_detalle,p1.prod_precio,sum(p2.prod_precio*c.comp_cantidad) precio_sumatoria_ind
from Composicion c join Producto p1 on c.comp_producto=p1.prod_codigo join Producto p2 on c.comp_componente=p2.prod_codigo
group by p1.prod_detalle,p1.prod_precio
having sum(c.comp_cantidad)>2 --aca para mi era count de los comp_componente, pero son dos formas de verlo creo
order by sum(c.comp_cantidad) desc

--respuesta guia
SELECT COMBO.prod_detalle,COMBO.prod_precio,SUM(Componente.prod_precio * C.comp_cantidad) 
FROM Producto COMBO
	INNER JOIN Composicion C
		ON C.comp_producto = COMBO.prod_codigo
	INNER JOIN Producto Componente
		ON Componente.prod_codigo = C.comp_componente
GROUP BY COMBO.prod_detalle,COMBO.prod_precio
HAVING SUM(C.comp_cantidad) > 2
ORDER BY SUM(C.comp_cantidad) DESC

/*14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna*/
select fact_cliente, 
       count(distinct fact_numero+fact_tipo+fact_sucursal) cant_compras_ult_año, 
       avg(fact_total) promedio_x_compra, 
       count(distinct item_producto) cant_prod_dif,
       max(fact_total) mayor_compra
from Factura join Item_Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
where year(fact_fecha)=(select max(year(fact_fecha)) from Factura)--(SELECT DATEPART(YY,GETDATE()))
group by fact_cliente
order by 2 DESC

--resolucion guia
SELECT fact_cliente	'Código Cliente',
	   COUNT(DISTINCT fact_tipo + fact_sucursal + fact_numero) 'Compras ultimo año',
	   AVG(fact_total) 'Promedio por Compra',
	   COUNT(DISTINCT item_producto) 'Cantidad de Artículos Diferentes',
	   MAX(fact_total) 'Compra Máxima'
FROM Factura JOIN Item_Factura
		ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero			
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY fact_cliente
ORDER BY 2 DESC

SELECT * FROM Factura
WHERE fact_cliente = '01742'

/*15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2*/

select prod1.item_producto,d1.prod_detalle, prod2.item_producto,d2.prod_detalle, count(*) veces_vend_juntos
from Item_Factura prod1 join Producto d1 on prod1.item_producto=d1.prod_codigo 
                        join Item_Factura prod2 on prod1.item_tipo+prod1.item_numero+prod1.item_sucursal=prod2.item_tipo+prod2.item_numero+prod2.item_sucursal
                        join Producto d2 on prod2.item_producto=d2.prod_codigo
group by prod1.item_producto,d1.prod_detalle, prod2.item_producto,d2.prod_detalle
having count(*)>500
order by count(*) desc

--resolucion guia
SELECT  P1.prod_codigo 'Código Producto 1',
		P1.prod_detalle 'Detalle Producto 1',
		P2.prod_codigo 'Código Producto 2',
		P2.prod_detalle 'Detalle Producto 2',
		COUNT(*) 'Cantidad de veces'
FROM Producto P1 JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto,
	 Producto P2 JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
WHERE I1.item_tipo + I1.item_sucursal + I1.item_numero = I2.item_tipo + I2.item_sucursal + I2.item_numero
	AND I1.item_producto < I2.item_producto 
GROUP BY P1.prod_codigo, P1.prod_detalle, P2.prod_codigo, P2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY 5 DESC

/* 16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente 
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente.
*/

SELECT clie_codigo,
       clie_razon_social,
       clie_domicilio,
       sum(item_cantidad) unidades_vendidas,
       (SELECT TOP 1 item_producto
        FROM Factura JOIN Item_Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
        WHERE year(fact_fecha)=2012 AND fact_cliente=clie_codigo
        GROUP BY item_producto
        ORDER BY SUM(item_cantidad) DESC, item_producto ASC) item_mas_comprado
FROM Cliente c JOIN Factura f on c.clie_codigo=f.fact_cliente 
               JOIN Item_Factura i on f.fact_tipo+f.fact_numero+f.fact_sucursal=i.item_tipo+i.item_numero+i.item_sucursal
WHERE year(fact_fecha)=2012 --2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
GROUP BY clie_codigo,clie_razon_social,clie_domicilio
HAVING sum(item_cantidad) < (SELECT AVG(item_cantidad) FROM Item_Factura JOIN Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
                            WHERE item_producto = ( SELECT TOP 1 item_producto 
                            FROM Item_Factura JOIN Factura on fact_tipo+fact_numero+fact_sucursal=item_tipo+item_numero+item_sucursal
                            WHERE year(fact_fecha)=2012
                            GROUP BY item_producto
                            ORDER BY SUM(item_cantidad) DESC ) ) / 3
ORDER BY 3

/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.*/

SELECT 
YEAR(f.fact_fecha)*100+MONTH(f.fact_fecha) PERIODO, 
p.prod_codigo PROD, 
p.prod_detalle DETALLE,
SUM(ISNULL(i.item_cantidad,0)) CANTIDAD_VENDIDA,
ISNULL((SELECT SUM(isnull(i1.item_cantidad,0))
FROM Item_Factura i1 JOIN Factura f1 on f1.fact_tipo+f1.fact_numero+f1.fact_sucursal=i1.item_tipo+i1.item_numero+i1.item_sucursal
WHERE year(f.fact_fecha)=dateadd(year,1,f1.fact_fecha) and month(f.fact_fecha)=month(f1.fact_fecha) and i1.item_producto=i.item_producto
GROUP BY i1.item_producto),0) VENTAS_AÑO_ANT,
ISNULL(COUNT(f.fact_tipo+f.fact_numero+f.fact_sucursal),0) CANT_FACTURAS
FROM Producto p JOIN Item_Factura i on p.prod_codigo=i.item_producto 
              JOIN Factura f on f.fact_tipo+f.fact_numero+f.fact_sucursal=i.item_tipo+i.item_numero+i.item_sucursal
GROUP BY YEAR(f.fact_fecha)*100+MONTH(f.fact_fecha), p.prod_codigo, p.prod_detalle, year(f.fact_fecha), month(f.fact_fecha), i.item_producto
ORDER BY 1 DESC,2 


