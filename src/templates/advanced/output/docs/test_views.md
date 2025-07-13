```markdown
# SQL Schema Documentation: test_views.sql

## Overview

This SQL file contains tSQLt tests designed to validate the functionality and correctness of various views within the `DevDB` database. The tests cover aspects such as data categorization, calculation accuracy, data inclusion, and the proper interaction of views in complex queries. The tests utilize fake tables to isolate the view logic and ensure reliable results.

## Dependencies

This file depends on:

*   `DevDB` database existing.
*   `tSQLt` framework being installed.
*   The existence of the tables `dbo.Users` and `dbo.Products` (although these are faked during the tests).
*   The existence of the views `dbo.UserStats`, `dbo.ProductAnalytics`, and `dbo.UserProductSummary` (these are the targets of the tests).

What depends on this file:

*   The stability and reliability of the `dbo.UserStats`, `dbo.ProductAnalytics`, and `dbo.UserProductSummary` views. Any changes to these views should be accompanied by re-running these tests.

## Test Classes

### ViewTests

This test class contains all the tests for the views.

## Stored Procedures (Tests)

### ViewTests.[test UserStats view categorizes users by activity correctly]

**Purpose:**

This test verifies that the `dbo.UserStats` view correctly categorizes users into "New", "Regular", and "Veteran" categories based on their account creation date.

**Business Logic:**

The test creates fake `dbo.Users` data with users created at different times. It then queries the `dbo.UserStats` view and asserts that the number of users in each category matches the expected values.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the actual number of users in each category matches the expected number. If the assertion fails, a message is displayed indicating the specific categorization error.

**Usage Example:**

```sql
EXEC ViewTests.[test UserStats view categorizes users by activity correctly];
```

### ViewTests.[test UserStats view calculates DaysActive correctly]

**Purpose:**

This test validates that the `dbo.UserStats` view accurately calculates the number of days a user has been active (i.e., the difference between the current date and the user's account creation date).

**Business Logic:**

The test creates a fake `dbo.Users` table and inserts a user with a known creation date. It then queries the `dbo.UserStats` view to retrieve the `DaysActive` value for that user and asserts that the calculated value is within a reasonable tolerance (1 day) of the expected value.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test checks if the calculated `DaysActive` value is within the acceptable range (99 to 101 days). If the value falls outside this range, the test fails with a message indicating that the `DaysActive` calculation is incorrect.

**Usage Example:**

```sql
EXEC ViewTests.[test UserStats view calculates DaysActive correctly];
```

### ViewTests.[test ProductAnalytics view categorizes stock levels correctly]

**Purpose:**

This test ensures that the `dbo.ProductAnalytics` view correctly categorizes products into "Out of Stock", "Low Stock", "Medium Stock", and "High Stock" categories based on their stock levels.

**Business Logic:**

The test creates a fake `dbo.Products` table and inserts products with different stock levels. It then queries the `dbo.ProductAnalytics` view and asserts that the number of products in each category matches the expected values.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the actual number of products in each category matches the expected number. If the assertion fails, a message is displayed indicating the specific categorization error.

**Usage Example:**

```sql
EXEC ViewTests.[test ProductAnalytics view categorizes stock levels correctly];
```

### ViewTests.[test ProductAnalytics view calculates inventory value correctly]

**Purpose:**

This test verifies that the `dbo.ProductAnalytics` view accurately calculates the inventory value of a product (i.e., the product of its price and stock level).

**Business Logic:**

The test creates a fake `dbo.Products` table and inserts a product with known price and stock values. It then queries the `dbo.ProductAnalytics` view to retrieve the `InventoryValue` for that product and asserts that the calculated value matches the expected value.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the calculated `InventoryValue` matches the expected value. If the assertion fails, a message is displayed indicating that the `InventoryValue` calculation is incorrect.

**Usage Example:**

```sql
EXEC ViewTests.[test ProductAnalytics view calculates inventory value correctly];
```

### ViewTests.[test ProductAnalytics view formats display name correctly]

**Purpose:**

This test validates that the `dbo.ProductAnalytics` view correctly formats the display name of a product, including the product name and price. It assumes the existence of a function named `FormatProductName` that is used to format the display name.

**Business Logic:**

The test creates a fake `dbo.Products` table and inserts a product with a known name and price. It then queries the `dbo.ProductAnalytics` view to retrieve the `DisplayName` for that product and asserts that the formatted display name matches the expected value.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the formatted `DisplayName` matches the expected value. If the assertion fails, a message is displayed indicating that the display name formatting is incorrect.

**Usage Example:**

```sql
EXEC ViewTests.[test ProductAnalytics view formats display name correctly];
```

### ViewTests.[test UserProductSummary view includes all users]

**Purpose:**

This test ensures that the `dbo.UserProductSummary` view includes data for all users, even if they don't have any associated product information.

**Business Logic:**

The test creates fake `dbo.Users` and `dbo.Products` tables and inserts multiple users and products. It then queries the `dbo.UserProductSummary` view and asserts that the number of rows returned matches the number of users.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the number of rows returned by the `dbo.UserProductSummary` view matches the number of users. If the assertion fails, a message is displayed indicating that the view is not including data for all users.

**Usage Example:**

```sql
EXEC ViewTests.[test UserProductSummary view includes all users];
```

### ViewTests.[test UserProductSummary view calculates product metrics correctly]

**Purpose:**

This test validates that the `dbo.UserProductSummary` view accurately calculates product metrics such as the number of products, average price, and total inventory value.

**Business Logic:**

The test creates fake `dbo.Users` and `dbo.Products` tables and inserts a user and multiple products with known values. It then queries the `dbo.UserProductSummary` view to retrieve the `ProductCount`, `AveragePrice`, and `TotalInventoryValue` for that user and asserts that the calculated values match the expected values.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the calculated `ProductCount`, `AveragePrice`, and `TotalInventoryValue` match the expected values. If the assertion fails, a message is displayed indicating the specific calculation error.

**Usage Example:**

```sql
EXEC ViewTests.[test UserProductSummary view calculates product metrics correctly];
```

### ViewTests.[test complex query with multiple views works correctly]

**Purpose:**

This test verifies that a complex query that joins multiple views (`dbo.UserStats` and `dbo.ProductAnalytics`) works correctly and returns the expected results.

**Business Logic:**

The test creates fake `dbo.Users` and `dbo.Products` tables and inserts users with different categories and a high-value product. It then executes a complex query that joins `dbo.UserStats` with a subquery on `dbo.ProductAnalytics` to count the number of high-value products. The query filters users based on their category and asserts that the number of rows returned matches the expected value.

**Input/Output Parameters:**

This stored procedure does not have any input or output parameters.

**Error Handling:**

The test uses `tSQLt.AssertEquals` to check if the number of rows returned by the complex query matches the expected value. If the assertion fails, a message is displayed indicating that the query is not working correctly.

**Usage Example:**

```sql
EXEC ViewTests.[test complex query with multiple views works correctly];
```
```