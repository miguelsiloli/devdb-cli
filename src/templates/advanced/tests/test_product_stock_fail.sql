-- tSQLt Intentional Failure Test
-- This test demonstrates tSQLt's failure handling and is designed to fail
USE DevDB;
GO

-- Create Test Class for Intentional Failures
EXEC tSQLt.NewTestClass @ClassName = 'IntentionalFailureTests';
GO

-- Test 1: Intentional assertion failure to demonstrate tSQLt error handling
CREATE PROCEDURE IntentionalFailureTests.[test product stock assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known stock level
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('Test Widget', 19.99, 10);
    
    -- Act: Get the actual stock level
    DECLARE @ActualStock INT;
    SELECT @ActualStock = Stock FROM dbo.Products WHERE ProductName = 'Test Widget';
    
    -- Assert: Intentionally check for wrong stock level (this will fail)
    EXEC tSQLt.AssertEquals @Expected = 5, @Actual = @ActualStock, 
         @Message = 'INTENTIONAL FAILURE: Expected stock to be 5, but it was 10. This test demonstrates tSQLt failure handling.';
END;
GO

-- Test 2: Intentional exception expectation failure
CREATE PROCEDURE IntentionalFailureTests.[test exception expectation fails when no exception thrown]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Act & Assert: Expect an exception that won't be thrown
    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%This exception will never be thrown%';
    
    -- This simple statement won't throw an exception, causing the test to fail
    SELECT 1 AS SimpleSelect;
END;
GO

-- Test 3: Intentional string comparison failure
CREATE PROCEDURE IntentionalFailureTests.[test string comparison fails intentionally]
AS
BEGIN
    -- Arrange: Set up test data
    DECLARE @ActualValue NVARCHAR(50) = 'Hello World';
    DECLARE @ExpectedValue NVARCHAR(50) = 'Goodbye World';
    
    -- Act & Assert: Intentionally compare different strings
    EXEC tSQLt.AssertEquals @Expected = @ExpectedValue, @Actual = @ActualValue, 
         @Message = 'INTENTIONAL FAILURE: Demonstrating string comparison failure in tSQLt.';
END;
GO

-- Test 4: Intentional range assertion failure  
CREATE PROCEDURE IntentionalFailureTests.[test range assertion fails intentionally]
AS
BEGIN
    -- Arrange: Set up test value
    DECLARE @ActualValue INT = 25;
    
    -- Act & Assert: Intentionally check if value is in wrong range
    IF @ActualValue >= 10 AND @ActualValue <= 20
    BEGIN
        EXEC tSQLt.Fail 'INTENTIONAL FAILURE: Value 25 is not between 10 and 20. This demonstrates range assertion failure.';
    END;
END;
GO

-- Test 5: Intentional table content failure
CREATE PROCEDURE IntentionalFailureTests.[test table content assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert actual data
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('Product A', 10.00, 5),
    ('Product B', 20.00, 10);
    
    -- Create expected table with different data
    CREATE TABLE #ExpectedProducts (ProductName NVARCHAR(100), Price DECIMAL(10,2), Stock INT);
    INSERT INTO #ExpectedProducts VALUES 
    ('Product A', 15.00, 5),  -- Different price
    ('Product C', 20.00, 10); -- Different product name
    
    -- Act & Assert: Compare tables (this will fail due to differences)
    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedProducts', @Actual = 'dbo.Products', 
         @Message = 'INTENTIONAL FAILURE: Table contents do not match. This demonstrates table comparison failure.';
END;
GO

-- Test 6: Intentional null assertion failure
CREATE PROCEDURE IntentionalFailureTests.[test null assertion fails intentionally]
AS
BEGIN
    -- Arrange: Create a non-null value
    DECLARE @ActualValue NVARCHAR(50) = 'This is not null';
    
    -- Act & Assert: Intentionally assert that a non-null value is null
    EXEC tSQLt.AssertEquals @Expected = NULL, @Actual = @ActualValue, 
         @Message = 'INTENTIONAL FAILURE: Expected NULL but got a non-null value. This demonstrates null assertion failure.';
END;
GO