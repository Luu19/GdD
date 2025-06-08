/*
	1. Hacer una función que dado un artículo y un deposito devuelva un string que
	indique el estado del depósito según el artículo. Si la cantidad almacenada es 
	menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el 
	% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
	“DEPOSITO COMPLETO”
*/
CREATE FUNCTION dbo.Ejercicio1Func(@producto CHAR(8), @deposito char(2))
RETURNS char(30)
AS
BEGIN
	declare @porcentaje_ocupacion decimal(12,2)
	declare @cantidad_stock decimal(12,2)
	declare @stock_max decimal(12,2)
	
	(select @stock_max = s.stoc_stock_maximo, @cantidad_stock = s.stoc_cantidad from STOCK s where s.stoc_producto = @producto and s.stoc_deposito = @deposito)
	SET @porcentaje_ocupacion = @cantidad_stock / @stock_max

	if @porcentaje_ocupacion > 1 
		return 'DEPOSITO COMPLETO' 
	else
		return 'OCUPACION DEL DEPOSITO ' + CONVERT(varchar(10), @porcentaje_ocupacion * 100) + ' %'
RETURN 0
END
GO

-- SELECT dbo.Ejercicio1Func('00000102','00')


/*
	2. Realizar una función que dado un artículo y una fecha, retorne el stock que 
	existía a esa fecha
*/
CREATE FUNCTION dbo.Ejercicio2(@producto CHAR(8), @fecha datetime)
RETURNS char(25)
AS
BEGIN
	declare @stock_actual decimal(12,2)
	declare @stock_historico decimal(12,2)
	
	set @stock_actual = (select s.stoc_cantidad from STOCK s where s.stoc_producto = @producto)
	set @stock_historico = 
	(
		select sum(i.item_cantidad)
		from Factura f
		join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero
		where i.item_producto = @producto and @fecha > f.fact_fecha
	) 
	
		return @stock_actual + @stock_historico
RETURN 0
END
GO

/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado 
	en caso que sea necesario. Se sabe que debería existir un único gerente general 
	(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado 
	sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por 
	mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la 
	empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla 
	de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad 
	de empleados que había sin jefe antes de la ejecución.
*/
CREATE PROCEDURE dbo.ejercicio3
    (@modificados int OUTPUT)
AS
BEGIN
    DECLARE @gerente numeric(6)

	set @gerente = (
		select top 1 e.empl_codigo from Empleado e order by e.empl_salario desc, e.empl_ingreso asc
	)
		
	set @modificados = (select count(*) from Empleado e where e.empl_jefe is NULL and e.empl_codigo <> @gerente)
	
	if @modificados > 1 
		update Empleado set empl_jefe =  @gerente where empl_jefe is NULL and empl_codigo = @gerente

return
END
GO

/*
4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
	empleado empl_comision con la sumatoria del total de lo vendido por ese
	empleado a lo largo del último año. Se deberá retornar el código del vendedor 
	que más vendió (en monto) a lo largo del último año.
*/
CREATE PROCEDURE dbo.ejercicio4
    (@Modif int OUTPUT)
AS
BEGIN
    DECLARE @gerente numeric(6)

	set @gerente = (
		select top 1 e.empl_codigo from Empleado e order by e.empl_salario desc, e.empl_ingreso asc
	)
		
	set @Modif = (select count(*) from Empleado e where e.empl_jefe is NULL and e.empl_codigo <> @gerente)
	
	if @Modif > 1 
		update Empleado set empl_jefe =  @gerente where empl_jefe is NULL and empl_codigo = @gerente

return
END
GO

/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
	Create table Fact_table
	( anio char(4),
	mes char(2),
	familia char(3),
	rubro char(4),
	zona char(3),
	cliente char(6),
	producto char(8),
	cantidad decimal(12,2),
	monto decimal(12,2)
	)
	Alter table Fact_table
	Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

IF OBJECT_ID('Fact_table','U') IS NOT NULL 
DROP TABLE Fact_table
GO
Create table Fact_table
(
	anio char(4) NOT NULL, --YEAR(fact_fecha)
	mes char(2) NOT NULL, --RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2)
	familia char(3) NOT NULL,--prod_familia
	rubro char(4) NOT NULL,--prod_rubro
	zona char(3) NOT NULL,--depa_zona
	cliente char(6) NOT NULL,--fact_cliente
	producto char(8) NOT NULL,--item_producto
	cantidad decimal(12,2) NOT NULL,--item_cantidad
	monto decimal(12,2)--asumo que es item_precio debido a que es por cada producto, 
					   --asumo tambien que el precio ya esta determinado por total y no por unidad (no debe multiplicarse por cantidad)
)
Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto)
GO

IF OBJECT_ID('Ejercicio5','P') IS NOT NULL
DROP PROCEDURE Ejercicio5
GO

CREATE PROCEDURE dbo.ejercicio5
AS
BEGIN
    insert into Fact_table 
	select 
		year(fact_fecha),
		MONTH(fact_fecha),
		p.prod_familia,
		p.prod_rubro,
		d.depa_zona, 
		f.fact_cliente,
		p.prod_codigo,
		p.prod_codigo,
		i.item_cantidad,
		i.item_precio * i.item_cantidad
	from Factura f
	join Item_Factura i on f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo    + i.item_sucursal + i.item_numero
	join Producto p on p.prod_codigo = i.item_producto
	join Empleado e on e.empl_codigo = f.fact_vendedor
	join Departamento d on d.depa_codigo = e.empl_departamento
	group by YEAR(fact_fecha)
		,MONTH(fact_fecha)
		,prod_familia
		,prod_rubro
		,depa_zona
		,fact_cliente
		,prod_codigo
return
END
GO

/*
	6. Realizar un procedimiento que si en alguna factura se facturaron componentes
	que conforman un combo determinado (o sea que juntos componen otro
	producto de mayor nivel), en cuyo caso deberá reemplazar las filas
	correspondientes a dichos productos por una sola fila con el producto que
	componen con la cantidad de dicho producto que corresponda.
*/
CREATE PROCEDURE dbo.ejericcio6
AS
BEGIN
    -- Declaración de variables internas
    declare @fact_tipo char(1)
    declare @fact_sucursal char(4)
	declare @fact_numero char(4)

	declare @comp_producto char(8)
	declare @comp_cantidad decimal(12, 0)

	declare @precio_combo DECIMAL(12,0)


	--- Cursor para las facturas
	declare cursor_factura cursor for
		select 
			f.fact_tipo,
			f.fact_sucursal,
			f.fact_numero
		from Factura f

	open cursor_factura
	fetch next from cursor_factura into @fact_tipo, @fact_sucursal, @fact_numero
	while @FETCH_STATUS = 0

	begin 
		--- Cursor para los items
		declare cursor_item cursor for
		select 
			c.comp_producto
		from Item_Factura i
		join Composicion c on c.comp_componente = i.item_producto
		where i.item_tipo + i.item_sucursar + i.item_numero = @fact_tipo + @fact_sucursal + @fact_numero and i.item_cantidad > c.comp_cantidad 
		group by c.comp_producto
		having count(*) = (select count(*) from Composicion where comp_producto= c.comp_producto)

		open cursor_item
		fetch next from cursor_item into @comp_producto
		while @FETCH_STATUS = 0
		begin
			select @cantidad_combo = min(floor(item_cantidad/c.comp_cantidad))
			from Item_Factura
			join Composicion c on c.comp_componente = i.item_producto
			where i.item_producto = @comp_producto
			and i.item_tipo + i.item_sucursar + i.item_numero = @fact_tipo + @fact_sucursal + @fact_numero 
			and i.item_cantidad > c.comp_cantidad 
			and c.comp_producto = @comp_producto

			select @precio_combo = @cantidad_combo * prod_precio from Producto where prod_codigo = @comp_producto
			-- insertamos

			INSERT INTO [dbo].[Item_Factura]
					   ([item_tipo]
					   ,[item_sucursal]
					   ,[item_numero]
					   ,[item_producto]
					   ,[item_cantidad]
					   ,[item_precio])
				 VALUES
					   (@fact_tipo
					   ,@fact_sucursal
					   ,@fact_numero
					   ,@comp_producto
					   ,@cantidad_combo
					   ,@precio_combo);

			update Item_Factura set 
				item_cantidad = item_cantidad - (@cantidad_combo * select comp_cantidad from Composicion 
								where comp_componente = item_producto and comp_producto = @comp_producto)
				item_precio = (item_cantidad - (@cantidad_combo * select comp_cantidad from Composicion 
								where comp_componente = item_producto and comp_producto = @comp_producto)) *
								(select prod_precio from Producto where prod_codigo = item_producto)
			from Item_Factura, Composicion C1 
			where I1.item_sucursal = @fact_sucursal and
				  I1.item_numero = @fact_numero and
				  I1.item_tipo = @fact_tipo AND
				  I1.item_producto = C1.comp_componente AND
				  C1.comp_producto = @comp_producto
			-- Elimina todas las filas de ítems de la factura cuya cantidad quedó en 0
			delete from Item_Factura
			where item_sucursal = @fact_sucursal and
				  item_numero = @fact_numero and
				  item_tipo = @fact_tipo and
				  item_cantidad = 0 
END
GO

/*
	7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
	insertar una línea por cada artículo con los movimientos de stock generados por
	las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/

IF OBJECT_ID('Ventas','U') IS NOT NULL 
DROP TABLE Ventas
GO
Create table Ventas
(
vent_codigo char(8) NULL, --Código del articulo
vent_detalle char(50) NULL, --Detalle del articulo
vent_movimientos int NULL, --Cantidad de movimientos de ventas (Item Factura)
vent_precio_prom decimal(12,2) NULL, --Precio promedio de venta
vent_renglon int IDENTITY(1,1) PRIMARY KEY, --Nro de linea de la tabla (PK)
vent_ganancia char(6) NOT NULL, --Precio de venta - Cantidad * Costo Actual
)


CREATE PROCEDURE Ejercicio7 (@fecha_1 datetime, @fecha_2 datetime)
AS
BEGIN
	declare @producto_codigo char(8)
	declare @producto_detalle char(8)
	declare @cantidad_mov decimal(12,0)
	declare @precio_promedio decimal(12,2)
	declare @ganacia decimal(12,2)

    declare @fact_tipo char(1)
    declare @fact_sucursal char(4)
	declare @fact_numero char(4)

	declare cursor_items cursor for
		select 
			p.prod_codigo,
			p.prod_detalle,
			count(i.item_producto),
			avg(i.item_precio)
			,sum(i.item_cantidad*i.item_precio)
		from Factura
		join Item_Factura i on i.item_tipo + i.item_sucursar + i.item_numero = fact_tipo + fact_sucursal + fact_numero 
		join Producto p on p.prod_codigo = i.item_producto
		where f.fact_fecha > @fecha_1 and f.fact_fecha < @fecha_2
		group by p.prod_codigo, p.prod_detalle

	open cursor_items
	fetch next from cursor_items into @producto_codigo, @producto_detalle, @cantidad_mov, @precio_promedio, @ganacia
	while @FETCH_STATUS = 0
	begin 
		insert into VENTAS
		values
			(@producto_codigo, @producto_detalle, @cantidad_mov, @precio_promedio, ROW_NUMBER(), @ganacia)
	fetch next from cursor_items into @producto_codigo, @producto_detalle, @cantidad_mov, @precio_promedio, @ganacia
	END
	CLOSE cursor_items
	DEALLOCATE cursor_items
END
GO

/*
	8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
	productos facturados que tengan composición y en los cuales el precio de
	facturación sea diferente al precio del cálculo de los precios unitarios por
	cantidad de sus componentes, se aclara que un producto que compone a otro,
	también puede estar compuesto por otros y así sucesivamente, la tabla se debe
	crear y está formada por las siguientes columnas:
	Código | Código Detalle | Cantidad | Precio_generado | Precio_facturado
*/
IF OBJECT_ID('Diferencias','U') IS NOT NULL 
DROP TABLE Diferencias
GO

CREATE TABLE Diferencias
(
	dif_codigo char(8) NULL
	,dif_detalle char(50) NULL
	,dif_cantidad int NULL
	,dif_precio_generado decimal(12,2) NULL
	,dif_precio_facturado decimal(12,2) NULL
)

CREATE PROCEDURE Ejercicio8 
AS
BEGIN
	declare @producto_codigo char(8)
	declare @producto_detalle char(8)
	declare @cantidad_prod decimal(12,0)
	declare @precio_generado decimal(12,2)
	declare @precio_facturado decimal(12,2)

    declare @fact_tipo char(1)
    declare @fact_sucursal char(4)
	declare @fact_numero char(4)

	declare cursor_item cursor for
		select 
			p.prod_codigo,
			p.prod_detalle,
			count(c.comp_componente),
			dbo.precio_producto(p.prod_codigo),
			i.item_precio
		from Item_Factura i
		join Producto p on p.prod_codigo = i.item_producto
		join Composicion c on c.comp_producto = p.prod_codigo
		group by p.prod_codigo, p.prod_detalle

	open cursor_items
	fetch next from cursor_items into @producto_codigo, @producto_detalle, @cantidad_prod, @precio_generado, @precio_facturado
	while @FETCH_STATUS = 0
	begin 
		insert into Diferencias
		values
			(@producto_codigo, @producto_detalle, @cantidad_prod, @precio_generado, @precio_facturado)
	fetch next from cursor_items into @producto_codigo, @producto_detalle, @cantidad_prod, @precio_generado, @precio_facturado
	END
	CLOSE cursor_items
	DEALLOCATE cursor_items
END
GO

-- El 9  es un trigger