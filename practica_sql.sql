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

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/

SELECT 
r.rubr_detalle DETALLE_RUBRO,
ISNULL(SUM(i.item_cantidad*i.item_precio),0) VENTAS,
ISNULL((SELECT TOP 1 p1.prod_codigo
        FROM Producto p1 JOIN Item_Factura i1 on i1.item_producto=p1.prod_codigo
        WHERE p1.prod_rubro=r.rubr_id
        GROUP BY p1.prod_codigo
        ORDER BY SUM(i1.item_cantidad) DESC
        ),'-') PROD1,
ISNULL((SELECT TOP 1 p2.prod_codigo
        FROM Producto p2 JOIN Item_Factura i2 on i2.item_producto=p2.prod_codigo
        WHERE p2.prod_rubro=r.rubr_id AND p2.prod_codigo != (SELECT TOP 1 p3.prod_codigo
                                                            FROM Producto p3 JOIN Item_Factura i3 on i3.item_producto=p3.prod_codigo
                                                            WHERE p3.prod_rubro=r.rubr_id
                                                            GROUP BY p3.prod_codigo
                                                            ORDER BY SUM(i3.item_cantidad) DESC)
        GROUP BY p2.prod_codigo
        ORDER BY SUM(i2.item_cantidad) DESC),'-') PROD2,
ISNULL((SELECT TOP 1 f.fact_cliente
        FROM Producto p4 JOIN Item_Factura i4 on i4.item_producto=p4.prod_codigo
                         JOIN Factura f on f.fact_tipo+f.fact_numero+f.fact_sucursal=i4.item_tipo+i4.item_numero+i4.item_sucursal
        WHERE p4.prod_rubro=r.rubr_id AND f.fact_fecha >= DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura))
        GROUP BY f.fact_cliente
        ORDER BY COUNT(i4.item_cantidad) DESC --o seria item_producto?
         ),'-') CLIENTE
FROM Rubro r JOIN Producto p on r.rubr_id=p.prod_rubro
             JOIN Item_Factura i on i.item_producto=p.prod_codigo   
GROUP BY r.rubr_detalle, rubr_id
ORDER BY COUNT(DISTINCT i.item_producto)

/*19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
 Codigo de producto
 Detalle del producto
 Codigo de la familia del producto
 Detalle de la familia actual del producto
 Codigo de la familia sugerido para el producto
 Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

SELECT
p.prod_codigo,
p.prod_detalle,
p.prod_familia,
f.fami_detalle FAMILIA_ACTUAL,
(SELECT TOP 1 p1.prod_familia
FROM Producto p1
WHERE LEFT(p.prod_detalle,5)=LEFT(p1.prod_detalle,5)
GROUP BY p1.prod_familia
ORDER BY COUNT(*) DESC, p1.prod_familia) FAMILIA_SUGERIDA,
(SELECT f3.fami_detalle 
FROM Familia f3
WHERE f3.fami_id=(SELECT TOP 1 p1.prod_familia
                  FROM Producto p1
                  WHERE LEFT(p.prod_detalle,5)=LEFT(p1.prod_detalle,5)
                  GROUP BY p1.prod_familia
                  ORDER BY COUNT(*) DESC,p1.prod_familia)) DETALLE_FAMILIA_SUGERIDA
FROM Producto p JOIN Familia f on p.prod_familia=f.fami_id
WHERE p.prod_familia != (SELECT TOP 1 p1.prod_familia
                        FROM Producto p1
                        WHERE LEFT(p.prod_detalle,5)=LEFT(p1.prod_detalle,5)
                        GROUP BY p1.prod_familia
                        ORDER BY COUNT(*) DESC, p1.prod_familia)
ORDER BY p.prod_detalle 

/*20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año.*/

SELECT TOP 3 
e.empl_codigo LEGAJO, 
e.empl_nombre+empl_apellido NOMBRE_Y_APELLIDO, 
YEAR(e.empl_ingreso) AÑO_INGRESO,
(CASE 
WHEN (SELECT COUNT(*) 
      FROM Factura f
      WHERE f.fact_vendedor=e.empl_codigo AND YEAR(f.fact_fecha)=2011) >=50
THEN (SELECT COUNT(*) 
      FROM Factura f1 
      WHERE e.empl_codigo=f1.fact_vendedor and YEAR(f1.fact_fecha)=2011 and f1.fact_total>100)
ELSE(SELECT COUNT(*)*0.5 
     FROM Factura f2 
     WHERE YEAR(f2.fact_fecha)=2011 and f2.fact_vendedor in (SELECT e1.empl_codigo 
                                                            FROM Empleado e1 
                                                            WHERE e1.empl_jefe=e.empl_codigo))
END) PUNTAJE_2011,
(CASE 
WHEN (SELECT COUNT(*) 
      FROM Factura f
      WHERE f.fact_vendedor=e.empl_codigo AND YEAR(f.fact_fecha)=2012) >=50
THEN (SELECT COUNT(*) 
      FROM Factura f1 
      WHERE e.empl_codigo=f1.fact_vendedor and YEAR(f1.fact_fecha)=2012 and f1.fact_total>100)
ELSE(SELECT COUNT(*)*0.5 
     FROM Factura f2 
     WHERE YEAR(f2.fact_fecha)=2012 and f2.fact_vendedor in (SELECT e1.empl_codigo 
                                                            FROM Empleado e1 
                                                            WHERE e1.empl_jefe=e.empl_codigo))
END) PUNTAJE_2012
FROM Empleado e
ORDER BY 5 DESC

/*21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta 
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año*/

SELECT 
YEAR(ti.fact_fecha) AÑO,
COUNT(DISTINCT ti.fact_cliente) CLIENTES_MAL_FACTURADOS,
COUNT(*) FACTURAS_INCORRECTAS
FROM (SELECT 
      fact_cliente,
      fact_fecha,
      fact_sucursal,
      fact_tipo,
      fact_numero
     FROM Factura JOIN Item_Factura on fact_sucursal+fact_tipo+fact_numero=item_sucursal+item_tipo+item_numero
     GROUP BY fact_cliente,fact_fecha,fact_sucursal,fact_tipo,fact_numero,fact_total,fact_total_impuestos
     HAVING (fact_total-fact_total_impuestos) NOT BETWEEN SUM(item_cantidad*item_precio)-1
                                             AND SUM(item_cantidad*item_precio)+1) ti --tabla de facturas incorrectas y clientes mal facturados
GROUP BY YEAR(ti.fact_fecha)

/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.*/

SELECT 
r.rubr_detalle DETALLE_RUBRO,
TRIMESTRE = CASE
            WHEN MONTH(f.fact_fecha) BETWEEN 1 AND 3 THEN 1
            WHEN MONTH(f.fact_fecha) BETWEEN 4 AND 6 THEN 2
            WHEN MONTH(f.fact_fecha) BETWEEN 7 AND 9 THEN 3
            WHEN MONTH(f.fact_fecha) BETWEEN 10 AND 12 THEN 4
            END,
COUNT(DISTINCT f.fact_sucursal+f.fact_tipo+f.fact_numero) FACTURAS_EMITIDAS,
COUNT(DISTINCT p.prod_codigo) PRODUCTOS_DISTINTOS_VENDIDOS
FROM Rubro r JOIN Producto p on r.rubr_id=p.prod_rubro
             JOIN Item_Factura i on i.item_producto=p.prod_codigo
             JOIN Factura f on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
WHERE p.prod_codigo not in (SELECT comp_producto FROM Composicion)
GROUP BY r.rubr_detalle, YEAR(f.fact_fecha), CASE
            WHEN MONTH(f.fact_fecha) BETWEEN 1 AND 3 THEN 1
            WHEN MONTH(f.fact_fecha) BETWEEN 4 AND 6 THEN 2
            WHEN MONTH(f.fact_fecha) BETWEEN 7 AND 9 THEN 3
            WHEN MONTH(f.fact_fecha) BETWEEN 10 AND 12 THEN 4
            END
HAVING COUNT(DISTINCT f.fact_sucursal+f.fact_tipo+f.fact_numero)>100
ORDER BY r.rubr_detalle ASC, COUNT(DISTINCT f.fact_sucursal+f.fact_tipo+f.fact_numero) DESC

/*23. Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente.*/

WITH PRODUCTOS_CON_COMPOSICION --NO USAR WITH 
AS (SELECT DISTINCT comp_producto PROD_COMPUESTO FROM Composicion),

VENTA_ANUAL_POR_PRODUCTO 
AS (SELECT item_producto PROD, SUM(item_cantidad*item_precio) VENTA_ANUAL,YEAR(fact_fecha) ANIO
    FROM Factura JOIN Item_Factura on fact_sucursal+fact_tipo+fact_numero=item_sucursal+item_tipo+item_numero
    WHERE item_producto in  (SELECT PROD_COMPUESTO FROM PRODUCTOS_CON_COMPOSICION)
    GROUP BY item_producto,YEAR(fact_fecha)),

PRODUCTOS_COMPUESTOS_MAS_VENDIDOS_POR_ANIO
AS (SELECT 
    (SELECT TOP 1 PROD FROM VENTA_ANUAL_POR_PRODUCTO VA1 WHERE VA1.ANIO=VA.ANIO ORDER BY VENTA_ANUAL DESC) PROD, 
    VA.ANIO,
    (SELECT TOP 1 VA2.VENTA_ANUAL
     FROM VENTA_ANUAL_POR_PRODUCTO VA2
     WHERE VA2.ANIO = VA.ANIO
     ORDER BY VA2.VENTA_ANUAL DESC) VENTA_ANUAL
    FROM VENTA_ANUAL_POR_PRODUCTO VA),

CANTIDAD_COMPONENTES_POR_PRODUCTO_COMPUESTO
AS (SELECT comp_producto PROD_COMP, COUNT(DISTINCT comp_componente) CANT_COMPONENTES
    FROM Composicion
    GROUP BY comp_producto
    ),

CANTIDAD_FACTURAS_POR_PRODUCTO
AS (SELECT item_producto PROD, COUNT(DISTINCT fact_sucursal+fact_tipo+fact_numero) CANT_FACTURAS, YEAR(fact_fecha) ANIO
    FROM Factura JOIN Item_Factura on fact_sucursal+fact_tipo+fact_numero=item_sucursal+item_tipo+item_numero
    GROUP BY item_producto,YEAR(fact_fecha)),

CLIENTES_QUE_MAS_COMPRARON
AS (SELECT DISTINCT
    (SELECT TOP 1 f1.fact_cliente
     FROM Factura f1 JOIN Item_Factura i1 on f1.fact_sucursal+f1.fact_tipo+f1.fact_numero=i1.item_sucursal+i1.item_tipo+i1.item_numero
     WHERE i1.item_producto = i.item_producto AND YEAR(f1.fact_fecha)=YEAR(f.fact_fecha)
     GROUP BY f1.fact_cliente
     ORDER BY SUM(item_cantidad) DESC) CLIENTE, 
     i.item_producto PRODUCTO,
     YEAR(f.fact_fecha) ANIO
    FROM Factura f JOIN Item_Factura i on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
    GROUP BY YEAR(f.fact_fecha), i.item_producto
    ),

VENTAS_ANUALES
AS (SELECT YEAR(fact_fecha) ANIO, SUM(item_cantidad*item_precio) VENTAS_TOTALES
    FROM Factura JOIN Item_Factura on fact_sucursal+fact_tipo+fact_numero=item_sucursal+item_tipo+item_numero
    GROUP BY YEAR(fact_fecha))

SELECT
T1.ANIO AÑO,
T1.PROD PROD_COMP_MAS_VENDIDO,
T2.CANT_COMPONENTES CANTIDAD_COMPONENTES,
T3.CANT_FACTURAS CANTIDAD_FACTURAS,
T4.CLIENTE CLIENTE_QUE_MAS_COMPRO,
(T5.VENTA_ANUAL*100)/(SELECT VENTAS_TOTALES FROM VENTAS_ANUALES VA WHERE VA.ANIO=T1.ANIO) PORCENTAJE_VENTAS
FROM PRODUCTOS_COMPUESTOS_MAS_VENDIDOS_POR_ANIO T1
     JOIN CANTIDAD_COMPONENTES_POR_PRODUCTO_COMPUESTO T2 ON T1.PROD=T2.PROD_COMP
     JOIN CANTIDAD_FACTURAS_POR_PRODUCTO T3 ON T3.PROD=T1.PROD AND T3.ANIO=T1.ANIO
     JOIN CLIENTES_QUE_MAS_COMPRARON T4 ON T4.PRODUCTO=T1.PROD AND T4.ANIO=T1.ANIO
     JOIN VENTA_ANUAL_POR_PRODUCTO T5 ON T1.PROD=T5.PROD AND T1.ANIO=T5.ANIO
GROUP BY T1.ANIO,T1.PROD,T2.CANT_COMPONENTES,T3.CANT_FACTURAS,T4.CLIENTE,T5.VENTA_ANUAL
ORDER BY T5.VENTA_ANUAL DESC

/*24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) UNIDADES_FACTURADAS
FROM Item_Factura i 
     JOIN Factura f on i.item_sucursal+i.item_tipo+i.item_numero=f.fact_sucursal+f.fact_tipo+f.fact_numero
     JOIN Producto p on p.prod_codigo=i.item_producto
WHERE (f.fact_vendedor) in (SELECT TOP 2 e1.empl_codigo
                            FROM Empleado e1 
                            ORDER BY e1.empl_comision DESC)
      AND (i.item_producto) in (SELECT DISTINCT comp_producto FROM Composicion)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING COUNT(DISTINCT f.fact_sucursal+f.fact_tipo+f.fact_numero) >= 5
ORDER BY SUM(i.item_cantidad) DESC

/*25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.*/

SELECT 
year(f.fact_fecha) [AÑO],
p.prod_familia [FAMILIA_MAS_VENDIDA],
COUNT(DISTINCT p.prod_rubro) [CANT_RUBROS],
(CASE
WHEN (SELECT TOP 1 P2.prod_codigo
      FROM Item_Factura I2 
           JOIN Producto P2 ON P2.prod_codigo=I2.item_producto
           JOIN Factura F2 ON F2.fact_sucursal+F2.fact_tipo+F2.fact_numero=I2.item_sucursal+I2.item_tipo+I2.item_numero
      WHERE YEAR(F2.fact_fecha)=YEAR(f.fact_fecha) AND P2.prod_familia=p.prod_familia
      GROUP BY P2.prod_codigo
      ORDER BY SUM(I2.item_cantidad) DESC) in (SELECT c.comp_producto FROM Composicion c) 
THEN (SELECT COUNT(*) FROM Composicion c1 WHERE c1.comp_producto=(SELECT TOP 1 P2.prod_codigo
                                                                  FROM Item_Factura I2 
                                                                  JOIN Producto P2 ON P2.prod_codigo=I2.item_producto
                                                                  JOIN Factura F2 ON F2.fact_sucursal+F2.fact_tipo+F2.fact_numero=I2.item_sucursal+I2.item_tipo+I2.item_numero
                                                                  WHERE YEAR(F2.fact_fecha)=YEAR(f.fact_fecha) AND P2.prod_familia=p.prod_familia
                                                                  GROUP BY P2.prod_codigo
                                                                  ORDER BY SUM(I2.item_cantidad) DESC))
ELSE 0 --o 1 xd 
END) [CANT_PROD_QUE_COMPONEN_AL_PROD_MAS_VENDIDO_DE_LA_FAMILIA],
COUNT(DISTINCT f.fact_sucursal+f.fact_tipo+f.fact_numero) [CANT_FACTURAS_EN_LAS_QUE_APARECEN_PRODUCTOS_DE_LA_FAMILIA],
(SELECT TOP 1 F3.fact_cliente
FROM Item_Factura I3
     JOIN Factura F3 ON F3.fact_sucursal+F3.fact_tipo+F3.fact_numero=I3.item_sucursal+I3.item_tipo+I3.item_numero
     JOIN Producto P3 ON P3.prod_codigo=I3.item_producto
WHERE P3.prod_familia=p.prod_familia and YEAR(f.fact_fecha)=YEAR(F3.fact_fecha)
GROUP BY F3.fact_cliente
ORDER BY SUM(I3.item_cantidad) DESC) [CLIENTE_QUE_MAS_COMPRO],
(((SUM(i.item_cantidad*i.item_precio))*100)/(SELECT SUM(I4.item_cantidad*I4.item_precio)
                                            FROM Factura F4 
                                            JOIN Item_Factura I4 ON F4.fact_sucursal+F4.fact_tipo+F4.fact_numero=I4.item_sucursal+I4.item_tipo+I4.item_numero
                                            WHERE YEAR(F4.fact_fecha)=YEAR(f.fact_fecha))) [PORCENTAJE_QUE_REPRESENTA]
FROM Factura f 
     JOIN Item_Factura i on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
     JOIN Producto p on i.item_producto=p.prod_codigo
WHERE p.prod_familia = (SELECT TOP 1 P1.prod_familia --mejor poner el filtro de la familia mas vendida en el where, ya que manejariamos menos datos para el group by
                        FROM Item_Factura I1 
                             JOIN Factura F1 ON F1.fact_sucursal+F1.fact_tipo+F1.fact_numero=I1.item_sucursal+I1.item_tipo+I1.item_numero
                             JOIN Producto P1 ON P1.prod_codigo=I1.item_producto
                        WHERE YEAR(F1.fact_fecha)=YEAR(f.fact_fecha)
                        GROUP BY P1.prod_familia
                        ORDER BY SUM(I1.item_cantidad) DESC)
GROUP BY YEAR(f.fact_fecha), p.prod_familia
ORDER BY SUM(i.item_cantidad*i.item_precio), 2 DESC

/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
 Empleado
 Depósitos que tiene a cargo
 Monto total facturado en el año corriente
 Codigo de Cliente al que mas le vendió
 Producto más vendido
 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT 
e.empl_codigo, 
COUNT(DISTINCT d.depo_codigo) DEPOSITOS_A_CARGO,
(SELECT SUM(f6.fact_total) FROM Factura f6 WHERE f6.fact_vendedor=f.fact_vendedor AND YEAR(f6.fact_fecha)=YEAR(f.fact_fecha)) MONTO_FACTURADO,
(SELECT TOP 1 f2.fact_cliente
FROM Factura f2
WHERE YEAR(f.fact_fecha)=YEAR(f2.fact_fecha) AND f2.fact_vendedor=f.fact_vendedor
GROUP BY f2.fact_cliente
ORDER BY SUM(f2.fact_total) DESC
) CLIENTE_AL_QUE_MAS_LE_VENDIO,
(SELECT TOP 1 i3.item_producto
FROM Item_Factura i3 JOIN Factura f3 on f3.fact_sucursal+f3.fact_tipo+f3.fact_numero=i3.item_sucursal+i3.item_tipo+i3.item_numero
WHERE f.fact_vendedor=f3.fact_vendedor AND YEAR(f.fact_fecha)=YEAR(f3.fact_fecha)
GROUP BY i3.item_producto
ORDER BY SUM(i3.item_cantidad) DESC) PRODUCTO_MAS_VENDIDO,
(((SELECT SUM(f5.fact_total) FROM Factura f5 WHERE YEAR(f5.fact_fecha)=YEAR(f.fact_fecha) AND f5.fact_vendedor=f.fact_vendedor)*100)/(SELECT SUM(f4.fact_total) FROM Factura f4 WHERE YEAR(f4.fact_fecha)=YEAR(f.fact_fecha))) PORCENTAJE_DE_VENTA
FROM Empleado e 
    LEFT JOIN DEPOSITO d on d.depo_encargado=e.empl_codigo --LEFT JOIN POR SI HAY EMPLEADOS QUE NO ESTAN A CARGO DE DEPOSITOS O QUE NO HAYAN FACTURADO
    LEFT JOIN Factura f on f.fact_vendedor=e.empl_codigo
WHERE YEAR(f.fact_fecha)=(SELECT TOP 1 YEAR(f1.fact_fecha) FROM Factura f1 ORDER BY YEAR(f1.fact_fecha) DESC)
GROUP BY e.empl_codigo, YEAR(f.fact_fecha), f.fact_vendedor
ORDER BY (SELECT SUM(f5.fact_total) FROM Factura f5 WHERE YEAR(f5.fact_fecha)=YEAR(f.fact_fecha) AND f5.fact_vendedor=f.fact_vendedor) DESC

/*27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
 Año
 Codigo de envase
 Detalle del envase
 Cantidad de productos que tienen ese envase
 Cantidad de productos facturados de ese envase
 Producto mas vendido de ese envase
 Monto total de venta de ese envase en ese año
 Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor*/

SELECT 
YEAR(f.fact_fecha) AÑO,
e.enva_codigo CODIGO_ENVASE,
e.enva_detalle DETALLE_ENVASE,
COUNT(DISTINCT p.prod_codigo) CANTIDAD_DE_PRODUCTOS_QUE_LO_UTILIZAN,
SUM(ISNULL(i.item_cantidad,0)) CANTIDAD_DE_PRODUCTOS_FACTURADOS,
(SELECT TOP 1 i2.item_producto
FROM Item_Factura i2 
     JOIN Factura f2 on f2.fact_sucursal+f2.fact_tipo+f2.fact_numero=i2.item_sucursal+i2.item_tipo+i2.item_numero
     JOIN Producto p2 on p2.prod_codigo=i2.item_producto
WHERE YEAR(f2.fact_fecha)=YEAR(f.fact_fecha) AND p2.prod_envase=e.enva_codigo
GROUP BY i2.item_producto
ORDER BY SUM(i2.item_cantidad) DESC) PRODUCTO_MAS_VENDIDO,
SUM(i.item_cantidad*i.item_precio) VENTA_ANUAL_ENVASE,
((SUM(i.item_cantidad*i.item_precio))*100/(SELECT SUM(f3.fact_total) 
                                           FROM Factura f3 
                                           WHERE YEAR(f3.fact_fecha)=YEAR(f.fact_fecha))) PORCENTAJE_DE_VENTAS
FROM Envases e 
     LEFT JOIN Producto p on e.enva_codigo=p.prod_envase
     LEFT JOIN Item_Factura i on i.item_producto=p.prod_codigo
     JOIN Factura f on f.fact_sucursal+f.fact_tipo+f.fact_numero=i.item_sucursal+i.item_tipo+i.item_numero
GROUP BY YEAR(f.fact_fecha), e.enva_codigo, e.enva_detalle
ORDER BY 1, 7 DESC  

