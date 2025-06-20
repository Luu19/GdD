--GUÍA T-SQL--
--EJERCICIO 1--
/* Hacer una función que dado un artículo y un deposito devuelva un string que indique el estado del depósito 
según el artículo. Si la cantidad almacenada es menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo
XX el % de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar “DEPOSITO COMPLETO”. 
*/
 alter function ejercicio1 (@articulo char(8) , @deposito char(2))
 returns varchar(50)
 as begin 
	declare @stock numeric(12,2) , @maximo numeric(12,2)
	 select @stock = isnull(stoc_cantidad,0), @maximo = stoc_stock_maximo from STOCK	
	where stoc_deposito = @deposito and stoc_producto = @articulo
  if @stock >= @maximo or @maximo = 0
	return 'DEPOSITO COMPLETO' 
  	/*sin ELSE*/
	return 'OCUPACIÓN DEL DEPÓSITO ' + @deposito +' '+STR(@stock / @maximo * 100,5,2) --string de 5 posiciones y 2 decimales
	end
  go

  /* o 
  set @return = 'aaa'
  return @retorno*/

  select stoc_producto, stoc_cantidad, stoc_stock_maximo, dbo.ejercicio1(stoc_producto,stoc_deposito) from STOCK
  order by 1

  --EJERCICIO 2--
  /*Realizar una función que dado un artículo y una fecha, retorne el stock que existía a esa fecha */
   create or alter function ejercicio2 (@articulo char(8) , @fecha datetime)
   returns numeric(12,2)
   as begin 
		declare @cantidad numeric(12,2)
		select @articulo = stoc_producto, @cantidad = sum(stoc_cantidad) from stock	
		join Item_Factura on item_producto = @articulo
		join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal
		where @articulo = stoc_producto and 
		fact_fecha <= @fecha
		group by stoc_producto
		return @cantidad
	end
	go
	  select distinct stoc_producto, dbo.ejercicio2(stoc_producto,CAST('2013-05-23' AS DATE)) as cantidad_en_fecha from STOCK
  order by 1


 
  CREATE FUNCTION fx_ejercicio_2(@producto char(8), @fecha DATE) 
RETURNS numeric(6,0) AS 
BEGIN

DECLARE @retorno numeric(6,0)
DECLARE @cantidad decimal(12,2)
DECLARE @minimo decimal(12,2)
DECLARE @maximo decimal(12,2)
DECLARE @diferencia decimal(12,2)

declare cProductos cursor for
		select I.item_cantidad 
		from factura f inner join Item_Factura i
		on f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero 
		where i.item_producto = @producto
		and f.fact_fecha >= @fecha
		order by f.fact_fecha desc

SELECT @retorno = s.stoc_cantidad, @minimo = s.stoc_punto_reposicion, 
@maximo = s.stoc_stock_maximo
FROM stock s
WHERE s.stoc_producto = @producto
AND s.stoc_deposito = '00'

SET @diferencia = @maximo - @minimo

open cProductos
fetch next from cProductos into @cantidad
while @@FETCH_STATUS = 0
begin
	set @retorno = @retorno + @cantidad
	if @retorno > @maximo
		SET @retorno = @retorno - @diferencia
	fetch next from cProductos into @cantidad
end
close cProductos;
deallocate cProductos;	

RETURN @retorno
END

GO

--EJERCICIO 3--
/* Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en caso que sea necesario.
Se sabe que debería existir un único gerente general (debería ser el único empleado sin jefe). 
Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general, el cual 
será seleccionado por mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la empresa. 
Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único empleado sin jefe 
(el gerente general) y deberá retornar la cantidad de empleados que había sin jefe antes de la ejecución.  */

create procedure ejercicio3
as 
	begin
	declare @jefe numeric(6)
	if(select count(*) from Empleado where empl_jefe is null) > 1
		select top 1 @jefe = empl_codigo from Empleado 
		where empl_jefe is null
		order by empl_salario desc, empl_ingreso
		update Empleado set empl_jefe = @jefe
		where empl_jefe is null and empl_codigo <> @jefe
	end
go

--EJERCICIO 4--
/*Cree el/los objetos de base de datos necesarios para actualizar la columna de 
empleado empl_comision con la sumatoria del total de lo vendido por ese 
empleado a lo largo del último año. Se deberá retornar el código del vendedor 
que más vendió (en monto) a lo largo del último año. */

create proc ejercicio4(@vendedorMas numeric(6) OUTPUT)
as begin

	update Empleado set empl_comision = (select sum(distinct fact_total) from Factura										
										where year(fact_fecha) = (select year(max(fact_fecha)) from Factura)
										and fact_vendedor = empleado.empl_codigo
										group by fact_vendedor)
	select top 1 @vendedorMas = empl_codigo from Empleado 
	order by empl_comision desc	
	end
go


--EJERCICIO 5--
/*Realizar un procedimiento que complete con los datos existentes en el modelo 
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición: 
*/

create or alter proc ejercicio5 as 
	begin
	Create table Fact_tablev1
	(anio char(4) not null, mes char(2) not null, familia char(3) not null, rubro char(4) not null, zona char(3) not null, cliente char(6) not null, producto char(8) not null, 
	cantidad decimal(12,2) not null, monto decimal(12,2) not null ) 
	Alter table Fact_table 
	Add constraint Pk_fact primary key(anio,mes,familia,rubro,zona,cliente,producto) --?
	insert into Fact_tablev1(anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
		select year(fact_fecha), month(fact_fecha), prod_familia,prod_rubro, fact_sucursal , clie_codigo, prod_codigo,item_cantidad, item_cantidad * item_precio from Factura
		join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		join Producto on prod_codigo = item_producto
		join Cliente on clie_codigo = fact_cliente
	end
go

exec ejercicio5;

