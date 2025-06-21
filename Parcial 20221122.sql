-- Parcial 22 11 2022
use GD2015C1
/*
Realizar una consulta SQL que muestre productos que tengan 3 componentes a nivel producto y cuyos componentes tengan
2 rubros distintos.
De estos productos mostrar:
	1. Codigo de producto
	2. Nombre de producto
	3. Cantidad de veces que fueron vendidos sus componentes en el 2012
	4. Monto total vendido del producto
*/
select 
	p.prod_codigo,
	p.prod_detalle,
	(
		select sum(item_cantidad)
		from Item_Factura i
		join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		where year(f.fact_fecha) = 2012
		and i.item_producto in (select comp_componente from Composicion where comp_producto = p.prod_codigo)
	),
	(
		select sum(item_cantidad * item_precio)
		from Item_Factura i
		join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		and i.item_producto = p.prod_codigo
	)
from Producto p
join Composicion c on c.comp_producto = p.prod_codigo
join Producto p1 on p1.prod_codigo = c.comp_componente
group by p.prod_codigo, p.prod_detalle
having count(DISTINCT c.comp_componente) > 3 and count(DISTINCT p1.prod_rubro) > 2

/*
Implementar una regla de negocio en linea donde se valide que nunca un producto compuesto
pueda estar compuesto por dos componente de rubros dintitntos a él
*/
GO
CREATE TRIGGER validacion_prod_compuesto
ON Composicion
FOR INSERT, UPDATE 
AS
BEGIN
	
	if exists ( 
	select i.comp_producto from inserted i
	join Producto p1 on p1.prod_codigo = i.comp_producto 
	join Producto p2 on p2.prod_codigo = i.comp_componente
	where p1.prod_rubro <> p2.prod_rubro
	group by i.comp_producto
	having count(*) >= 2)
	begin
		print 'Error'
		rollback
	end
END
GO
