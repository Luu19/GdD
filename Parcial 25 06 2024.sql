USE GD2015C1
-- Parcial 25 06 2024
/*
	En pos de la mejora continua y poder optimizar el uso de los depósitos, se le pide
	un informe con la siguiente información:
		1. El depósito
		2. El domicilio del depósito
		3. Cantidad de productos compuestos con stock
		4. Cantidad de productos no compuestos con stock
		5. Indicar un string 'Mayoría compuestos', en caso de que el depósito tenga mayor
		cantidad de productos compuestos o 'Mayoría no compuestos', caso contrario
		6. Empleado más joven de todos los depósitos
	Solamente mostrar aquellos depósitos donde la cantidad total de productos en stock este entre 0 y 1000
*/

/*
count((case when  s.stoc_producto in (select comp_producto from Composicion) and s.stoc_cantidad > 0 then 1 else 0 end))
 --> No se puede tener un subselect adentro de un case when porque el motor no sabe cómo performar esto
*/
select
	d.depo_codigo,
	d.depo_domicilio,
	SUM(CASE WHEN c.comp_producto IS NOT NULL AND s.stoc_cantidad > 0 THEN 1 ELSE 0 END) AS compuestos_con_stock,
    SUM(CASE WHEN c.comp_producto IS NULL AND s.stoc_cantidad > 0 THEN 1 ELSE 0 END) AS no_compuestos_con_stock,
    CASE
        WHEN SUM(CASE WHEN c.comp_producto IS NOT NULL AND s.stoc_cantidad > 0 THEN 1 ELSE 0 END) >
             SUM(CASE WHEN c.comp_producto IS NULL AND s.stoc_cantidad > 0 THEN 1 ELSE 0 END)
            THEN 'Mayoría compuestos'
        ELSE 'Mayoría no compuestos'
    END,
	 (
		select top 1
		e.empl_codigo
		from Empleado e
		where e.empl_codigo in (select depo_encargado from DEPOSITO)
		order by e.empl_nacimiento desc
	 )
from DEPOSITO d
join STOCK s on s.stoc_deposito = d.depo_codigo
LEFT JOIN Composicion c ON c.comp_producto = s.stoc_producto
group by d.depo_codigo, d.depo_domicilio
having SUM(CASE WHEN s.stoc_cantidad > 0 THEN 1 ELSE 0 END) BETWEEN 0 AND 1000

/*
	La compañia desea implementar una política para incrementar el consumo de ciertos productos. Se pide crear
	el/los objetos necesarios para que se imprima un cupón con la leyenda 'Ud. accedera a un 5% de descuento
	del total de su proxima factura' a los clientes que realicen compras superiores de los $5000 y que entre
	los productos comprados haya adquirido algún producto de los siguientes rubros:
		- PILAS
		- PASTILLAS
		- ARTICULOS DE TOCADOR
*/
GO
CREATE TRIGGER cupon
ON Item_Factura
FOR INSERT 
AS
BEGIN
	if exists (
		select 1 from inserted
		join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		join Producto on prod_codigo = item_producto
		join Rubro on rubr_id = prod_rubro
		where  rubr_detalle IN ('PILAS', 'PASTILLAS', 'ARTICULOS DE TOCADOR') and fact_total > 5000
	)
	begin
		print 'Ud. accedera a un 5% de descuento del total de su proxima factura'
	end
END
GO 
