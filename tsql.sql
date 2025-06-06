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

