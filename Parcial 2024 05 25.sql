-- Parcial 2024 05 25
/*
	Dada la crisis que atraviesa la empresa, el directorio solicita un informe especial para poder
	analizar y definir la nueva estrategia a adoptar.
	Este informe consta de un listado de aquellos productos cuyas ventas de lo que va del año 2012
	fueron superiores al 15% del promedio de ventas de los productos vendidos entre los años 2010 y 2011.
	En base a lo solicitado, armar una consulta SQL que retorne la siguiente informacion:
		1. Detalle del producto
		2. Mostrar la leyenda "Popular" si dicho producto figura en más de 100 facturas realizadas
		en el 2012. Caso contrario, mostrar una leyenda "Sin interes"
		3. Cantidad de facturas en las que aparece el producto en el año 2012
		4. Codigo de cliente que mas compro dicho producto en el 2012 (en caso de existir más de un cliente, mostrar
		solamente el de menor codigo)
*/
use GD2015C1
select
	p.prod_detalle as detalle_producto,
	(case when count(f.fact_sucursal + f.fact_numero + f.fact_tipo) > 100 then 'Popular' else 'Sin interes' end),
	count(f.fact_sucursal + f.fact_numero + f.fact_tipo),
	(
		select top 1 f1.fact_cliente
		from Factura f1
		join Item_Factura i1 on i1.item_numero + i1.item_sucursal + i1.item_tipo = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
		where year(f1.fact_fecha) = 2012
		group by f1.fact_cliente
		order by sum(i1.item_cantidad), 1
	)
from Factura f
join Item_Factura i on i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_tipo + f.fact_sucursal
join Producto p on p.prod_codigo = i.item_producto
where year(f.fact_fecha) = 2012
group by p.prod_codigo, i.item_producto, p.prod_detalle
having sum(i.item_cantidad * i.item_precio) > 
	(
		select sum(i2.item_cantidad * i2.item_precio) as total
		from Factura f2
		join Item_Factura i2 on i2.item_numero + i2.item_sucursal + i2.item_tipo = f2.fact_numero + f2.fact_tipo + f2.fact_sucursal
		where year(f2.fact_fecha) = 2010 or year(f2.fact_fecha) = 2011
		group by i2.item_producto
	) * 1.15

/*
	Realizar el o los objetos de la base de datos necesarios para que dado un código de producto
	y una fecha y devuelva la mayor cantidad de días consecutivos a partir de esa fecha que el
	producto tuvo al menos la venta de una unidad en el día, el sistema de ventas online está habilitado
	24/7 por lo que se deben evaluar todos los dias incluyendo domingos y feriados
*/
go
CREATE PROCEDURE dias_consecutivos_de_ventas
    (@prod_codigo char(8),
	@fecha datetime,
	@dias_consecutivos int output)
AS
BEGIN
	declare @hay_venta int
	declare @dia datetime

	set @dias_consecutivos = 0
	set @dia = @fecha

	while 1 = 1
	begin
		select @hay_venta = count(1)
		from Factura f
		join Item_Factura i on i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_tipo + f.fact_sucursal
		where i.item_producto = @prod_codigo
		and CONVERT(date, f.fact_fecha) = CONVERT(date, @dia)

		if @hay_venta > 1
		begin
			set @dias_consecutivos = 1 + @dias_consecutivos
			set @dia = DATEADD(day, 1, @dia)
		end
		else
			break
	end
return @dias_consecutivos
END
GO