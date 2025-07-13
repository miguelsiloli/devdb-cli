-- schemas/03_functions.sql
-- This script creates user-defined functions (UDFs).

USE DevDB;
GO

-- Scalar function to calculate user age from created date
PRINT 'Creating scalar function: CalculateUserAge';
GO
CREATE FUNCTION dbo.CalculateUserAge(@CreatedAt DATETIME2)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;
    SET @Age = DATEDIFF(DAY, @CreatedAt, GETUTCDATE());
    RETURN @Age;
END;
GO

-- Table-valued function to get active products
PRINT 'Creating table-valued function: GetActiveProducts';
GO
CREATE FUNCTION dbo.GetActiveProducts(@MinStock INT = 0)
RETURNS TABLE
AS
RETURN (
    SELECT 
        ProductID,
        ProductName,
        Price,
        Stock,
        Price * Stock AS TotalValue
    FROM dbo.Products
    WHERE Stock > @MinStock
);
GO

-- Scalar function to format product display name
PRINT 'Creating scalar function: FormatProductName';
GO
CREATE FUNCTION dbo.FormatProductName(@ProductName NVARCHAR(100), @Price DECIMAL(10,2))
RETURNS NVARCHAR(150)
AS
BEGIN
    RETURN @ProductName + ' - $' + CAST(@Price AS NVARCHAR(20));
END;
GO