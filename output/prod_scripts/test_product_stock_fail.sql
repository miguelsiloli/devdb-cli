-- =====================================================
-- File: intentional_failure_tests.sql
-- Description: tSQLt tests designed to intentionally fail, demonstrating tSQLt's failure handling capabilities.
-- Author: miguel.b.silva@***.com
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
-- tSQLt Intentional Failure Test
-- This test demonstrates tSQLt's failure handling and is designed to fail
USE devdb;

GO

-- Create Test Class for Intentional Failures
EXEC tsqlt.newtestclass @classname = 'IntentionalFailureTests';

GO

-- Test 1: Intentional assertion failure to demonstrate tSQLt error handling

CREATE PROCEDURE intentionalfailuretests.[test product stock assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known stock level
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('Test Widget', 19.99, 10);

    -- Act: Get the actual stock level
    DECLARE @actualstock INT;

    SELECT @actualstock = stock
    FROM dbo.products
    WHERE productname = 'Test Widget';

    -- Assert: Intentionally check for wrong stock level (this will fail)
    EXEC tsqlt.assertequals @expected = 5,
                             @actual = @actualstock,
                             @message = 'INTENTIONAL FAILURE: Expected stock to be 5, but it was 10. This test demonstrates tSQLt failure handling.';
END;

GO

-- Test 2: Intentional exception expectation failure

CREATE PROCEDURE intentionalfailuretests.[test exception expectation fails when no exception thrown]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Act & Assert: Expect an exception that won't be thrown
    EXEC tsqlt.expectexception @expectedmessagepattern = '%This exception will never be thrown%';

    -- This simple statement won't throw an exception, causing the test to fail
    SELECT 1 AS simpleselect;
END;

GO

-- Test 3: Intentional string comparison failure

CREATE PROCEDURE intentionalfailuretests.[test string comparison fails intentionally]
AS
BEGIN
    -- Arrange: Set up test data
    DECLARE @actualvalue NVARCHAR(50) = 'Hello World';
    DECLARE @expectedvalue NVARCHAR(50) = 'Goodbye World';

    -- Act & Assert: Intentionally compare different strings
    EXEC tsqlt.assertequals @expected = @expectedvalue,
                             @actual = @actualvalue,
                             @message = 'INTENTIONAL FAILURE: Demonstrating string comparison failure in tSQLt.';
END;

GO

-- Test 4: Intentional range assertion failure

CREATE PROCEDURE intentionalfailuretests.[test range assertion fails intentionally]
AS
BEGIN
    -- Arrange: Set up test value
    DECLARE @actualvalue INT = 25;

    -- Act & Assert: Intentionally check if value is in wrong range
    IF @actualvalue >= 10
       AND @actualvalue <= 20
    BEGIN
        EXEC tsqlt.fail 'INTENTIONAL FAILURE: Value 25 is not between 10 and 20. This demonstrates range assertion failure.';
    END;
END;
GO

-- Test 5: Intentional table content failure

CREATE PROCEDURE intentionalfailuretests.[test table content assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert actual data
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('Product A', 10.00, 5),
           ('Product B', 20.00, 10);

    -- Create expected table with different data
    CREATE TABLE #expectedproducts (
        productname NVARCHAR(100),
        price DECIMAL(10, 2),
        stock INT
    );

    INSERT INTO #expectedproducts
    VALUES ('Product A', 15.00, 5), -- Different price
           ('Product C', 20.00, 10); -- Different product name

    -- Act & Assert: Compare tables (this will fail due to differences)
    EXEC tsqlt.assertequalstable @expected = '#ExpectedProducts',
                                 @actual = 'dbo.Products',
                                 @message = 'INTENTIONAL FAILURE: Table contents do not match. This demonstrates table comparison failure.';
END;

GO

-- Test 6: Intentional null assertion failure

CREATE PROCEDURE intentionalfailuretests.[test null assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create a non-null value
    DECLARE @actualvalue NVARCHAR(50) = 'This is not null';

    -- Act & Assert: Intentionally assert that a non-null value is null
    EXEC tsqlt.assertequals @expected = NULL,
                             @actual = @actualvalue,
                             @message = 'INTENTIONAL FAILURE: Expected NULL but got a non-null value. This demonstrates null assertion failure.';
END;

GO