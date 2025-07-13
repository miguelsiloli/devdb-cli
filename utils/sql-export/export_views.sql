/*
    DevDB Views Export Utility
    
    Exports all views from the database with their complete definitions
    
    Usage: Run this script against your source database to export all views
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Views Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- Export all views
SELECT 
    '-- View: [' + s.name + '].[' + v.name + ']' + CHAR(13) +
    'IF OBJECT_ID(''[' + s.name + '].[' + v.name + ']'', ''V'') IS NOT NULL' + CHAR(13) +
    '    DROP VIEW [' + s.name + '].[' + v.name + '];' + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13) +
    m.definition + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13)
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
INNER JOIN sys.sql_modules m ON v.object_id = m.object_id
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY s.name, v.name;

PRINT '-- =================================================='
PRINT '-- END OF VIEWS EXPORT'
PRINT '-- =================================================='