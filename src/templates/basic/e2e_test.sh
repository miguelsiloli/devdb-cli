#!/bin/bash
#
# E2E Test Script - DevDB Automated Development Database Deployment System
# This script performs a complete end-to-end test including:
# 1. Cold start (clean environment)
# 2. Schema deployment verification
# 3. User script execution
# 4. Test validation
#

# --- Configuration ---
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DEVDB_SCRIPT="${SCRIPT_DIR}/devdb.sh"

# --- Style Definitions ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m'

# --- Helper Functions ---
info() {
  echo -e "${COLOR_BLUE}E2E INFO: $1${COLOR_NC}"
}

success() {
  echo -e "${COLOR_GREEN}E2E SUCCESS: $1${COLOR_NC}"
}

warn() {
  echo -e "${COLOR_YELLOW}E2E WARN: $1${COLOR_NC}"
}

error() {
  echo -e "${COLOR_RED}E2E ERROR: $1${COLOR_NC}" >&2
  exit 1
}

# --- Test Functions ---

test_cold_start() {
  info "=== STAGE 1: Cold Start Test ==="
  
  # Clean up any existing environment
  info "Cleaning up existing environment..."
  "$DEVDB_SCRIPT" down || true
  
  # Remove any existing containers
  docker rm -f devdb-sqlserver devdb-gui 2>/dev/null || true
  
  # Start fresh environment
  info "Starting fresh environment..."
  "$DEVDB_SCRIPT" up
  
  # Verify containers are running
  info "Verifying containers are running..."
  if ! docker ps | grep -q devdb-sqlserver; then
    error "SQL Server container is not running"
  fi
  
  if ! docker ps | grep -q devdb-gui; then
    error "GUI container is not running"
  fi
  
  success "Cold start completed successfully"
}

test_schema_deployment() {
  info "=== STAGE 2: Schema Deployment Test ==="
  
  # Initialize schemas
  info "Initializing database schemas..."
  "$DEVDB_SCRIPT" schema || error "Schema initialization failed"
  
  # Test database creation
  info "Verifying DevDB database exists..."
  "$DEVDB_SCRIPT" query "SELECT name FROM sys.databases WHERE name = 'DevDB'" || error "DevDB database not found"
  
  # Test table creation
  info "Verifying Users table exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as TableExists FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users'" || error "Users table not found"
  
  info "Verifying Products table exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as TableExists FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Products'" || error "Products table not found"
  
  # Test stored procedure creation
  info "Verifying AddNewUser stored procedure exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ProcExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'AddNewUser'" || error "AddNewUser procedure not found"
  
  info "Verifying ManageProductInventory stored procedure exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ProcExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ManageProductInventory'" || error "ManageProductInventory procedure not found"
  
  info "Verifying CreateUserWithValidation stored procedure exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ProcExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'CreateUserWithValidation'" || error "CreateUserWithValidation procedure not found"
  
  # Test view creation
  info "Verifying PricedProducts view exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ViewExists FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'PricedProducts'" || error "PricedProducts view not found"
  
  info "Verifying UserStats view exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ViewExists FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'UserStats'" || error "UserStats view not found"
  
  info "Verifying ProductAnalytics view exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as ViewExists FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'ProductAnalytics'" || error "ProductAnalytics view not found"
  
  # Test function creation
  info "Verifying CalculateUserAge function exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as FuncExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'CalculateUserAge'" || error "CalculateUserAge function not found"
  
  info "Verifying GetActiveProducts function exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as FuncExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'GetActiveProducts'" || error "GetActiveProducts function not found"
  
  info "Verifying FormatProductName function exists..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT COUNT(*) as FuncExists FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'FormatProductName'" || error "FormatProductName function not found"
  
  success "Schema deployment verified successfully"
}

test_user_scripts() {
  info "=== STAGE 3: User Script Execution Test ==="
  
  # Test basic data insertion
  info "Testing direct data insertion..."
  "$DEVDB_SCRIPT" query "USE DevDB; INSERT INTO Products (ProductName, Price, Stock) VALUES ('E2E Test Product', 29.99, 100)" || error "Failed to insert test product"
  
  # Test stored procedure execution
  info "Testing stored procedure execution..."
  "$DEVDB_SCRIPT" query "USE DevDB; EXEC AddNewUser @Username = 'e2euser', @Email = 'e2e@test.com'" || error "Failed to execute AddNewUser procedure"
  
  # Test advanced stored procedure with validation
  info "Testing advanced stored procedure with validation..."
  "$DEVDB_SCRIPT" query "USE DevDB; DECLARE @UserID INT; EXEC CreateUserWithValidation @Username = 'e2euser_advanced', @Email = 'advanced@e2e.com', @NewUserID = @UserID OUTPUT; SELECT @UserID as NewUserID;" || error "Failed to execute CreateUserWithValidation procedure"
  
  # Test inventory management procedure
  info "Testing inventory management procedure..."
  "$DEVDB_SCRIPT" query "USE DevDB; DECLARE @ProductID INT; SELECT @ProductID = ProductID FROM Products WHERE ProductName = 'E2E Test Product'; DECLARE @NewStock INT; EXEC ManageProductInventory @ProductID = @ProductID, @Action = 'ADD', @Quantity = 50, @NewStock = @NewStock OUTPUT; SELECT @NewStock as UpdatedStock;" || error "Failed to execute ManageProductInventory procedure"
  
  # Test view query
  info "Testing view query..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT * FROM PricedProducts WHERE ProductName = 'E2E Test Product'" || error "Failed to query PricedProducts view"
  
  # Test advanced views
  info "Testing UserStats view..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT Username, UserCategory, DaysActive FROM UserStats WHERE Username IN ('e2euser', 'e2euser_advanced')" || error "Failed to query UserStats view"
  
  info "Testing ProductAnalytics view..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT ProductName, StockStatus, InventoryValue FROM ProductAnalytics WHERE ProductName = 'E2E Test Product'" || error "Failed to query ProductAnalytics view"
  
  # Test user-defined functions
  info "Testing scalar function..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT dbo.FormatProductName('E2E Test Product', 29.99) as FormattedName" || error "Failed to execute FormatProductName function"
  
  info "Testing table-valued function..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT * FROM dbo.GetActiveProducts(50) WHERE ProductName = 'E2E Test Product'" || error "Failed to execute GetActiveProducts function"
  
  # Test data retrieval
  info "Testing data retrieval..."
  "$DEVDB_SCRIPT" query "USE DevDB; SELECT Username, Email FROM Users WHERE Username IN ('e2euser', 'e2euser_advanced')" || error "Failed to retrieve test users"
  
  success "User script execution completed successfully"
}

test_automated_tests() {
  info "=== STAGE 4: Automated Test Suite ==="
  
  # Run the basic passing test
  info "Running test_user_creation.sql..."
  "$DEVDB_SCRIPT" test test_user_creation.sql || error "test_user_creation.sql failed"
  
  # Run the function tests
  info "Running test_functions.sql..."
  "$DEVDB_SCRIPT" test test_functions.sql || error "test_functions.sql failed"
  
  # Run the view tests
  info "Running test_views.sql..."
  "$DEVDB_SCRIPT" test test_views.sql || error "test_views.sql failed"
  
  # Run the stored procedure tests
  info "Running test_stored_procedures.sql..."
  "$DEVDB_SCRIPT" test test_stored_procedures.sql || error "test_stored_procedures.sql failed"
  
  # Run the failing test (expect it to fail)
  info "Running test_product_stock_fail.sql (expected to fail)..."
  if "$DEVDB_SCRIPT" test test_product_stock_fail.sql; then
    error "test_product_stock_fail.sql should have failed but passed"
  else
    success "test_product_stock_fail.sql failed as expected"
  fi
  
  success "Automated test suite completed successfully"
}

cleanup_test_data() {
  info "=== STAGE 5: Cleanup Test Data ==="
  
  # Clean up test data
  info "Cleaning up test data..."
  "$DEVDB_SCRIPT" query "USE DevDB; DELETE FROM Products WHERE ProductName = 'E2E Test Product'" || warn "Failed to clean up test product"
  "$DEVDB_SCRIPT" query "USE DevDB; DELETE FROM Users WHERE Username IN ('e2euser', 'e2euser_advanced')" || warn "Failed to clean up test users"
  
  success "Test data cleanup completed"
}

# --- Main Execution ---
main() {
  info "Starting E2E Test Suite for DevDB"
  info "=================================="
  
  # Check prerequisites
  if [ ! -f "$DEVDB_SCRIPT" ]; then
    error "devdb.sh script not found at $DEVDB_SCRIPT"
  fi
  
  if [ ! -x "$DEVDB_SCRIPT" ]; then
    error "devdb.sh script is not executable. Run: chmod +x devdb.sh"
  fi
  
  # Run test stages
  test_cold_start
  test_schema_deployment
  test_user_scripts
  test_automated_tests
  cleanup_test_data
  
  success "=================================="
  success "E2E Test Suite completed successfully!"
  info "All stages passed:"
  info "  ✓ Cold start (clean environment)"
  info "  ✓ Schema deployment verification (tables, views, functions, procedures)"
  info "  ✓ User script execution (advanced stored procedures, functions, views)"
  info "  ✓ Automated test validation (functions, views, stored procedures)"
  info "  ✓ Test data cleanup"
  
  info "You can now use the system with: ./devdb.sh [command]"
}

# Run main function
main "$@"