USE GD2015C1
/*
	Sabiendo que si un producto no es vendido en un dep�sito determinado entonces no
	posee registros en �l
	Se requiere una consulta SQL que para todos los productos que se quedaron sin stock
	en un dep�sito (cantidad 0 o nula) y poseen un stock mayor al punto de resposici�n en otro
	dep�sito, devuelva:
		- C�digo de producto
		- Detalle del producto
		- Domicilio del dep�sito sin stock
		- Cantidad de dep�sitos con un stock superior a� punto de reposici�n
	La consulta debe ser ordenada por c�digo de producto
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