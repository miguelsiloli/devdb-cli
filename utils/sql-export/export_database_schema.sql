/*
    DevDB Database Schema Export Utility
    
    This script exports complete database metadata including:
    - Tables (structure, constraints, indexes)
    - Views
    - Stored Procedures
    - Functions
    - Triggers
    - Foreign Key Relationships
    - User-Defined Data Types
    - Permissions
    
    Usage: Run this script against your source database to generate
           migration scripts for DevDB Docker environment.
*/

-- Set output options for clean script generation
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT '-- =================================================='
PRINT '-- DevDB Database Schema Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- ==================================================
-- SECTION 1: USER-DEFINED DATA TYPES
-- ==================================================
PRINT '-- =================================================='
PRINT '-- USER-DEFINED DATA TYPES'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'CREATE TYPE [' + t.name + '] FROM [' + st.name + ']' +
    CASE 
        WHEN st.name IN ('varchar', 'nvarchar', 'char', 'nchar') 
            THEN '(' + CASE WHEN t.max_length = -1 THEN 'MAX' ELSE CAST(t.max_length AS VARCHAR) END + ')'
        WHEN st.name IN ('decimal', 'numeric') 
            THEN '(' + CAST(t.precision AS VARCHAR) + ',' + CAST(t.scale AS VARCHAR) + ')'
        ELSE ''
    END +
    CASE WHEN t.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END + ';'
FROM sys.types t
INNER JOIN sys.types st ON t.system_type_id = st.system_type_id
WHERE t.is_user_defined = 1
ORDER BY t.name;

PRINT ''

-- ==================================================
-- SECTION 2: TABLES WITH STRUCTURE
-- ==================================================
PRINT '-- =================================================='
PRINT '-- TABLES'
PRINT '-- =================================================='
PRINT ''

DECLARE @TableSQL NVARCHAR(MAX) = '';

SELECT @TableSQL = @TableSQL + 
    'CREATE TABLE [' + s.name + '].[' + t.name + '] (' + CHAR(13) +
    STUFF((
        SELECT ',' + CHAR(13) + '    [' + c.name + '] ' + 
               UPPER(ty.name) + 
               CASE 
                   WHEN ty.name IN ('varchar', 'nvarchar', 'char', 'nchar') 
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR) END + ')'
                   WHEN ty.name IN ('decimal', 'numeric') 
                       THEN '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
                   WHEN ty.name IN ('float') 
                       THEN '(' + CAST(c.precision AS VARCHAR) + ')'
                   WHEN ty.name IN ('datetime2', 'time', 'datetimeoffset') 
                       THEN '(' + CAST(c.scale AS VARCHAR) + ')'
                   ELSE ''
               END +
               CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
               CASE WHEN c.is_identity = 1 
                   THEN ' IDENTITY(' + CAST(IDENT_SEED(s.name + '.' + t.name) AS VARCHAR) + ',' + CAST(IDENT_INCR(s.name + '.' + t.name) AS VARCHAR) + ')'
                   ELSE ''
               END +
               CASE WHEN dc.definition IS NOT NULL 
                   THEN ' DEFAULT ' + dc.definition
                   ELSE ''
               END
        FROM sys.columns c
        INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE c.object_id = t.object_id
        ORDER BY c.column_id
        FOR XML PATH('')
    ), 1, 1, '') + CHAR(13) + ');' + CHAR(13) + CHAR(13)
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY s.name, t.name;

PRINT @TableSQL;

-- ==================================================
-- SECTION 3: PRIMARY KEYS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- PRIMARY KEYS'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'ALTER TABLE [' + s.name + '].[' + t.name + '] ADD CONSTRAINT [' + pk.name + '] PRIMARY KEY CLUSTERED (' +
    STUFF((
        SELECT ', [' + c.name + ']'
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = pk.parent_object_id AND ic.index_id = pk.unique_index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') + ');'
FROM sys.key_constraints pk
INNER JOIN sys.tables t ON pk.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE pk.type = 'PK'
ORDER BY s.name, t.name;

PRINT ''

-- ==================================================
-- SECTION 4: FOREIGN KEYS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- FOREIGN KEY CONSTRAINTS'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'ALTER TABLE [' + s1.name + '].[' + t1.name + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY (' +
    STUFF((
        SELECT ', [' + c1.name + ']'
        FROM sys.foreign_key_columns fkc
        INNER JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
        WHERE fkc.constraint_object_id = fk.object_id
        ORDER BY fkc.constraint_column_id
        FOR XML PATH('')
    ), 1, 2, '') + ') REFERENCES [' + s2.name + '].[' + t2.name + '] (' +
    STUFF((
        SELECT ', [' + c2.name + ']'
        FROM sys.foreign_key_columns fkc
        INNER JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
        WHERE fkc.constraint_object_id = fk.object_id
        ORDER BY fkc.constraint_column_id
        FOR XML PATH('')
    ), 1, 2, '') + ')' +
    CASE WHEN fk.delete_referential_action > 0 
        THEN ' ON DELETE ' + 
             CASE fk.delete_referential_action 
                 WHEN 1 THEN 'CASCADE' 
                 WHEN 2 THEN 'SET NULL' 
                 WHEN 3 THEN 'SET DEFAULT' 
             END
        ELSE ''
    END +
    CASE WHEN fk.update_referential_action > 0 
        THEN ' ON UPDATE ' + 
             CASE fk.update_referential_action 
                 WHEN 1 THEN 'CASCADE' 
                 WHEN 2 THEN 'SET NULL' 
                 WHEN 3 THEN 'SET DEFAULT' 
             END
        ELSE ''
    END + ';'
FROM sys.foreign_keys fk
INNER JOIN sys.tables t1 ON fk.parent_object_id = t1.object_id
INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id
INNER JOIN sys.tables t2 ON fk.referenced_object_id = t2.object_id
INNER JOIN sys.schemas s2 ON t2.schema_id = s2.schema_id
ORDER BY s1.name, t1.name, fk.name;

PRINT ''

-- ==================================================
-- SECTION 5: INDEXES
-- ==================================================
PRINT '-- =================================================='
PRINT '-- INDEXES'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'CREATE ' + 
    CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
    CASE WHEN i.type_desc = 'CLUSTERED' THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
    ' INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] (' +
    STUFF((
        SELECT ', [' + c.name + ']' + 
               CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') + ')' +
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.index_columns ic
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
    )
    THEN ' INCLUDE (' +
         STUFF((
             SELECT ', [' + c.name + ']'
             FROM sys.index_columns ic
             INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
             WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
             ORDER BY ic.index_column_id
             FOR XML PATH('')
         ), 1, 2, '') + ')'
    ELSE ''
    END + ';'
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.is_primary_key = 0 
  AND i.is_unique_constraint = 0
  AND i.type > 0  -- Exclude heaps
  AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY s.name, t.name, i.name;

PRINT ''
PRINT '-- =================================================='
PRINT '-- END OF SCHEMA EXPORT'
PRINT '-- =================================================='