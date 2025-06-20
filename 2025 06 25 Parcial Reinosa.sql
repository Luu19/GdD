USE GD2015C1
/*
	Sabiendo que si un producto no es vendido en un depósito determinado entonces no
	posee registros en él
	Se requiere una consulta SQL que para todos los productos que se quedaron sin stock
	en un depósito (cantidad 0 o nula) y poseen un stock mayor al punto de resposición en otro
	depósito, devuelva:
		- Código de producto
		- Detalle del producto
		- Domicilio del depósito sin stock
		- Cantidad de depósitos con un stock superior añ punto de reposición
	La consulta debe ser ordenada por código de producto
*/
select
	p.prod_codigo,
	p.prod_detalle,
	d.depo_domicilio,
	(select count(*) from STOCK where stoc_cantidad > stoc_punto_reposicion and stoc_producto = p.prod_codigo and stoc_deposito = d.depo_codigo)
from Producto p
left join STOCK s on s.stoc_producto = p.prod_codigo
join DEPOSITO d on d.depo_codigo = s.stoc_deposito
where (s.stoc_cantidad = 0 or s.stoc_cantidad = NULL) 
	and p.prod_codigo in 
	(select stoc_producto from STOCK where stoc_cantidad > stoc_punto_reposicion and stoc_deposito <> d.depo_codigo)
order by p.prod_codigo

/*
	Dado el contexto inflacionario se tiene que aplicar un control en el cual nunca se 
	permita vender un producto a un precio que no esté entre 0%-5% del precio de venta
	del producto el mes anterior, ni tampoco que esté en más de un 50% el precio del mismo
	producto que hace 12 meses atrás. Aquellos productos nuevos, o que no tuvieron ventas en 
	meses anteriores no debe considerar esta regla ya que no hay precio de referencia
*/
GO
CREATE TRIGGER validacion_precio
ON Item_Factura
FOR INSERT  
AS
BEGIN

    declare @tipo char(1)
	declare @sucursal char(4)
	declare @nro char(8)
	declare @producto char(8)
	declare @precio decimal(12,2)
	declare @fecha smalldatetime

	declare cursor_factura cursor for 
    select item_tipo, item_sucursal, item_numero 
    from inserted
    join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
	open cursor_factura
	fetch next from cursor_factura into @tipo, @sucursal, @nro
	while @@FETCH_STATUS = 0
	begin  	
		declare cursor_item cursor for 
			select item_producto, item_precio, fact_fecha 
			from inserted
			join Factura on fact_numero+fact_sucursal+fact_tipo = @tipo + @sucursal + @nro
		open cursor_item
		fetch next from cursor_item into @producto, @precio, @fecha
		while @@FETCH_STATUS = 0
		begin
			if exists (select 1 from Item_Factura 
					where item_numero+item_sucursal+item_tipo <> @tipo + @sucursal + @nro
					and item_producto = @producto )
			begin		 
				if(	
					exists ( 
						select 1 from Item_Factura 
						join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
						where DATEDIFF(month, fact_fecha, @fecha) = 1 and @precio > item_precio * 1.05
						and item_producto = @producto)
					or 
					exists ( 
						select 1 from Item_Factura 
						join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
						where DATEDIFF(year, fact_fecha, @fecha) = 1 and @precio > item_precio * 1.5
						and item_producto = @producto)
					)
				begin 
					delete Item_Factura
					where item_numero = @nro and item_sucursal = @sucursal and item_tipo = @tipo
					delete Factura 
					where fact_numero = @nro and fact_sucursal = @sucursal and fact_tipo = @tipo 
				end
			end
			fetch next from cursor_item into @producto, @precio, @fecha
		end
		close cursor_item
		deallocate cursor_item
		fetch next from cursor_factura into @tipo, @sucursal, @nro
	end
	close cursor_factura
	deallocate cursor_factura

END
GO