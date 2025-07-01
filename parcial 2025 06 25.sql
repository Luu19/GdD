USE GD2015C1;

select prod_codigo, prod_detalle,depo_domicilio,(select count(distinct stoc_deposito) from stock
															where stoc_cantidad > stoc_punto_reposicion
															and stoc_producto = prod_codigo) as depositos_con_stock from STOCK
join DEPOSITO on depo_codigo = stoc_deposito
join Producto on prod_codigo = stoc_producto
where (stoc_cantidad is null or stoc_cantidad = 0) 
and stoc_producto in (select stoc_producto from stock where stoc_cantidad > stoc_punto_reposicion)
order by prod_codigo

/*
Dado el contexto inflacionario se tiene que aplicar un control en el cual nunca se 
permita vender un producto a un precio que no esté entre 0%-5% del precio de venta
del producto el mes anterior, ni tampoco que esté en más de un 50% el precio del mismo
producto que hace 12 meses atrás. Aquellos productos nuevos, o que no tuvieron ventas en 
meses anteriores no debe considerar esta regla ya que no hay precio de referencia */

create trigger chequeo_precio on Item_factura for insert
as 
	if dbo.prod_nuevo(select item_producto from inserted) = 0  or 
	(select )
		and  
	()
	begin
	rollback transaction
	return 'No se puede vender un producto con el precio así (...)'
	end
	go

select item from item_factura
order by item_producto
