-- schemas/02_sprocs_and_views.sql
-- This script creates stored procedures and views.

USE DevDB;
GO

PRINT 'Creating stored procedure: AddNewUser';
GO
CREATE PROCEDURE dbo.AddNewUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Users (Username, Email)
    VALUES (@Username, @Email);
END;
GO

PRINT 'Creating view: PricedProducts';
GO
CREATE VIEW dbo.PricedProducts AS
SELECT
    ProductID,
    ProductName,
    Price
FROM
    dbo.Products
WHERE
    Price > 0;
GO