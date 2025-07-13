-- schemas/04_advanced_views.sql
-- This script creates advanced views and indexed views.

USE DevDB;
GO

-- View with user statistics
PRINT 'Creating view: UserStats';
GO
CREATE VIEW dbo.UserStats AS
SELECT 
    u.UserID,
    u.Username,
    u.Email,
    u.CreatedAt,
    dbo.CalculateUserAge(u.CreatedAt) AS DaysActive,
    CASE 
        WHEN dbo.CalculateUserAge(u.CreatedAt) > 365 THEN 'Veteran'
        WHEN dbo.CalculateUserAge(u.CreatedAt) > 30 THEN 'Regular'
        ELSE 'New'
    END AS UserCategory
FROM dbo.Users u;
GO

-- View with product analytics
PRINT 'Creating view: ProductAnalytics';
GO
CREATE VIEW dbo.ProductAnalytics AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Stock,
    p.Price * p.Stock AS InventoryValue,
    dbo.FormatProductName(p.ProductName, p.Price) AS DisplayName,
    CASE 
        WHEN p.Stock = 0 THEN 'Out of Stock'
        WHEN p.Stock <= 10 THEN 'Low Stock'
        WHEN p.Stock <= 50 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS StockStatus
FROM dbo.Products p;
GO

-- View combining user and product data (for future order system)
PRINT 'Creating view: UserProductSummary';
GO
CREATE VIEW dbo.UserProductSummary AS
SELECT 
    u.UserID,
    u.Username,
    u.UserCategory,
    p.ProductCount,
    p.AveragePrice,
    p.TotalInventoryValue
FROM dbo.UserStats u
CROSS JOIN (
    SELECT 
        COUNT(*) AS ProductCount,
        AVG(Price) AS AveragePrice,
        SUM(Price * Stock) AS TotalInventoryValue
    FROM dbo.Products
) p;
GO