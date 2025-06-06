/*
	1. Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
	indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es 
	menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el 
	% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
	�DEPOSITO COMPLETO�
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
	2. Realizar una funci�n que dado un art�culo y una fecha, retorne el stock que 
	exist�a a esa fecha
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
	en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general 
	(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado 
	sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por 
	mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la 
	empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla 
	de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad 
	de empleados que hab�a sin jefe antes de la ejecuci�n.
*/