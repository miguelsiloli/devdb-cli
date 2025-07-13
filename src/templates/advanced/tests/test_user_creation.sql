-- tSQLt Tests for User Creation
USE DevDB;
GO

-- Create Test Class for User Creation
EXEC tSQLt.NewTestClass @ClassName = 'UserCreationTests';
GO

-- Test 1: AddNewUser stored procedure creates user successfully
CREATE PROCEDURE UserCreationTests.[test AddNewUser creates user successfully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Execute the stored procedure
    EXEC dbo.AddNewUser @Username = 'testuser', @Email = 'test@example.com';
    
    -- Assert: Verify the user was created
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username = 'testuser' AND Email = 'test@example.com';
    
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @UserCount, 
         @Message = 'AddNewUser should create exactly one user with correct details';
END;
GO

-- Test 2: AddNewUser sets CreatedAt timestamp
CREATE PROCEDURE UserCreationTests.[test AddNewUser sets CreatedAt timestamp]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Execute the stored procedure
    EXEC dbo.AddNewUser @Username = 'timestampuser', @Email = 'timestamp@example.com';
    
    -- Assert: Verify CreatedAt was set (should be recent)
    DECLARE @CreatedAt DATETIME2;
    SELECT @CreatedAt = CreatedAt FROM dbo.Users WHERE Username = 'timestampuser';
    
    EXEC tSQLt.AssertNotEquals @Expected = NULL, @Actual = @CreatedAt, 
         @Message = 'AddNewUser should set CreatedAt timestamp';
    
    -- Check that CreatedAt is recent (within last minute)
    DECLARE @TimeDiff INT;
    SELECT @TimeDiff = DATEDIFF(SECOND, @CreatedAt, GETUTCDATE());
    
    -- Assert that time difference is reasonable (0-60 seconds)
    IF @TimeDiff < 0 OR @TimeDiff > 60
    BEGIN
        EXEC tSQLt.Fail 'AddNewUser should set CreatedAt to current timestamp';
    END;
END;
GO

-- Test 3: AddNewUser handles username with special characters
CREATE PROCEDURE UserCreationTests.[test AddNewUser handles special characters in username]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Execute with special characters in username
    EXEC dbo.AddNewUser @Username = 'test-user_123', @Email = 'special@example.com';
    
    -- Assert: Verify user was created with exact username
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username = 'test-user_123';
    
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @UserCount, 
         @Message = 'AddNewUser should handle special characters in username';
END;
GO

-- Test 4: AddNewUser handles international email domains
CREATE PROCEDURE UserCreationTests.[test AddNewUser handles international email domains]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Execute with international email domain
    EXEC dbo.AddNewUser @Username = 'intluser', @Email = 'user@company.co.uk';
    
    -- Assert: Verify user was created with correct email
    DECLARE @Email NVARCHAR(100);
    SELECT @Email = Email FROM dbo.Users WHERE Username = 'intluser';
    
    EXEC tSQLt.AssertEquals @Expected = 'user@company.co.uk', @Actual = @Email, 
         @Message = 'AddNewUser should handle international email domains';
END;
GO

-- Test 5: AddNewUser generates sequential UserID
CREATE PROCEDURE UserCreationTests.[test AddNewUser generates sequential UserID]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Create multiple users
    EXEC dbo.AddNewUser @Username = 'user1', @Email = 'user1@example.com';
    EXEC dbo.AddNewUser @Username = 'user2', @Email = 'user2@example.com';
    EXEC dbo.AddNewUser @Username = 'user3', @Email = 'user3@example.com';
    
    -- Assert: Verify all users were created
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username IN ('user1', 'user2', 'user3');
    
    EXEC tSQLt.AssertEquals @Expected = 3, @Actual = @UserCount, 
         @Message = 'AddNewUser should create all users successfully';
    
    -- Verify UserIDs are sequential (assuming IDENTITY starts at 1)
    DECLARE @MinUserID INT, @MaxUserID INT;
    SELECT @MinUserID = MIN(UserID), @MaxUserID = MAX(UserID) 
    FROM dbo.Users WHERE Username IN ('user1', 'user2', 'user3');
    
    DECLARE @UserIDDiff INT = @MaxUserID - @MinUserID;
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @UserIDDiff, 
         @Message = 'AddNewUser should generate sequential UserIDs';
END;
GO

-- Test 6: AddNewUser with empty username parameter
CREATE PROCEDURE UserCreationTests.[test AddNewUser with empty username fails gracefully]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Try to create user with empty username
    EXEC dbo.AddNewUser @Username = '', @Email = 'empty@example.com';
    
    -- Assert: Verify user was still created (basic procedure doesn't validate)
    -- Note: This test documents current behavior - the basic AddNewUser doesn't validate
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username = '';
    
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @UserCount, 
         @Message = 'AddNewUser currently accepts empty username (documents current behavior)';
END;
GO

-- Test 7: AddNewUser with NULL parameters
CREATE PROCEDURE UserCreationTests.[test AddNewUser with NULL username creates user]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Try to create user with NULL username
    EXEC dbo.AddNewUser @Username = NULL, @Email = 'null@example.com';
    
    -- Assert: Verify user was created with NULL username
    DECLARE @UserCount INT;
    SELECT @UserCount = COUNT(*) FROM dbo.Users WHERE Username IS NULL;
    
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @UserCount, 
         @Message = 'AddNewUser currently accepts NULL username (documents current behavior)';
END;
GO

-- Test 8: AddNewUser creates user with all expected columns
CREATE PROCEDURE UserCreationTests.[test AddNewUser populates all expected columns]
AS
BEGIN
    -- Arrange: Create fake Users table
    EXEC tSQLt.FakeTable @TableName = 'dbo.Users';
    
    -- Act: Create a user
    EXEC dbo.AddNewUser @Username = 'completeuser', @Email = 'complete@example.com';
    
    -- Assert: Verify all expected columns are populated
    DECLARE @UserID INT, @Username NVARCHAR(50), @Email NVARCHAR(100), @CreatedAt DATETIME2;
    SELECT @UserID = UserID, @Username = Username, @Email = Email, @CreatedAt = CreatedAt 
    FROM dbo.Users WHERE Username = 'completeuser';
    
    EXEC tSQLt.AssertNotEquals @Expected = 0, @Actual = @UserID, 
         @Message = 'AddNewUser should set UserID';
    EXEC tSQLt.AssertEquals @Expected = 'completeuser', @Actual = @Username, 
         @Message = 'AddNewUser should set Username correctly';
    EXEC tSQLt.AssertEquals @Expected = 'complete@example.com', @Actual = @Email, 
         @Message = 'AddNewUser should set Email correctly';
    EXEC tSQLt.AssertNotEquals @Expected = NULL, @Actual = @CreatedAt, 
         @Message = 'AddNewUser should set CreatedAt';
END;
GO