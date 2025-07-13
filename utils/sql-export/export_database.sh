#!/bin/bash
# DevDB Database Export Bash Script
#
# This script automates the export of database metadata from SQL Server using sqlcmd
# Usage: ./export_database.sh -s "localhost" -d "MyDB" -o "./exported_db/" [-u username] [-p password] [-w] [-data]

# Default values
SERVER_NAME=""
DATABASE_NAME=""
OUTPUT_PATH="./exported_database/"
USERNAME=""
PASSWORD=""
WINDOWS_AUTH=true
EXPORT_DATA=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "DevDB Database Export Script"
    echo ""
    echo "Usage: $0 -s SERVER -d DATABASE [OPTIONS]"
    echo ""
    echo "Required parameters:"
    echo "  -s, --server       SQL Server name or IP address"
    echo "  -d, --database     Database name to export"
    echo ""
    echo "Optional parameters:"
    echo "  -o, --output       Output directory (default: ./exported_database/)"
    echo "  -u, --username     SQL Server username (for SQL authentication)"
    echo "  -p, --password     SQL Server password (for SQL authentication)"
    echo "  -w, --windows-auth Use Windows authentication (default: true)"
    echo "  --sql-auth         Use SQL Server authentication"
    echo "  --export-data      Include table data in export"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Windows Authentication (default)"
    echo "  $0 -s localhost -d MyDatabase"
    echo ""
    echo "  # SQL Server Authentication"
    echo "  $0 -s localhost -d MyDatabase --sql-auth -u sa -p MyPassword"
    echo ""
    echo "  # Include data export"
    echo "  $0 -s localhost -d MyDatabase --export-data"
    echo ""
    echo "  # Custom output directory"
    echo "  $0 -s localhost -d MyDatabase -o /tmp/db_export/"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SERVER_NAME="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            WINDOWS_AUTH=false
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            WINDOWS_AUTH=false
            shift 2
            ;;
        -w|--windows-auth)
            WINDOWS_AUTH=true
            shift
            ;;
        --sql-auth)
            WINDOWS_AUTH=false
            shift
            ;;
        --export-data)
            EXPORT_DATA=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown parameter: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SERVER_NAME" || -z "$DATABASE_NAME" ]]; then
    echo -e "${RED}❌ Error: Server name and database name are required${NC}"
    show_usage
    exit 1
fi

# Check if sqlcmd is available
if ! command -v sqlcmd &> /dev/null; then
    echo -e "${RED}❌ Error: sqlcmd is not installed or not in PATH${NC}"
    echo "Please install SQL Server command line tools"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_PATH"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}📁 Created output directory: $OUTPUT_PATH${NC}"
else
    echo -e "${RED}❌ Failed to create output directory: $OUTPUT_PATH${NC}"
    exit 1
fi

# Build authentication parameters
if [[ "$WINDOWS_AUTH" == true ]]; then
    AUTH_PARAMS="-E"
    AUTH_DESC="Windows Authentication"
else
    if [[ -z "$USERNAME" ]]; then
        echo -e "${RED}❌ Error: Username required for SQL Server authentication${NC}"
        exit 1
    fi
    AUTH_PARAMS="-U \"$USERNAME\""
    if [[ -n "$PASSWORD" ]]; then
        AUTH_PARAMS="$AUTH_PARAMS -P \"$PASSWORD\""
    fi
    AUTH_DESC="SQL Server Authentication (User: $USERNAME)"
fi

echo -e "${CYAN}🚀 Starting database export${NC}"
echo -e "${CYAN}📊 Database: $DATABASE_NAME${NC}"
echo -e "${CYAN}🖥️  Server: $SERVER_NAME${NC}"
echo -e "${CYAN}🔐 Authentication: $AUTH_DESC${NC}"
echo -e "${CYAN}📂 Output: $OUTPUT_PATH${NC}"
echo ""

# Function to execute SQL script and save output
export_sql_script() {
    local script_name="$1"
    local output_file="$2"
    local description="$3"
    
    echo -e "${YELLOW}🔄 Exporting $description...${NC}"
    
    local script_dir="$(dirname "$0")"
    local script_path="$script_dir/$script_name"
    local output_path="$OUTPUT_PATH/$output_file"
    
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}  ❌ Script not found: $script_path${NC}"
        return 1
    fi
    
    # Execute sqlcmd
    local cmd="sqlcmd -S \"$SERVER_NAME\" -d \"$DATABASE_NAME\" $AUTH_PARAMS -i \"$script_path\" -o \"$output_path\" -h -1 -W"
    eval $cmd
    
    if [[ $? -eq 0 && -f "$output_path" ]]; then
        local file_size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}  ✅ $description exported ($file_size bytes)${NC}"
        return 0
    else
        echo -e "${RED}  ❌ Failed to export $description${NC}"
        return 1
    fi
}

# Export database components
export_sql_script "export_database_schema.sql" "01_schema.sql" "Database Schema (Tables, Constraints, Indexes)"
export_sql_script "export_views.sql" "02_views.sql" "Views"
export_sql_script "export_functions.sql" "03_functions.sql" "Functions"
export_sql_script "export_procedures.sql" "04_procedures.sql" "Stored Procedures"
export_sql_script "export_triggers.sql" "05_triggers.sql" "Triggers"
export_sql_script "export_permissions.sql" "06_permissions.sql" "Permissions and Security"

if [[ "$EXPORT_DATA" == true ]]; then
    echo -e "${CYAN}📊 Data export requested...${NC}"
    export_sql_script "export_data.sql" "07_data.sql" "Table Data"
fi

# Create master deployment script
echo -e "${YELLOW}🔄 Creating master deployment script...${NC}"

cat > "$OUTPUT_PATH/00_deploy_all.sql" << EOF
/*
    DevDB Database Migration Script
    Generated: $(date '+%Y-%m-%d %H:%M:%S')
    Source Database: $DATABASE_NAME
    Source Server: $SERVER_NAME
*/

USE [DevDB];
GO

PRINT 'Starting database migration...';
PRINT 'Source: $DATABASE_NAME on $SERVER_NAME';
PRINT 'Target: DevDB Docker Environment';
PRINT '';

-- Step 1: Create Schema (Tables, Constraints, Indexes)
PRINT 'Step 1: Creating database schema...';
:r 01_schema.sql

-- Step 2: Create Views
PRINT 'Step 2: Creating views...';
:r 02_views.sql

-- Step 3: Create Functions
PRINT 'Step 3: Creating functions...';
:r 03_functions.sql

-- Step 4: Create Stored Procedures
PRINT 'Step 4: Creating stored procedures...';
:r 04_procedures.sql

-- Step 5: Create Triggers
PRINT 'Step 5: Creating triggers...';
:r 05_triggers.sql

-- Step 6: Apply Permissions
PRINT 'Step 6: Applying permissions...';
:r 06_permissions.sql

$(if [[ "$EXPORT_DATA" == true ]]; then
echo "-- Step 7: Import Data"
echo "PRINT 'Step 7: Importing data...';"
echo ":r 07_data.sql"
fi)

PRINT '';
PRINT 'Database migration completed successfully!';
PRINT 'Review the individual script files for any manual adjustments needed.';
EOF

# Create README file
cat > "$OUTPUT_PATH/README.md" << EOF
# DevDB Database Export

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Source Database:** $DATABASE_NAME
**Source Server:** $SERVER_NAME

## Files Generated

1. **00_deploy_all.sql** - Master deployment script that runs all components in order
2. **01_schema.sql** - Database schema (tables, constraints, indexes, foreign keys)
3. **02_views.sql** - All database views
4. **03_functions.sql** - User-defined functions (scalar, table-valued, inline)
5. **04_procedures.sql** - Stored procedures
6. **05_triggers.sql** - DML and DDL triggers
7. **06_permissions.sql** - Security roles, users, and permissions
$(if [[ "$EXPORT_DATA" == true ]]; then echo "8. **07_data.sql** - Table data (INSERT statements)"; fi)

## Deployment Instructions

### Option 1: Use Master Script (Recommended)
\`\`\`bash
# Navigate to your DevDB project
cd your-devdb-project

# Start your DevDB environment
./devdb.sh up

# Deploy using the master script
./devdb.sh query -i ${OUTPUT_PATH}00_deploy_all.sql
\`\`\`

### Option 2: Deploy Individual Components
\`\`\`bash
# Deploy each component separately
./devdb.sh query -i ${OUTPUT_PATH}01_schema.sql
./devdb.sh query -i ${OUTPUT_PATH}02_views.sql
./devdb.sh query -i ${OUTPUT_PATH}03_functions.sql
./devdb.sh query -i ${OUTPUT_PATH}04_procedures.sql
./devdb.sh query -i ${OUTPUT_PATH}05_triggers.sql
./devdb.sh query -i ${OUTPUT_PATH}06_permissions.sql
$(if [[ "$EXPORT_DATA" == true ]]; then echo "./devdb.sh query -i ${OUTPUT_PATH}07_data.sql"; fi)
\`\`\`

### Option 3: Use SQL Server Management Studio
1. Connect to your DevDB Docker instance (localhost:1433)
2. Open and execute scripts in the order above
3. Review any error messages and adjust as needed

## Notes

- Review each script before deployment
- Some permissions may need manual adjustment for the Docker environment
- Large data exports may need to be split into smaller batches
- Consider using the DevDB polish command to improve SQL formatting

## Testing

After deployment, run your DevDB tests:
\`\`\`bash
./devdb.sh test all
\`\`\`
EOF

echo ""
echo -e "${GREEN}🎉 Database export completed successfully!${NC}"
echo -e "${CYAN}📁 Output location: $OUTPUT_PATH${NC}"
echo -e "${CYAN}📋 Files generated:${NC}"

# List generated files with sizes
for file in "$OUTPUT_PATH"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        if [[ "$size" != "unknown" && "$size" -gt 1024 ]]; then
            size_display="$(echo "scale=1; $size/1024" | bc 2>/dev/null || echo "$size")KB"
        else
            size_display="${size} bytes"
        fi
        echo -e "${WHITE}   📄 $filename ($size_display)${NC}"
    fi
done

echo ""
echo -e "${GREEN}🚀 Next steps:${NC}"
echo -e "${WHITE}   1. Review the generated scripts${NC}"
echo -e "${WHITE}   2. Copy the exported folder to your DevDB project${NC}"
echo -e "${WHITE}   3. Run: ./devdb.sh query -i exported_database/00_deploy_all.sql${NC}"
echo -e "${WHITE}   4. Test: ./devdb.sh test all${NC}"