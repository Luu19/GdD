USE GD2015C1

-- Parcial 04/07/2023

/*
Realizar una consulta SQL que retorne para todas las zonas que tengan 3 (tres) o más depósitos:
	1. Detalle Zona
	2. Cantidad de depósitos x zona
	3. Cantidad de productos distintos compuestos en sus depósitos
	4. Producto mas vendido en el año 201 que tenga stock en al menos uno de sus depósitos
	5. Mejor encargado perteneciente a esa zona (El que más vendió en la historia)
El resultado deberá estar ordenado por monto total vendido del encargado descendiente
*/

select
	z.zona_detalle,
	count(distinct d.depo_codigo),
	count(distinct (case when stoc_producto in (select comp_producto from Composicion) then stoc_producto else 0 end)),
	(
		select top 1 item_producto
		from Item_Factura i
		join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		where year(f.fact_fecha) = 2012
			and exists (
				SELECT 1
				FROM STOCK s JOIN DEPOSITO d2 ON d2.depo_codigo = s.stoc_deposito
				   WHERE s.stoc_cantidad > 0
					 AND d2.depo_zona = z.zona_codigo
					 AND s.stoc_producto = i.item_producto
			)
		group by item_producto
		order by sum(item_cantidad) desc
	),
	(
		select top 1 fact_vendedor
		from Item_Factura i
		join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		join Empleado on empl_codigo = fact_vendedor
		join Departamento on depa_codigo = empl_departamento
		where depa_zona = z.zona_detalle
		group by fact_vendedor
		order by sum(item_cantidad) 
	) as encargado
from Zona z
join DEPOSITO d on d.depo_zona = z.zona_codigo
join STOCK s on s.stoc_deposito = d.depo_codigo
group by z.zona_codigo, z.zona_detalle
having count(distinct d.depo_codigo) > 3
order by (
		select sum(item_cantidad * item_precio)
		from Item_Factura i
		join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		join Empleado on empl_codigo = fact_vendedor
		join Departamento on depa_codigo = empl_departamento
		where depa_zona = z.zona_detalle
		group by fact_vendedor
		order by sum(item_cantidad) 
	)

/*
Actualmente el campo fact_vendedor representa al empleado que vendió la factura. Implementar el/los
objetos necesarios para respetar la integridad referencial de dicho campo, suponiendo que no existe una
FK entre ambos
*/
GO
CREATE TRIGGER validacion_vendedor
ON Factura
FOR INSERT, UPDATE 
AS
BEGIN

	if exists ( select 1 from inserted where not exists (select 1 from Empleado where empl_codigo = fact_vendedor))
	begin
		print 'Error: el vendedor no existe'
		rollback

	end
END
GO

