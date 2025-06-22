-- Parcial 25 06 2024
use GD2015C1

/*
	La empresa est� muy comprometida con el desarrollo sustentable, y como consecuencia de ello propone cambiar 
	los envases de sus productos por envases reciclados.
	Si bien entiende la importancia de este cambio, tambi�n es consciente de los costos que esto conlleva, 
	por lo cual se realizar� de manera paulatina.
	Por tal motivo se solicita un listado con los 5 productos m�s vendidos y los 5 productos menos vendidos durante el a�o 2012.
	Comparar la cantidad vendida de cada uno de estos productos con la cantidad vendida del a�o anterior e indicar el string
	�M�s ventas� o �Menos ventas�, seg�n corresponda.
	Adem�s, indicar el detalle del envase.

	El resultado debe incluir:
	A) C�digo del producto
	B) Comparaci�n con el a�o anterior
	C) Detalle del envase
*/
select
	p.prod_codigo,
	(
		case when sum(i.item_cantidad) > 
		(select sum(item_cantidad)
		from Item_Factura
		join Factura  on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		where item_producto = p.prod_codigo) then 'M�s ventas' else 'Menos ventas' end
	),
	enva_detalle
from Producto p
join Item_Factura i on i.item_producto = p.prod_codigo 
join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
join Envases on prod_envase = enva_codigo
where year(f.fact_fecha) = 2012 and p.prod_codigo in
(
	select top 5 
		p.prod_codigo
	from Producto p
	join Item_Factura i on i.item_producto = p.prod_codigo 
	join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
	group by p.prod_codigo, p.prod_detalle
	order by sum(i.item_cantidad) asc) 
	or p.prod_codigo in (
		select top 5 
			p.prod_codigo
		from Producto p
		join Item_Factura i on i.item_producto = p.prod_codigo 
		join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		group by p.prod_codigo, p.prod_detalle
		order by sum(i.item_cantidad) desc)
group by p.prod_codigo

--- OTRA FORMA
select
	p.prod_codigo,
	(
		case when (select sum(item_cantidad)
		from Item_Factura
		join Factura  on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		where item_producto = p.prod_codigo and YEAR(fact_fecha) = 2012 ) > 
		(select sum(item_cantidad)
		from Item_Factura
		join Factura  on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		where item_producto = p.prod_codigo and YEAR(fact_fecha) = 2011 ) then 'M�s ventas' else 'Menos ventas' end
	),
	enva_detalle
from Producto p
join Envases on prod_envase = enva_codigo
where p.prod_codigo in
(
	select top 5 
		p.prod_codigo
	from Producto p
	join Item_Factura i on i.item_producto = p.prod_codigo 
	join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
	where year(f.fact_fecha) = 2012
	group by p.prod_codigo, p.prod_detalle
	order by sum(i.item_cantidad) asc) 
	or p.prod_codigo in (
		select top 5 
			p.prod_codigo
		from Producto p
		join Item_Factura i on i.item_producto = p.prod_codigo 
		join Factura  f on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		where year(f.fact_fecha) = 2012
		group by p.prod_codigo, p.prod_detalle
		order by sum(i.item_cantidad) desc)
group by p.prod_codigo, enva_detalle
order by p.prod_codigo

/*
	La compa��a cumple a�os y decidi� repartir algunas sorpresas entre sus clientes. Se pide crear el/los objetos necesarios
	para que se imprima un cup�n con la leyenda 'Recuerde solicitar su regalo sorpresa en su pr�xima compra' a los clientes
	que, entre los productos comprados, hayan adquirido alg�n producto de los siguientes rubros: PILAS y PASTILLAS y tengan un
	l�mite crediticio menos a $15000
*/

GO
CREATE TRIGGER sorpresa_de_compra
ON Item_Factura
FOR INSERT 
AS
BEGIN
	if exists (
		select 1 from inserted
		join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		join Producto on prod_codigo = item_producto
		join Rubro on rubr_id = prod_rubro
		join Cliente on clie_codigo = fact_cliente
		where  rubr_detalle IN ('PILAS', 'PASTILLAS') and clie_limite_credito < 15000
	)
	begin
		print 'Recuerde solicitar su regalo sorpresa en su pr�xima compra'
	end
END
GO 
