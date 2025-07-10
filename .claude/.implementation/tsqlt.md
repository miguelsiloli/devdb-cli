Excellent choice. Phase 2, "The Game Changer," is where we'll see the most significant improvement in the quality and ergonomics of database testing. By integrating **tSQLt**, we move from simple script execution to a structured, professional unit testing methodology.

Here is a detailed plan and implementation guide for evolving our DevDB system to incorporate tSQLt.

---

### **Phase 2: Integrating the tSQLt Framework**

#### **Objective:**
Replace the ad-hoc `IF/ELSE/THROW` testing mechanism with the tSQLt framework. This will provide structured tests, rich assertions, automatic transaction isolation, and standardized XML output for CI/CD integration.

#### **Key Changes at a Glance:**
1.  **Download tSQLt:** We will add the tSQLt framework file to our project.
2.  **Automate Installation:** The `docker-compose.yml` will be updated to install tSQLt automatically after the main schema is created.
3.  **Rewrite Tests:** Our existing tests will be rewritten as tSQLt stored procedures.
4.  **Update the Control Script:** The `devdb.sh` script will be modified to run tSQLt tests and parse the results.

---

### **Step 1: Get tSQLt**

1.  Go to the official tSQLt website: [https://tsqlt.org/](https://tsqlt.org/)
2.  Download the latest version of the framework. It will be a single `.sql` file, typically named `tSQLt.class.sql`.
3.  Place this file inside a new directory in our project: `./.devdb/tSQLt/`.

Our directory structure now looks like this:
```plaintext
devdb-project/
├── .devdb/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── tSQLt/
│       └── tSQLt.class.sql  <-- The downloaded file
...
```

### **Step 2: Automate tSQLt Installation**

We need to run `tSQLt.class.sql` *after* our main database and schemas are created. The SQL Server Docker image's entrypoint runs scripts in alphabetical order. We can leverage this by creating a simple "post-init" script.

1.  **Create a post-initialization script:**
    Create a new file named `schemas/99_post_init.sql`. The `99` prefix ensures it runs last.

    **File: `schemas/99_post_init.sql`**
    ```sql
    -- This script runs after all other schema scripts.
    -- It enables CLR, which is required by tSQLt.
    USE DevDB;
    GO

    PRINT 'Enabling CLR for tSQLt installation...';
    -- tSQLt requires CLR to be enabled on the database.
    EXEC sp_configure 'clr enabled', 1;
    RECONFIGURE;
    GO
    ```

2.  **Update `docker-compose.yml` to run the tSQLt install:**
    We will modify the `db` service definition to mount the tSQLt file and a wrapper script that executes it.

    **Create a wrapper script: `.devdb/tSQLt/install_tsqlt.sh`**
    This script waits for SQL Server to be ready and then runs the tSQLt installation script.
    ```bash
    #!/bin/bash
    # Wait for SQL Server to be fully ready before installing tSQLt
    # This is more robust than just relying on script ordering.
    sleep 20s

    echo "Running tSQLt installation script..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d DevDB -i /docker-entrypoint-initdb.d/tSQLt.class.sql
    ```
    Make it executable: `chmod +x .devdb/tSQLt/install_tsqlt.sh`

    **Update the file: `.devdb/docker-compose.yml`**
    We'll modify the `volumes` and add a `command` to the `db` service.

    ```yaml
    # .devdb/docker-compose.yml
    version: "3.8"

    services:
      db:
        image: mcr.microsoft.com/mssql/server:2022-latest
        container_name: devdb-sqlserver
        environment:
          ACCEPT_EULA: "${ACCEPT_EULA}"
          SA_PASSWORD: "${SA_PASSWORD}"
        ports:
          - "${DB_PORT}:1433"
        volumes:
          # Mount schemas for auto-initialization (runs first)
          - ../schemas:/docker-entrypoint-initdb.d
          # Mount tSQLt install script (to be called by our command)
          - ./tSQLt/tSQLt.class.sql:/docker-entrypoint-initdb.d/tSQLt.class.sql:ro
          # Mount our wrapper script
          - ./tSQLt/install_tsqlt.sh:/usr/local/bin/install_tsqlt.sh:ro
        # This command runs the default entrypoint AND our custom script
        command: /bin/bash -c "/opt/mssql/bin/sqlservr & /usr/local/bin/install_tsqlt.sh"
        networks:
          - devdb-net
        healthcheck:
          # The healthcheck remains the same
          test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "${SA_PASSWORD}", "-Q", "SELECT 1"]
          interval: 10s
          timeout: 5s
          retries: 10
    
      # ... gui service remains the same ...

    networks:
      devdb-net:
        driver: bridge
    ```

Now, every time a developer runs `./devdb.sh reset`, they will get a fresh database with the schema and a fully installed tSQLt framework.

### **Step 3: Rewrite Tests using tSQLt**

We'll convert our old test files into tSQLt-compatible stored procedures. In tSQLt, tests are organized into "test classes," which are just database schemas.

**Delete the old test files:**
`rm tests/test_user_creation.sql tests/test_product_stock_fail.sql`

**Create a new test file: `tests/test_UserManagement.sql`**
This file will contain a test class and multiple tests related to user management.

```sql
-- tests/test_UserManagement.sql
USE DevDB;
GO

-- 1. Create a Test Class (a schema to group our tests)
EXEC tSQLt.NewTestClass @ClassName = 'UserManagement';
GO

-- 2. Create our first test procedure
CREATE PROCEDURE UserManagement.[test that AddNewUser successfully inserts a new user]
AS
BEGIN
    -- Assemble: Create a fake version of the Users table. This isolates our test.
    -- The fake table has the same columns but no constraints or triggers.
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';

    -- Act: Execute the stored procedure we want to test
    EXEC dbo.AddNewUser @Username = 'testuser', @Email = 'test@example.com';

    -- Assert: Check if the fake table contains the expected data
    DECLARE @Actual INT = (SELECT COUNT(*) FROM dbo.Users WHERE Username = 'testuser');
    DECLARE @Expected INT = 1;

    EXEC tSQLt.AssertEquals @Expected = @Expected, @Actual = @Actual, @Message = 'Expected a single user to be created.';
END;
GO

-- 3. Create another test procedure
CREATE PROCEDURE UserManagement.[test that AddNewUser does not create duplicates]
AS
BEGIN
    -- Assemble: Fake the table and insert a pre-existing user
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    INSERT INTO dbo.Users (Username, Email) VALUES ('existinguser', 'existing@example.com');
    
    -- Add a unique constraint to the faked table to test error handling
    EXEC tSQLt.ApplyConstraint @TableName = 'dbo.Users', @ConstraintName = 'UQ_Users_Username';

    -- Act & Assert: Expect an error when trying to insert a duplicate username
    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Violation of UNIQUE KEY constraint%';

    EXEC dbo.AddNewUser @Username = 'existinguser', @Email = 'another@example.com';
END;
GO
```

### **Step 4: Update `devdb.sh` to be tSQLt-aware**

Finally, we modify our control script to run these new tests and parse the output.

**Modify the `devdb.sh` script:**

We'll change the `cmd_test` function and the `run_single_test` helper.

```bash
#!/bin/bash
# ... (all previous parts of the script remain the same) ...

# Run tests
cmd_test() {
  if [ -z "$1" ]; then
    error "No test specified. Usage: ./devdb.sh test [ClassName | all]"
  fi

  # Load DB connection details from .env
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"

  if [ "$1" == "all" ]; then
    info "Running all tSQLt tests..."
    # Generate JUnit XML for CI/CD systems
    local report_file="tsqlt-report.xml"
    /opt/mssql-tools/bin/sqlcmd -S localhost,"${DB_PORT}" -U sa -P "${SA_PASSWORD}" -d DevDB \
      -Q "EXEC tSQLt.RunAll @ResultFormatter = 'JUnit'" -o "$report_file" -h-1 -W

    # Check the XML for failures to set the exit code correctly
    if grep -q '<failure' "$report_file"; then
      error "One or more tSQLt tests failed. See details in $report_file"
    else
      success "All tSQLt tests passed. Report generated: $report_file"
    fi
  else
    # Logic to install and run tests from a single file
    info "Installing and running tests from class: $1"
    local test_file="./tests/$1.sql"
    if [ ! -f "$test_file" ]; then
      error "Test file not found: $test_file"
    fi
    
    # Install the tests from the file
    /opt/mssql-tools/bin/sqlcmd -S localhost,"${DB_PORT}" -U sa -P "${SA_PASSWORD}" -d DevDB -i "$test_file" -b > /dev/null
    
    # Run the tests from that specific class
    /opt/mssql-tools/bin/sqlcmd -S localhost,"${DB_PORT}" -U sa -P "${SA_PASSWORD}" -d DevDB \
      -Q "EXEC tSQLt.Run @TestName = '$1'"
  fi
}

# The old run_single_test function is no longer needed.
# ... (rest of the script)
```

**Note on the `devdb.sh` changes:**
*   `./devdb.sh test all`: Now runs all tests and produces a `tsqlt-report.xml` file. This is perfect for CI. It checks the XML for `<failure>` tags to determine if the script should exit with an error.
*   `./devdb.sh test UserManagement`: This command is useful for development. It installs the tests from `tests/UserManagement.sql` and then runs only the tests in that class, showing the results directly in the console.

### **How to Use the New System**

1.  **Reset the environment** to get the new tSQLt installation:
    ```bash
    ./devdb.sh reset
    ```

2.  **Run all tests and generate a report:**
    ```bash
    ./devdb.sh test all
    ```
    *Output:*
    ```
    INFO: Running all tSQLt tests...
    SUCCESS: All tSQLt tests passed. Report generated: tsqlt-report.xml
    ```
    (Now you can check the `tsqlt-report.xml` file for details).

3.  **Run a specific test class during development:**
    ```bash
    ./devdb.sh test UserManagement
    ```
    *Output:*
    ```
    INFO: Installing and running tests from class: UserManagement
    +----------------------+
    |Test Results          |
    +----------------------+
    |Test Case Name                                                          |Result |
    +------------------------------------------------------------------------+-------+
    |UserManagement.[test that AddNewUser does not create duplicates]        |Success|
    |UserManagement.[test that AddNewUser successfully inserts a new user]   |Success|
    ---------------------------------------------------------------------------------
    Test Case Summary: 2 test case(s) executed, 2 succeeded, 0 failed, 0 errored.
    ---------------------------------------------------------------------------------
    ```

We have now successfully evolved our DevDB project into Phase 2. The testing system is far more robust, developer-friendly, and ready for professional CI/CD integration.