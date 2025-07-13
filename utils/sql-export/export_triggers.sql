/*
    DevDB Triggers Export Utility
    
    Exports all triggers from the database including:
    - Table triggers (DML)
    - Database triggers (DDL)
    - Server triggers
    
    Usage: Run this script against your source database to export all triggers
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Triggers Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- Export DML Triggers (Table Triggers)
PRINT '-- =================================================='
PRINT '-- DML TRIGGERS (Table Triggers)'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- Trigger: [' + s.name + '].[' + tr.name + '] on [' + s.name + '].[' + t.name + ']' + CHAR(13) +
    'IF OBJECT_ID(''[' + s.name + '].[' + tr.name + ']'', ''TR'') IS NOT NULL' + CHAR(13) +
    '    DROP TRIGGER [' + s.name + '].[' + tr.name + '];' + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13) +
    m.definition + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13)
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.sql_modules m ON tr.object_id = m.object_id
WHERE tr.parent_class = 1  -- Object (table) triggers
  AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND tr.is_ms_shipped = 0
ORDER BY s.name, t.name, tr.name;

-- Export DDL Triggers (Database Level)
PRINT '-- =================================================='
PRINT '-- DDL TRIGGERS (Database Level)'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- DDL Trigger: [' + tr.name + ']' + CHAR(13) +
    'IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = ''' + tr.name + ''' AND parent_class = 0)' + CHAR(13) +
    '    DROP TRIGGER [' + tr.name + '] ON DATABASE;' + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13) +
    m.definition + CHAR(13) +
    'GO' + CHAR(13) + CHAR(13)
FROM sys.triggers tr
INNER JOIN sys.sql_modules m ON tr.object_id = m.object_id
WHERE tr.parent_class = 0  -- Database triggers
  AND tr.is_ms_shipped = 0
ORDER BY tr.name;

-- Show trigger details for reference
PRINT '-- =================================================='
PRINT '-- TRIGGER DETAILS REFERENCE'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- Table Trigger Details:' + CHAR(13) +
    '-- Trigger: [' + s.name + '].[' + tr.name + ']' + CHAR(13) +
    '-- Table: [' + s.name + '].[' + t.name + ']' + CHAR(13) +
    '-- Type: ' + tr.type_desc + CHAR(13) +
    '-- Events: ' + 
    STUFF((
        SELECT ', ' + te.type_desc
        FROM sys.trigger_events te
        WHERE te.object_id = tr.object_id
        ORDER BY te.type
        FOR XML PATH('')
    ), 1, 2, '') + CHAR(13) +
    '-- Is Disabled: ' + CASE WHEN tr.is_disabled = 1 THEN 'YES' ELSE 'NO' END + CHAR(13) +
    '-- Instead Of: ' + CASE WHEN tr.is_instead_of_trigger = 1 THEN 'YES' ELSE 'NO' END + CHAR(13) +
    '-- Is Nested: ' + CASE WHEN tr.is_not_for_replication = 1 THEN 'NO' ELSE 'YES' END + CHAR(13) + CHAR(13)
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE tr.parent_class = 1
  AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND tr.is_ms_shipped = 0
ORDER BY s.name, t.name, tr.name;

PRINT '-- =================================================='
PRINT '-- END OF TRIGGERS EXPORT'
PRINT '-- =================================================='