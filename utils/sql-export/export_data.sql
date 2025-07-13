/*
    DevDB Data Export Utility
    
    Generates INSERT statements for all tables in the database
    Handles various data types and NULL values properly
    
    Usage: 
    1. Run this script against your source database
    2. Review and modify the generated INSERT statements as needed
    3. Execute the INSERT statements in your DevDB Docker environment
    
    Note: This script generates basic INSERT statements. For large datasets,
          consider using BCP or SSIS for better performance.
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Data Export (INSERT Statements)'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

DECLARE @TableName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @InsertSQL NVARCHAR(MAX);

-- Cursor to iterate through all user tables
DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY s.name, t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- =================================================='
    PRINT '-- Data for table: [' + @SchemaName + '].[' + @TableName + ']'
    PRINT '-- =================================================='
    PRINT ''
    
    -- Check if table has data
    SET @SQL = 'SELECT @count = COUNT(*) FROM [' + @SchemaName + '].[' + @TableName + ']';
    DECLARE @RowCount INT;
    EXEC sp_executesql @SQL, N'@count INT OUTPUT', @count = @RowCount OUTPUT;
    
    IF @RowCount > 0
    BEGIN
        PRINT '-- Table contains ' + CAST(@RowCount AS VARCHAR) + ' rows';
        PRINT '';
        
        -- Generate INSERT statements
        SET @SQL = '
        SELECT ''INSERT INTO [' + @SchemaName + '].[' + @TableName + '] ('' +
        STUFF((
            SELECT '', ['' + c.name + '']''
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(''[' + @SchemaName + '].[' + @TableName + ']'')
              AND c.is_computed = 0
              AND c.is_identity = 0
            ORDER BY c.column_id
            FOR XML PATH('''')
        ), 1, 2, '''') + '') VALUES ('' +
        STUFF((
            SELECT '', '' + 
                CASE 
                    WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239) -- text, ntext, varchar, char, nvarchar, nchar
                        THEN ''''''''' + REPLACE(CAST(['' + c.name + ''] AS NVARCHAR(MAX)), '''''''', '''''''''''') + ''''''''
                    WHEN c.system_type_id IN (48, 52, 56, 59, 60, 62, 104, 106, 108, 122, 127) -- tinyint, smallint, int, real, money, float, bit, decimal, numeric, smallmoney, bigint
                        THEN CAST(['' + c.name + ''] AS NVARCHAR(MAX))
                    WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) -- date, time, datetime2, datetimeoffset, smalldatetime, datetime
                        THEN ''''''''' + CONVERT(VARCHAR, ['' + c.name + ''], 120) + ''''''''
                    WHEN c.system_type_id = 36 -- uniqueidentifier
                        THEN ''''''''' + CAST(['' + c.name + ''] AS VARCHAR(36)) + ''''''''
                    WHEN c.system_type_id IN (34, 173, 165) -- image, binary, varbinary
                        THEN ''0x'' + CAST(['' + c.name + ''] AS NVARCHAR(MAX))
                    ELSE ''''''''' + CAST(['' + c.name + ''] AS NVARCHAR(MAX)) + ''''''''
                END
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(''[' + @SchemaName + '].[' + @TableName + ']'')
              AND c.is_computed = 0
              AND c.is_identity = 0
            ORDER BY c.column_id
            FOR XML PATH('''')
        ), 1, 2, '''') + '');''
        FROM [' + @SchemaName + '].[' + @TableName + ']';
        
        -- Execute the dynamic SQL to generate INSERT statements
        EXEC(@SQL);
        
        PRINT '';
    END
    ELSE
    BEGIN
        PRINT '-- Table is empty';
        PRINT '';
    END
    
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

PRINT '-- =================================================='
PRINT '-- END OF DATA EXPORT'
PRINT '-- =================================================='