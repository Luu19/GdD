USE GD2015C1
/*Implementar una regla de negocio en linea donde se valide que nunca un
producto compuesto pueda estar compuesto por componentes de rubros distintos a el*/
GO

CREATE TRIGGER regla_productos_compuestos
ON Composicion
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 
               FROM inserted i
                    JOIN Producto p on i.comp_producto=p.prod_codigo
                    JOIN Producto p2 on i.comp_componente=p2.prod_codigo
                WHERE p.prod_rubro!=p2.prod_rubro)
    BEGIN
        RAISERROR('No se puede componer un producto con componentes de rubros distintos a el',16,1)
        RETURN
    END

    INSERT INTO Composicion (comp_cantidad,comp_producto,comp_componente)
    SELECT i.comp_cantidad,i.comp_producto,i.comp_componente
    FROM inserted i
        JOIN Producto p on i.comp_producto=p.prod_codigo
        JOIN Producto p2 on i.comp_componente=p2.prod_codigo
    WHERE NOT EXISTS (SELECT 1 FROM Composicion WHERE comp_producto=i.comp_producto AND comp_componente=i.comp_componente)

    UPDATE Composicion
    SET comp_cantidad=i.comp_cantidad
    FROM inserted i
        JOIN Composicion c on i.comp_producto=c.comp_producto and i.comp_componente=c.comp_componente   
END
