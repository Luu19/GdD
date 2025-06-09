/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/



create function funcionComposicion(@producto char(8),@componente char(8))
	returns BIT as
	begin 
		select @producto = comp_componente from Composicion
		declare productos cursor
		/*sp para modificar algo anterior
		trigger para algo del momento/futuro */
	end
	go

create trigger ej on Composicion
	after insert --evitar instead of. Si para unos casos tiene que ingresar y en otros no, utilizar. 
	as
	declare @componente char(8)
	select @componente = comp_componente from inserted
	if sum(dbo.funcionComposicion(@componente,@componente)) > 0 -- select 
	begin 
		PRINT 'El producto no se insertó, no debe ser compuesto con sigo mismo'
		ROLLBACK 
	end
	else 
	begin 
		PRINT 'El producto se insertó correctamente'
	end 
	go

	/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/


create function dbo.Ejercicio14Func(@producto char(8)) -- retorna el precio del producto si no es compuesto o de la suma de los componentes 
end go


create trigger ejer14 on Item_Factura 
	instead of insert --instead of porque existen 3 opciones posibles. Para ocasiones de Fila por fila. After para casos más masivos
	as 
	declare @precio decimal(12,2), @producto char(8)
 select @producto item_producto, @precio item_precio  from inserted 
 join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo 
 --cursor de inserted. Devuelve todos los campos de ítem. Precio obtenido en el cursor.
	if ((select distinct comp_producto from Composicion where comp_producto = @producto) is null)
		print 'ok'
	else if(@precio > dbo.Ejercicio14Func(@producto) / 2 ) and (@precio < dbo.Ejercicio14Func(@producto))--a un precio menor que la suma de los precios de sus componentes
		begin 
			print
			insert 
		end
		--en caso de no--

		/*borra para los datos de la factura y la item_factura y la cabezera de las dos. No es rollback, tumba la operación al encontrar el 
		primero que encuentra. No es rollback porque sino el cursor podría ingresar de nuevo en la factura.
		Al ingresar de nuevo al cursor, saltará un error de FK por el código de la factura
		 Se puede utilizar el rollback*/

