/*Armar una consulta que muestre para todos los productos:

Producto

Detalle del producto

Detalle composición (si no es compuesto un string SIN COMPOSICION,, si es compuesto un string CON COMPOSICION

Cantidad de Componentes (si no es compuesto, tiene que mostrar 0)

Cantidad de veces que fue comprado por distintos clientes

Nota: No se permiten sub select en el FROM.*/

SELECT 
p.prod_codigo [Producto],
p.prod_detalle [Detalle del producto],
CASE
when count(c.comp_componente)>0 then 'CON COMPOSICION'
else 'SIN COMPOSICION'
END [Detalle composicion],
ISNULL(COUNT(c.comp_componente),0) [Cantidad de Componentes],
ISNULL(COUNT(distinct f.fact_cliente),0) [Cantidad de veces que fue comprado por distintos clientes]
FROM Producto p 
    LEFT JOIN Composicion c on p.prod_codigo=c.comp_producto
    LEFT JOIN Item_Factura i on p.prod_codigo=i.item_producto
    LEFT JOIN Factura f on i.item_sucursal+i.item_tipo+i.item_numero=f.fact_sucursal+f.fact_tipo+f.fact_numero
GROUP BY p.prod_codigo,p.prod_detalle

/*Implementar el/los objetos necesarios para implementar la siguiente restricción en línea:
Cuando se inserta en una venta un COMBO, nunca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes.
 Nota: Se sabe que actualmente todos los artículos guardados de ventas están descompuestos en sus componentes.*/

CREATE TRIGGER venta_combo --lo podia hacer con dos insert por separado y ahorrarme el cursor
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
    declare @item_producto char(8)
    declare @item_sucursal char(4)
    declare @item_tipo char(1)
    declare @item_numero char(8)
    declare @item_precio decimal(12,2) 
    declare @item_cantidad decimal(12,2)

    declare cursor_venta_combo CURSOR FOR
    select item_producto,item_sucursal,item_tipo,item_numero,item_precio,item_cantidad from inserted 

    OPEN cursor_venta_combo 
    FETCH NEXT FROM cursor_venta_combo into @item_producto,@item_sucursal,@item_tipo,@item_numero,@item_precio,@item_cantidad
    while @@FETCH_STATUS = 0
    BEGIN
    if(@item_producto in (select distinct comp_producto from Composicion))
    BEGIN
        INSERT INTO Item_Factura (item_producto,item_sucursal,item_tipo,item_numero,item_precio,item_cantidad)
        SELECT distinct comp_componente, @item_sucursal,@item_tipo,@item_numero,prod_precio,comp_cantidad*@item_cantidad
        FROM Composicion JOIN Producto on prod_codigo=comp_componente
    END
    ELSE 
    BEGIN
    INSERT INTO Item_Factura (item_producto,item_sucursal,item_tipo,item_numero,item_precio,item_cantidad)
    VALUES (@item_producto,@item_sucursal,@item_tipo,@item_numero,@item_precio,@item_cantidad)
    END
    END
    CLOSE cursor_venta_combo
    DEALLOCATE cursor_venta_combo
END
GO
