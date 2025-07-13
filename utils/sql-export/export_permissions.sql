/*
    DevDB Permissions Export Utility
    
    Exports database permissions including:
    - Database roles and role memberships
    - Object-level permissions
    - Schema permissions
    - User-defined database users
    
    Usage: Run this script against your source database to export security configuration
*/

SET NOCOUNT ON;

PRINT '-- =================================================='
PRINT '-- DevDB Permissions Export'
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '-- Database: ' + DB_NAME()
PRINT '-- =================================================='
PRINT ''

-- ==================================================
-- SECTION 1: DATABASE USERS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- DATABASE USERS'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- User: [' + p.name + ']' + CHAR(13) +
    CASE p.type
        WHEN 'S' THEN 'CREATE USER [' + p.name + '] FOR LOGIN [' + p.name + '];'
        WHEN 'U' THEN 'CREATE USER [' + p.name + '] WITHOUT LOGIN;'
        WHEN 'G' THEN '-- Windows Group: [' + p.name + '] (CREATE USER [' + p.name + '] FROM EXTERNAL PROVIDER;)'
        ELSE '-- User Type: ' + p.type_desc + ' - [' + p.name + ']'
    END + CHAR(13)
FROM sys.database_principals p
WHERE p.type IN ('S', 'U', 'G')
  AND p.is_fixed_role = 0
  AND p.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
  AND p.name NOT LIKE '##%'
ORDER BY p.name;

PRINT ''

-- ==================================================
-- SECTION 2: DATABASE ROLES
-- ==================================================
PRINT '-- =================================================='
PRINT '-- CUSTOM DATABASE ROLES'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'CREATE ROLE [' + p.name + '];' + CHAR(13)
FROM sys.database_principals p
WHERE p.type = 'R'
  AND p.is_fixed_role = 0
  AND p.name NOT IN ('public')
ORDER BY p.name;

PRINT ''

-- ==================================================
-- SECTION 3: ROLE MEMBERSHIPS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- ROLE MEMBERSHIPS'
PRINT '-- =================================================='
PRINT ''

SELECT 
    'ALTER ROLE [' + r.name + '] ADD MEMBER [' + m.name + '];' + CHAR(13)
FROM sys.database_role_members rm
INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name NOT IN ('public')
  AND m.name NOT IN ('dbo')
ORDER BY r.name, m.name;

PRINT ''

-- ==================================================
-- SECTION 4: OBJECT PERMISSIONS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- OBJECT PERMISSIONS'
PRINT '-- =================================================='
PRINT ''

SELECT 
    CASE p.state
        WHEN 'G' THEN 'GRANT'
        WHEN 'D' THEN 'DENY'
        WHEN 'R' THEN 'REVOKE'
    END + ' ' + p.permission_name + 
    CASE 
        WHEN o.type IS NOT NULL THEN ' ON [' + s.name + '].[' + o.name + ']'
        WHEN s.name IS NOT NULL THEN ' ON SCHEMA::[' + s.name + ']'
        ELSE ''
    END + 
    ' TO [' + pr.name + ']' +
    CASE WHEN p.state = 'G' AND p.with_grant_option = 1 THEN ' WITH GRANT OPTION' ELSE '' END + ';' + CHAR(13)
FROM sys.database_permissions p
INNER JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
LEFT JOIN sys.schemas s ON COALESCE(o.schema_id, p.major_id) = s.schema_id
WHERE p.class IN (0, 1, 3)  -- Database, Object, Schema
  AND pr.name NOT IN ('public', 'dbo')
  AND pr.is_fixed_role = 0
ORDER BY pr.name, p.permission_name, COALESCE(s.name, ''), COALESCE(o.name, '');

PRINT ''

-- ==================================================
-- SECTION 5: SCHEMA PERMISSIONS
-- ==================================================
PRINT '-- =================================================='
PRINT '-- SCHEMA PERMISSIONS SUMMARY'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- Schema: [' + s.name + '] - Owner: [' + pr.name + ']' + CHAR(13) +
    CASE 
        WHEN pr.name != 'dbo' THEN 'ALTER AUTHORIZATION ON SCHEMA::[' + s.name + '] TO [' + pr.name + '];'
        ELSE '-- Default owner (dbo)'
    END + CHAR(13)
FROM sys.schemas s
INNER JOIN sys.database_principals pr ON s.principal_id = pr.principal_id
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA', 'guest', 'db_owner', 'db_accessadmin', 
                     'db_securityadmin', 'db_ddladmin', 'db_datareader', 'db_datawriter',
                     'db_denydatareader', 'db_denydatawriter')
ORDER BY s.name;

PRINT ''

-- ==================================================
-- SECTION 6: PERMISSIONS SUMMARY FOR REFERENCE
-- ==================================================
PRINT '-- =================================================='
PRINT '-- PERMISSIONS SUMMARY (For Reference)'
PRINT '-- =================================================='
PRINT ''

SELECT 
    '-- User/Role: [' + pr.name + '] (' + pr.type_desc + ')' + CHAR(13) +
    '-- Permissions: ' + CHAR(13) +
    STUFF((
        SELECT CHAR(13) + '--   ' + 
               CASE p.state WHEN 'G' THEN 'GRANT' WHEN 'D' THEN 'DENY' WHEN 'R' THEN 'REVOKE' END + 
               ' ' + p.permission_name + 
               CASE 
                   WHEN o.type IS NOT NULL THEN ' ON [' + s.name + '].[' + o.name + ']'
                   WHEN s.name IS NOT NULL THEN ' ON SCHEMA::[' + s.name + ']'
                   ELSE ' (Database Level)'
               END
        FROM sys.database_permissions p2
        LEFT JOIN sys.objects o ON p2.major_id = o.object_id
        LEFT JOIN sys.schemas s ON COALESCE(o.schema_id, p2.major_id) = s.schema_id
        WHERE p2.grantee_principal_id = pr.principal_id
        ORDER BY p2.permission_name
        FOR XML PATH('')
    ), 1, 3, '') + CHAR(13) + CHAR(13)
FROM sys.database_principals pr
WHERE EXISTS (
    SELECT 1 FROM sys.database_permissions p 
    WHERE p.grantee_principal_id = pr.principal_id
)
  AND pr.name NOT IN ('public', 'dbo')
  AND pr.is_fixed_role = 0
ORDER BY pr.name;

PRINT '-- =================================================='
PRINT '-- END OF PERMISSIONS EXPORT'
PRINT '-- =================================================='