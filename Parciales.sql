-- Parcial 04 07 2023 - Reinosa
/*
	Realizar una consulta SQL que retorne para los 10 clientes que más compraron en el 2012 
	y que fueron atendidos por más de 3 vendedores distintos:
		1. Nombre y Apellido del Cliente
		2. Cantidad de productos distintos comprados en el 2012
		3. Cantidad de unidades compradas dentro del primer semestre del 2012

	El resultado deberá mostrar ordenado la cantidad de ventas descendente del 2012 de cada cliente,
	en caso de igualdad de ventas, ordenar por código de cliente.
*/

select top 10 clie_razon_social, count(distinct item_producto) as prod_distintos, 
sum(case when month(fact_fecha)between 1 and 6 then item_cantidad else 0 end) as compras 
from Cliente
join Factura on fact_cliente = clie_codigo
join Item_Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
where year(fact_fecha) = 2012
group by clie_razon_social,clie_codigo
having count(distinct fact_vendedor) > 3
order by count(distinct fact_numero) desc ,clie_codigo asc

-- Parcial 11 07 2023

/*
	La empresa necesita recuperar ventas perdidas. Con el fin de lanzar una nueva campaña comercial,
	se pide una consulta SQL que retorne aquellos clientes cuyas ventas (considerar fact_total)
	del año 2012 fueron inferiores al 25% del promedio de ventas de los productos vendidos entre los
	años 2011 y 2010.
	En base a lo solicitado, se requiere un listado con la siguiente información:
		1. Razon social del cliente
		2. Mostrar la leyenda 'Cliente Recurrente' si dicho cliente realizó más de una compra
		en el 2012. En caso de que haya solo 1 compra, entonces mostrar la leyenda 'Unica vez'
		3. Cantidad de productos totales vendidas en el 2012 para ese cliente
		4. Codigo de producto que mayor tuvo ventas en el 2012 (en caso de existir mas de 1,
		mostrar solamente el de menor codigo) para ese cliente
*/

select c.clie_razon_social, 
(case when count(distinct f.fact_numero) > 1 then 'Cliente recurrente' else case when count(distinct f.fact_numero) = 1 then 'Unica vez' else null end end),
sum(i.item_cantidad) as productos_totales, 
(select top 1 item_producto from Item_Factura
join Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
where fact_cliente = c.clie_codigo and year(fact_fecha) = 2012
group by item_producto
order by sum(item_cantidad) desc, item_producto asc) from Cliente c
join Factura f on fact_cliente = clie_codigo
join Item_Factura i on i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
where year(fact_fecha) = 2012
group by clie_razon_social, clie_codigo
having sum(fact_total) < 0.25 * (select avg(fact_total) from factura
								where fact_cliente = c.clie_codigo and 
								(year(fact_fecha) = 2011 or year(fact_fecha) = 2010))


-- Parcial 25 06 2024
/*
	La empresa está muy comprometida con el desarrollo sustentable, y como consecuencia de ello propone cambiar 
	los envases de sus productos por envases reciclados.
	Si bien entiende la importancia de este cambio, también es consciente de los costos que esto conlleva, 
	por lo cual se realizará de manera paulatina.
	Por tal motivo se solicita un listado con los 5 productos más vendidos y los 5 productos menos vendidos durante el año 2012.
	Comparar la cantidad vendida de cada uno de estos productos con la cantidad vendida del año anterior e indicar el string
	‘Más ventas’ o ‘Menos ventas’, según corresponda.
	Además, indicar el detalle del envase.

	El resultado debe incluir:
	A) Código del producto
	B) Comparación con el año anterior
	C) Detalle del envase*/

	select prod_codigo,(case when sum(item_cantidad) > 
						(select sum(i.item_cantidad) from Item_Factura i
						join Factura on i.item_tipo + i.item_numero + i.item_sucursal = fact_tipo + fact_numero + fact_sucursal
						where year(fact_fecha) = 2011 and item_producto = prod_codigo) then 'Más ventas' else 'Menos ventas' end) 
			,enva_detalle from Producto
	join Envases on enva_codigo = prod_envase
	join Item_Factura on item_producto = prod_codigo
	join Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
	where prod_codigo in (select top 5 item_producto from Item_Factura
							join Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
							where year(fact_fecha) = 2012							
							group by item_producto
							order by sum(item_cantidad) desc) -- más vendidos
		and year(fact_fecha) = 2012
	group by prod_codigo , enva_detalle

	union
	select prod_codigo, (case when sum(item_cantidad) > 
						(select sum(i.item_cantidad) from Item_Factura i
						join Factura on i.item_tipo + i.item_numero + i.item_sucursal = fact_tipo + fact_numero + fact_sucursal
						where year(fact_fecha) = 2011 and item_producto = prod_codigo) then 'Más ventas' else 'Menos ventas' end) 
			,enva_detalle from Producto
	join Envases on enva_codigo = prod_envase
	join Item_Factura on item_producto = prod_codigo
	join Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
	where prod_codigo in (select top 5 item_producto from Item_Factura
						join Factura on item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
						where year(fact_fecha) = 2012
						group by item_producto
						order by sum(item_cantidad) asc) --menos vendidos
		and year(fact_fecha) = 2012
	group by prod_codigo , enva_detalle


