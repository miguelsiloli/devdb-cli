/*
    DevDB Stored Procedures Export Utility
    
    Exports all stored procedures from the database with their complete definitions
    
    Usage: Run this script against your source database to export all stored procedures
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Stored Procedures Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- Export all stored procedures
SELECT 
    '-- Stored Procedure: [' + s.name + '].[' + p.name + ']' + CHAR(13) +
    'IF OBJECT_ID(''[' + s.name + '].[' + p.name + ']'', ''P'') IS NOT NULL' + CHAR(13) +
    '    DROP PROCEDURE [' + s.name + '].[' + p.name + '];' + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13) +
    m.definition + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13)
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
INNER JOIN sys.sql_modules m ON p.object_id = m.object_id
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND p.is_ms_shipped = 0
ORDER BY s.name, p.name;

PRINT '-- =================================================='
PRINT '-- END OF STORED PROCEDURES EXPORT'
PRINT '-- =================================================='