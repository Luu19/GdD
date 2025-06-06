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