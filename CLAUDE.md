# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DevDB is an automated development database deployment system that provides a one-command solution to deploy fresh, containerized SQL Server databases for local development. The system ensures consistent, clean, and fast environments for all team members.

## Key Commands

### Core Environment Management
- `./devdb.sh up` - Starts SQL Server and Web GUI containers, builds database from schemas/ on first run
- `./devdb.sh down` - Stops and removes all containers and network
- `./devdb.sh reset` - Complete environment reset (down then up) for clean slate
- `./devdb.sh status` - Shows current container status

### Testing and Queries
- `./devdb.sh test all` - Executes all .sql files in ./tests directory, stops on first failure
- `./devdb.sh test <filename.sql>` - Executes specific test file from ./tests directory
- `./devdb.sh query "<SQL>"` - Executes ad-hoc SQL query directly against database
- `./devdb.sh schema` - Re-initializes database schemas from ./schemas directory

### End-to-End Testing
- `./e2e_test.sh` - Runs complete validation suite including cold start, schema deployment, user scripts, and test validation

## Architecture

The system uses Docker Compose to orchestrate two services:
- **SQL Server (devdb-sqlserver)**: Microsoft SQL Server 2022 container with automatic schema initialization
- **Web GUI (devdb-gui)**: Adminer web interface for database management

### Key Components

1. **Control Script (`devdb.sh`)**: Bash script providing unified CLI interface
2. **Docker Compose (`/.devdb/docker-compose.yml`)**: Service definitions and networking
3. **Environment Config (`/.devdb/.env`)**: Database passwords and port configuration (not in git)
4. **Schema Files (`/schemas/*.sql`)**: Database objects executed in alphabetical order
5. **Test Files (`/tests/*.sql`)**: SQL test scripts with error handling

### Database Structure

The system creates a `DevDB` database with:
- **Tables**: Users, Products (defined in schemas/01_tables.sql)
- **Views**: PricedProducts, UserStats, ProductAnalytics
- **Functions**: CalculateUserAge, GetActiveProducts, FormatProductName
- **Stored Procedures**: AddNewUser, ManageProductInventory, CreateUserWithValidation

## Development Workflow

1. **Initial Setup**: Clone repo, configure .env file, make scripts executable
2. **Start Environment**: `./devdb.sh up` (downloads images and initializes DB on first run)
3. **Make Schema Changes**: Edit files in schemas/ directory
4. **Apply Changes**: `./devdb.sh reset` (destroys and recreates database)
5. **Run Tests**: `./devdb.sh test all` to validate changes
6. **Iterate**: Continue development with clean, consistent state

## Connection Details

- **SQL Server**: localhost:1433 (or DB_PORT from .env), user: sa, password: from .env
- **Web GUI**: http://localhost:8081 (or GUI_PORT from .env)

## Important Notes

- Schema files in `schemas/` are executed in alphabetical order during container initialization
- Test files should use `THROW` statements for failures to ensure proper exit codes
- The `.devdb/.env` file is required but excluded from git - copy from `.env.example`
- All containers run on isolated `devdb-net` Docker network
- System designed for development use only, not production deployment

## tSQLt Integration (Future Phase)

The project documentation indicates plans for Phase 2 integration with tSQLt testing framework, which would replace current ad-hoc testing with structured unit tests, transaction isolation, and XML output for CI/CD integration.

## Prerequisites

- Docker (Docker Desktop on Windows/macOS, Docker Engine on Linux)
- Git for repository cloning
- Bash-compatible shell for script execution