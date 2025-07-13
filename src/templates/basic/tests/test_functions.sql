-- tSQLt Tests for User-Defined Functions
USE DevDB;
GO

-- Create Test Class for Functions
EXEC tSQLt.NewTestClass @ClassName = 'FunctionTests';
GO

-- Test 1: CalculateUserAge function
CREATE PROCEDURE FunctionTests.[test CalculateUserAge returns correct days difference]
AS
BEGIN
    -- Arrange: Create a fake Users table for isolation
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Insert test data with known date
    DECLARE @TestDate DATETIME2 = DATEADD(DAY, -30, GETUTCDATE());
    INSERT INTO dbo.Users (Username, Email, CreatedAt) 
    VALUES ('testuser_func', 'test@func.com', @TestDate);
    
    -- Act: Call the function
    DECLARE @ActualAge INT;
    SELECT @ActualAge = dbo.CalculateUserAge(CreatedAt) 
    FROM dbo.Users 
    WHERE Username = 'testuser_func';
    
    -- Assert: Check the result (allow 1 day tolerance for timing)
    IF @ActualAge < 29 OR @ActualAge > 31
    BEGIN
        EXEC tSQLt.Fail 'CalculateUserAge should return approximately 30 days';
    END;
END;
GO

-- Test 2: FormatProductName function
CREATE PROCEDURE FunctionTests.[test FormatProductName formats correctly]
AS
BEGIN
    -- Arrange: Set up test data
    DECLARE @ProductName NVARCHAR(100) = 'Test Product';
    DECLARE @Price DECIMAL(10,2) = 19.99;
    DECLARE @Expected NVARCHAR(150) = 'Test Product - $19.99';
    
    -- Act: Call the function
    DECLARE @Actual NVARCHAR(150);
    SELECT @Actual = dbo.FormatProductName(@ProductName, @Price);
    
    -- Assert: Check the result
    EXEC tSQLt.AssertEquals @Expected = @Expected, @Actual = @Actual, 
         @Message = 'FormatProductName should format product name with price correctly';
END;
GO

-- Test 3: GetActiveProducts table-valued function - basic functionality
CREATE PROCEDURE FunctionTests.[test GetActiveProducts returns products with stock greater than minimum]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test products with different stock levels
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('TVF Test Product 1', 10.00, 5),
    ('TVF Test Product 2', 20.00, 15),
    ('TVF Test Product 3', 30.00, 0);
    
    -- Act: Call the function with MinStock = 0
    DECLARE @ActiveProductCount INT;
    SELECT @ActiveProductCount = COUNT(*) 
    FROM dbo.GetActiveProducts(0) 
    WHERE ProductName LIKE 'TVF Test%';
    
    -- Assert: Should return 2 products (stock > 0)
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @ActiveProductCount, 
         @Message = 'GetActiveProducts should return products with stock > 0';
END;
GO

-- Test 4: GetActiveProducts with minimum stock parameter
CREATE PROCEDURE FunctionTests.[test GetActiveProducts respects minimum stock parameter]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test products with different stock levels
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('TVF Test Product 1', 10.00, 5),
    ('TVF Test Product 2', 20.00, 15),
    ('TVF Test Product 3', 30.00, 0);
    
    -- Act: Call the function with MinStock = 10
    DECLARE @HighStockCount INT;
    SELECT @HighStockCount = COUNT(*) 
    FROM dbo.GetActiveProducts(10) 
    WHERE ProductName LIKE 'TVF Test%';
    
    -- Assert: Should return 1 product (stock > 10)
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @HighStockCount, 
         @Message = 'GetActiveProducts should respect MinStock parameter';
END;
GO

-- Test 5: GetActiveProducts calculates TotalValue correctly
CREATE PROCEDURE FunctionTests.[test GetActiveProducts calculates total value correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known price and stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('Value Test Product', 25.00, 4);
    
    -- Act: Get the total value from the function
    DECLARE @ActualTotalValue DECIMAL(10,2);
    SELECT @ActualTotalValue = TotalValue 
    FROM dbo.GetActiveProducts(0) 
    WHERE ProductName = 'Value Test Product';
    
    -- Assert: Should be 25.00 * 4 = 100.00
    EXEC tSQLt.AssertEquals @Expected = 100.00, @Actual = @ActualTotalValue, 
         @Message = 'GetActiveProducts should calculate TotalValue as Price * Stock';
END;
GO