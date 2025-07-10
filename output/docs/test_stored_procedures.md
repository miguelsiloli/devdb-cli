```markdown
# SQL Schema Documentation: test_stored_procedures.sql

## Overview

This SQL file contains tSQLt unit tests for two stored procedures: `ManageProductInventory` and `CreateUserWithValidation`. These tests ensure that the stored procedures function correctly under various conditions, including valid inputs, error handling, and constraint enforcement. The tests use fake tables to isolate the stored procedures and prevent unintended side effects on the actual database.

## Dependencies

This file depends on:

*   `tSQLt` framework for unit testing.
*   The existence of the `DevDB` database.
*   The existence of the stored procedures `dbo.ManageProductInventory` and `dbo.CreateUserWithValidation`.
*   The existence of the tables `dbo.Products` and `dbo.Users`.

Other files that may depend on this file:

*   None. This is a test file.

## Test Class: StoredProcedureTests

The tests are organized within a tSQLt test class named `StoredProcedureTests`.

```sql
EXEC tSQLt.NewTestClass @ClassName = 'StoredProcedureTests';
GO
```

## Stored Procedure Tests

### 1. `[test ManageProductInventory ADD action increases stock correctly]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's `ADD` action.  Verifies that adding a quantity to the product's stock increases the stock level correctly.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.
2.  Inserts a test product with an initial stock level of 50.
3.  Executes `ManageProductInventory` with the `ADD` action, adding a quantity of 10.
4.  Asserts that the `@NewStock` output parameter is equal to 60.

**SQL:**

```sql
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
```

### 2. `[test ManageProductInventory REMOVE action decreases stock correctly]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's `REMOVE` action.  Verifies that removing a quantity from the product's stock decreases the stock level correctly.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.
2.  Inserts a test product with an initial stock level of 50.
3.  Executes `ManageProductInventory` with the `REMOVE` action, removing a quantity of 20.
4.  Asserts that the `@NewStock` output parameter is equal to 30.

**SQL:**

```sql
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
```

### 3. `[test ManageProductInventory SET action sets stock to exact value]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's `SET` action.  Verifies that setting the stock level to a specific quantity works correctly.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.
2.  Inserts a test product with an initial stock level of 50.
3.  Executes `ManageProductInventory` with the `SET` action, setting the stock level to 100.
4.  Asserts that the `@NewStock` output parameter is equal to 100.

**SQL:**

```sql
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
```

### 4. `[test ManageProductInventory throws error on insufficient stock]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's error handling when attempting to remove more stock than available.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.
2.  Inserts a test product with a low stock level of 10.
3.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50002 and a message containing "Insufficient stock" is raised.
4.  Executes `ManageProductInventory` with the `REMOVE` action, attempting to remove a quantity of 20.

**SQL:**

```sql
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
```

### 5. `[test ManageProductInventory throws error on invalid action]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's error handling when an invalid action is provided.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.
2.  Inserts a test product.
3.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50003 and a message containing "Invalid action" is raised.
4.  Executes `ManageProductInventory` with an invalid action ('INVALID').

**SQL:**

```sql
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
```

### 6. `[test ManageProductInventory throws error when product not found]`

**Purpose:** Tests the `ManageProductInventory` stored procedure's error handling when the specified product ID does not exist.

**Logic:**

1.  Creates a fake `Products` table using `tSQLt.FakeTable`.  The table is empty.
2.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50001 and a message containing "Product with ID" and "not found" is raised.
3.  Executes `ManageProductInventory` with a non-existent product ID (999).

**SQL:**

```sql
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
```

### 7. `[test CreateUserWithValidation creates user successfully]`

**Purpose:** Tests the `CreateUserWithValidation` stored procedure's successful user creation.

**Logic:**

1.  Creates a fake `Users` table using `tSQLt.FakeTable`.
2.  Executes `CreateUserWithValidation` with valid username and email.
3.  Asserts that the `@NewUserID` output parameter is not 0, indicating a successful user creation.
4.  Verifies that a user with the specified username exists in the `Users` table.

**SQL:**

```sql
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
```

### 8. `[test CreateUserWithValidation throws error when username too short]`

**Purpose:** Tests the `CreateUserWithValidation` stored procedure's validation for username length.

**Logic:**

1.  Creates a fake `Users` table using `tSQLt.FakeTable`.
2.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50004 and a message containing "Username must be at least 3 characters" is raised.
3.  Executes `CreateUserWithValidation` with a username that is too short ('ab').

**SQL:**

```sql
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
```

### 9. `[test CreateUserWithValidation throws error on invalid email format]`

**Purpose:** Tests the `CreateUserWithValidation` stored procedure's validation for email format.

**Logic:**

1.  Creates a fake `Users` table using `tSQLt.FakeTable`.
2.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50005 and a message containing "Invalid email format" is raised.
3.  Executes `CreateUserWithValidation` with an invalid email format ('invalidemail').

**SQL:**

```sql
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
```

### 10. `[test CreateUserWithValidation throws error on duplicate username]`

**Purpose:** Tests the `CreateUserWithValidation` stored procedure's handling of duplicate usernames.

**Logic:**

1.  Creates a fake `Users` table using `tSQLt.FakeTable`.
2.  Inserts an existing user into the `Users` table.
3.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50006 and a message containing "Username already exists" is raised.
4.  Executes `CreateUserWithValidation` with a duplicate username ('existing\_user').

**SQL:**

```sql
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
```

### 11. `[test CreateUserWithValidation throws error on duplicate email]`

**Purpose:** Tests the `CreateUserWithValidation` stored procedure's handling of duplicate email addresses.

**Logic:**

1.  Creates a fake `Users` table using `tSQLt.FakeTable`.
2.  Inserts an existing user into the `Users` table.
3.  Uses `tSQLt.ExpectException` to assert that an exception with error number 50007 and a message containing "Email already exists" is raised.
4.  Executes `CreateUserWithValidation` with a duplicate email address ('existing@example.com').

**SQL:**

```sql
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
```
