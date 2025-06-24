-- Parcial de 24 06 2025
use GD2015C1
/*
	Realizar una consulta SQL que retorne para el ultimo año, los 5 vendedores con
	menos clientes asignados, que más vendieron en pesos (si hay varios con menos
	clientes asignados debe traer el que mas vendió), solo deben considerarse las facturas
	que tengan mas de dos items facturados:
		1. Apellido y Nombre del vendedor
		2. Total de unidades de Productos vendidas
		3. Monto promedio de venta x factura
		4. Monto total de ventas
	El resultado debera mostrar ordenado la cantidad de ventas descendente, en caso de
	igualdad de cantidad, ordenar x codigo de vendedor
*/
select
	e.empl_apellido + ' ' + e.empl_nombre,
	sum(i.item_cantidad),
	avg(f.fact_total),
	sum(f.fact_total)
from Empleado e
join Factura f on f.fact_vendedor = e.empl_codigo
join Item_Factura i on i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_tipo + f.fact_sucursal
where year(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura) -- Seria el ultimo año
and f.fact_numero + f.fact_tipo + f.fact_sucursal in 
	(select 
		(f1.fact_numero + f1.fact_tipo + f1.fact_sucursal) 
		from Factura f1
		join Item_Factura i1 on i1.item_numero + i1.item_sucursal + i1.item_tipo = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
		group by f1.fact_numero + f1.fact_tipo + f1.fact_sucursal -- Agrupo x factura
		having count(i1.item_producto) > 2 -- filtro aquellas que tengan mas de dos items
	) 
 and e.empl_codigo in
(
	select top 5 
	empl_codigo
	from Empleado
	join Factura on fact_vendedor = empl_codigo
	where YEAR(fact_fecha) = (SELECT MAX(YEAR(f1.fact_fecha)) FROM Factura f1)
	group by empl_codigo
	order by count(distinct fact_cliente) asc, sum(fact_total) desc
)
group by e.empl_codigo, e.empl_nombre, e.empl_apellido
order by count(f.fact_numero + f.fact_tipo + f.fact_sucursal) desc, e.empl_codigo
