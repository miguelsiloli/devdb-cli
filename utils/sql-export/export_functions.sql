/*
    DevDB Functions Export Utility
    
    Exports all user-defined functions from the database
    Includes scalar functions, table-valued functions, and inline table-valued functions
    
    Usage: Run this script against your source database to export all functions
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Functions Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- Export all user-defined functions
SELECT 
    '-- Function: [' + s.name + '].[' + f.name + '] (' + 
    CASE f.type
        WHEN 'FN' THEN 'Scalar Function'
        WHEN 'IF' THEN 'Inline Table-Valued Function'
        WHEN 'TF' THEN 'Table-Valued Function'
        WHEN 'FS' THEN 'Assembly Scalar Function'
        WHEN 'FT' THEN 'Assembly Table-Valued Function'
        ELSE 'Unknown Function Type'
    END + ')' + CHAR(13) +
    'IF OBJECT_ID(''[' + s.name + '].[' + f.name + ']'', ''' + f.type + ''') IS NOT NULL' + CHAR(13) +
    '    DROP FUNCTION [' + s.name + '].[' + f.name + '];' + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13) +
    m.definition + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13)
FROM sys.objects f
INNER JOIN sys.schemas s ON f.schema_id = s.schema_id
INNER JOIN sys.sql_modules m ON f.object_id = m.object_id
WHERE f.type IN ('FN', 'IF', 'TF', 'FS', 'FT')  -- All function types
  AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND f.is_ms_shipped = 0
ORDER BY s.name, f.name;

PRINT '-- =================================================='
PRINT '-- END OF FUNCTIONS EXPORT'
PRINT '-- =================================================='