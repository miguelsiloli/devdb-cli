-- =====================================================
-- File: [filename will be provided by user]
-- Description: tSQLt tests for the AddNewUser stored procedure, covering various scenarios such as successful user creation, timestamp setting, handling special characters, international email domains, sequential UserID generation, and edge cases with empty or NULL parameters.
-- Author: miguel.b.silva@***.com
-- Created: 2025-07-10
-- Last Modified: 2025-07-10
-- =====================================================
USE devdb;

GO

-- Create Test Class for User Creation
EXEC tsqlt.newtestclass @classname = 'UserCreationTests';

GO

-- Test 1: AddNewUser stored procedure creates user successfully

CREATE PROCEDURE usercreationtests.[test addnewuser creates user successfully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Execute the stored procedure
    EXEC dbo.addnewuser @username = 'testuser', @email = 'test@example.com';

    -- Assert: Verify the user was created
    DECLARE @usercount INT;

    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username = 'testuser'
        AND email = 'test@example.com';

    EXEC tsqlt.assertequals @expected = 1,
                             @actual = @usercount,
                             @message = 'AddNewUser should create exactly one user with correct details';
END;

GO

-- Test 2: AddNewUser sets CreatedAt timestamp

CREATE PROCEDURE usercreationtests.[test addnewuser sets createdat timestamp]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Execute the stored procedure
    EXEC dbo.addnewuser @username = 'timestampuser', @email = 'timestamp@example.com';

    -- Assert: Verify CreatedAt was set (should be recent)
    DECLARE @createdat datetime2;

    SELECT @createdat = createdat
    FROM dbo.users
    WHERE username = 'timestampuser';

    EXEC tsqlt.assertnotequals @expected = NULL,
                                 @actual = @createdat,
                                 @message = 'AddNewUser should set CreatedAt timestamp';

    -- Check that CreatedAt is recent (within last minute)
    DECLARE @timediff INT;

    SELECT @timediff = datediff(SECOND, @createdat, getutcdate());

    -- Assert that time difference is reasonable (0-60 seconds)
    IF @timediff < 0
        OR @timediff > 60
    BEGIN
        EXEC tsqlt.fail 'AddNewUser should set CreatedAt to current timestamp';
    END;
END;

GO

-- Test 3: AddNewUser handles username with special characters

CREATE PROCEDURE usercreationtests.[test addnewuser handles special characters in username]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Execute with special characters in username
    EXEC dbo.addnewuser @username = 'test-user_123', @email = 'special@example.com';

    -- Assert: Verify user was created with exact username
    DECLARE @usercount INT;

    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username = 'test-user_123';

    EXEC tsqlt.assertequals @expected = 1,
                             @actual = @usercount,
                             @message = 'AddNewUser should handle special characters in username';
END;

GO

-- Test 4: AddNewUser handles international email domains

CREATE PROCEDURE usercreationtests.[test addnewuser handles international email domains]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Execute with international email domain
    EXEC dbo.addnewuser @username = 'intluser', @email = 'user@company.co.uk';

    -- Assert: Verify user was created with correct email
    DECLARE @email nvarchar(100);

    SELECT @email = email
    FROM dbo.users
    WHERE username = 'intluser';

    EXEC tsqlt.assertequals @expected = 'user@company.co.uk',
                             @actual = @email,
                             @message = 'AddNewUser should handle international email domains';
END;

GO

-- Test 5: AddNewUser generates sequential UserID

CREATE PROCEDURE usercreationtests.[test addnewuser generates sequential userid]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Create multiple users
    EXEC dbo.addnewuser @username = 'user1', @email = 'user1@example.com';
    EXEC dbo.addnewuser @username = 'user2', @email = 'user2@example.com';
    EXEC dbo.addnewuser @username = 'user3', @email = 'user3@example.com';

    -- Assert: Verify all users were created
    DECLARE @usercount INT;

    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username IN ('user1', 'user2', 'user3');

    EXEC tsqlt.assertequals @expected = 3,
                             @actual = @usercount,
                             @message = 'AddNewUser should create all users successfully';

    -- Verify UserIDs are sequential (assuming IDENTITY starts at 1)
    DECLARE @minuserid INT, @maxuserid INT;

    SELECT @minuserid = min(userid), @maxuserid = max(userid)
    FROM dbo.users
    WHERE username IN ('user1', 'user2', 'user3');

    DECLARE @useriddiff INT = @maxuserid - @minuserid;

    EXEC tsqlt.assertequals @expected = 2,
                             @actual = @useriddiff,
                             @message = 'AddNewUser should generate sequential UserIDs';
END;

GO

-- Test 6: AddNewUser with empty username parameter

CREATE PROCEDURE usercreationtests.[test addnewuser with empty username fails gracefully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Try to create user with empty username
    EXEC dbo.addnewuser @username = '', @email = 'empty@example.com';

    -- Assert: Verify user was still created (basic procedure doesn't validate)
    -- Note: This test documents current behavior - the basic AddNewUser doesn't validate
    DECLARE @usercount INT;

    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username = '';

    EXEC tsqlt.assertequals @expected = 1,
                             @actual = @usercount,
                             @message = 'AddNewUser currently accepts empty username (documents current behavior)';
END;

GO

-- Test 7: AddNewUser with NULL parameters

CREATE PROCEDURE usercreationtests.[test addnewuser with null username creates user]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Try to create user with NULL username
    EXEC dbo.addnewuser @username = NULL, @email = 'null@example.com';

    -- Assert: Verify user was created with NULL username
    DECLARE @usercount INT;

    SELECT @usercount = count(*)
    FROM dbo.users
    WHERE username IS NULL;

    EXEC tsqlt.assertequals @expected = 1,
                             @actual = @usercount,
                             @message = 'AddNewUser currently accepts NULL username (documents current behavior)';
END;

GO

-- Test 8: AddNewUser creates user with all expected columns

CREATE PROCEDURE usercreationtests.[test addnewuser populates all expected columns]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tsqlt.faketable @tablename = 'dbo.Users';

    -- Act: Create a user
    EXEC dbo.addnewuser @username = 'completeuser', @email = 'complete@example.com';

    -- Assert: Verify all expected columns are populated
    DECLARE @userid INT, @username nvarchar(50), @email nvarchar(100), @createdat datetime2;

    SELECT @userid = userid, @username = username, @email = email, @createdat = createdat
    FROM dbo.users
    WHERE username = 'completeuser';

    EXEC tsqlt.assertnotequals @expected = 0,
                                 @actual = @userid,
                                 @message = 'AddNewUser should set UserID';

    EXEC tsqlt.assertequals @expected = 'completeuser',
                             @actual = @username,
                             @message = 'AddNewUser should set Username correctly';

    EXEC tsqlt.assertequals @expected = 'complete@example.com',
                             @actual = @email,
                             @message = 'AddNewUser should set Email correctly';

    EXEC tsqlt.assertnotequals @expected = NULL,
                                 @actual = @createdat,
                                 @message = 'AddNewUser should set CreatedAt';
END;

GO