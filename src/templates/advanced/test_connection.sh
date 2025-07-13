#!/bin/bash
# Simple connection test script

set -e

# Load environment variables
source .devdb/.env

echo "Testing SQL Server connection..."

# Test direct connection
if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1 AS TestConnection" -C -l 5; then
    echo "✅ SUCCESS: Database connection working!"
    
    # Test basic query
    echo "Testing basic query..."
    if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT @@VERSION" -C -l 5; then
        echo "✅ SUCCESS: Basic query working!"
    else
        echo "❌ FAILED: Basic query failed"
        exit 1
    fi
    
    # Test schema initialization
    echo "Testing schema initialization..."
    if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -i "/docker-entrypoint-initdb.d/01_tables.sql" -C -l 30; then
        echo "✅ SUCCESS: Schema initialization working!"
    else
        echo "❌ FAILED: Schema initialization failed"
        exit 1
    fi
    
else
    echo "❌ FAILED: Cannot connect to database"
    exit 1
fi

echo "🎉 All tests passed! Database is working correctly."