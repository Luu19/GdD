USE GD2015C1
-- Parcial 25 06 2024
/*
	La empresa está muy comprometida con el desarrollo sustentable, y como consecuencia de ello propone cambiar 
	los envases de sus productos por envases reciclados.
	Si bien entiende la importancia de este cambio, también es consciente de los costos que esto conlleva, 
	por lo cual se realizará de manera paulatina.
	Por tal motivo se solicita un listado con los 5 productos más vendidos y los 5 productos menos vendidos durante el año 2012.
	Comparar la cantidad vendida de cada uno de estos productos con la cantidad vendida del año anterior e indicar el string
	‘Más ventas’ o ‘Menos ventas’, según corresponda.
	Además, indicar el detalle del envase.

	El resultado debe incluir:
	A) Código del producto
	B) Comparación con el año anterior
	C) Detalle del envase
*/

SELECT 
pp.prod_codigo,
(CASE
WHEN SUM(ii.item_cantidad) >= (SELECT SUM(i1.item_cantidad)
                            FROM Item_Factura i1 
                                JOIN Factura f1 on i1.item_sucursal=f1.fact_sucursal and i1.item_tipo=f1.fact_tipo and i1.item_numero=f1.fact_numero
                            WHERE YEAR(f1.fact_fecha)=2011 and i1.item_producto=pp.prod_codigo
                            )
THEN 'Mas ventas'
ELSE 'Menos ventas'
END) [Comparación con el año anterior],
ee.enva_detalle
FROM Producto pp 
    JOIN Envases ee on pp.prod_envase=ee.enva_codigo
    LEFT JOIN Item_Factura ii on pp.prod_codigo=ii.item_producto
    JOIN Factura ff on ii.item_sucursal=ff.fact_sucursal and ii.item_tipo=ff.fact_tipo and ii.item_numero=ff.fact_numero and year(fact_fecha)=2012
WHERE pp.prod_codigo in (SELECT TOP 5 
                        p.prod_codigo
                        FROM Producto p 
                        JOIN Envases e on p.prod_envase=e.enva_codigo
                        LEFT JOIN Item_Factura i on p.prod_codigo=i.item_producto
                        JOIN Factura f on i.item_sucursal=f.fact_sucursal and i.item_tipo=f.fact_tipo and i.item_numero=f.fact_numero
                        WHERE YEAR(f.fact_fecha)=2012
                        GROUP BY p.prod_codigo
                        ORDER BY ISNULL(SUM(i.item_cantidad),0) DESC)
or pp.prod_codigo in  (SELECT TOP 5 
                        p.prod_codigo
                        FROM Producto p 
                        JOIN Envases e on p.prod_envase=e.enva_codigo
                        LEFT JOIN Item_Factura i on p.prod_codigo=i.item_producto
                        JOIN Factura f on i.item_sucursal=f.fact_sucursal and i.item_tipo=f.fact_tipo and i.item_numero=f.fact_numero
                        WHERE YEAR(f.fact_fecha)=2012
                        GROUP BY p.prod_codigo
                        ORDER BY ISNULL(SUM(i.item_cantidad),0) ASC) 
GROUP BY pp.prod_codigo,ee.enva_detalle
ORDER BY ISNULL(SUM(ii.item_cantidad),0) DESC               

/*
	La compañía cumple años y decidió repartir algunas sorpresas entre sus clientes. Se pide crear el/los objetos necesarios
	para que se imprima un cupón con la leyenda 'Recuerde solicitar su regalo sorpresa en su próxima compra' a los clientes
	que, entre los productos comprados, hayan adquirido algún producto de los siguientes rubros: PILAS y PASTILLAS y tengan un
	límite crediticio menos a $15000
*/

CREATE TYPE clientes_aptos AS TABLE (cliente_apto char(6))
go
CREATE PROC enviar_cupones
@clientes clientes_aptos READONLY
AS
BEGIN
    declare @clie_codigo char(6)
    declare cursor_enviar_cupones CURSOR
    for select cliente_apto from @clientes

    open cursor_enviar_cupones
    FETCH NEXT FROM cursor_enviar_cupones INTO @clie_codigo

    while @@FETCH_STATUS = 0
    BEGIN
        print 'cliente:' + @clie_codigo + ' Recuerde solicitar su regalo sorpresa en su próxima compra'
        FETCH NEXT FROM cursor_enviar_cupones INTO @clie_codigo
    END

    close cursor_enviar_cupones
    DEALLOCATE cursor_enviar_cupones
    
END

go
CREATE TRIGGER cupon 
ON  Item_Factura 
AFTER INSERT
AS
BEGIN
    
    declare @clientes_cupones clientes_aptos 

    INSERT INTO @clientes_cupones
    select distinct clie_codigo
    from inserted
        JOIN Factura on fact_sucursal=item_sucursal and item_tipo=fact_tipo and item_numero=fact_numero
        JOIN Cliente on clie_codigo=fact_cliente
        JOIN Producto on prod_codigo=item_producto
    where clie_limite_credito<15000 and prod_rubro in (select rubr_id from Rubro where rubr_detalle='PILAS' or rubr_detalle='PASTILLAS')

   EXEC enviar_cupones @clientes_cupones
END


select rubr_detalle from Rubro
