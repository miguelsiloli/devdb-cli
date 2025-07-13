```markdown
# SQL Schema Documentation: test_product_stock_fail.sql

## Overview

This SQL file contains a suite of tSQLt tests designed to intentionally fail. These tests are used to demonstrate and validate tSQLt's error handling and assertion capabilities. The tests cover various failure scenarios, including assertion failures, exception expectation failures, string comparison failures, range assertion failures, table content failures, and null assertion failures. All tests are part of the `IntentionalFailureTests` test class.

## Dependencies

-   This file depends on the `tSQLt` framework being installed in the `DevDB` database.
-   It also depends on the `DevDB` database existing.

## Tables

This file uses fake tables created by `tSQLt.FakeTable`.  The primary table used is `dbo.Products`.

### dbo.Products (Fake Table)

**Purpose and Business Logic:**

This table is a fake table created within the scope of the tSQLt tests. It simulates a real `Products` table for testing purposes. It stores information about products, including their name, price, and stock level.

**Column Descriptions:**

| Column Name    | Data Type       | Description                               |
| -------------- | --------------- | ----------------------------------------- |
| ProductName    | NVARCHAR(100)   | The name of the product.                  |
| Price          | DECIMAL(10, 2)  | The price of the product.                 |
| Stock          | INT             | The current stock level of the product.   |

**Primary Keys, Foreign Keys, and Constraints:**

-   This is a fake table, so no explicit primary keys or constraints are defined in this script. However, the tests implicitly rely on the existence of these columns.

**Indexes:**

-   No indexes are explicitly created in this script, as it's a fake table.

## Stored Procedures

This file defines several stored procedures, each representing a test case within the `IntentionalFailureTests` test class.

### IntentionalFailureTests.[test product stock assertion fails intentionally]

**Purpose and Business Logic:**

This test case intentionally fails an assertion to demonstrate tSQLt's failure handling. It creates a fake `Products` table, inserts a product with a known stock level, and then asserts that the stock level is a different value.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on tSQLt's assertion mechanism (`tSQLt.AssertEquals`) to detect and report the failure.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test product stock assertion fails intentionally];
```

**Code:**

```sql
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
```

### IntentionalFailureTests.[test exception expectation fails when no exception thrown]

**Purpose and Business Logic:**

This test case intentionally fails by expecting an exception that is never thrown. It uses `tSQLt.ExpectException` to specify an expected exception message pattern, but the subsequent code does not raise any exceptions.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on `tSQLt.ExpectException` to detect the absence of the expected exception and report the failure.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test exception expectation fails when no exception thrown];
```

**Code:**

```sql
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
```

### IntentionalFailureTests.[test string comparison fails intentionally]

**Purpose and Business Logic:**

This test case intentionally fails a string comparison assertion. It sets up two different string values and then uses `tSQLt.AssertEquals` to compare them, resulting in a failure.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on `tSQLt.AssertEquals` to detect the string comparison failure and report it.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test string comparison fails intentionally];
```

**Code:**

```sql
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
```

### IntentionalFailureTests.[test range assertion fails intentionally]

**Purpose and Business Logic:**

This test case intentionally fails a range assertion. It sets up a value and then uses a conditional statement to check if the value falls within a specific range. Since the value is outside the range, the `tSQLt.Fail` procedure is called to report the failure.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on a conditional statement and `tSQLt.Fail` to detect and report the range assertion failure.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test range assertion fails intentionally];
```

**Code:**

```sql
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
```

### IntentionalFailureTests.[test table content assertion fails intentionally]

**Purpose and Business Logic:**

This test case intentionally fails a table content assertion. It creates a fake `Products` table, inserts some data, and then creates a temporary table (`#ExpectedProducts`) with different data. Finally, it uses `tSQLt.AssertEqualsTable` to compare the two tables, resulting in a failure due to the differences in their contents.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on `tSQLt.AssertEqualsTable` to detect the differences in table contents and report the failure.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test table content assertion fails intentionally];
```

**Code:**

```sql
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
```

### IntentionalFailureTests.[test null assertion fails intentionally]

**Purpose and Business Logic:**

This test case intentionally fails a null assertion. It sets up a non-null value and then uses `tSQLt.AssertEquals` to assert that the value is null, resulting in a failure.

**Input/Output Parameters:**

This procedure does not have any input or output parameters.

**Error Handling Approach:**

The test relies on `tSQLt.AssertEquals` to detect the null assertion failure and report it.

**Usage Example:**

```sql
EXEC IntentionalFailureTests.[test null assertion fails intentionally];
```

**Code:**

```sql
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
```
