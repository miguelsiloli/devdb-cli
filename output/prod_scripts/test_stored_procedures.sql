-- =====================================================
-- File: tSQLt_StoredProcedureTests.sql
-- Description: tSQLt tests for stored procedures ManageProductInventory and CreateUserWithValidation
-- Author: miguel.b.silva@***.com
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
USE devdb;

GO

-- Create Test Class for Stored Procedures
EXEC tsqlt.newtestclass @classname = 'StoredProcedureTests';

GO

-- Test 1: ManageProductInventory ADD action

CREATE PROCEDURE storedproceduretests.[test manageproductinventory add action increases stock correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('SP Test Product', 19.99, 50);

    DECLARE @productid INT = scope_identity();

    -- Act: Execute the ADD action
    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = @productid,
                                    @action = 'ADD',
                                    @quantity = 10,
                                    @newstock = @newstock OUTPUT;

    -- Assert: Check the new stock value
    EXEC tsqlt.assertequals @expected = 60,
                            @actual = @newstock,
                            @message = 'ManageProductInventory ADD action should increase stock by quantity';
END;

GO

-- Test 2: ManageProductInventory REMOVE action

CREATE PROCEDURE storedproceduretests.[test manageproductinventory remove action decreases stock correctly]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('SP Test Product', 19.99, 50);

    DECLARE @productid INT = scope_identity();

    -- Act: Execute the REMOVE action
    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = @productid,
                                    @action = 'REMOVE',
                                    @quantity = 20,
                                    @newstock = @newstock OUTPUT;

    -- Assert: Check the new stock value
    EXEC tsqlt.assertequals @expected = 30,
                            @actual = @newstock,
                            @message = 'ManageProductInventory REMOVE action should decrease stock by quantity';
END;

GO

-- Test 3: ManageProductInventory SET action

CREATE PROCEDURE storedproceduretests.[test manageproductinventory set action sets stock to exact value]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with known stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('SP Test Product', 19.99, 50);

    DECLARE @productid INT = scope_identity();

    -- Act: Execute the SET action
    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = @productid,
                                    @action = 'SET',
                                    @quantity = 100,
                                    @newstock = @newstock OUTPUT;

    -- Assert: Check the new stock value
    EXEC tsqlt.assertequals @expected = 100,
                            @actual = @newstock,
                            @message = 'ManageProductInventory SET action should set stock to exact quantity';
END;

GO

-- Test 4: ManageProductInventory insufficient stock error

CREATE PROCEDURE storedproceduretests.[test manageproductinventory throws error on insufficient stock]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product with low stock
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('SP Test Product', 19.99, 10);

    DECLARE @productid INT = scope_identity();

    -- Act & Assert: Expect error when trying to remove more stock than available
    EXEC tsqlt.expectexception @expectederrornumber = 50002,
                            @expectedmessagepattern = '%Insufficient stock%';

    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = @productid,
                                    @action = 'REMOVE',
                                    @quantity = 20,
                                    @newstock = @newstock OUTPUT;
END;

GO

-- Test 5: ManageProductInventory invalid action error

CREATE PROCEDURE storedproceduretests.[test manageproductinventory throws error on invalid action]
AS
BEGIN
    -- Arrange: Create fake Products table
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Insert test product
    INSERT INTO dbo.products (productname, price, stock)
    VALUES ('SP Test Product', 19.99, 50);

    DECLARE @productid INT = scope_identity();

    -- Act & Assert: Expect error when using invalid action
    EXEC tsqlt.expectexception @expectederrornumber = 50003,
                            @expectedmessagepattern = '%Invalid action%';

    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = @productid,
                                    @action = 'INVALID',
                                    @quantity = 10,
                                    @newstock = @newstock OUTPUT;
END;

GO

-- Test 6: ManageProductInventory product not found error

CREATE PROCEDURE storedproceduretests.[test manageproductinventory throws error when product not found]
AS
BEGIN
    -- Arrange: Create fake Products table (empty)
    EXEC tsqlt.faketable @tablename = 'dbo.Products';

    -- Act & Assert: Expect error when product doesn't exist
    EXEC tsqlt.expectexception @expectederrornumber = 50001,
                            @expectedmessagepattern = '%Product with ID%not found%';

    DECLARE @newstock INT;
    EXEC dbo.manageproductinventory @productid = 999,
                                    @action = 'ADD',
                                    @quantity = 10,
                                    @newstock = @newstock OUTPUT;
END;

GO

-- Test 7: CreateUserWithValidation successful creation

CREATE PROCEDURE storedproceduretests.[test createuserwithvalidation creates user successfully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Execute the procedure
    DECLARE @newuserid INT;
    EXEC dbo.createuserwithvalidation @username = 'sptest_user',
                                    @email = 'sptest@example.com',
                                    @newuserid = @newuserid OUTPUT;

    -- Assert: Check that user was created and ID was returned
    EXEC tsqlt.assertnotequals @expected = 0,
                            @actual = @newuserid,
                            @message = 'CreateUserWithValidation should return a valid user ID';

    -- Verify user exists in table
    DECLARE @usercount INT;
    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username = 'sptest_user';

    EXEC tsqlt.assertequals @expected = 1,
                            @actual = @usercount,
                            @message = 'CreateUserWithValidation should insert exactly one user';
END;

GO

-- Test 8: CreateUserWithValidation username too short

CREATE PROCEDURE storedproceduretests.[test createuserwithvalidation throws error when username too short]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act & Assert: Expect error for username too short
    EXEC tsqlt.expectexception @expectederrornumber = 50004,
                            @expectedmessagepattern = '%Username must be at least 3 characters%';

    DECLARE @newuserid INT;
    EXEC dbo.createuserwithvalidation @username = 'ab',
                                    @email = 'short@example.com',
                                    @newuserid = @newuserid OUTPUT;
END;

GO

-- Test 9: CreateUserWithValidation invalid email format

CREATE PROCEDURE storedproceduretests.[test createuserwithvalidation throws error on invalid email format]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act & Assert: Expect error for invalid email format
    EXEC tsqlt.expectexception @expectederrornumber = 50005,
                            @expectedmessagepattern = '%Invalid email format%';

    DECLARE @newuserid INT;
    EXEC dbo.createuserwithvalidation @username = 'test_invalid_email',
                                    @email = 'invalidemail',
                                    @newuserid = @newuserid OUTPUT;
END;

GO

-- Test 10: CreateUserWithValidation duplicate username

CREATE PROCEDURE storedproceduretests.[test createuserwithvalidation throws error on duplicate username]
AS
BEGIN
    -- Arrange: Create fake Users table with existing user
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    INSERT INTO dbo.users (username, email)
    VALUES ('existing_user', 'existing@example.com');

    -- Act & Assert: Expect error for duplicate username
    EXEC tsqlt.expectexception @expectederrornumber = 50006,
                            @expectedmessagepattern = '%Username already exists%';

    DECLARE @newuserid INT;
    EXEC dbo.createuserwithvalidation @username = 'existing_user',
                                    @email = 'different@example.com',
                                    @newuserid = @newuserid OUTPUT;
END;

GO

-- Test 11: CreateUserWithValidation duplicate email

CREATE PROCEDURE storedproceduretests.[test createuserwithvalidation throws error on duplicate email]
AS
BEGIN
    -- Arrange: Create fake Users table with existing user
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    INSERT INTO dbo.users (username, email)
    VALUES ('existing_user', 'existing@example.com');

    -- Act & Assert: Expect error for duplicate email
    EXEC tsqlt.expectexception @expectederrornumber = 50007,
                            @expectedmessagepattern = '%Email already exists%';

    DECLARE @newuserid INT;
    EXEC dbo.createuserwithvalidation @username = 'different_user',
                                    @email = 'existing@example.com',
                                    @newuserid = @newuserid OUTPUT;
END;

GO