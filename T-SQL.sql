--GU�A T-SQL--
--EJERCICIO 1--
/* Hacer una funci�n que dado un art�culo y un deposito devuelva un string que indique el estado del dep�sito 
seg�n el art�culo. Si la cantidad almacenada es menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo
XX el % de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar �DEPOSITO COMPLETO�. 
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
	return 'OCUPACI�N DEL DEP�SITO ' + @deposito +' '+STR(@stock / @maximo * 100,5,2) --string de 5 posiciones y 2 decimales
	end
  go

  /* o 
  set @return = 'aaa'
  return @retorno*/

  select stoc_producto, stoc_cantidad, stoc_stock_maximo, dbo.ejercicio1(stoc_producto,stoc_deposito) from STOCK
  order by 1

  --EJERCICIO 2--
  /*Realizar una funci�n que dado un art�culo y una fecha, retorne el stock que exist�a a esa fecha */
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
/* Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en caso que sea necesario. Se sabe que deber�a existir un �nico 
gerente general (deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado sin jefe deber� elegir entre ellos el gerente general, el 
cual ser� seleccionado por mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la empresa. Al finalizar la ejecuci�n 
del objeto la tabla deber� cumplir con la regla de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad de empleados que hab�a 
sin jefe antes de la ejecuci�n.  */

