-- schemas/05_stored_procedures.sql
-- This script creates advanced stored procedures.

USE DevDB;
GO

-- Stored procedure to manage product inventory
PRINT 'Creating stored procedure: ManageProductInventory';
GO
CREATE PROCEDURE dbo.ManageProductInventory
    @ProductID INT,
    @Action NVARCHAR(10), -- 'ADD', 'REMOVE', 'SET'
    @Quantity INT,
    @NewStock INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentStock INT;
    DECLARE @ErrorMessage NVARCHAR(255);
    
    -- Get current stock
    SELECT @CurrentStock = Stock 
    FROM dbo.Products 
    WHERE ProductID = @ProductID;
    
    -- Check if product exists
    IF @CurrentStock IS NULL
    BEGIN
        SET @ErrorMessage = 'Product with ID ' + CAST(@ProductID AS NVARCHAR(10)) + ' not found';
        THROW 50001, @ErrorMessage, 1;
    END;
    
    -- Perform the action
    IF @Action = 'ADD'
        SET @NewStock = @CurrentStock + @Quantity;
    ELSE IF @Action = 'REMOVE'
    BEGIN
        SET @NewStock = @CurrentStock - @Quantity;
        IF @NewStock < 0
        BEGIN
            SET @ErrorMessage = 'Insufficient stock. Current: ' + CAST(@CurrentStock AS NVARCHAR(10)) + ', Requested: ' + CAST(@Quantity AS NVARCHAR(10));
            THROW 50002, @ErrorMessage, 1;
        END;
    END
    ELSE IF @Action = 'SET'
        SET @NewStock = @Quantity;
    ELSE
    BEGIN
        SET @ErrorMessage = 'Invalid action. Use ADD, REMOVE, or SET';
        THROW 50003, @ErrorMessage, 1;
    END;
    
    -- Update the stock
    UPDATE dbo.Products 
    SET Stock = @NewStock 
    WHERE ProductID = @ProductID;
    
    -- Return success message
    PRINT 'Inventory updated successfully. New stock: ' + CAST(@NewStock AS NVARCHAR(10));
END;
GO

-- Stored procedure to get product report
PRINT 'Creating stored procedure: GetProductReport';
GO
CREATE PROCEDURE dbo.GetProductReport
    @MinPrice DECIMAL(10,2) = 0,
    @MaxPrice DECIMAL(10,2) = 999999,
    @StockStatus NVARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        pa.ProductID,
        pa.ProductName,
        pa.Price,
        pa.Stock,
        pa.InventoryValue,
        pa.DisplayName,
        pa.StockStatus
    FROM dbo.ProductAnalytics pa
    WHERE pa.Price BETWEEN @MinPrice AND @MaxPrice
    AND (@StockStatus = 'ALL' OR pa.StockStatus = @StockStatus)
    ORDER BY pa.InventoryValue DESC;
END;
GO

-- Stored procedure to create user with validation
PRINT 'Creating stored procedure: CreateUserWithValidation';
GO
CREATE PROCEDURE dbo.CreateUserWithValidation
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @NewUserID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate username
    IF LEN(@Username) < 3
    BEGIN
        THROW 50004, 'Username must be at least 3 characters long', 1;
    END;
    
    -- Validate email format (basic check)
    IF @Email NOT LIKE '%@%.%'
    BEGIN
        THROW 50005, 'Invalid email format', 1;
    END;
    
    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username)
    BEGIN
        THROW 50006, 'Username already exists', 1;
    END;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
    BEGIN
        THROW 50007, 'Email already exists', 1;
    END;
    
    -- Insert the new user
    INSERT INTO dbo.Users (Username, Email)
    VALUES (@Username, @Email);
    
    -- Get the new user ID
    SET @NewUserID = SCOPE_IDENTITY();
    
    -- Return success message
    PRINT 'User created successfully with ID: ' + CAST(@NewUserID AS NVARCHAR(10));
END;
GO

-- Stored procedure to get user analytics
PRINT 'Creating stored procedure: GetUserAnalytics';
GO
CREATE PROCEDURE dbo.GetUserAnalytics
    @UserCategory NVARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        us.UserID,
        us.Username,
        us.Email,
        us.CreatedAt,
        us.DaysActive,
        us.UserCategory
    FROM dbo.UserStats us
    WHERE (@UserCategory = 'ALL' OR us.UserCategory = @UserCategory)
    ORDER BY us.DaysActive DESC;
END;
GO