# {{PROJECT_NAME}} - DevDB Project

This DevDB project provides a one-command solution to deploy a fresh, containerized SQL Server database for local development. It ensures a consistent, clean, and fast environment for all team members.

**Project created:** {{CREATION_DATE}}  
**Author:** {{AUTHOR_NAME}}

## Prerequisites

1.  **Git**: To clone the repository.
2.  **Docker**: [Docker Desktop](https://www.docker.com/products/docker-desktop) (for Windows/macOS) or Docker Engine (for Linux) must be installed and running.

## First-Time Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd sql_server_dev
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
    chmod +x e2e_test.sh
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

- ./devdb.sh up - Start database
- ./devdb.sh down - Stop database
- ./devdb.sh reset - Reset environment
- ./devdb.sh schema - Initialize schemas
- ./devdb.sh test [file|all] - Run tests
- ./devdb.sh query "<SQL>" - Execute queries
- ./devdb.sh status - Show container status
- ./devdb.sh polish [path] - Format and standardize SQL files ⭐
- ./devdb.sh help - Show help

### Running Tests and Queries

| Command | Description |
| :--- | :--- |
| `./devdb.sh test all` | Executes all `.sql` files found in the `./tests` directory. The script will stop on the first failing test. |
| `./devdb.sh test <filename.sql>` | Executes a single, specific test file from the `./tests` directory. (e.g., `./devdb.sh test test_user_creation.sql`) |
| `./devdb.sh query "<SQL>"` | Executes an ad-hoc SQL query string directly against the database. (e.g., `./devdb.sh query "SELECT * FROM Users"`) |

### End-to-End Testing

Run the complete E2E test suite to validate the entire system:

```bash
./e2e_test.sh
```

This will perform:
- Cold start (clean environment)
- Schema deployment verification
- User script execution
- Test validation
- Cleanup

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

## Project Structure

```
sql_server_dev/
├── .devdb/
│   ├── docker-compose.yml    # Docker services configuration
│   ├── .env.example         # Environment template
│   └── .env                 # Local environment (ignored by git)
├── schemas/
│   ├── 01_tables.sql        # Database and table creation
│   └── 02_sprocs_and_views.sql  # Stored procedures and views
├── tests/
│   ├── test_user_creation.sql      # User creation test
│   └── test_product_stock_fail.sql # Failing test example
├── devdb.sh                 # Main control script
├── e2e_test.sh             # End-to-end test suite
├── deployment:sequence.md   # Deployment documentation
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Development Workflow

1. **Start the environment:**
   ```bash
   ./devdb.sh up
   ```

2. **Make schema changes** in the `schemas/` directory

3. **Reset the environment** to apply changes:
   ```bash
   ./devdb.sh reset
   ```

4. **Run tests** to validate:
   ```bash
   ./devdb.sh test all
   ```

5. **Continue development** with confidence

## Troubleshooting

### Docker Permission Issues
If you get permission denied errors:
```bash
sudo usermod -aG docker $USER
# Then restart your terminal
```

### Container Health Check Failures
- Ensure SA_PASSWORD meets complexity requirements (8+ chars, upper/lower/numbers/symbols)
- Check Docker daemon is running: `docker info`
- Verify system resources are available

### Schema Deployment Issues
- Check SQL syntax in schema files
- Ensure proper GO statement placement
- Verify file permissions in schemas directory

## Security Notes

- The `.env` file is ignored by Git and contains sensitive information
- Never commit database passwords to version control
- The system is designed for development use only
- Use strong passwords for the SA account

## Contributing

1. Make changes in appropriate directories
2. Test with `./e2e_test.sh`
3. Update documentation as needed
4. Follow the sequential deployment process outlined in `deployment:sequence.md`

## License

This project is provided as-is for development purposes.