# DevDB Deployment Sequence

This document outlines the sequential deployment process for the DevDB Automated Development Database Deployment System, designed to ensure proper testing and validation at each stage.

## Overview

The deployment follows a decoupled, sequential approach where each stage must be completed and tested before proceeding to the next. This ensures reliability and proper validation throughout the deployment process.

## Stage 1: Docker Infrastructure Setup

### Objective
Create and test the containerized database infrastructure.

### Files Created
- `.devdb/docker-compose.yml` - Docker Compose configuration
- `.devdb/.env.example` - Environment variable template
- `.devdb/.env` - Local environment configuration (copied from example)

### Actions Performed
1. **Create Infrastructure Directory**
   ```bash
   mkdir -p .devdb
   ```

2. **Create Docker Compose Configuration**
   - SQL Server 2022 container with health checks
   - Adminer GUI container for database management
   - Network configuration for container communication
   - Volume mounts for schema and test files

3. **Create Environment Configuration**
   - Template file with required environment variables
   - Local copy for immediate testing

### Testing Criteria
- Docker Compose file syntax validation
- Environment file structure verification
- Container startup capability (requires Docker daemon access)

### Status
✅ **COMPLETED** - Infrastructure files created and configured

---

## Stage 2: Schema Examples Creation

### Objective
Create SQL schema files that will be automatically deployed during database initialization.

### Files Created
- `schemas/01_tables.sql` - Database and table creation
- `schemas/02_sprocs_and_views.sql` - Stored procedures and views

### Actions Performed
1. **Create Schema Directory**
   ```bash
   mkdir -p schemas
   ```

2. **Database Structure Setup**
   - DevDB database creation
   - Users table with identity and constraints
   - Products table with pricing and stock tracking

3. **Business Logic Implementation**
   - AddNewUser stored procedure for user management
   - PricedProducts view for filtered product display

### Testing Criteria
- SQL syntax validation
- Proper GO statement separation
- Logical table relationships
- Schema deployment order (numerical prefixes)

### Status
✅ **COMPLETED** - Schema files created with proper structure

---

## Stage 3: Test Scripts Development

### Objective
Create automated test scripts to validate database functionality.

### Files Created
- `tests/test_user_creation.sql` - User creation validation (passing test)
- `tests/test_product_stock_fail.sql` - Stock validation (failing test for demo)

### Actions Performed
1. **Create Test Directory**
   ```bash
   mkdir -p tests
   ```

2. **Test Implementation**
   - Arrange-Act-Assert pattern usage
   - Error handling with THROW statements
   - Data cleanup procedures
   - Test isolation techniques

### Testing Criteria
- Test isolation (no dependencies between tests)
- Proper error handling and reporting
- Data cleanup after test execution
- Both passing and failing test scenarios

### Status
✅ **COMPLETED** - Test scripts created with proper validation logic

---

## Stage 4: Master Control Script

### Objective
Create a unified command-line interface for all database operations.

### Files Created
- `devdb.sh` - Main control script with full functionality

### Actions Performed
1. **Script Structure Setup**
   - Bash script with error handling (`set -e`)
   - Color-coded output for better UX
   - Command routing and validation

2. **Core Functionality Implementation**
   - `up` - Start database environment with health checks
   - `down` - Stop and clean up containers
   - `reset` - Complete environment reset
   - `test` - Individual and batch test execution
   - `query` - Ad-hoc SQL query execution
   - `status` - Container status monitoring

3. **Docker Integration**
   - Health check monitoring with timeout
   - Container exec for SQL execution
   - Volume mounting for test file access
   - Environment variable integration

### Testing Criteria
- Script executable permissions
- Command validation and error handling
- Docker daemon connectivity
- SQL Server connection establishment

### Status
✅ **COMPLETED** - Master control script with full functionality

---

## Stage 5: End-to-End Testing

### Objective
Create comprehensive E2E test that validates the entire system from cold start to full operation.

### Files Created
- `e2e_test.sh` - Complete end-to-end test suite

### Actions Performed
1. **Test Suite Structure**
   - Sequential test stages with clear separation
   - Colored output for progress tracking
   - Error handling and cleanup procedures

2. **Test Stages Implementation**
   - **Cold Start Test**: Clean environment setup
   - **Schema Deployment Test**: Database structure validation
   - **User Script Test**: Manual SQL execution verification
   - **Automated Test Suite**: Test script execution validation
   - **Cleanup**: Test data removal

3. **Validation Logic**
   - Database existence verification
   - Table and schema object validation
   - Stored procedure and view confirmation
   - Data manipulation testing
   - Test framework validation

### Testing Criteria
- Complete system functionality validation
- Clean startup from empty state
- Schema deployment verification
- User interaction testing
- Automated test execution

### Status
✅ **COMPLETED** - E2E test suite with comprehensive validation

---

## Stage 6: Supporting Files

### Objective
Create additional project files for proper project management and documentation.

### Files Created
- `.gitignore` - Version control exclusions
- `README.md` - Project documentation and usage guide

### Actions Performed
1. **Version Control Setup**
   - Environment file exclusions
   - OS-specific file filtering
   - IDE configuration exclusions

2. **Documentation Creation**
   - Project overview and prerequisites
   - Setup and configuration instructions
   - Command reference and usage examples
   - Connection details and troubleshooting

### Testing Criteria
- Git ignore functionality
- Documentation completeness
- Setup instruction validation

### Status
✅ **COMPLETED** - Supporting files created

---

## Deployment Validation

### Prerequisites
- Docker installed and running
- Docker Compose available
- Appropriate user permissions for Docker operations

### Validation Steps

1. **Environment Setup**
   ```bash
   cp .devdb/.env.example .devdb/.env
   # Edit .devdb/.env with appropriate SA_PASSWORD
   ```

2. **Permission Setup**
   ```bash
   chmod +x devdb.sh
   chmod +x e2e_test.sh
   ```

3. **Full System Test**
   ```bash
   ./e2e_test.sh
   ```

### Expected Outcomes
- All containers start successfully
- Database schemas deploy correctly
- Test scripts execute with expected results
- System ready for development use

---

## Usage After Deployment

### Basic Operations
```bash
# Start the database environment
./devdb.sh up

# Run all tests
./devdb.sh test all

# Execute custom queries
./devdb.sh query "SELECT * FROM Users"

# Stop the environment
./devdb.sh down
```

### Development Workflow
1. Start environment: `./devdb.sh up`
2. Make schema changes in `schemas/` directory
3. Reset environment: `./devdb.sh reset`
4. Run tests: `./devdb.sh test all`
5. Continue development

---

## System Architecture

### Component Interaction
```
┌─────────────────┐    ┌─────────────────┐
│   devdb.sh      │    │   e2e_test.sh   │
│ (Control Script)│    │ (E2E Testing)   │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   Docker Compose      │
         │  (.devdb/docker-      │
         │   compose.yml)        │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼───┐      ┌─────▼─────┐    ┌─────▼─────┐
│SQL    │      │ Adminer   │    │ Schemas   │
│Server │      │ GUI       │    │ & Tests   │
└───────┘      └───────────┘    └───────────┘
```

### File Dependencies
- `devdb.sh` → `.devdb/docker-compose.yml` → `.devdb/.env`
- `schemas/` → SQL Server initialization
- `tests/` → Test execution via `devdb.sh`
- `e2e_test.sh` → `devdb.sh` → All system components

---

## Troubleshooting

### Common Issues
1. **Docker Permission Denied**
   - Add user to docker group: `sudo usermod -aG docker $USER`
   - Restart terminal session

2. **Container Health Check Failures**
   - Check SA_PASSWORD complexity requirements
   - Verify Docker daemon is running
   - Check available system resources

3. **Schema Deployment Issues**
   - Verify SQL syntax in schema files
   - Check file permissions in schemas directory
   - Validate GO statement placement

### Validation Commands
```bash
# Check Docker status
docker info

# Verify container health
docker ps
docker logs devdb-sqlserver

# Test database connectivity
./devdb.sh query "SELECT @@VERSION"
```

---

## Security Considerations

### Environment Security
- `.env` file excluded from version control
- Strong password requirements enforced
- Container network isolation

### Access Control
- SA user access restricted to development use
- Local-only database binding
- Container-to-container communication only

---

## Maintenance

### Regular Tasks
1. **Update Base Images**
   ```bash
   docker pull mcr.microsoft.com/mssql/server:2022-latest
   docker pull adminer
   ```

2. **Schema Migrations**
   - Add new schema files with higher numbers
   - Test with `./devdb.sh reset`
   - Validate with E2E tests

3. **Test Suite Maintenance**
   - Add new tests for new features
   - Update existing tests for schema changes
   - Validate test isolation

### Monitoring
- Container health status
- Database performance metrics
- Test execution results
- Error log analysis

---

## Conclusion

The DevDB system provides a robust, sequential deployment process that ensures reliable database development environments. Each stage is independently testable and validates the previous stage's outputs, creating a dependable deployment pipeline for SQL Server development projects.

The decoupled architecture allows for easy maintenance, troubleshooting, and extension while maintaining strict validation at each deployment stage.