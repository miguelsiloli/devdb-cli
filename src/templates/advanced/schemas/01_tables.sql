-- =====================================================
-- File: database_schema.sql
-- Description: Creates the DevDB database and its Users and Products tables.
-- Author: Unknown Author
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
USE master;

GO

IF NOT EXISTS
    (SELECT *
     FROM sys.databases
     WHERE name = 'DevDB')
BEGIN
    CREATE DATABASE devdb;
END;

GO

USE devdb;

GO

PRINT 'Creating table: Users';

CREATE TABLE users (
    userid INT PRIMARY KEY identity(1, 1),
    username nvarchar(50) NOT NULL UNIQUE,
    email nvarchar(100) NOT NULL UNIQUE,
    createdat datetime2 DEFAULT getutcdate()
);

GO

PRINT 'Creating table: Products';

CREATE TABLE products (
    productid INT PRIMARY KEY identity(1, 1),
    productname nvarchar(100) NOT NULL,
    price decimal(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

GO