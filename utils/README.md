# DevDB Utilities

This directory contains utility scripts to help with database migration and management tasks for DevDB projects.

## 📁 Directory Structure

```
utils/
└── sql-export/
    ├── export_database_schema.sql    # Schema export (tables, constraints, indexes)
    ├── export_views.sql              # Views export
    ├── export_procedures.sql         # Stored procedures export
    ├── export_functions.sql          # Functions export
    ├── export_triggers.sql           # Triggers export
    ├── export_data.sql               # Data export (INSERT statements)
    ├── export_permissions.sql        # Security and permissions export
    ├── export_database.ps1           # PowerShell automation script
    ├── export_database.sh            # Bash automation script
    └── README.md                     # This file
```

## 🚀 Quick Start

### Option 1: Automated Export (PowerShell - Windows)
```powershell
# Windows Authentication
.\utils\sql-export\export_database.ps1 -ServerName "localhost" -DatabaseName "MyDB" -OutputPath ".\exported_db\"

# SQL Server Authentication
.\utils\sql-export\export_database.ps1 -ServerName "localhost" -DatabaseName "MyDB" -Username "sa" -Password "MyPassword" -WindowsAuth:$false

# Include data export
.\utils\sql-export\export_database.ps1 -ServerName "localhost" -DatabaseName "MyDB" -ExportData
```

### Option 2: Automated Export (Bash - Linux/macOS)
```bash
# Windows Authentication (if running on Windows with WSL)
./utils/sql-export/export_database.sh -s "localhost" -d "MyDB" -o "./exported_db/"

# SQL Server Authentication
./utils/sql-export/export_database.sh -s "localhost" -d "MyDB" --sql-auth -u "sa" -p "MyPassword"

# Include data export
./utils/sql-export/export_database.sh -s "localhost" -d "MyDB" --export-data
```

### Option 3: Manual Export (SQL Scripts)
Run each SQL script individually against your source database in SQL Server Management Studio or using sqlcmd:

```sql
-- 1. Export schema
sqlcmd -S "localhost" -d "MyDB" -E -i "utils/sql-export/export_database_schema.sql" -o "schema.sql"

-- 2. Export views
sqlcmd -S "localhost" -d "MyDB" -E -i "utils/sql-export/export_views.sql" -o "views.sql"

-- 3. Export procedures
sqlcmd -S "localhost" -d "MyDB" -E -i "utils/sql-export/export_procedures.sql" -o "procedures.sql"

-- And so on...
```

## 📋 Export Components

### 1. Database Schema (`export_database_schema.sql`)
Exports complete database structure including:
- **User-defined data types**
- **Tables** with columns, data types, constraints
- **Primary keys** and clustered indexes
- **Foreign key relationships** with cascade options
- **Indexes** (clustered, non-clustered, unique, with included columns)

### 2. Views (`export_views.sql`)
- All user-defined views with complete definitions
- Includes DROP/CREATE statements for clean deployment
- Schema-qualified names

### 3. Stored Procedures (`export_procedures.sql`)
- All user-defined stored procedures
- Complete procedure definitions with parameters
- DROP/CREATE pattern for safe deployment

### 4. Functions (`export_functions.sql`)
- **Scalar functions** (return single value)
- **Table-valued functions** (return table)
- **Inline table-valued functions**
- Complete function definitions with parameters and return types

### 5. Triggers (`export_triggers.sql`)
- **DML triggers** (table-level: INSERT, UPDATE, DELETE)
- **DDL triggers** (database-level: CREATE, ALTER, DROP)
- Trigger event details and configuration
- INSTEAD OF triggers for views

### 6. Data (`export_data.sql`)
- **INSERT statements** for all table data
- Handles various data types (text, numbers, dates, binary)
- NULL value handling
- Proper string escaping for SQL injection prevention

### 7. Permissions (`export_permissions.sql`)
- **Database users** and their authentication types
- **Custom database roles**
- **Role memberships**
- **Object-level permissions** (tables, views, procedures)
- **Schema permissions** and ownership

## 🎯 Usage Scenarios

### Scenario 1: Migrate Existing Database to DevDB
1. **Export your existing database:**
   ```bash
   ./utils/sql-export/export_database.sh -s "prod-server" -d "ProductionDB" -o "./prod_export/"
   ```

2. **Create new DevDB project:**
   ```bash
   ./devdb init migrated-prod-db --template advanced
   cd migrated-prod-db
   ```

3. **Start DevDB environment:**
   ```bash
   ./devdb.sh up
   ```

4. **Deploy exported database:**
   ```bash
   ./devdb.sh query -i ../prod_export/00_deploy_all.sql
   ```

5. **Test the migration:**
   ```bash
   ./devdb.sh test all
   ```

### Scenario 2: Development Database Sync
Keep your DevDB environment in sync with development database changes:

```bash
# Weekly sync from dev database
./utils/sql-export/export_database.sh -s "dev-server" -d "DevDatabase" -o "./dev_sync/"

# Apply changes to DevDB
./devdb.sh query -i dev_sync/00_deploy_all.sql
```

### Scenario 3: Schema-Only Migration
For cases where you only need the structure without data:

```bash
# Export without data
./utils/sql-export/export_database.sh -s "source-server" -d "SourceDB" -o "./schema_only/"

# The scripts will include everything except data
```

## 🔧 Advanced Usage

### Custom Export Filtering
Modify the SQL scripts to filter specific objects:

```sql
-- In export_database_schema.sql, add WHERE clause to filter tables:
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA') 
  AND t.name NOT LIKE 'temp_%'  -- Exclude temporary tables
```

### Large Database Optimization
For large databases, consider:

1. **Export schema first, then data separately**
2. **Use BCP for large data exports** instead of INSERT statements
3. **Split data export by table** or date ranges
4. **Use SQLCMD variables** for parameterized exports

### Integration with CI/CD
```bash
# Example CI/CD pipeline step
./utils/sql-export/export_database.sh \
  -s "$DB_SERVER" \
  -d "$DB_NAME" \
  --sql-auth \
  -u "$DB_USER" \
  -p "$DB_PASSWORD" \
  -o "./db_backup_$(date +%Y%m%d)/"
```

## 🛠️ Prerequisites

### For PowerShell Script
- **PowerShell 5.1+** or **PowerShell Core 6+**
- **SQL Server PowerShell Module** (optional, falls back to sqlcmd)
- **sqlcmd** (SQL Server Command Line Tools)

### For Bash Script
- **Bash 4.0+**
- **sqlcmd** (SQL Server Command Line Tools)
- **bc** command (for file size calculations)

### Installing SQL Server Command Line Tools

**Windows:**
- Download from Microsoft SQL Server Tools
- Or install via package manager: `winget install Microsoft.SQLServerCommandLineUtilities`

**Linux (Ubuntu/Debian):**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev
```

**macOS:**
```bash
brew install mssql-tools
```

## 📝 Output Format

The export scripts generate a structured output directory:

```
exported_database/
├── 00_deploy_all.sql          # Master deployment script
├── 01_schema.sql              # Database schema
├── 02_views.sql               # Views
├── 03_functions.sql           # Functions  
├── 04_procedures.sql          # Stored procedures
├── 05_triggers.sql            # Triggers
├── 06_permissions.sql         # Security/permissions
├── 07_data.sql               # Data (if --export-data used)
└── README.md                 # Deployment instructions
```

## ⚠️ Important Notes

### Security Considerations
- **Review exported permissions** before deployment
- **Remove or modify sensitive data** from data exports
- **Use environment variables** for credentials in CI/CD
- **Avoid hardcoding passwords** in scripts

### Compatibility
- Scripts are designed for **SQL Server 2016+**
- Some features may need adjustment for older versions
- **Always test exports** in a development environment first

### Limitations
- **Does not export:** Full-text indexes, XML schemas, certificates, asymmetric keys
- **Large binary data** may cause performance issues in INSERT statements
- **Cross-database references** need manual adjustment
- **Linked server definitions** are not included

## 🔍 Troubleshooting

### Common Issues

**"sqlcmd not found"**
- Install SQL Server Command Line Tools
- Add sqlcmd to your system PATH

**Authentication failed**
- Verify server name and credentials
- Check if SQL Server allows remote connections
- Ensure correct authentication mode (Windows vs SQL)

**Permission denied errors**
- Run with appropriate database permissions
- User needs db_datareader, db_ddladmin permissions minimum

**Large export timeouts**
- Increase sqlcmd timeout: add `-t 0` parameter
- Split large data exports into smaller chunks
- Use BCP for large data volumes

### Getting Help

```bash
# Show help for bash script
./utils/sql-export/export_database.sh --help

# Show help for PowerShell script
Get-Help .\utils\sql-export\export_database.ps1 -Full
```

## 🤝 Contributing

To add new export functionality:

1. Create new `.sql` script in `sql-export/` directory
2. Add export function to automation scripts
3. Update README with new component description
4. Test with various database configurations

---

**Happy Database Migration!** 🎉

These utilities make it easy to migrate existing SQL Server databases into your DevDB Docker development environment.