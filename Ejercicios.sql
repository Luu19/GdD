--EJERCICIO 1--
/*Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o 
igual a $ 1000 ordenado por c�digo de cliente. */
select clie_codigo, clie_razon_social from Cliente 
where clie_limite_credito >= 1000
--EJERCICIO 2--
/*Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por 
cantidad vendida. */

select prod_codigo, prod_detalle from Producto 
join Item_Factura on prod_codigo = item_producto
--join Factura on fact_numero = item_numero //hay que joinear todas las fks
join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
where year(fact_fecha) = 2012
group by prod_detalle, prod_codigo --codigo en join => en group by
order by sum(item_cantidad)

--EJERCICIO 3--
/*Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock 
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por 
nombre del art�culo de menor a mayor*/

select prod_codigo, prod_detalle, sum(stoc_cantidad) as cantidad_total
from Producto join STOCK on stoc_producto = prod_codigo -- con left join se incluyen todos los NULL de producto (no se encuentran en stock)
--where stoc_cantidad > 0
group by prod_detalle, prod_codigo
order by prod_detalle

--EJERCICIO 4--
/*Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de 
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock 
promedio por dep�sito sea mayor a 100*/

select prod_codigo, prod_detalle, count(comp_componente) -- cuantos art�culos diferentes -- comp_cantidad: cantidad de cada articulo
from Producto left join Composicion on comp_producto = prod_codigo 
join STOCK on stoc_producto = prod_codigo
group by prod_codigo, prod_detalle
having avg(stoc_cantidad) > 100

select prod_detalle  -- cuantos art�culos diferentes -- comp_cantidad: cantidad de cada articulo
from Producto join STOCK on stoc_producto = prod_codigo
group by prod_detalle
having avg(stoc_cantidad) > 100

--EJERCICIO 5--

/*Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de 
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que 
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011. */
select prod_codigo, prod_detalle, (select item_cantidad from Item_Factura join) from Producto --NO, select en select no

select prod_codigo, prod_detalle, sum(item_cantidad) from Producto 
--join STOCK on stoc_producto = prod_codigo
join Item_Factura on item_producto = prod_codigo
join Factura on fact_numero = item_numero-- combinar todo
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
having sum(item_cantidad) > (select sum(item_cantidad) from Item_Factura join Factura on 
						fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
						--group by item_producto, fact_fecha
						where year(fact_fecha) = 2011 and item_producto = prod_codigo)
order by 1

--EJERCICIO 6--
/*Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese 
rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que 
tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.*/

					--distinct por repeticiones en STOCK
select rubr_id, rubr_detalle, count(distinct prod_codigo) as cantidad_productos, sum(isnull(stoc_cantidad,0)) as cantidad_stock from Rubro --prod_rubro rubr_id. un producto pertenece a X rubro
left join Producto on prod_rubro = rubr_id --left join porque no todos los productos aparecen en STOCK. Prioridad a la TABLA de la izquierda	  
--join STOCK on prod_codigo = stoc_producto tabla on columnaTabla = columnaSelect
--tambi�n se relaciona por dep�sito por PK del stock. 
										--se multiplica por cantidad de productos por dep�sito en el que aparece										
left join stock on stoc_producto = prod_codigo
--con el where los se pierde el join. filtro los elementos que relacion� con STOCK
where prod_codigo in (select stoc_producto from STOCK group by stoc_producto --select prod_codigo from Producto join STOCK on stoc_producto = prod_codigo group by prod_codigo--faltan productos. Directamente comparo con stoc_producto
					having sum(isnull(stoc_cantidad,0)) > (select stoc_cantidad from STOCK
					where stoc_deposito = '00' and stoc_producto = '00000000'))
					--FALTAN RUBROS por no tener stock					
group by rubr_id, rubr_detalle 
--having sum(stoc_cantidad) > (select stoc_cantidad from STOCK -- ya no tengo el stock del producto, est� agrupado por rubro. No sirve
						--where stoc_deposito = '00' and stoc_producto = '00000000')*/
order by 1

--pasado a limpio. SE VEN LOS 31 RUBROS A PESAR DE NO TENER STOCK
select rubr_id, rubr_detalle, count(distinct prod_codigo) as cantidad_productos, sum(isnull(stoc_cantidad,0)) as cantidad_stock from Rubro 
left join Producto on prod_codigo in (select stoc_producto from STOCK group by stoc_producto --reduzco el universo antes del siguiente join
					having sum(isnull(stoc_cantidad,0)) > (select stoc_cantidad from STOCK
					where stoc_deposito = '00' and stoc_producto = '00000000')) and prod_rubro = rubr_id									
left join stock on stoc_producto = prod_codigo
group by rubr_id, rubr_detalle 
order by 1

--EJERCICIO 7--
/*Generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio 
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio = 
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos art�culos que posean 
stock. */

select prod_codigo, prod_detalle, isnull(max(item_precio),0) as mayor_precio, isnull(min(item_precio),0) as menor_precio, 
CAST((isnull(max(item_precio),0) * 100 / isnull(min(item_precio),1) - 100) as decimal(5,2)) as diferencia from Producto
left join Item_Factura on item_producto = prod_codigo
join STOCK on stoc_producto = prod_codigo  
where isnull(stoc_cantidad,0) > 0  and isnull(item_precio,0) > 0
group by prod_codigo, prod_detalle

--EJERCICIO 8--
/*Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del 
art�culo, stock del dep�sito que m�s stock tiene. */

select prod_codigo, prod_detalle, (select stoc_cantidad from STOCK 
						where stoc_deposito =(select top 1 stoc_deposito from STOCK
											group by stoc_deposito
											order by sum(stoc_cantidad) desc)
											and stoc_producto = prod_codigo), 
						count(stoc_deposito) from Producto
left join STOCK on stoc_producto = prod_codigo
group by prod_detalle,prod_codigo
having count(stoc_deposito) < (select count(DISTINCT depo_codigo) from DEPOSITO) -- '=' no '<'
order by count(stoc_deposito) desc

select top 1 stoc_deposito from STOCK
						group by stoc_deposito
						order by sum(stoc_cantidad) desc

select stoc_cantidad from STOCK
where stoc_deposito =(select top 1 stoc_deposito from STOCK
						group by stoc_deposito
						order by sum(stoc_cantidad) desc)

select prod_detalle, stoc_cantidad from Producto
left join STOCK on stoc_producto = prod_codigo
order by stoc_cantidad desc
select * from stock
order by 1

--EJERCICIO 9--
/*Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del 
mismo y la cantidad de dep�sitos que ambos tienen asignados.*/
--el jefe tambi�n es un empleado 

--jefe y empleado comparten dep�sito (no ocurre con ning�n dep�sito)
select empl_jefe, empl_codigo, empl_nombre, count(depo_codigo) from Empleado 
left join deposito on depo_encargado = empl_codigo and depo_encargado = empl_jefe
group by empl_jefe, empl_codigo, empl_nombre
order by 4

--dep�sitos de jefe y empleado por separado
select empl_codigo, empl_nombre, empl_jefe, count(depo_codigo) as cantidad_empleado, 
	(select count(depo_codigo) from DEPOSITO 
	--left join deposito on depo_encargado = isnull(empl_jefe,-1)
	where depo_encargado = empl_jefe) as cantidad_jefe
from Empleado 
left join deposito on depo_encargado = empl_codigo
group by empl_codigo, empl_nombre,empl_jefe

/*select empl_codigo, empl_nombre, empl_jefe, cast(count(depo_codigo) as varchar) + ' como jefe' from Empleado 
left join deposito on depo_encargado = empl_jefe
group by empl_codigo, empl_nombre,empl_jefe
order by 1*/
--CORRECCI�N: Deben aparecer las cantidades juntas--
select empl_jefe, empl_codigo, rtrim(empl_apellido)+' '+rtrim(empl_nombre), count(depo_codigo) 
from Empleado 
left join DEPOSITO on empl_codigo = depo_encargado or empl_jefe = depo_encargado
group by empl_jefe, empl_codigo, rtrim(empl_apellido)+' '+rtrim(empl_nombre)

--EJERCICIO 10-- 
/*Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos 
vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que 
mayor compra realizo. */

select distinct prod_codigo, (select top 1 fact_cliente from Factura
								--join Item_Factura on item_numero = fact_numero
								join item_factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
								where item_producto = prod_codigo
								group by fact_cliente
								order by sum(item_cantidad) desc) as cliente_mayor_compra from Producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_numero = item_numero
where prod_codigo in (select top 10 item_producto from Item_Factura 
						group by item_producto 
						order by sum(item_cantidad)) or
	 prod_codigo in (select top 10 item_producto from Item_Factura
					group by item_producto
					order by sum(item_cantidad) desc)
order by 1

select top 1 item_producto, fact_cliente, sum(item_cantidad) from Item_Factura
join Factura on fact_numero = item_numero
where item_producto = 10395
group by fact_cliente, item_producto
order by sum(item_cantidad) desc

--EJERCICIO 11--
/*Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de 
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deber�n 
ordenar de mayor a menor, por la familia que m�s productos diferentes vendidos tenga, 
solo se deber�n mostrar las familias que tengan una venta superior a 20000 pesos para 
el a�o 2012.*/

select fami_detalle, count(distinct prod_codigo) as productos, sum(item_cantidad * item_precio) as ventas from Familia
join Producto on prod_familia = fami_id
join Item_Factura on item_producto = prod_codigo
where fami_id in (select fami_id from Familia
						join Producto on prod_familia = fami_id
						join Item_Factura on item_producto = prod_codigo
						join factura on fact_numero = item_numero
						where year(fact_fecha) = 2012 
						group by fami_id
						having sum(item_cantidad * item_precio) > 20000)
group by fami_detalle
order by 2 

select item_producto, sum(item_cantidad * item_precio) from item_Factura
join factura on fact_numero = item_numero
where year(fact_fecha) = 2012 
group by item_producto
having sum(item_cantidad * item_precio) > 20000

--EJERCICIO 12--
/*Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe 
promedio pagado por el producto, cantidad de dep�sitos en los cuales hay stock del 
producto y stock actual del producto en todos los dep�sitos. Se deber�n mostrar 
aquellos productos que hayan tenido operaciones en el a�o 2012 y los datos deber�n 
ordenarse de mayor a menor por monto vendido del producto.*/

select prod_codigo, prod_detalle, count(distinct fact_cliente) as clientes, 
isnull(cast(avg(distinct item_precio) as decimal(18,2)),0) as precio_promedio
,count(distinct stoc_deposito) as depositos,--sum(stoc_cantidad) as stock_total
(select sum(stoc_cantidad) from stock where stoc_producto = prod_codigo) as stock_total-- 
from producto
left join Item_factura on item_producto = prod_codigo
left join Factura on fact_numero = item_numero
left join STOCK on stoc_producto = prod_codigo
where year(fact_fecha) = 2012
group by prod_detalle, prod_codigo
order by sum(item_cantidad) desc

--EJERCICIO 13--
/*Realizar una consulta que retorne para cada producto que posea composici�n  nombre 
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
de los productos que lo componen. Solo se deber�n mostrar los productos que est�n 
compuestos por m�s de 2 productos y deben ser ordenados de mayor a menor por 
cantidad de productos que lo componen.*/

select A.prod_detalle, A.prod_precio, sum(comp_cantidad * B.prod_precio)
from Producto A
join Composicion C on comp_producto = A.prod_codigo
join Producto B on B.prod_codigo = comp_componente
group by A.prod_detalle, A.prod_precio
having sum(comp_cantidad) > 2
order by sum(comp_cantidad) desc

--EJERCICIO 14--
/*Escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que 
debe retornar son:  
C�digo del cliente, Cantidad de veces que compro en el �ltimo a�o, Promedio por compra en el �ltimo a�o, 
Cantidad de productos diferentes que compro en el �ltimo a�o, Monto de la mayor compra que realizo en el �ltimo a�o  
Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en el �ltimo a�o. 
No se deber�n visualizar NULLs en ninguna columna */

select fact_cliente, count(distinct fact_numero) as ComprasRealizadas, avg(fact_total) as PromedioPorCompra,
count(distinct item_producto) as CantidadProductosDistintos , 
max(fact_total) as MayorCompra from Factura
left join Item_Factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero 
where year(fact_fecha) = (select max(year(fact_fecha)) from Factura)
group by fact_cliente
order by 2 desc

--EJERCICIO 15--
/*Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos 
(en la misma factura) m�s de 500 veces. El resultado debe mostrar el c�digo y 
descripci�n de cada uno de los productos y la cantidad de veces que fueron vendidos 
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron 
juntos dichos productos. Los distintos pares no deben retornarse m�s de una vez. */

select distinct p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle , count(*) as veces from Producto p1
join Item_Factura i1 on p1.prod_codigo = i1.item_producto,
Producto p2 join Item_Factura i2 on p2.prod_codigo = i2.item_producto
where I1.item_tipo + I1.item_sucursal + I1.item_numero = I2.item_tipo + I2.item_sucursal + I2.item_numero 
and i1.item_producto < i2.item_producto -- ???? and i1.item_producto <> i2.item_producto
group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
having count(*) > 500 --and p1.prod_codigo <> p2.prod_codigo
order by 5 desc

--EJERCICIO 16--
/*Con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran 
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son 
inferiores a 1/3 del promedio de ventas del producto que m�s se vendi� en el 2012.  
Adem�s mostrar 
1. Nombre del Cliente 
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente. 
3. C�digo de producto que mayor venta tuvo en el 2012 (en caso de existir m�s de 1, 
mostrar solamente el de menor c�digo) para ese cliente.  
Aclaraciones:  
La composici�n es de 2 niveles, es decir, un producto compuesto solo se compone de 
productos no compuestos. 
Los clientes deben ser ordenados por c�digo de provincia ascendente.*/

select clie_razon_social, count(item_cantidad) as cantidad_vendida, (select top 1 item_producto from Item_Factura
							join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo								
							where year(fact_fecha) = 2012 and fact_cliente = clie_codigo
							group by item_producto
							order by sum(item_cantidad) desc, item_producto asc) as producto_mayor_venta from cliente
join Factura on fact_cliente = clie_codigo
join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
/*+*/ where year(fact_fecha) = 2012
group by clie_razon_social,clie_codigo,clie_domicilio
having sum(item_cantidad) <  (select top 1 avg(item_cantidad) from Item_Factura
							join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo								
							where year(fact_fecha) = 2012
							group by item_producto
							order by sum(item_cantidad) desc) * (1/3)
order by clie_domicilio

--EJERCICIO 17--
/*Escriba una consulta que retorne una estad�stica de ventas por a�o y mes para cada 
producto  
La consulta debe retornar:  
PERIODO: A�o y mes de la estad�stica con el formato YYYYMM 
PROD: C�digo de producto 
DETALLE: Detalle del producto 
CANTIDAD_VENDIDA = Cantidad vendida del producto en el periodo 
VENTAS_A�O_ANT= Cantidad vendida del producto en el mismo mes del periodo 
pero del a�o anterior 
CANT_FACTURAS= Cantidad de facturas en las que se vendi� el producto en el 
periodo 
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada 
por periodo y c�digo de producto. */
select distinct -- format(f2.fact_fecha, 'yyyy-MM') --no permite group by por mes y a�o
 STR(YEAR(f2.fact_fecha))+STR(MONTH(f2.fact_fecha))
,prod_codigo, prod_detalle, 
sum(item_cantidad) as cantidad_vendida ,isnull((select sum(isnull(item_cantidad,0)) from Item_Factura i 
										join Factura f1 on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
										where i.item_producto = prod_codigo and
										year(f1.fact_fecha) = year(f2.fact_fecha) - 1 
										and month(f1.fact_fecha) = month(f2.fact_fecha)
										/*and prod_codigo = i.item_producto*/),0)as cantidad_vendida_a�o_ant ,
count(fact_numero) as cantidad_facturas from Factura f2
join Item_Factura on item_numero + item_sucursal + item_tipo = f2.fact_numero + f2.fact_sucursal + f2.fact_tipo
join Producto on prod_codigo = item_producto
group by year(f2.fact_fecha), month(f2.fact_fecha), prod_codigo, prod_detalle 
order by 1 desc, 2
 
 --EJERCICIO 18--
/* Escriba una consulta que retorne una estad�stica de ventas para todos los rubros. 
La consulta debe retornar: 
DETALLE_RUBRO: Detalle del rubro 
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro 
PROD1: C�digo del producto m�s vendido de dicho rubro 
PROD2: C�digo del segundo producto m�s vendido de dicho rubro 
CLIENTE: C�digo del cliente que compro m�s productos del rubro en los �ltimos 30 
d�as 
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada 
por cantidad de productos diferentes vendidos del rubro. */

select rubr_detalle, sum(item_precio * item_cantidad) as ventas, (select top 1 prod_codigo from Producto
												where prod_rubro = rubr_id
												group by prod_codigo
												order by sum(item_cantidad)) as producto_mas_vendido,
												(select top 1 prod_codigo from Producto
												where prod_rubro = rubr_id and prod_codigo <> (select top 1 prod_codigo from Producto
																								where prod_rubro = rubr_id
																								group by prod_codigo
																								order by sum(item_cantidad))
																								group by prod_codigo
																								order by sum(item_cantidad)) as '2producto_mas_vendido',
(select top 1 clie_codigo from Cliente
join Factura on fact_cliente = clie_codigo
join item_factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
join Producto on item_producto = prod_codigo
where prod_rubro = rubr_id --and fact_fecha = GETDATE() - day(30)
group by clie_codigo
order by sum(item_cantidad)) as cliente from Producto
join Rubro on rubr_id = prod_rubro
join Item_Factura on item_producto = prod_codigo
group by rubr_detalle, rubr_id
order by count(distinct prod_codigo)

SELECT R.rubr_detalle	
	,SUM(IFACT.item_precio * IFACT.item_cantidad) as ventas
	,ISNULL((
		SELECT TOP 1 item_producto
		FROM Producto INNER JOIN Item_Factura ON item_producto = prod_codigo
		WHERE R.rubr_id = prod_rubro
		GROUP BY item_producto	ORDER BY SUM(item_cantidad)DESC
		),0) AS [Cod del prod mas vendido]
	,ISNULL((
		SELECT TOP 1 item_producto
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
		WHERE R.rubr_id = prod_rubro
			AND prod_codigo <> (SELECT TOP 1 item_producto
									FROM Producto
										INNER JOIN Item_Factura
											ON item_producto = prod_codigo
									WHERE R.rubr_id = prod_rubro
									GROUP BY item_producto
									ORDER BY SUM(item_cantidad)DESC
									)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad)DESC
		),0) AS [Cod del segundo prod mas vendido]
	,ISNULL((
		SELECT TOP 1 fact_cliente
		FROM Producto
			INNER JOIN Item_Factura	ON item_producto = prod_codigo
			INNER JOIN Factura	ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_rubro = R.rubr_id --AND fact_fecha BETWEEN GETDATE() AND (GETDATE()-30)
			--AND fact_fecha > DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura))--
			--AND fact_fecha BETWEEN DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura)) AND (SELECT MAX(fact_fecha) FROM Factura)
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		),'-') AS [Cod CLiente]
FROM RUBRO R
	INNER JOIN Producto P
		ON P.prod_rubro = R.rubr_id
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
GROUP BY R.rubr_detalle,R.rubr_id
ORDER BY COUNT(DISTINCT IFACT.item_producto)
/*dudoso*/