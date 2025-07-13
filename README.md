# DevDB CLI - SQL Server Development Database Scaffolding Tool

DevDB CLI is a command-line tool that creates complete SQL Server development environments with a single command, similar to `airflow init`. It generates professional project scaffolding with Docker Compose, testing frameworks, AI-powered tools, and comprehensive documentation.

## 🚀 Quick Start

```bash
# Using the direct CLI script (development mode)
./devdb init my-awesome-project

# Create a basic project without AI tools
./devdb init my-basic-project --template basic

# Create project in specific directory
./devdb init my-project --path ~/projects

# Force overwrite existing directory
./devdb init my-project --force
```

## 📋 Prerequisites

- **Python 3.7+** with `sqlparse` package
- **Docker** (Docker Desktop or Docker Engine)
- **Git** (for author information detection)
- **Bash-compatible shell** (Linux, macOS, WSL on Windows)

## 🛠️ Installation

### Option 1: Direct Usage (Development Mode)
```bash
git clone https://github.com/miguelsiloli/devdb-cli.git
cd sql_server_dev
./devdb init my-project
```

### Option 2: Development Installation
```bash
git clone https://github.com/miguelsiloli/devdb-cli.git
cd sql_server_dev
pip install -e .
devdb init my-project
```

### Option 3: Build and Install from Source
```bash
git clone https://github.com/miguelsiloli/devdb-cli.git
cd sql_server_dev
./build.sh
pip install dist/devdb-cli-1.0.0.tar.gz
devdb init my-project
```

### Option 4: Direct Python Module (Alternative)
```bash
python3 src/cli.py init my-project
```

## 📖 Command Reference

### `devdb init`

Creates a new DevDB project with complete scaffolding.

```bash
devdb init [PROJECT_NAME] [OPTIONS]
```

**Arguments:**
- `PROJECT_NAME` - Name of the project directory (default: `devdb-project`)

**Options:**
- `--path, -p PATH` - Parent directory for the project (default: current directory)
- `--template, -t TEMPLATE` - Project template: `basic` or `advanced` (default: `advanced`)
- `--force, -f` - Overwrite existing directory if it exists

**Examples:**
```bash
# Basic usage (using direct script)
./devdb init my-database-project

# Advanced template with custom path
./devdb init ecommerce-db --path ~/projects --template advanced

# Basic template for simple projects
./devdb init simple-db --template basic

# Force overwrite existing directory
./devdb init existing-project --force

# After pip installation
devdb init my-project --template advanced
```

### `devdb version`

Shows the current version of DevDB CLI.

```bash
devdb version
```

## 🎯 Project Templates

### Advanced Template (Default)
Perfect for professional development with AI-powered tools:

- ✅ Complete Docker Compose setup (SQL Server 2022 + Adminer)
- ✅ Professional SQL schema files with examples
- ✅ tSQLt testing framework integration
- ✅ AI-powered SQL code polishing with Gemini
- ✅ Comprehensive documentation generation
- ✅ Professional SQL headers with change tracking
- ✅ Full control script with 8+ commands
- ✅ End-to-end testing pipeline

### Basic Template
Ideal for simple projects or teams without AI integration:

- ✅ Core Docker Compose setup
- ✅ Essential SQL schema files
- ✅ tSQLt testing framework
- ✅ Basic documentation
- ✅ Control script with core commands
- ❌ No AI tools (code polishing, docs generation)

## 📁 Generated Project Structure

```
my-project/
├── .devdb/
│   ├── docker-compose.yml      # Container orchestration
│   ├── .env                    # Environment configuration (generated)
│   ├── .env.example           # Environment template
│   ├── scripts/               # AI tools (advanced template only)
│   │   └── code_polisher.py   # SQL formatting with Gemini AI
│   └── tSQLt/                 # Testing framework files
├── schemas/
│   ├── 01_tables.sql          # Database tables
│   ├── 02_sprocs_and_views.sql # Procedures and views
│   ├── 03_functions.sql       # User-defined functions
│   ├── 04_advanced_views.sql  # Complex views
│   ├── 05_stored_procedures.sql # Additional procedures
│   └── 99_install_tsqlt.sql   # Testing framework setup
├── tests/
│   ├── test_functions.sql     # Function tests
│   ├── test_stored_procedures.sql # Procedure tests
│   ├── test_views.sql         # View tests
│   ├── test_user_creation.sql # User management tests
│   └── test_product_stock_fail.sql # Example failure test
├── output/
│   ├── prod_scripts/          # Polished SQL output
│   └── docs/                  # Generated documentation
├── devdb.sh                   # Main control script
├── e2e_test.sh               # End-to-end testing
├── test_connection.sh        # Connection verification
├── .gitignore                # Git ignore rules
├── README.md                 # Project documentation
└── CLAUDE.md                 # Claude Code instructions
```

## 🎮 Using Your Generated Project

After creating a project, navigate to it and start developing:

```bash
cd my-project

# Start the development environment
./devdb.sh up

# Run all tests
./devdb.sh test all

# Execute a specific test
./devdb.sh test test_functions.sql

# Run an ad-hoc SQL query
./devdb.sh query "SELECT * FROM Users"

# Polish SQL files with AI (advanced template)
./devdb.sh polish tests/my_script.sql

# Reset environment (clean slate)
./devdb.sh reset

# Stop everything
./devdb.sh down
```

## 🔧 Configuration

### Environment Variables

The generated `.devdb/.env` file contains:

```bash
# SQL Server Configuration
SA_PASSWORD=<auto-generated-strong-password>
DB_PORT=1433
GUI_PORT=8081

# AI Integration (advanced template)
GEMINI_API_KEY=your-gemini-api-key-here
AUTHOR_NAME="Your Name"

# Output Directories
POLISH_OUTPUT_DIR=output/prod_scripts
DOCS_OUTPUT_DIR=output/docs
```

### Customization

1. **Database Configuration**: Edit `.devdb/.env` to change ports, passwords
2. **AI Integration**: Add your Gemini API key for SQL polishing features
3. **Schema Files**: Modify files in `schemas/` directory
4. **Tests**: Add new test files to `tests/` directory
5. **Documentation**: Update `README.md` and `CLAUDE.md` as needed

## 🌐 Access Points

After running `./devdb.sh up`:

- **SQL Server**: `localhost:1433` (user: `sa`, password: from `.env`)
- **Web GUI**: `http://localhost:8081` (Adminer database management)

## 🧪 Testing

The generated projects include comprehensive testing:

- **Unit Tests**: tSQLt framework for isolated SQL testing
- **Integration Tests**: End-to-end validation with `e2e_test.sh`
- **Connection Tests**: Basic connectivity verification
- **CI/CD Ready**: Structured for automated testing pipelines

## 🤖 AI Features (Advanced Template)

### SQL Code Polishing
```bash
# Polish a single file
./devdb.sh polish tests/my_script.sql

# Polish all files in a directory
./devdb.sh polish schemas/
```

Features:
- Professional SQL header generation with change history
- Intelligent code formatting with `sqlparse`
- Gemini AI-powered code optimization
- Automatic documentation updates

### Professional Headers
Generated SQL files include standardized headers:

```sql
/***************************************************************************************************
Procedure:          GetUserAnalytics
Create Date:        2025-07-10
Author:             John Doe <john@company.com>
Description:        Retrieves comprehensive user analytics including activity metrics,
                   purchase history, and engagement scores for business intelligence reporting.
Call by:            [Leave empty for now]
Affected table(s):  Users, Orders, UserActivity
Used By:            [Leave empty for now]
Parameter(s):       @StartDate DATETIME - Analysis start date
                   @EndDate DATETIME - Analysis end date
Usage:              EXEC GetUserAnalytics '2025-01-01', '2025-12-31'
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2025-07-10          John Doe            Initial creation and implementation.
***************************************************************************************************/
```

## 🚨 Troubleshooting

### Common Issues

**Docker not running:**
```bash
# Start Docker Desktop or Docker service
sudo systemctl start docker  # Linux
```

**Port conflicts:**
```bash
# Change ports in .devdb/.env
DB_PORT=1434
GUI_PORT=8082
```

**Permission errors:**
```bash
# Make scripts executable
chmod +x devdb.sh e2e_test.sh test_connection.sh
```

**Missing Python packages:**
```bash
# Install required packages
pip install sqlparse google-genai
```

## 🔮 Future Features

- **Migration Tools**: Schema versioning and upgrade scripts
- **Plugin System**: Custom template and tool integration
