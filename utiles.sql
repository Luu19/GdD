
CREATE FUNCTION dbo.precio_producto(@producto CHAR(8)) -- Precio de un producto / producto compuesto
RETURNS decimal(12,2)
AS
BEGIN
    declare @cantidad decimal(12,2), @precio decimal(12,2)
    select @precio = 0
	IF (select count(*) from composicion where comp_producto = @producto) = 0
        return (select prod_precio from producto where prod_codigo = @producto)
	BEGIN
		DECLARE @ProdAux char(8)
		DECLARE cursor_componente CURSOR FOR SELECT comp_componente, comp_cantidad
										FROM Composicion
										WHERE comp_producto = @producto 
		OPEN cursor_componente
		FETCH NEXT from cursor_componente INTO @ProdAux, @cantidad
		WHILE @@FETCH_STATUS = 0
			BEGIN
				select @precio = @precio + @cantidad*dbo.Ejercicio14Func(@prodaux) 
    			FETCH NEXT from cursor_componente INTO @ProdAux
			END
		CLOSE cursor_componente
		DEALLOCATE cursor_componente
		RETURN @precio
	END
END
GO