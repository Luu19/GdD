use GD2015C1

/*
	Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o 
	igual a $ 1000 ordenado por c�digo de cliente
*/
select 
	c.clie_codigo,
	c.clie_razon_social  
from Cliente c
where c.clie_limite_credito >= 1000

/*
	Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por 
	cantidad vendida.
*/
select 
	p.prod_codigo,
	p.prod_detalle  
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
where year(f.fact_fecha) = 2012
group by p.prod_codigo, p.prod_detalle
order by sum(i.item_cantidad)

/*
	Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock 
	total, sin importar en que deposito se encuentre, los datos deben ser ordenados por 
	nombre del art�culo de menor a mayor.
*/
select 
	p.prod_codigo,
	p.prod_detalle,
	isnull(sum(s.stoc_cantidad), 0)
from Producto p 
join STOCK s on s.stoc_producto = p.prod_codigo
group by p.prod_codigo, p.prod_detalle
order by 2

/*
	Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de 
	art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock 
	promedio por dep�sito sea mayor a 100.
*/
select 
	p.prod_codigo,
	p.prod_detalle,
	count(c.comp_componente)
from Producto p 
join Composicion c on c.comp_producto = p.prod_codigo
group by p.prod_codigo, p.prod_detalle
having p.prod_codigo in 
(
	select s.stoc_producto
	from STOCK s 
	group by s.stoc_producto
	having avg(s.stoc_cantidad) > 100
)

/*
	Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de 
	stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que 
	fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.
*/
select 
	p.prod_codigo,
	p.prod_detalle,
	sum(i.item_cantidad)
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
where year(f.fact_fecha) = 2012
group by p.prod_codigo, p.prod_detalle
having sum(i.item_cantidad) > (
	select 
	sum(i2.item_cantidad)
	from Item_Factura i2
	join Factura  f2 on f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
	where year(f2.fact_fecha) = 2011 and i2.item_producto = p.prod_codigo
	)

/*
	Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese 
	rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que 
	tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.
*/
select 
	r.rubr_id,
	r.rubr_detalle,
	count(p.prod_codigo),
	sum(s.stoc_cantidad)

from Rubro r
left join Producto p  on p.prod_rubro = r.rubr_id
left join STOCK s on s.stoc_producto = p.prod_codigo
where s.stoc_cantidad > (
        SELECT 
            s2.stoc_cantidad
        FROM 
            STOCK s2
        JOIN 
            DEPOSITO d2 ON d2.depo_codigo = s2.stoc_deposito
        WHERE 
            s2.stoc_producto = '00000000' AND d2.depo_codigo = '00'
    )
group by r.rubr_id, r.rubr_detalle

/*
	Generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio 
	menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio = 
	10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos art�culos que posean 
	stock.
*/
select
	p.prod_codigo,
	p.prod_detalle,
	max(i.item_precio) as max_precio,
	min(i.item_precio) as min_precio,
	cast(
		(max(i.item_precio) - min(i.item_precio)) *100 / min(i.item_precio) AS DECIMAL(10,2)
		)
from Producto p 
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
where p.prod_codigo in (select s.stoc_producto from STOCK s where s.stoc_cantidad > 0)
group by p.prod_codigo, p.prod_detalle

/*
	Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del
	art�culo, stock del dep�sito que m�s stock tiene.
*/
select
	p.prod_detalle,
	max(s.stoc_cantidad)
from Producto p
join STOCK s on s.stoc_producto = p.prod_codigo
group by p.prod_codigo, p.prod_detalle
having count(distinct s.stoc_deposito) = (select count(*) from DEPOSITO) -- tiene stock en todos los depositos

/*
	Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del
	mismo y la cantidad de dep�sitos que ambos tienen asignados.
*/
select
	e.empl_codigo,
	e.empl_jefe,
	(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = e.empl_codigo)
from Empleado e

/*
	Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos 
	vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que 
	mayor compra realizo.
*/
select  
	p.prod_codigo,
	(SELECT TOP 1
			fact_cliente
	FROM Item_Factura
	JOIN Factura ON item_numero + item_tipo + item_sucursal = 
	fact_numero + fact_tipo + fact_sucursal
	WHERE item_producto = prod_codigo 
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC) AS mejor_cliente
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
where p.prod_codigo in (
	select top 10 
		p.prod_codigo
	from Producto p
	join Item_Factura i on i.item_producto = p.prod_codigo 
	join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
	group by p.prod_codigo, p.prod_detalle
	order by sum(i.item_cantidad) asc) 
	or p.prod_codigo in (
		select top 10 
			p.prod_codigo
		from Producto p
		join Item_Factura i on i.item_producto = p.prod_codigo 
		join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		group by p.prod_codigo, p.prod_detalle
		order by sum(i.item_cantidad) desc)
group by p.prod_codigo, p.prod_detalle

/*
	11 - Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
	productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deber�n 
	ordenar de mayor a menor, por la familia que m�s productos diferentes vendidos tenga, 
	solo se deber�n mostrar las familias que tengan una venta superior a 20000 pesos para 
	el a�o 2012.
*/
select
	fam.fami_detalle,
	count(distinct i.item_producto) as productos_distintos_vendidos,
	sum(f.fact_total) as total
	-- tambi�n se puede hacer sin Factura y poner SUM(item_precio * item_cantidad) en vez de sum(f.fact_total)
from Familia fam
join Producto p on p.prod_familia = fam.fami_id
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
group by fam.fami_id, fam.fami_detalle
having fam.fami_id in (
		select
			fam2.fami_id
		from Familia fam2
		join Producto p2 on p2.prod_familia = fam2.fami_id
		join Item_Factura i2 on i2.item_producto = p2.prod_codigo 
		join Factura f2 on f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
		where year(f2.fact_fecha) = 2012
		group by fam2.fami_id, fam2.fami_detalle
		having sum(f2.fact_total) > 2000
		)
order by 2 desc

/*
	12 - Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe 
	promedio pagado por el producto, cantidad de dep�sitos en los cuales hay stock del 
	producto y stock actual del producto en todos los dep�sitos. Se deber�n mostrar 
	aquellos productos que hayan tenido operaciones en el a�o 2012 y los datos deber�n 
	ordenarse de mayor a menor por monto vendido del producto.
*/
select
	p.prod_codigo,
	count(distinct f.fact_cliente) as cantidad_clientes,
	avg(i.item_precio) as precio_promedio,
	isnull(count(s.stoc_deposito), 0) as cantidad_depositos,
	sum(s.stoc_cantidad) as stock_total
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
left join STOCK s on s.stoc_producto = p.prod_codigo
group by p.prod_codigo
having p.prod_codigo in 
	(
		select
			i2.item_producto
		from Item_Factura i2 
		join Factura f2 on f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
		where year(f2.fact_fecha) = 2012
		group by i2.item_producto
	)
order by sum(i.item_cantidad * i.item_precio) desc

/*
	13 - Realizar una consulta que retorne para cada producto que posea composici�n nombre 
	del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
	de los productos que lo componen. Solo se deber�n mostrar los productos que est�n 
	compuestos por m�s de 2 productos y deben ser ordenados de mayor a menor por 
	cantidad de productos que lo componen.
*/
select
	p.prod_detalle,
	p.prod_precio,
	sum(c.comp_cantidad * pc.prod_precio)
from Producto p
join Composicion c on c.comp_producto = p.prod_codigo
join Producto pc on pc.prod_codigo = c.comp_componente
group by p.prod_detalle, p.prod_codigo, p.prod_precio
having count(distinct c.comp_componente) > 2
order by sum(c.comp_cantidad)

/*
	14 - Escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que 
	debe retornar son:
		C�digo del cliente
		Cantidad de veces que compro en el �ltimo a�o
		Promedio por compra en el �ltimo a�o
		Cantidad de productos diferentes que compro en el �ltimo a�o
		Monto de la mayor compra que realizo en el �ltimo a�o
	Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en 
	el �ltimo a�o.
	No se deber�n visualizar NULLs en ninguna columna
*/
select
	c.clie_codigo,
	count(f.fact_cliente) as cantidad_veces,
	avg(f.fact_total) as promedio_compra,
	count(distinct i.item_producto) as cantidad_prod_distintos,
	max(f.fact_total) as mayor_compra
from Cliente c
join Factura f on f.fact_cliente = c.clie_codigo
join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
where year(f.fact_fecha) = year(f.fact_fecha) - 1
group by c.clie_codigo
order by count(f.fact_cliente)

/*
	15 - Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos 
	(en la misma factura) m�s de 500 veces. El resultado debe mostrar el c�digo y 
	descripci�n de cada uno de los productos y la cantidad de veces que fueron vendidos 
	juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron 
	juntos dichos productos. Los distintos pares no deben retornarse m�s de una vez.

*/
-- creo que quedaria mas performante 2 joins a Producto
SELECT I1.item_producto AS 'Codigo 1',
	(SELECT prod_detalle 
	FROM Producto 
	WHERE prod_codigo = I1.item_producto) AS 'Producto 1',
	I2.item_producto AS 'Codigo 2',
	(SELECT prod_detalle 
	FROM Producto 
	WHERE prod_codigo = I2.item_producto) AS 'Producto 2',
	COUNT(*) AS 'Repeticiones'
FROM Item_Factura I1
join Item_Factura I2 on I1.item_numero + I1.item_sucursal + I1.item_tipo =  I2.item_numero + I2.item_sucursal + I2.item_tipo 
AND I1.item_producto != I2.item_producto
AND I1.item_producto > I2.item_producto
GROUP BY I1.item_producto, I2.item_producto
HAVING COUNT(*) > 500
ORDER BY 5

/*
	16 - Con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran 
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
	Los clientes deben ser ordenados por c�digo de provincia ascendente.
*/
select 
	c.clie_razon_social,
	ISNULL(SUM(i.item_cantidad), 0),
	(select top 1 i1.item_producto
	FROM Item_Factura i1
	JOIN Factura f1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = 
	f1.fact_numero + f1.fact_tipo + f1.fact_sucursal 
	where year(f1.fact_fecha) = 2012 and f1.fact_cliente = c.clie_codigo
	GROUP BY i1.item_producto
	ORDER BY SUM(i1.item_cantidad) DESC, i1.item_producto asc)
from Cliente c
left join Factura f on c.clie_codigo = f.fact_cliente and year(f.fact_fecha) = 2012
join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero 
group by c.clie_razon_social, c.clie_codigo, c.clie_domicilio
having sum(f.fact_total) < 
(
	select 
		top 1 avg(i2.item_cantidad * i2.item_precio) * (1.00 / 3) 
	from Factura f2
	join Item_Factura i2 on f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
	where year(f2.fact_fecha) = 2012
	group by i2.item_producto
	order by sum(i2.item_cantidad) desc 
)

order by c.clie_domicilio asc


/*
	17 - Escriba una consulta que retorne una estad�stica de ventas por a�o y mes para cada
	producto.
	La consulta debe retornar:
		PERIODO: A�o y mes de la estad�stica con el formato YYYYMM
		PROD: C�digo de producto
		DETALLE: Detalle del producto
		CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
		VENTAS_A�O_ANT= Cantidad vendida del producto en el mismo mes del periodo 
		pero del a�o anterior
		CANT_FACTURAS= Cantidad de facturas en las que se vendi� el producto en el 
		periodo	
	La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada 
	por periodo y c�digo de producto.
*/

select
	FORMAT(f.fact_fecha, 'yyyyMM') AS periodo,
	p.prod_codigo,
	p.prod_detalle,
	sum(i.item_cantidad) as cantidad,
		ISNULL(
	  (
		SELECT 
		  SUM(i2.item_cantidad)
		FROM Item_Factura AS i2
		JOIN Factura AS f2
		  ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero
		   = i2.item_tipo + i2.item_sucursal + i2.item_numero
		WHERE 
		  i2.item_producto = p.prod_codigo
		  AND FORMAT(f2.fact_fecha, 'yyyyMM')
			  = FORMAT(
				  DATEADD(
					YEAR, 
					-1, 
					CONVERT(date, FORMAT(f.fact_fecha,'yyyyMM') + '01')
				  ), 
				  'yyyyMM'
				)
	  ),
	  0
	) AS ventas_a�o_ant,
	count(distinct f.fact_tipo + f.fact_sucursal + f.fact_numero)
from Factura f
join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
join Producto p on p.prod_codigo = i.item_producto
group by FORMAT(f.fact_fecha, 'yyyyMM'), p.prod_codigo, p.prod_detalle
order by FORMAT(f.fact_fecha, 'yyyyMM'), p.prod_codigo