# DevDB Database Export PowerShell Script
# 
# This script automates the export of database metadata from SQL Server
# Usage: .\export_database.ps1 -ServerName "localhost" -DatabaseName "MyDB" -OutputPath ".\exported_db\"

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\exported_database\",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$WindowsAuth = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportData = $false
)

# Import SQL Server module if available
try {
    Import-Module SqlServer -ErrorAction Stop
    Write-Host "✅ SQL Server PowerShell module loaded" -ForegroundColor Green
} catch {
    Write-Host "⚠️  SQL Server PowerShell module not found. Falling back to sqlcmd." -ForegroundColor Yellow
    $UseSqlCmd = $true
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "📁 Created output directory: $OutputPath" -ForegroundColor Green
}

# Build connection string
if ($WindowsAuth) {
    $ConnectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=True;TrustServerCertificate=True;"
    $SqlCmdAuth = "-E"
} else {
    $ConnectionString = "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;TrustServerCertificate=True;"
    $SqlCmdAuth = "-U $Username -P $Password"
}

Write-Host "🚀 Starting database export for: $DatabaseName on $ServerName" -ForegroundColor Cyan
Write-Host "📂 Output directory: $OutputPath" -ForegroundColor Cyan

# Function to execute SQL script and save output
function Export-SqlScript {
    param(
        [string]$ScriptName,
        [string]$OutputFile,
        [string]$Description
    )
    
    Write-Host "🔄 Exporting $Description..." -ForegroundColor Yellow
    
    $ScriptPath = Join-Path $PSScriptRoot $ScriptName
    $OutputFilePath = Join-Path $OutputPath $OutputFile
    
    try {
        if ($UseSqlCmd) {
            # Use sqlcmd
            $command = "sqlcmd -S `"$ServerName`" -d `"$DatabaseName`" $SqlCmdAuth -i `"$ScriptPath`" -o `"$OutputFilePath`" -h -1 -W"
            Invoke-Expression $command
        } else {
            # Use SQL Server PowerShell module
            Invoke-Sqlcmd -ConnectionString $ConnectionString -InputFile $ScriptPath | Out-File -FilePath $OutputFilePath -Encoding UTF8
        }
        
        if (Test-Path $OutputFilePath) {
            $fileSize = (Get-Item $OutputFilePath).Length
            Write-Host "  ✅ $Description exported ($fileSize bytes)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Failed to export $Description" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Error exporting $Description`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Export database components
Export-SqlScript "export_database_schema.sql" "01_schema.sql" "Database Schema (Tables, Constraints, Indexes)"
Export-SqlScript "export_views.sql" "02_views.sql" "Views"
Export-SqlScript "export_functions.sql" "03_functions.sql" "Functions"
Export-SqlScript "export_procedures.sql" "04_procedures.sql" "Stored Procedures"
Export-SqlScript "export_triggers.sql" "05_triggers.sql" "Triggers"
Export-SqlScript "export_permissions.sql" "06_permissions.sql" "Permissions and Security"

if ($ExportData) {
    Write-Host "📊 Data export requested..." -ForegroundColor Cyan
    Export-SqlScript "export_data.sql" "07_data.sql" "Table Data"
}

# Create a master deployment script
$MasterScript = @"
/*
    DevDB Database Migration Script
    Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Source Database: $DatabaseName
    Source Server: $ServerName
*/

USE [DevDB];
GO

PRINT 'Starting database migration...';
PRINT 'Source: $DatabaseName on $ServerName';
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

$(if ($ExportData) { @"
-- Step 7: Import Data
PRINT 'Step 7: Importing data...';
:r 07_data.sql
"@ })

PRINT '';
PRINT 'Database migration completed successfully!';
PRINT 'Review the individual script files for any manual adjustments needed.';
"@

$MasterScriptPath = Join-Path $OutputPath "00_deploy_all.sql"
$MasterScript | Out-File -FilePath $MasterScriptPath -Encoding UTF8

# Create README file
$ReadmeContent = @"
# DevDB Database Export

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Source Database:** $DatabaseName
**Source Server:** $ServerName

## Files Generated

1. **00_deploy_all.sql** - Master deployment script that runs all components in order
2. **01_schema.sql** - Database schema (tables, constraints, indexes, foreign keys)
3. **02_views.sql** - All database views
4. **03_functions.sql** - User-defined functions (scalar, table-valued, inline)
5. **04_procedures.sql** - Stored procedures
6. **05_triggers.sql** - DML and DDL triggers
7. **06_permissions.sql** - Security roles, users, and permissions
$(if ($ExportData) { "8. **07_data.sql** - Table data (INSERT statements)" })

## Deployment Instructions

### Option 1: Use Master Script (Recommended)
``````bash
# Navigate to your DevDB project
cd your-devdb-project

# Start your DevDB environment
./devdb.sh up

# Deploy using the master script
./devdb.sh query -i $($OutputPath -replace '\\', '/')00_deploy_all.sql
``````

### Option 2: Deploy Individual Components
``````bash
# Deploy each component separately
./devdb.sh query -i $($OutputPath -replace '\\', '/')01_schema.sql
./devdb.sh query -i $($OutputPath -replace '\\', '/')02_views.sql
./devdb.sh query -i $($OutputPath -replace '\\', '/')03_functions.sql
./devdb.sh query -i $($OutputPath -replace '\\', '/')04_procedures.sql
./devdb.sh query -i $($OutputPath -replace '\\', '/')05_triggers.sql
./devdb.sh query -i $($OutputPath -replace '\\', '/')06_permissions.sql
$(if ($ExportData) { "./devdb.sh query -i $($OutputPath -replace '\\', '/')07_data.sql" })
``````

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
``````bash
./devdb.sh test all
``````
"@

$ReadmePath = Join-Path $OutputPath "README.md"
$ReadmeContent | Out-File -FilePath $ReadmePath -Encoding UTF8

Write-Host ""
Write-Host "🎉 Database export completed successfully!" -ForegroundColor Green
Write-Host "📁 Output location: $OutputPath" -ForegroundColor Cyan
Write-Host "📋 Files generated:" -ForegroundColor Cyan
Get-ChildItem $OutputPath | ForEach-Object { 
    $size = if ($_.Length -gt 1KB) { "{0:N1} KB" -f ($_.Length / 1KB) } else { "$($_.Length) bytes" }
    Write-Host "   📄 $($_.Name) ($size)" -ForegroundColor White
}
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Green
Write-Host "   1. Review the generated scripts" -ForegroundColor White
Write-Host "   2. Copy the exported folder to your DevDB project" -ForegroundColor White
Write-Host "   3. Run: ./devdb.sh query -i exported_database/00_deploy_all.sql" -ForegroundColor White
Write-Host "   4. Test: ./devdb.sh test all" -ForegroundColor White