-- tSQLt Tests for Stored Procedures
USE DevDB;
GO

-- Create Test Class for Stored Procedures
EXEC tSQLt.NewTestClass @ClassName = 'StoredProcedureTests';
GO

-- Test 1: ManageProductInventory ADD action
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory ADD action increases stock correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('SP Test Product', 19.99, 50);
    DECLARE @ProductID INT = SCOPE_IDENTITY();
    
    -- Act: Execute the ADD action
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = @ProductID, @Action = 'ADD', @Quantity = 10, @NewStock = @NewStock OUTPUT;
    
    -- Assert: Check the new stock value
    EXEC tSQLt.AssertEquals @Expected = 60, @Actual = @NewStock, 
         @Message = 'ManageProductInventory ADD action should increase stock by quantity';
END;
GO

-- Test 2: ManageProductInventory REMOVE action
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory REMOVE action decreases stock correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('SP Test Product', 19.99, 50);
    DECLARE @ProductID INT = SCOPE_IDENTITY();
    
    -- Act: Execute the REMOVE action
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = @ProductID, @Action = 'REMOVE', @Quantity = 20, @NewStock = @NewStock OUTPUT;
    
    -- Assert: Check the new stock value
    EXEC tSQLt.AssertEquals @Expected = 30, @Actual = @NewStock, 
         @Message = 'ManageProductInventory REMOVE action should decrease stock by quantity';
END;
GO

-- Test 3: ManageProductInventory SET action
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory SET action sets stock to exact value]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with known stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('SP Test Product', 19.99, 50);
    DECLARE @ProductID INT = SCOPE_IDENTITY();
    
    -- Act: Execute the SET action
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = @ProductID, @Action = 'SET', @Quantity = 100, @NewStock = @NewStock OUTPUT;
    
    -- Assert: Check the new stock value
    EXEC tSQLt.AssertEquals @Expected = 100, @Actual = @NewStock, 
         @Message = 'ManageProductInventory SET action should set stock to exact quantity';
END;
GO

-- Test 4: ManageProductInventory insufficient stock error
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory throws error on insufficient stock]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product with low stock
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('SP Test Product', 19.99, 10);
    DECLARE @ProductID INT = SCOPE_IDENTITY();
    
    -- Act & Assert: Expect error when trying to remove more stock than available
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50002, 
         @ExpectedMessagePattern = '%Insufficient stock%';
    
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = @ProductID, @Action = 'REMOVE', @Quantity = 20, @NewStock = @NewStock OUTPUT;
END;
GO

-- Test 5: ManageProductInventory invalid action error
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory throws error on invalid action]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Insert test product
    INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('SP Test Product', 19.99, 50);
    DECLARE @ProductID INT = SCOPE_IDENTITY();
    
    -- Act & Assert: Expect error when using invalid action
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50003, 
         @ExpectedMessagePattern = '%Invalid action%';
    
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = @ProductID, @Action = 'INVALID', @Quantity = 10, @NewStock = @NewStock OUTPUT;
END;
GO

-- Test 6: ManageProductInventory product not found error
CREATE PROCEDURE StoredProcedureTests.[test ManageProductInventory throws error when product not found]
AS
BEGIN
    -- Arrange: Create fake Products table (empty)
    EXEC tSQLt.FakeTable @TableName = 'dbo.Products';
    
    -- Act & Assert: Expect error when product doesn't exist
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001, 
         @ExpectedMessagePattern = '%Product with ID%not found%';
    
    DECLARE @NewStock INT;
    EXEC dbo.ManageProductInventory @ProductID = 999, @Action = 'ADD', @Quantity = 10, @NewStock = @NewStock OUTPUT;
END;
GO

-- Test 7: CreateUserWithValidation successful creation
CREATE PROCEDURE StoredProcedureTests.[test CreateUserWithValidation creates user successfully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Execute the procedure
    DECLARE @NewUserID INT;
    EXEC dbo.CreateUserWithValidation @Username = 'sptest_user', @Email = 'sptest@example.com', @NewUserID = @NewUserID OUTPUT;
    
    -- Assert: Check that user was created and ID was returned
    EXEC tSQLt.AssertNotEquals @Expected = 0, @Actual = @NewUserID, 
         @Message = 'CreateUserWithValidation should return a valid user ID';
    
    -- Verify user exists in table
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username = 'sptest_user';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @UserCount, 
         @Message = 'CreateUserWithValidation should insert exactly one user';
END;
GO

-- Test 8: CreateUserWithValidation username too short
CREATE PROCEDURE StoredProcedureTests.[test CreateUserWithValidation throws error when username too short]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act & Assert: Expect error for username too short
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50004, 
         @ExpectedMessagePattern = '%Username must be at least 3 characters%';
    
    DECLARE @NewUserID INT;
    EXEC dbo.CreateUserWithValidation @Username = 'ab', @Email = 'short@example.com', @NewUserID = @NewUserID OUTPUT;
END;
GO

-- Test 9: CreateUserWithValidation invalid email format
CREATE PROCEDURE StoredProcedureTests.[test CreateUserWithValidation throws error on invalid email format]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act & Assert: Expect error for invalid email format
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50005, 
         @ExpectedMessagePattern = '%Invalid email format%';
    
    DECLARE @NewUserID INT;
    EXEC dbo.CreateUserWithValidation @Username = 'test_invalid_email', @Email = 'invalidemail', @NewUserID = @NewUserID OUTPUT;
END;
GO

-- Test 10: CreateUserWithValidation duplicate username
CREATE PROCEDURE StoredProcedureTests.[test CreateUserWithValidation throws error on duplicate username]
AS
BEGIN
    -- Arrange: Create fake Users table with existing user
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    INSERT INTO dbo.Users (Username, Email) VALUES ('existing_user', 'existing@example.com');
    
    -- Act & Assert: Expect error for duplicate username
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50006, 
         @ExpectedMessagePattern = '%Username already exists%';
    
    DECLARE @NewUserID INT;
    EXEC dbo.CreateUserWithValidation @Username = 'existing_user', @Email = 'different@example.com', @NewUserID = @NewUserID OUTPUT;
END;
GO

-- Test 11: CreateUserWithValidation duplicate email
CREATE PROCEDURE StoredProcedureTests.[test CreateUserWithValidation throws error on duplicate email]
AS
BEGIN
    -- Arrange: Create fake Users table with existing user
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    INSERT INTO dbo.Users (Username, Email) VALUES ('existing_user', 'existing@example.com');
    
    -- Act & Assert: Expect error for duplicate email
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50007, 
         @ExpectedMessagePattern = '%Email already exists%';
    
    DECLARE @NewUserID INT;
    EXEC dbo.CreateUserWithValidation @Username = 'different_user', @Email = 'existing@example.com', @NewUserID = @NewUserID OUTPUT;
END;
GO