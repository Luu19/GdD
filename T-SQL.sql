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
--EJERCICIO 7--
/* Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe 
insertar una línea por cada artículo con los movimientos de stock generados por 
las ventas entre esas fechas. La tabla se encuentra creada y vacía.*/
if not exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'ventas') AND type in (N'U'))    
			begin create table ventas(
			codigo char(8),
			detalle char(50),
			cantidad decimal(12,2),
			precio decimal(12,2),
			renglon bigint identity(1,1) primary key,			 
			ganancia decimal (12,2)
			)
	end

create proc ejercicio7(@fechaInicial smalldatetime,@fechaFinal smalldatetime) as
	begin	 
	declare @codigo char(8),@detalle char(50), @cantidad decimal(12,2), @precio decimal(12,2), @ganancia decimal(12,2)
	declare cursor_ventas cursor for	 
		select prod_codigo, prod_detalle, sum(item_cantidad) as cant_mov, AVG(item_precio) as precio_venta, sum(item_precio * item_cantidad) as ganancia  from Factura
		join Item_Factura on item_sucursal + item_tipo + item_numero = fact_sucursal + fact_tipo + fact_numero
		join Producto on prod_codigo = item_producto
		WHERE fact_fecha BETWEEN @fechaInicial AND @fechaFinal
		group by prod_codigo, prod_detalle
	open cursor_ventas	
	fetch next from cursor_ventas into @codigo, @detalle, @cantidad, @precio, @ganancia --1er afuera para fetch
	while @@FETCH_STATUS = 0
		begin					
		insert into ventas (codigo, detalle, cantidad, precio, ganancia)
		values (@codigo, @detalle, @cantidad, @precio, @ganancia)
		fetch next from cursor_ventas into @codigo, @detalle, @cantidad, @precio, @ganancia
		end
	close cursor_ventas
	deallocate cursor_ventas
	end
	go
exec ejercicio7 '2012-01-01','2012-07-01';
select * from ventas
--EJERCICIO 8--
/*Realizar un procedimiento que complete la tabla Diferencias de precios, para los 
productos facturados que tengan composición y en los cuales el precio de 
facturación sea diferente al precio del cálculo de los precios unitarios por 
cantidad de sus componentes, se aclara que un producto que compone a otro, 
también puede estar compuesto por otros y así sucesivamente, la tabla se debe 
crear y está formada por las siguientes columnas: 
DIFERENCIAS 
Código Detalle Cantidad  Precio_generado Precio_facturado */

IF OBJECT_ID('Diferencias','U') IS NOT NULL 
DROP TABLE Diferencias
GO
if not exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Diferencias') AND type in (N'U'))
    begin
			create table Diferencias(
			id bigint identity(1,1) primary key,
			codigo char(8), --fk ?
			detalle char(50),
			cantidad decimal(12,2),
			precio_generado decimal(12,2),
			precio_facturado decimal (12,2)
			)
	end

create or alter function precio_comp(@codigo char(8)) returns decimal(12,2)
	as	
	begin
	declare @precio_total decimal(12,2), @precio_comp decimal(12,2), @comp_cantidad decimal(12,2), @comp_aux char(8)
	set @precio_total = 0
	declare cursor_componente cursor for
		select distinct comp_componente, comp_cantidad, c.prod_precio from Composicion
		join Producto c on c.prod_codigo = comp_componente
		where @codigo = comp_producto
	open cursor_componente
	fetch next from cursor_componente into @comp_aux, @comp_cantidad, @precio_comp
	while @@FETCH_STATUS = 0 begin
		if @comp_aux in (select comp_producto from Composicion) begin
			set @precio_total = @precio_total + dbo.precio_comp(@comp_aux)			
			fetch next from cursor_componente into @comp_aux, @comp_cantidad, @precio_comp end
		else begin
			set @precio_total = @precio_total + @comp_cantidad * @precio_comp
			fetch next from cursor_componente into @comp_aux, @comp_cantidad, @precio_comp end
		end
		return @precio_total
	end
go

create or alter proc ejercicio8 as
	begin 
	declare @codigo char(8),@detalle char(50), @cantidad decimal(12,2), @precio_generado decimal(12,2), @precio_facturado decimal(12,2)
	declare cursor_dif cursor for
		select distinct prod_codigo, prod_detalle, sum(comp_cantidad), dbo.precio_comp(prod_codigo), prod_precio from Item_Factura
		join Producto on prod_codigo = item_producto
		join Composicion on comp_producto = prod_codigo
		where dbo.precio_comp(prod_codigo) <> item_precio
		group by prod_codigo, prod_detalle, prod_precio
	open cursor_dif
	fetch next from cursor_dif into @codigo, @detalle, @cantidad, @precio_generado, @precio_facturado
	while @@FETCH_STATUS = 0
		begin
		insert into Diferencias(codigo, detalle, cantidad, precio_generado, precio_facturado)
		values (@codigo, @detalle, @cantidad, @precio_generado, @precio_facturado)
		fetch next from cursor_dif into @codigo, @detalle, @cantidad, @precio_generado, @precio_facturado
		end
		close cursor_dif
		deallocate cursor_dif
	end
go
 exec ejercicio8;

 select * from Diferencias

 --EJERCICIO 10--
 /*Crear el/los objetos de base de datos que ante el intento de borrar un artículo 
verifique que no exista stock y si es así lo borre en caso contrario que emita un 
mensaje de error.  */
--no todos los productos están en la lista STOCK

create trigger ejercicio10 on Producto for DELETE as
	begin 
	if (select count(prod_codigo) from deleted 
		join STOCK on stoc_producto = prod_codigo
		where stoc_cantidad > 0) > 0
		begin
		rollback transaction
		return 'No puede borrar un producto con stock'
		end
	end 
go
--EJERCICIO 11--
/*Cree el/los objetos de base de datos necesarios para que dado un código de 
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o 
indirectamente). Solo contar aquellos empleados (directos o indirectos) que 
tengan un código mayor que su jefe directo. */

create or alter function ejercicio11(@cod_jefe numeric(6,0)) 
returns int
as
	begin 
	declare @cantidad int, @cod_empl numeric(6,0)
	set @cantidad = 0
	declare cursor_empl cursor for 
		select distinct empl_codigo from Empleado
		where empl_codigo > @cod_jefe and empl_jefe = @cod_jefe
	open cursor_empl
	fetch next from cursor_empl into @cod_empl
	while @@fetch_status = 0 begin
			--if dbo.ejercicio11(@cod_empl) > 0 begin
				set @cantidad = @cantidad + dbo.ejercicio11(@cod_empl) + 1
			--	end
			--else begin
		--		set @cantidad = @cantidad + 1 end
			fetch next from cursor_empl into @cod_empl				
		end
			return @cantidad
	end	
go

select empl_codigo, empl_jefe from Empleado

select distinct dbo.ejercicio11(2) from empleado

--EJERCICIO 12--
/* Cree el/los objetos de base de datos necesarios para que nunca un producto 
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se 
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos 
y tecnologías. No se conoce la cantidad de niveles de composición existentes. */

create function componentes(@producto char(8),@componente char(8))
returns int as
	begin
	if @componente = @producto begin 
	return 1 end
	else begin
		declare @return bit, @comp_aux char(8)
		set @return = 0
		declare cursor_productos cursor for
			select comp_componente from Composicion 
			where comp_producto = @producto
		open cursor_productos
		fetch next into @componente
		while @@FETCH_STATUS = 0 begin		
			select @return = sum(dbo.componentes(comp_producto, comp_componente)) from composicion 
					where comp_componente = @componente
					/*IF dbo.Ejercicio12Func(@producto,@prodaux) = 1 resolución
					RETURN 1 */
			fetch next into @componente
			end
		close cursor_producto
		deallocate cursor_producto
		return @return
		end
	end
go

create trigger ejercicio_12 on composicion after insert as
	begin	
		if (select sum(dbo.componentes(comp_producto, comp_componente)) from inserted) > 0 begin
			rollback
			return 'No se puede ingresar un producto compuesto por si mismo'
			end
	end
go

--EJERCICIO 13--
/* Cree el/los objetos de base de datos necesarios para implantar la siguiente regla 
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de 
sus empleados totales (directos + indirectos)”. */

create or alter function sueldo_empls(@cod_jefe numeric(6,0))  --base funcion ejercicio11
returns int
as
	begin 
	declare @cantidad int, @cod_empl numeric(6,0)
	set @cantidad = 0
	declare cursor_empl cursor for 
		select distinct empl_codigo from Empleado
		where empl_codigo > @cod_jefe and empl_jefe = @cod_jefe
	open cursor_empl
	fetch next from cursor_empl into @cod_empl
	while @@fetch_status = 0 begin		
				set @cantidad = @cantidad + dbo.ejercicio11(@cod_empl) + 1
			fetch next from cursor_empl into @cod_empl				
		end
			return @cantidad
	end	
go

CREATE trigger ejercicio_13 on Empleado after insert as
	begin
		declare @jefe numeric(6,0)
		if (select empl_ingreso from inserted /*??*/) > dbo.sueldo_empls(@jefe) *1.20 
		begin 		
			print 'Un jefe no puede tener un sueldo 20% mayor que la suma de sus empleados'
			rollback transaction
		end
		end
go

