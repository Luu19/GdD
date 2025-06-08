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
	JAJA algun dia lo hare
*/