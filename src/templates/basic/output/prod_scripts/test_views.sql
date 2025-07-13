-- =====================================================
-- File: tSQLt View Tests.sql
-- Description: tSQLt tests for database views including UserStats and ProductAnalytics
-- Author: miguel.b.silva@***.com
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
-- tSQLt Tests for Views
USE devdb;

GO

-- Create Test Class for Views
EXEC tsqlt.newtestclass @classname = 'ViewTests';

GO

-- Test 1: UserStats view categorizes users correctly

CREATE PROCEDURE viewtests.[test userstats view categorizes users by activity correctly]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Insert test users with different creation dates
    INSERT INTO dbo.users (username, email, createdat)
    VALUES
    ('viewtest_new', 'new@test.com', dateadd(DAY, -5, getutcdate())),
    ('viewtest_regular', 'regular@test.com', dateadd(DAY, -60, getutcdate())),
    ('viewtest_veteran', 'veteran@test.com', dateadd(DAY, -400, getutcdate()));

    -- Act: Query the view
    DECLARE @newusercount INT, @regularusercount INT, @veteranusercount INT;

    SELECT @newusercount = COUNT(*)
    FROM dbo.userstats
    WHERE username LIKE 'viewtest%'
          AND usercategory = 'New';

    SELECT @regularusercount = COUNT(*)
    FROM dbo.userstats
    WHERE username LIKE 'viewtest%'
          AND usercategory = 'Regular';

    SELECT @veteranusercount = COUNT(*)
    FROM dbo.userstats
    WHERE username LIKE 'viewtest%'
          AND usercategory = 'Veteran';

    -- Assert: Check categorization
    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @newusercount,
                            @message = 'UserStats should categorize recent users as New';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @regularusercount,
                            @message = 'UserStats should categorize 60-day users as Regular';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @veteranusercount,
                            @message = 'UserStats should categorize 400-day users as Veteran';
END;

GO

-- Test 2: UserStats view calculates DaysActive correctly

CREATE PROCEDURE viewtests.[test userstats view calculates daysactive correctly]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Insert test user with known creation date
    DECLARE @testdate DATETIME2 = dateadd(DAY, -100, getutcdate());

    INSERT INTO dbo.users (username, email, createdat)
    VALUES
    ('viewtest_days', 'days@test.com', @testdate);

    -- Act: Get DaysActive from view
    DECLARE @daysactive INT;

    SELECT @daysactive = daysactive
    FROM dbo.userstats
    WHERE username = 'viewtest_days';

    -- Assert: Check days calculation (allow 1 day tolerance)
    IF @daysactive < 99
       OR @daysactive > 101
    BEGIN
        EXEC tsqlt.fail 'UserStats should calculate DaysActive correctly';
    END;
END;

GO

-- Test 3: ProductAnalytics view categorizes stock levels correctly

CREATE PROCEDURE viewtests.[test productanalytics view categorizes stock levels correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test products with different stock levels
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('viewtest_outofstock', 25.00, 0),
    ('viewtest_lowstock', 15.00, 5),
    ('viewtest_mediumstock', 30.00, 25),
    ('viewtest_highstock', 50.00, 100);

    -- Act: Query stock status categorization
    DECLARE @outofstockcount INT, @lowstockcount INT, @mediumstockcount INT, @highstockcount INT;

    SELECT @outofstockcount = COUNT(*)
    FROM dbo.productanalytics
    WHERE productname LIKE 'viewtest%'
          AND stockstatus = 'Out of Stock';

    SELECT @lowstockcount = COUNT(*)
    FROM dbo.productanalytics
    WHERE productname LIKE 'viewtest%'
          AND stockstatus = 'Low Stock';

    SELECT @mediumstockcount = COUNT(*)
    FROM dbo.productanalytics
    WHERE productname LIKE 'viewtest%'
          AND stockstatus = 'Medium Stock';

    SELECT @highstockcount = COUNT(*)
    FROM dbo.productanalytics
    WHERE productname LIKE 'viewtest%'
          AND stockstatus = 'High Stock';

    -- Assert: Check all categorizations
    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @outofstockcount,
                            @message = 'ProductAnalytics should categorize 0 stock as Out of Stock';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @lowstockcount,
                            @message = 'ProductAnalytics should categorize 5 stock as Low Stock';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @mediumstockcount,
                            @message = 'ProductAnalytics should categorize 25 stock as Medium Stock';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @highstockcount,
                            @message = 'ProductAnalytics should categorize 100 stock as High Stock';
END;

GO

-- Test 4: ProductAnalytics view calculates inventory value correctly

CREATE PROCEDURE viewtests.[test productanalytics view calculates inventory value correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known price and stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('viewtest_inventory', 25.50, 4);

    -- Act: Get inventory value from view
    DECLARE @inventoryvalue DECIMAL(10, 2);

    SELECT @inventoryvalue = inventoryvalue
    FROM dbo.productanalytics
    WHERE productname = 'viewtest_inventory';

    -- Assert: Check inventory value calculation (25.50 * 4 = 102.00)
    EXEC tsqlt.assertequals @expected = 102.00,
                            @actual = @inventoryvalue,
                            @message = 'ProductAnalytics should calculate InventoryValue as Price * Stock';
END;

GO

-- Test 5: ProductAnalytics view formats display name correctly

CREATE PROCEDURE viewtests.[test productanalytics view formats display name correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known name and price
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('Test Widget', 19.99, 10);

    -- Act: Get display name from view
    DECLARE @displayname NVARCHAR(150);

    SELECT @displayname = displayname
    FROM dbo.productanalytics
    WHERE productname = 'Test Widget';

    -- Assert: Check display name formatting
    EXEC tsqlt.assertequals @expected = 'Test Widget - $19.99',
                            @actual = @displayname,
                            @message = 'ProductAnalytics should format DisplayName using FormatProductName function';
END;

GO

-- Test 6: UserProductSummary view returns data for all users

CREATE PROCEDURE viewtests.[test userproductsummary view includes all users]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tsqlt.faketable @tablename = 'dbo.Users';
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test users
    INSERT INTO dbo.users (username, email, createdat)
    VALUES
    ('viewtest_user1', 'user1@test.com', dateadd(DAY, -10, getutcdate())),
    ('viewtest_user2', 'user2@test.com', dateadd(DAY, -50, getutcdate())),
    ('viewtest_user3', 'user3@test.com', dateadd(DAY, -400, getutcdate()));

    -- Insert test products
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('Product1', 10.00, 5),
    ('Product2', 20.00, 10);

    -- Act: Query summary view
    DECLARE @summarycount INT;

    SELECT @summarycount = COUNT(*)
    FROM dbo.userproductsummary
    WHERE username LIKE 'viewtest%';

    -- Assert: Should have data for all 3 users
    EXEC tsqlt.assertequals @expected = 3,
                            @actual = @summarycount,
                            @message = 'UserProductSummary should return data for all users';
END;

GO

-- Test 7: UserProductSummary view calculates product metrics correctly

CREATE PROCEDURE viewtests.[test userproductsummary view calculates product metrics correctly]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tsqlt.faketable @tablename = 'dbo.Users';
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test user
    INSERT INTO dbo.users (username, email, createdat)
    VALUES
    ('viewtest_metrics', 'metrics@test.com', dateadd(DAY, -10, getutcdate()));

    -- Insert test products with known values
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('Product1', 10.00, 5), -- InventoryValue = 50.00
    ('Product2', 20.00, 10); -- InventoryValue = 200.00
    -- Total: 2 products, Average price = 15.00, Total inventory = 250.00

    -- Act: Get metrics from view
    DECLARE @productcount INT, @averageprice DECIMAL(10, 2), @totalinventoryvalue DECIMAL(10, 2);

    SELECT @productcount = productcount,
           @averageprice = averageprice,
           @totalinventoryvalue = totalinventoryvalue
    FROM dbo.userproductsummary
    WHERE username = 'viewtest_metrics';

    -- Assert: Check calculations
    EXEC tsqlt.assertequals @expected = 2,
                            @actual = @productcount,
                            @message = 'UserProductSummary should count products correctly';

    EXEC tsqlt.assertequals @expected = 15.00,
                            @actual = @averageprice,
                            @message = 'UserProductSummary should calculate average price correctly';

    EXEC tsqlt.assertequals @expected = 250.00,
                            @actual = @totalinventoryvalue,
                            @message = 'UserProductSummary should calculate total inventory value correctly';
END;

GO

-- Test 8: Complex query using multiple views works correctly

CREATE PROCEDURE viewtests.[test complex query with multiple views works correctly]
AS
BEGIN
    -- Arrange: Create fake Users and Products tables
    EXEC tsqlt.faketable @tablename = 'dbo.Users';
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test users with different categories
    INSERT INTO dbo.users (username, email, createdat)
    VALUES
    ('viewtest_new', 'new@test.com', dateadd(DAY, -5, getutcdate())),
    ('viewtest_regular', 'regular@test.com', dateadd(DAY, -60, getutcdate())),
    ('viewtest_veteran', 'veteran@test.com', dateadd(DAY, -400, getutcdate()));

    -- Insert high-value products
    INSERT INTO dbo.products (productname, price, stock)
    VALUES
    ('High Value Product', 100.00, 50); -- InventoryValue = 5000.00 (> 1000)

    -- Act: Execute complex query joining UserStats with ProductAnalytics
    DECLARE @complexquerycount INT;

    SELECT @complexquerycount = COUNT(*)
    FROM dbo.userstats us
         CROSS JOIN (SELECT COUNT(*) AS highvalueproducts
                     FROM dbo.productanalytics pa
                     WHERE pa.inventoryvalue > 1000) hv
    WHERE us.username LIKE 'viewtest%'
          AND us.usercategory IN ('Regular', 'Veteran');

    -- Assert: Should have 2 users (regular + veteran)
    EXEC tsqlt.assertequals @expected = 2,
                            @actual = @complexquerycount,
                            @message = 'Complex query with multiple views should work correctly';
END;

GO