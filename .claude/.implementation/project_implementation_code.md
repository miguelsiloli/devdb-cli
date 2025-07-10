Of course. Here is a complete, ready-to-use implementation of the **DevDB Automated Development Database Deployment System** based on the architecture we defined.

This implementation includes all the necessary files:
1.  The `docker-compose.yml` file to define the services.
2.  The `.env.example` file for configuration.
3.  The master control script `devdb.sh`.
4.  Example schema and test files.
5.  A `README.md` to guide the developers.

You can create these files in a new project directory.

---

### **Directory Structure**

First, create the following directory structure:

```plaintext
devdb-project/
├── .devdb/
│   ├── docker-compose.yml
│   └── .env.example
├── schemas/
│   ├── 01_tables.sql
│   └── 02_sprocs_and_views.sql
├── tests/
│   ├── test_user_creation.sql
│   └── test_product_stock_fail.sql
├── .gitignore
├── devdb.sh
└── README.md
```

---

### **File Implementations**

#### 1. `.devdb/docker-compose.yml`

This file defines the SQL Server and Adminer GUI services, their networking, and volume mounts.

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
      # Mount schemas for auto-initialization on first run
      - ../schemas:/docker-entrypoint-initdb.d:ro
    networks:
      - devdb-net
    healthcheck:
      # This check ensures the server is fully ready to accept connections
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "${SA_PASSWORD}", "-Q", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 10

  gui:
    image: adminer
    container_name: devdb-gui
    ports:
      - "${GUI_PORT}:8080"
    networks:
      - devdb-net
    depends_on:
      db:
        condition: service_started

networks:
  devdb-net:
    driver: bridge
```

#### 2. `.devdb/.env.example`

This is a template for the environment variables. Users will copy this to `.env` and fill in their secrets.

```ini
# .devdb/.env.example
# Copy this file to .devdb/.env and edit the values.
# IMPORTANT: The .env file is ignored by git and should NEVER be committed.

# --- SQL Server Configuration ---
# You MUST accept the EULA to run the container
ACCEPT_EULA=Y

# Set a strong password for the 'sa' user.
# SQL Server requires a complex password: upper, lower, numbers/symbols, min 8 chars.
SA_PASSWORD=YourStrong_Password123!

# --- Port Mapping ---
# Port on your local machine to connect to the SQL Server instance
DB_PORT=1433

# Port on your local machine to access the Adminer Web GUI
GUI_PORT=8081
```

#### 3. `devdb.sh` (The Master Control Script)

This is the core of the user interface. Make sure to make it executable with `chmod +x devdb.sh`.

```bash
#!/bin/bash
#
# DevDB - Automated Development Database Deployment System
#

# --- Configuration ---
# Exit script on any error
set -e

# Path to the docker-compose file relative to the script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/.devdb/docker-compose.yml"
ENV_FILE="${SCRIPT_DIR}/.devdb/.env"

# --- Style Definitions ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# --- Helper Functions ---
info() {
  echo -e "${COLOR_BLUE}INFO: $1${COLOR_NC}"
}

success() {
  echo -e "${COLOR_GREEN}SUCCESS: $1${COLOR_NC}"
}

warn() {
  echo -e "${COLOR_YELLOW}WARN: $1${COLOR_NC}"
}

error() {
  echo -e "${COLOR_RED}ERROR: $1${COLOR_NC}" >&2
  exit 1
}

# --- Command Functions ---

# Print the help message
usage() {
  echo "DevDB - Automated Development Database Control"
  echo ""
  echo "Usage: ./devdb.sh [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  up           Start and provision the database services."
  echo "  down         Stop and remove the database services."
  echo "  reset        Reset the entire environment (down then up)."
  echo "  test [file]  Run a specific SQL test file from the ./tests directory."
  echo "  test all     Run all .sql tests in the ./tests directory."
  echo "  query \"<SQL>\" Execute an ad-hoc SQL query string."
  echo "  status       Show the status of the running containers."
  echo "  help         Show this help message."
  echo ""
}

# Start the database environment
cmd_up() {
  info "Starting DevDB environment..."
  if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in your PATH. Please install Docker and try again."
  fi
  if ! docker info &> /dev/null; then
      error "Docker daemon is not running. Please start Docker and try again."
  fi

  docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

  info "Waiting for SQL Server to be healthy... (this may take a minute on first run)"
  # Loop until health check passes or timeout
  for i in {1..30}; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' devdb-sqlserver 2>/dev/null || echo "starting")
    if [ "$HEALTH_STATUS" == "healthy" ]; then
      success "Database is up and running!"
      echo -e "--------------------------------------------------"
      echo -e "  ${COLOR_YELLOW}SQL Server Connection Details:${COLOR_NC}"
      echo -e "    Host:     localhost"
      echo -e "    Port:     $(grep DB_PORT "$ENV_FILE" | cut -d '=' -f2)"
      echo -e "    User:     sa"
      echo -e "    Password: (from your .env file)"
      echo ""
      echo -e "  ${COLOR_YELLOW}Web GUI:${COLOR_NC}"
      echo -e "    URL:      http://localhost:$(grep GUI_PORT "$ENV_FILE" | cut -d '=' -f2)"
      echo -e "--------------------------------------------------"
      exit 0
    fi
    printf "."
    sleep 2
  done

  error "Database container failed to become healthy. Check logs with 'docker logs devdb-sqlserver'."
}

# Stop the database environment
cmd_down() {
  info "Stopping and removing DevDB containers..."
  docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down --remove-orphans
  success "DevDB environment has been shut down."
}

# Run tests
cmd_test() {
  if [ -z "$1" ]; then
    error "No test specified. Usage: ./devdb.sh test [filename | all]"
  fi

  # Load DB connection details from .env
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"

  if [ "$1" == "all" ]; then
    info "Running all tests in ./tests directory..."
    for test_file in ./tests/**/*.sql ./tests/*.sql; do
      if [ -f "$test_file" ]; then
        run_single_test "$test_file"
      fi
    done
    success "All tests completed."
  else
    local test_file="./tests/$1"
    if [ ! -f "$test_file" ]; then
      error "Test file not found: $test_file"
    fi
    run_single_test "$test_file"
  fi
}

run_single_test() {
  local file_to_test=$1
  info "Executing test: $file_to_test"
  if /opt/mssql-tools/bin/sqlcmd -S localhost,"${DB_PORT}" -U sa -P "${SA_PASSWORD}" -d master -i "$file_to_test" -b; then
    success "Test PASSED: $file_to_test"
  else
    error "Test FAILED: $file_to_test. Check output above for details."
  fi
}

# Run an ad-hoc query
cmd_query() {
  if [ -z "$1" ]; then
    error "No query string provided. Usage: ./devdb.sh query \"SELECT * FROM ...\""
  fi
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  info "Executing query..."
  /opt/mssql-tools/bin/sqlcmd -S localhost,"${DB_PORT}" -U sa -P "${SA_PASSWORD}" -d master -Q "$1"
}


# --- Main Execution Logic ---
if [ ! -f "$ENV_FILE" ]; then
  error ".env file not found at ${ENV_FILE}. Please copy .env.example to .env and configure it."
fi

case "$1" in
  up)
    cmd_up
    ;;
  down)
    cmd_down
    ;;
  reset)
    info "Resetting environment..."
    cmd_down
    cmd_up
    ;;
  test)
    cmd_test "$2"
    ;;
  query)
    cmd_query "$2"
    ;;
  status)
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    ;;
  help|--help|-h|*)
    usage
    ;;
esac
```

#### 4. `schemas/` Directory Files

##### `schemas/01_tables.sql`
```sql
-- schemas/01_tables.sql
-- This script creates the main tables for the application.

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DevDB')
BEGIN
    CREATE DATABASE DevDB;
END;
GO

USE DevDB;
GO

PRINT 'Creating table: Users';
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE()
);
GO

PRINT 'Creating table: Products';
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Stock INT NOT NULL DEFAULT 0
);
GO
```

##### `schemas/02_sprocs_and_views.sql`
```sql
-- schemas/02_sprocs_and_views.sql
-- This script creates stored procedures and views.

USE DevDB;
GO

PRINT 'Creating stored procedure: AddNewUser';
GO
CREATE PROCEDURE dbo.AddNewUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Users (Username, Email)
    VALUES (@Username, @Email);
END;
GO

PRINT 'Creating view: PricedProducts';
GO
CREATE VIEW dbo.PricedProducts AS
SELECT
    ProductID,
    ProductName,
    Price
FROM
    dbo.Products
WHERE
    Price > 0;
GO
```

#### 5. `tests/` Directory Files

##### `tests/test_user_creation.sql`
```sql
-- tests/test_user_creation.sql
USE DevDB;
GO

PRINT 'TEST: Inserting a new user via stored procedure.';

-- Arrange: Clean up any previous test data
DELETE FROM dbo.Users WHERE Username = 'testuser';

-- Act: Execute the stored procedure
EXEC dbo.AddNewUser @Username = 'testuser', @Email = 'test@example.com';

-- Assert: Verify the user was created correctly
IF (SELECT COUNT(*) FROM dbo.Users WHERE Username = 'testuser' AND Email = 'test@example.com') = 1
BEGIN
    PRINT 'SUCCESS: User "testuser" was created successfully.';
END
ELSE
BEGIN
    -- This will cause sqlcmd with -b flag to exit with an error
    THROW 50000, 'ASSERTION FAILED: User "testuser" was not found after insertion.', 1;
END;
GO

-- Clean up after test
DELETE FROM dbo.Users WHERE Username = 'testuser';
GO
```

##### `tests/test_product_stock_fail.sql`
```sql
-- tests/test_product_stock_fail.sql
-- This test is designed to fail to demonstrate error handling.
USE DevDB;
GO

PRINT 'TEST: Verifying product stock level (intentional failure).';

-- Arrange: Set up a product with known stock
DELETE FROM dbo.Products WHERE ProductName = 'Test Widget';
INSERT INTO dbo.Products (ProductName, Price, Stock) VALUES ('Test Widget', 19.99, 10);

-- Assert: Check for an incorrect stock level
IF (SELECT Stock FROM dbo.Products WHERE ProductName = 'Test Widget') = 5 -- This is wrong on purpose
BEGIN
    PRINT 'SUCCESS: Stock level is 5.';
END
ELSE
BEGIN
    THROW 50000, 'ASSERTION FAILED: Expected stock to be 5, but it was not.', 1;
END;
GO

-- Clean up
DELETE FROM dbo.Products WHERE ProductName = 'Test Widget';
GO
```

#### 6. `.gitignore`

```
# Ignore the local environment file which contains secrets
.devdb/.env

# Ignore OS-specific files
.DS_Store
Thumbs.db

# Ignore log files
*.log

# Ignore IDE files
.vscode/
.idea/
```

#### 7. `README.md`

```markdown
# DevDB - Automated Development Database Deployment System

This project provides a one-command solution to deploy a fresh, containerized SQL Server database for local development. It ensures a consistent, clean, and fast environment for all team members.

## Prerequisites

1.  **Git**: To clone the repository.
2.  **Docker**: [Docker Desktop](https://www.docker.com/products/docker-desktop) (for Windows/macOS) or Docker Engine (for Linux) must be installed and running.

## First-Time Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd devdb-project
    ```

2.  **Configure your environment:**
    Copy the example `.env` file. This file contains your database password and is ignored by Git.
    ```bash
    cp .devdb/.env.example .devdb/.env
    ```
    **Open `.devdb/.env` in a text editor and set a strong `SA_PASSWORD`.**

3.  **Make the control script executable:**
    (On macOS and Linux)
    ```bash
    chmod +x devdb.sh
    ```

## How to Use

All commands are run via the `./devdb.sh` script.

### Core Commands

| Command | Description |
| :--- | :--- |
| `./devdb.sh up` | Starts the SQL Server and Web GUI containers. On first run, it builds the database from the `schemas/` directory. |
| `./devdb.sh down` | Stops and removes all containers and the network. |
| `./devdb.sh reset` | Completely resets the environment by running `down` then `up`. Perfect for getting a clean slate. |
| `./devdb.sh status` | Shows the current status of the running containers. |
| `./devdb.sh help` | Displays the help message with all available commands. |

### Running Tests and Queries

| Command | Description |
| :--- | :--- |
| `./devdb.sh test all` | Executes all `.sql` files found in the `./tests` directory. The script will stop on the first failing test. |
| `./devdb.sh test <filename.sql>` | Executes a single, specific test file from the `./tests` directory. (e.g., `./devdb.sh test test_user_creation.sql`) |
| `./devdb.sh query "<SQL>"` | Executes an ad-hoc SQL query string directly against the database. (e.g., `./devdb.sh query "SELECT * FROM Users"`) |

### Connecting with Tools

Once the environment is running (`./devdb.sh up`), you can connect using your favorite SQL tools:

*   **Connection Details:**
    *   **Server/Host:** `localhost`
    *   **Port:** `1433` (or whatever you set in `.env`)
    *   **Authentication:** SQL Server Authentication
    *   **User:** `sa`
    *   **Password:** The `SA_PASSWORD` you set in `.env`.
    *   **Database:** `DevDB`

*   **Web GUI:**
    *   Open your browser and go to **http://localhost:8081** (or the `GUI_PORT` you set).
    *   On the login screen, use the same credentials as above, with `localhost` as the server.

## How It Works

*   **Schema Management**: On the first run of `./devdb.sh up`, Docker automatically executes all `.sql` files in the `./schemas` directory in alphabetical order. To add or change the schema, modify these files and run `./devdb.sh reset`.
*   **Test Management**: The `./devdb.sh test` command uses `sqlcmd` to execute scripts from the `./tests` directory. A test is considered "failed" if the SQL script returns an error (e.g., using `THROW`).
```