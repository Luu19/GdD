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
select
	top 10
	c.clie_razon_social,
	count(distinct i.item_producto),
	sum(case when MONTH(f.fact_fecha) between 1 and 6 then i.item_cantidad else 0 end)
from Factura f
join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
join Cliente c on c.clie_codigo = f.fact_cliente
where year(f.fact_fecha) = 2012
group by c.clie_razon_social, c.clie_codigo, f.fact_cliente
having count(distinct f.fact_vendedor) > 3
order by count(distinct f.fact_tipo + f.fact_sucursal + f.fact_numero) desc, 1

/*
	Realizar un stored procedure que reciba un codigo de producto y una fecha y devuelva la mayor cantidad de dias
	consecutivos a partir de esa fecha que el producto tuvo al menos una venta de una unidad en el dia, el sistema
	de ventas online esta habilitado 24/7 por lo que se deben evaluar todos los dias incluyendo domingos y feriados
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
	    -- Busca si existe al menos una venta del producto indicado en el día actual
		select @hay_venta = count(1)
		from Factura f
		join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		where i.item_producto = @prod_codigo
		and CONVERT(date, f.fact_fecha) = CONVERT(date, @dia) -- compara sólo la fecha

		if @hay_venta > 0 -- Si hubo venta, sigue; si no, termina
		begin
			set @dias_consecutivos = @dias_consecutivos + 1
			set @dia = DATEADD(day, 1, @fecha)
		end
		else
		break
	end
return @dias_consecutivos
END
GO