-- Parcial 11 07 2023
USE GD2015C1

/*
	La empresa necesita recuperar ventas perdidas. Con el fin de lanzar una nueva campaña comercial,
	se pide una consulta SQL que retorne aquellos clientes cuyas ventas (considerar fact_total)
	del año 2012 fueron inferiores al 25% del promedio de ventas de los productos vendidos entre los
	años 2011 y 2010.
	En base a lo solicitado, se requiere un listado con la siguiente información:
		1. Razon social del cliente
		2. Mostrar la leyenda 'Cliente Recurrente' si dicho cliente realizó más de una compra
		en el 2012. En caso de que haya solo 1 compra, entonces mostrar la leyenda 'Unica vez'
		3. Cantidad de productos totales vendidas en el 2012 para ese cliente
		4. Codigo de producto que mayor tuvo ventas en el 2012 (en caso de existir mas de 1,
		mostrar solamente el de menor codigo) para ese cliente
*/
select
	c.clie_razon_social,
	case when count(distinct f.fact_numero + f.fact_sucursal + f.fact_tipo) > 1 then 'Cliente recurrente' else 'Unica vez' end,
	sum(i.item_cantidad),
	(
		select top 1 i1.item_producto
		from Factura f1
		join Item_Factura i1 on i1.item_numero + i1.item_sucursal + i1.item_tipo = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
		where year(f1.fact_fecha) = 2012
		group by i1.item_producto
		order by sum(i1.item_cantidad) desc
	)
from Factura f
join Item_Factura i on i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_tipo + f.fact_sucursal
join Cliente c on c.clie_codigo = f.fact_cliente
where year(f.fact_fecha) = 2012
group by c.clie_codigo, c.clie_razon_social
having sum(f.fact_total) < (
	select
	avg(f1.fact_total)
from Factura f1
where year(f1.fact_fecha) = 2011 or year(f1.fact_fecha) = 2010
) * 0.25

/*
	Para estimar qué STOCK se necesita comprar de cada producto, se toma como estimación
	las ventas de unidades promedio de los últimos 3 meses anteriores a una fecha. Se solicita
	que se guarde en una tabla (producto, cantidad a reponer) en funcion del criterio antes 
	mencionado y el stock existente
*/
CREATE TABLE Reposicion (
    producto CHAR(8) PRIMARY KEY,
    cantidad_a_reponer DECIMAL(12,2)
)

go
CREATE PROCEDURE calcular_reposicion
    @fecha DATETIME
AS
BEGIN
    -- Limpiar la tabla Reposicion
    TRUNCATE TABLE Reposicion

    DECLARE @prod_codigo CHAR(8)
    DECLARE @ventas_total DECIMAL(12,2)
    DECLARE @cant_meses INT
    DECLARE @promedio DECIMAL(12,2)
    DECLARE @stock DECIMAL(12,2)
    DECLARE @reponer DECIMAL(12,2)

    -- Cursor para recorrer todos los productos
    DECLARE c CURSOR FOR
        SELECT prod_codigo FROM Producto

    OPEN c
    FETCH NEXT FROM c INTO @prod_codigo
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcular ventas totales y cantidad de meses con ventas
        SELECT @ventas_total = SUM(i.item_cantidad)
        FROM Item_Factura i
        JOIN Factura f ON f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
        WHERE i.item_producto = @prod_codigo
          AND f.fact_fecha < @fecha
          AND f.fact_fecha >= DATEADD(MONTH, -3, @fecha)

        -- Calcular cantidad de meses distintos con ventas
        SELECT @cant_meses = COUNT(DISTINCT (YEAR(f.fact_fecha)*100 + MONTH(f.fact_fecha)))
        FROM Item_Factura i
        JOIN Factura f ON f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
        WHERE i.item_producto = @prod_codigo
          AND f.fact_fecha < @fecha
          AND f.fact_fecha >= DATEADD(MONTH, -3, @fecha)

        -- Promedio
        SET @promedio = ISNULL(@ventas_total,0) / CASE WHEN @cant_meses > 0 THEN @cant_meses ELSE 1 END

        -- Stock actual
        SELECT @stock = SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @prod_codigo

        -- Cantidad a reponer
        SET @reponer = CASE WHEN @promedio - ISNULL(@stock,0) > 0 THEN @promedio - ISNULL(@stock,0) ELSE 0 END

        -- Insertar en la tabla de reposición
        INSERT INTO Reposicion (producto, cantidad_a_reponer)
        VALUES (@prod_codigo, @reponer)

        FETCH NEXT FROM c INTO @prod_codigo
    END
    CLOSE c
    DEALLOCATE c
END
GO


