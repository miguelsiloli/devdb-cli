-- tSQLt Tests for Views
USE DevDB;
GO

-- Create Test Class for Views
EXEC tSQLt.NewTestClass @ClassName = 'ViewTests';
GO

-- Test 1: UserStats view categorizes users correctly
CREATE PROCEDURE ViewTests.[test UserStats view categorizes users by activity correctly]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Insert test users with different creation dates
    INSERT INTO dbo.Users (Username, Email, CreatedAt) VALUES 
    ('viewtest_new', 'new@test.com', DATEADD(DAY, -5, GETUTCDATE())),
    ('viewtest_regular', 'regular@test.com', DATEADD(DAY, -60, GETUTCDATE())),
    ('viewtest_veteran', 'veteran@test.com', DATEADD(DAY, -400, GETUTCDATE()));
    
    -- Act: Query the view
    DECLARE @NewUserCount INT, @RegularUserCount INT, @VeteranUserCount INT;
    
    SELECT @NewUserCount = COUNT(*) FROM dbo.UserStats 
    WHERE Username LIKE 'viewtest%' AND UserCategory = 'New';
    
    SELECT @RegularUserCount = COUNT(*) FROM dbo.UserStats 
    WHERE Username LIKE 'viewtest%' AND UserCategory = 'Regular';
    
    SELECT @VeteranUserCount = COUNT(*) FROM dbo.UserStats 
    WHERE Username LIKE 'viewtest%' AND UserCategory = 'Veteran';
    
    -- Assert: Check categorization
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @NewUserCount, 
         @Message = 'UserStats should categorize recent users as New';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @RegularUserCount, 
         @Message = 'UserStats should categorize 60-day users as Regular';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @VeteranUserCount, 
         @Message = 'UserStats should categorize 400-day users as Veteran';
END;
GO

-- Test 2: UserStats view calculates DaysActive correctly
CREATE PROCEDURE ViewTests.[test UserStats view calculates DaysActive correctly]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Insert test user with known creation date
    DECLARE @TestDate DATETIME2 = DATEADD(DAY, -100, GETUTCDATE());
    INSERT INTO dbo.Users (Username, Email, CreatedAt) VALUES 
    ('viewtest_days', 'days@test.com', @TestDate);
    
    -- Act: Get DaysActive from view
    DECLARE @DaysActive INT;
    SELECT @DaysActive = DaysActive FROM dbo.UserStats 
    WHERE Username = 'viewtest_days';
    
    -- Assert: Check days calculation (allow 1 day tolerance)
    IF @DaysActive < 99 OR @DaysActive > 101
    BEGIN
        EXEC tSQLt.Fail 'UserStats should calculate DaysActive correctly';
    END;
END;
GO

-- Test 3: ProductAnalytics view categorizes stock levels correctly
CREATE PROCEDURE ViewTests.[test ProductAnalytics view categorizes stock levels correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test products with different stock levels
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('viewtest_outofstock', 25.00, 0),
    ('viewtest_lowstock', 15.00, 5),
    ('viewtest_mediumstock', 30.00, 25),
    ('viewtest_highstock', 50.00, 100);
    
    -- Act: Query stock status categorization
    DECLARE @OutOfStockCount INT, @LowStockCount INT, @MediumStockCount INT, @HighStockCount INT;
    
    SELECT @OutOfStockCount = COUNT(*) FROM dbo.ProductAnalytics 
    WHERE ProductName LIKE 'viewtest%' AND StockStatus = 'Out of Stock';
    
    SELECT @LowStockCount = COUNT(*) FROM dbo.ProductAnalytics 
    WHERE ProductName LIKE 'viewtest%' AND StockStatus = 'Low Stock';
    
    SELECT @MediumStockCount = COUNT(*) FROM dbo.ProductAnalytics 
    WHERE ProductName LIKE 'viewtest%' AND StockStatus = 'Medium Stock';
    
    SELECT @HighStockCount = COUNT(*) FROM dbo.ProductAnalytics 
    WHERE ProductName LIKE 'viewtest%' AND StockStatus = 'High Stock';
    
    -- Assert: Check all categorizations
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @OutOfStockCount, 
         @Message = 'ProductAnalytics should categorize 0 stock as Out of Stock';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @LowStockCount, 
         @Message = 'ProductAnalytics should categorize 5 stock as Low Stock';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @MediumStockCount, 
         @Message = 'ProductAnalytics should categorize 25 stock as Medium Stock';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @HighStockCount, 
         @Message = 'ProductAnalytics should categorize 100 stock as High Stock';
END;
GO

-- Test 4: ProductAnalytics view calculates inventory value correctly
CREATE PROCEDURE ViewTests.[test ProductAnalytics view calculates inventory value correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known price and stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('viewtest_inventory', 25.50, 4);
    
    -- Act: Get inventory value from view
    DECLARE @InventoryValue DECIMAL(10,2);
    SELECT @InventoryValue = InventoryValue FROM dbo.ProductAnalytics 
    WHERE ProductName = 'viewtest_inventory';
    
    -- Assert: Check inventory value calculation (25.50 * 4 = 102.00)
    EXEC tSQLt.AssertEquals @Expected = 102.00, @Actual = @InventoryValue, 
         @Message = 'ProductAnalytics should calculate InventoryValue as Price * Stock';
END;
GO

-- Test 5: ProductAnalytics view formats display name correctly
CREATE PROCEDURE ViewTests.[test ProductAnalytics view formats display name correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known name and price
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('Test Widget', 19.99, 10);
    
    -- Act: Get display name from view
    DECLARE @DisplayName NVARCHAR(150);
    SELECT @DisplayName = DisplayName FROM dbo.ProductAnalytics 
    WHERE ProductName = 'Test Widget';
    
    -- Assert: Check display name formatting
    EXEC tSQLt.AssertEquals @Expected = 'Test Widget - $19.99', @Actual = @DisplayName, 
         @Message = 'ProductAnalytics should format DisplayName using FormatProductName function';
END;
GO

-- Test 6: UserProductSummary view returns data for all users
CREATE PROCEDURE ViewTests.[test UserProductSummary view includes all users]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test users
    INSERT INTO dbo.Users (Username, Email, CreatedAt) VALUES 
    ('viewtest_user1', 'user1@test.com', DATEADD(DAY, -10, GETUTCDATE())),
    ('viewtest_user2', 'user2@test.com', DATEADD(DAY, -50, GETUTCDATE())),
    ('viewtest_user3', 'user3@test.com', DATEADD(DAY, -400, GETUTCDATE()));
    
    -- Insert test products
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('Product1', 10.00, 5),
    ('Product2', 20.00, 10);
    
    -- Act: Query summary view
    DECLARE @SummaryCount INT;
    SELECT @SummaryCount = COUNT(*) FROM dbo.UserProductSummary 
    WHERE Username LIKE 'viewtest%';
    
    -- Assert: Should have data for all 3 users
    EXEC tSQLt.AssertEquals @Expected = 3, @Actual = @SummaryCount, 
         @Message = 'UserProductSummary should return data for all users';
END;
GO

-- Test 7: UserProductSummary view calculates product metrics correctly
CREATE PROCEDURE ViewTests.[test UserProductSummary view calculates product metrics correctly]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test user
    INSERT INTO dbo.Users (Username, Email, CreatedAt) VALUES 
    ('viewtest_metrics', 'metrics@test.com', DATEADD(DAY, -10, GETUTCDATE()));
    
    -- Insert test products with known values
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('Product1', 10.00, 5),    -- InventoryValue = 50.00
    ('Product2', 20.00, 10);   -- InventoryValue = 200.00
    -- Total: 2 products, Average price = 15.00, Total inventory = 250.00
    
    -- Act: Get metrics from view
    DECLARE @ProductCount INT, @AveragePrice DECIMAL(10,2), @TotalInventoryValue DECIMAL(10,2);
    SELECT @ProductCount = ProductCount, @AveragePrice = AveragePrice, @TotalInventoryValue = TotalInventoryValue 
    FROM dbo.UserProductSummary 
    WHERE Username = 'viewtest_metrics';
    
    -- Assert: Check calculations
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @ProductCount, 
         @Message = 'UserProductSummary should count products correctly';
    EXEC tSQLt.AssertEquals @Expected = 15.00, @Actual = @AveragePrice, 
         @Message = 'UserProductSummary should calculate average price correctly';
    EXEC tSQLt.AssertEquals @Expected = 250.00, @Actual = @TotalInventoryValue, 
         @Message = 'UserProductSummary should calculate total inventory value correctly';
END;
GO

-- Test 8: Complex query using multiple views works correctly
CREATE PROCEDURE ViewTests.[test complex query with multiple views works correctly]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test users with different categories
    INSERT INTO dbo.Users (Username, Email, CreatedAt) VALUES 
    ('viewtest_new', 'new@test.com', DATEADD(DAY, -5, GETUTCDATE())),
    ('viewtest_regular', 'regular@test.com', DATEADD(DAY, -60, GETUTCDATE())),
    ('viewtest_veteran', 'veteran@test.com', DATEADD(DAY, -400, GETUTCDATE()));
    
    -- Insert high-value products
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES 
    ('High Value Product', 100.00, 50);  -- InventoryValue = 5000.00 (> 1000)
    
    -- Act: Execute complex query joining UserStats with ProductAnalytics
    DECLARE @ComplexQueryCount INT;
    SELECT @ComplexQueryCount = COUNT(*)
    FROM dbo.UserStats us
    CROSS JOIN (
        SELECT COUNT(*) AS HighValueProducts
        FROM dbo.ProductAnalytics pa
        WHERE pa.InventoryValue > 1000
    ) hv
    WHERE us.Username LIKE 'viewtest%' AND us.UserCategory IN ('Regular', 'Veteran');
    
    -- Assert: Should have 2 users (regular + veteran)
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @ComplexQueryCount, 
         @Message = 'Complex query with multiple views should work correctly';
END;
GO