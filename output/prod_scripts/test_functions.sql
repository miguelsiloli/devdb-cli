-- =====================================================
-- File: FunctionTests.sql
-- Description: tSQLt tests for User-Defined Functions
-- Author: miguel.b.silva@***.com
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
-- SUMMARY OF CHANGES
-- Date(yyyy-mm-dd)    Author              Comments
-- ------------------- ------------------- ------------------------------------------------------------
-- 2025-07-10      miguel.b.silva@***.com       Automated polish and formatting.
-- =====================================================
USE devdb;

GO

-- Create Test Class for Functions
EXEC tsqlt.newtestclass @classname = 'FunctionTests';

GO

-- Test 1: CalculateUserAge function

CREATE PROCEDURE functiontests.[test calculateuserage returns correct days difference]
AS
BEGIN
    -- Arrange: Create a fake Users table for isolation
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Insert test data with known date
    DECLARE @testdate datetime2 = dateadd(DAY,
                                           -30,
                                           getutcdate());
    INSERT INTO dbo.users (username, email, createdat)
    VALUES ('testuser_func', 'test@func.com', @testdate);

    -- Act: Call the function
    DECLARE @actualage INT;
    SELECT @actualage = dbo.calculateuserage(createdat)
    FROM dbo.users
    WHERE username = 'testuser_func';

    -- Assert: Check the result (allow 1 day tolerance for timing)
    IF @actualage < 29
       OR @actualage > 31
    BEGIN
        EXEC tsqlt.fail 'CalculateUserAge should return approximately 30 days';
    END;
END;
GO

-- Test 2: FormatProductName function

CREATE PROCEDURE functiontests.[test formatproductname formats correctly]
AS
BEGIN
    -- Arrange: Set up test data
    DECLARE @productname nvarchar(100) = 'Test Product';
    DECLARE @price decimal(10, 2) = 19.99;
    DECLARE @expected nvarchar(150) = 'Test Product - $19.99';

    -- Act: Call the function
    DECLARE @actual nvarchar(150);
    SELECT @actual = dbo.formatproductname(@productname,
                                             @price);

    -- Assert: Check the result
    EXEC tsqlt.assertequals @expected = @expected,
                            @actual = @actual,
                            @message = 'FormatProductName should format product name with price correctly';
END;

GO

-- Test 3: GetActiveProducts table-valued function - basic functionality

CREATE PROCEDURE functiontests.[test getactiveproducts returns products with stock greater than minimum]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test products with different stock levels
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('TVF Test Product 1', 10.00, 5),
           ('TVF Test Product 2', 20.00, 15),
           ('TVF Test Product 3', 30.00, 0);

    -- Act: Call the function with MinStock = 0
    DECLARE @activeproductcount INT;
    SELECT @activeproductcount = count(*)
    FROM dbo.getactiveproducts(0)
    WHERE productname LIKE 'TVF Test%';

    -- Assert: Should return 2 products (stock > 0)
    EXEC tsqlt.assertequals @expected = 2,
                            @actual = @activeproductcount,
                            @message = 'GetActiveProducts should return products with stock > 0';
END;

GO

-- Test 4: GetActiveProducts with minimum stock parameter

CREATE PROCEDURE functiontests.[test getactiveproducts respects minimum stock parameter]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test products with different stock levels
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('TVF Test Product 1', 10.00, 5),
           ('TVF Test Product 2', 20.00, 15),
           ('TVF Test Product 3', 30.00, 0);

    -- Act: Call the function with MinStock = 10
    DECLARE @highstockcount INT;
    SELECT @highstockcount = count(*)
    FROM dbo.getactiveproducts(10)
    WHERE productname LIKE 'TVF Test%';

    -- Assert: Should return 1 product (stock > 10)
    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @highstockcount,
                            @message = 'GetActiveProducts should respect MinStock parameter';
END;

GO

-- Test 5: GetActiveProducts calculates TotalValue correctly

CREATE PROCEDURE functiontests.[test getactiveproducts calculates total value correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known price and stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('Value Test Product', 25.00, 4);

    -- Act: Get the total value from the function
    DECLARE @actualtotalvalue decimal(10, 2);
    SELECT @actualtotalvalue = totalvalue
    FROM dbo.getactiveproducts(0)
    WHERE productname = 'Value Test Product';

    -- Assert: Should be 25.00 * 4 = 100.00
    EXEC tsqlt.assertequals @expected = 100.00,
                            @actual = @actualtotalvalue,
                            @message = 'GetActiveProducts should calculate TotalValue as Price * Stock';
END;

GO