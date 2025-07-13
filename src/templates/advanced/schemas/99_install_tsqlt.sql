-- This script installs tSQLt framework after all other schemas are initialized
-- It runs last due to the 99 prefix, ensuring all tables/views/procedures are created first

USE DevDB;
GO

PRINT 'Enabling CLR for tSQLt installation...';
-- tSQLt requires CLR to be enabled on the database
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

-- Check if tSQLt is already installed
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'tSQLt')
BEGIN
    PRINT 'Installing tSQLt framework...';
    -- Execute the tSQLt installation script
    -- The tSQLt directory is mounted at /tsqlt in the container
    -- We use :r to include the file content
    :r /tsqlt/tSQLt.class.sql
    PRINT 'tSQLt framework installation complete.';
END
ELSE
BEGIN
    PRINT 'tSQLt framework already installed, skipping installation.';
END
GO