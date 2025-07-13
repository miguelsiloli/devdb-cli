```markdown
# SQL Schema Documentation: test_functions.sql

## Overview

This SQL file contains tSQLt tests for user-defined functions in the `DevDB` database. It includes tests for scalar functions (`CalculateUserAge`, `FormatProductName`) and a table-valued function (`GetActiveProducts`). The tests verify the functions' logic and output.

## Dependencies

-   Database: `DevDB`
-   tSQLt framework

## Tables

This file uses `tSQLt.FakeTable` to create isolated test environments. The following tables are faked during the tests:

### `dbo.Users`

**Purpose:** Represents user data, used for testing the `CalculateUserAge` function.

**Business Logic:** Stores user information, including the creation date, which is used to calculate the user's age in days.

**Columns:**

| Column    | Data Type   | Description                               |
| --------- | ----------- | ----------------------------------------- |
| Username  | VARCHAR(255) | User's username                           |
| Email     | VARCHAR(255) | User's email address                      |
| CreatedAt | DATETIME2   | Timestamp when the user account was created |

**Primary Key:** None (faked table)

**Foreign Keys:** None (faked table)

**Constraints:** None (faked table)

**Indexes:** None (faked table)

### `dbo.Products`

**Purpose:** Represents product data, used for testing the `GetActiveProducts` function.

**Business Logic:** Stores product information, including price and stock levels, which are used to determine active products and calculate their total value.

**Columns:**

| Column      | Data Type     | Description                               |
| ----------- | ------------- | ----------------------------------------- |
| ProductName | VARCHAR(255)  | Name of the product                       |
| Price       | DECIMAL(10,2) | Price of the product                      |
| Stock       | INT           | Current stock level of the product        |

**Primary Key:** None (faked table)

**Foreign Keys:** None (faked table)

**Constraints:** None (faked table)

**Indexes:** None (faked table)

## Stored Procedures (Tests)

This file contains several stored procedures that serve as tSQLt tests. Each procedure tests a specific aspect of a user-defined function.

### `FunctionTests.[test CalculateUserAge returns correct days difference]`

**Purpose:** Tests the `CalculateUserAge` function to ensure it returns the correct age in days based on the user's creation date.

**Business Logic:**
1.  Creates a fake `Users` table.
2.  Inserts a test user with a known creation date.
3.  Calls the `CalculateUserAge` function to calculate the user's age.
4.  Asserts that the calculated age is within an acceptable range (allowing for a 1-day tolerance due to timing).

**Input/Output Parameters:** None

**Error Handling:** Uses `tSQLt.Fail` to report test failures.

**Usage Example:**

```sql
EXEC FunctionTests.[test CalculateUserAge returns correct days difference];
```

### `FunctionTests.[test FormatProductName formats correctly]`

**Purpose:** Tests the `FormatProductName` function to ensure it correctly formats a product name with its price.

**Business Logic:**
1.  Sets up test data, including a product name and price.
2.  Calls the `FormatProductName` function to format the product name.
3.  Asserts that the formatted product name matches the expected format.

**Input/Output Parameters:** None

**Error Handling:** Uses `tSQLt.AssertEquals` to compare the actual and expected results and `tSQLt.Fail` (implicitly through `AssertEquals`) to report test failures.

**Usage Example:**

```sql
EXEC FunctionTests.[test FormatProductName formats correctly];
```

### `FunctionTests.[test GetActiveProducts returns products with stock greater than minimum]`

**Purpose:** Tests the `GetActiveProducts` table-valued function to ensure it returns products with stock levels greater than the specified minimum.

**Business Logic:**
1.  Creates a fake `Products` table.
2.  Inserts test products with different stock levels.
3.  Calls the `GetActiveProducts` function with a minimum stock level of 0.
4.  Asserts that the function returns the correct number of active products (products with stock > 0).

**Input/Output Parameters:** None

**Error Handling:** Uses `tSQLt.AssertEquals` to compare the actual and expected results and `tSQLt.Fail` (implicitly through `AssertEquals`) to report test failures.

**Usage Example:**

```sql
EXEC FunctionTests.[test GetActiveProducts returns products with stock greater than minimum];
```

### `FunctionTests.[test GetActiveProducts respects minimum stock parameter]`

**Purpose:** Tests the `GetActiveProducts` table-valued function to ensure it correctly respects the minimum stock parameter.

**Business Logic:**
1.  Creates a fake `Products` table.
2.  Inserts test products with different stock levels.
3.  Calls the `GetActiveProducts` function with a minimum stock level of 10.
4.  Asserts that the function returns the correct number of active products (products with stock > 10).

**Input/Output Parameters:** None

**Error Handling:** Uses `tSQLt.AssertEquals` to compare the actual and expected results and `tSQLt.Fail` (implicitly through `AssertEquals`) to report test failures.

**Usage Example:**

```sql
EXEC FunctionTests.[test GetActiveProducts respects minimum stock parameter];
```

### `FunctionTests.[test GetActiveProducts calculates total value correctly]`

**Purpose:** Tests the `GetActiveProducts` table-valued function to ensure it correctly calculates the total value of active products (Price \* Stock).

**Business Logic:**
1.  Creates a fake `Products` table.
2.  Inserts a test product with a known price and stock level.
3.  Calls the `GetActiveProducts` function with a minimum stock level of 0.
4.  Asserts that the function returns the correct total value for the product.

**Input/Output Parameters:** None

**Error Handling:** Uses `tSQLt.AssertEquals` to compare the actual and expected results and `tSQLt.Fail` (implicitly through `AssertEquals`) to report test failures.

**Usage Example:**

```sql
EXEC FunctionTests.[test GetActiveProducts calculates total value correctly];
```
```