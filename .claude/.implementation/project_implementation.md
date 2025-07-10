Of course. As a systems architect, I will now define the high-level architecture and system interfaces for the **DevDB - Automated Development Database Deployment System**.

This document outlines the technical design, components, and interaction patterns required to meet the objectives defined in the project charter.

---

## **DevDB System Architecture & Design**

### **1. Executive Summary**

This architecture is designed to be simple, robust, and platform-agnostic, leveraging industry-standard containerization and command-line tools. It centers around a `docker-compose` configuration that manages two core services: a **SQL Server instance** and a lightweight **Web GUI**. A master control script provides a unified Command-Line Interface (CLI) for developers to manage the entire lifecycle of their local database environment, from initial deployment to test execution and teardown.

The key principles of this design are:
*   **Encapsulation:** The entire database environment is self-contained within Docker, preventing conflicts with the host system.
*   **Idempotency:** Running the deployment command repeatedly results in the same clean, predictable state.
*   **Simplicity:** A single configuration file (`docker-compose.yml`) and a single control script (`devdb.sh`) orchestrate all operations.

### **2. High-Level Logical Architecture**

The system is composed of four main areas: the Developer's Host Machine, the CLI control layer, the Docker Engine, and the containerized services running on an isolated Docker network.



### **3. Component Breakdown**

#### **3.1. Developer's Host Machine**
*   **Purpose:** The primary environment where the developer works.
*   **Prerequisites:**
    *   **Docker Engine:** Must be installed and running (e.g., Docker Desktop for Windows/macOS, Docker for Linux).
    *   **Git:** For cloning the project repository.
    *   **Bash-compatible Shell:** For running the control script (Git Bash on Windows, Terminal on macOS/Linux).

#### **3.2. Control Layer (CLI)**
*   **Technology:** A single Bash script (`devdb.sh`).
*   **Purpose:** To provide a simple, unified interface for all system operations. This script acts as a façade, translating user-friendly commands into `docker-compose` and `sqlcmd` instructions.
*   **Responsibilities:**
    *   Parse user commands and arguments (e.g., `up`, `down`, `test`).
    *   Read configuration from the `.env` file.
    *   Orchestrate container lifecycle using `docker-compose`.
    *   Execute SQL scripts against the database using `sqlcmd`.
    *   Provide clear feedback, status messages, and error handling.

#### **3.3. Container Orchestration**
*   **Technology:** `docker-compose.yml` and `.env` file.
*   **Purpose:** To define, configure, and link the containerized services.
*   **`docker-compose.yml` Definition:**
    *   **Services:**
        1.  `devdb-sqlserver`: The SQL Server instance.
        2.  `devdb-gui`: The web-based database GUI.
    *   **Volumes:**
        *   Mounts the host's `./schemas` directory into the SQL Server container for automatic schema application.
        *   Mounts the host's `./tests` directory for on-demand test execution.
        *   (Optional) A named volume for persistent data if needed, though the primary use case is ephemeral.
    *   **Networking:**
        *   Creates a dedicated bridge network (`devdb-net`) to allow services to communicate via service names (e.g., `devdb-sqlserver`).
        *   Publishes ports to the host machine (e.g., `1433` for SQL Server, `8080` for the Web GUI).
*   **`.env` File:**
    *   Stores sensitive data and environment-specific configuration.
    *   **Variables:** `SA_PASSWORD`, `DB_PORT`, `GUI_PORT`, etc.
    *   This file is read by both `docker-compose` and the `devdb.sh` script to ensure consistency. It is excluded from version control (`.gitignore`).

#### **3.4. SQL Server Service (`devdb-sqlserver`)**
*   **Technology:** Official Microsoft SQL Server for Linux Docker image (`mcr.microsoft.com/mssql/server`).
*   **Configuration:**
    *   Accepts EULA and sets the SA password via environment variables from the `.env` file.
    *   **Entrypoint Initialization:** This is the core of the schema automation. The official image automatically executes any `.sql` or `.sh` scripts placed in the `/docker-entrypoint-initdb.d` directory upon the container's *first* creation. We will mount our `./schemas` directory to this location.
    *   Exposes port `1433` to the host for tools like SSMS or Azure Data Studio to connect.

#### **3.5. Web GUI Service (`devdb-gui`)**
*   **Technology:** **Adminer** (or a similar lightweight tool like SQLPad). Adminer is an excellent choice as it's a single PHP file, extremely lightweight, and supports SQL Server.
*   **Configuration:**
    *   Uses a standard `adminer` Docker image.
    *   Configured to connect to the `devdb-sqlserver` service over the internal `devdb-net` network.
    *   Exposes a port (e.g., `8080`) to the host, making the GUI accessible at `http://localhost:8080`.
    *   Requires no local installation or configuration by the user beyond starting the container.

### **4. Interface Definitions & Data Flow**

#### **4.1. User Interface: The CLI (`devdb.sh`)**
This interface abstracts the underlying complexity of Docker and SQL tools.

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `./devdb.sh up` | `[-d]` | Starts and provisions the database container. If it's the first run, it creates the container and runs schema scripts. On subsequent runs, it just starts the existing container. The `-d` flag runs it in detached mode. |
| `./devdb.sh down` | | Stops and removes the containers, network, and optionally the volumes, providing a complete cleanup. |
| `./devdb.sh reset` | | A convenience command that executes `down` followed by `up` to provide a guaranteed fresh database instance. |
| `./devdb.sh test` | `[test_file.sql \| "all"]` | Executes SQL test scripts against the running database. Takes a specific file name or "all" to run every script in the `/tests` directory. |
| `./devdb.sh query` | `"<SQL_QUERY>"` | Executes an ad-hoc SQL query string directly against the database and prints the results to the console. |
| `./devdb.sh status` | | Checks the status of the Docker containers and provides connection details. |

#### **4.2. Data Flow: Initial Database Deployment ("Cold Start")**

1.  **User Action:** Developer runs `./devdb.sh up`.
2.  **CLI:** The script invokes `docker-compose up`.
3.  **Docker Engine:**
    *   Reads `docker-compose.yml` and the `.env` file.
    *   Pulls the required images (`mssql-server`, `adminer`) if not present locally.
    *   Creates the `devdb-net` network.
    *   Starts the `devdb-sqlserver` container.
4.  **SQL Server Container:**
    *   On its first start, the SQL Server entrypoint script detects files in `/docker-entrypoint-initdb.d`.
    *   It executes each `.sql` file from the mounted `./schemas` directory in alphabetical order.
    *   The database is now fully provisioned with the production schema.
5.  **GUI Container:** The `devdb-gui` container starts and is ready to accept connections.
6.  **Feedback:** The CLI script tails the logs, waits for a "database is ready" signal, and then prints a success message with connection details for SQL Server (`localhost:1433`) and the Web GUI (`http://localhost:8080`).

#### **4.3. Data Flow: Test Execution**

1.  **User Action:** Developer runs `./devdb.sh test my_feature_test.sql`.
2.  **CLI:**
    *   The script verifies that the `devdb-sqlserver` container is running.
    *   It reads the `.env` file to get the SA password and port.
    *   It constructs a `sqlcmd` command: `sqlcmd -S localhost,${DB_PORT} -U sa -P "${SA_PASSWORD}" -i ./tests/my_feature_test.sql -b`. (The `-b` flag ensures the script exits with an error code on SQL failure).
3.  **sqlcmd:** The tool connects to the SQL Server instance via the port published on the host and executes the script.
4.  **Feedback:** The `sqlcmd` output (results, messages, or errors) is printed directly to the developer's console. The exit code of the `devdb.sh` script reflects the success or failure of the test.

### **5. Proposed Directory Structure**

```plaintext
devdb-project/
├── .devdb/
│   ├── docker-compose.yml     # Defines the services, network, and volumes
│   └── .env                   # Environment variables (DB password, ports) - NOT in git
├── schemas/
│   ├── 01_tables.sql          # All table creation scripts
│   ├── 02_views.sql           # All view creation scripts
│   └── 03_sprocs.sql          # All stored procedure scripts
├── tests/
│   ├── users/
│   │   ├── create_users.sql
│   │   └── permissions_test.sql
│   └── products/
│       └── stock_level_test.sql
├── .gitignore
├── devdb.sh                   # The master control script (executable)
└── README.md                  # Instructions for users
```

This architecture directly fulfills the project requirements by providing a fast, reliable, and isolated development environment that is managed through a simple and intuitive command-line interface, with the added benefit of a web-based GUI for quick data inspection.