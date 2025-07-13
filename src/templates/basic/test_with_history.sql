-- =====================================================
-- File: test_with_history.sql
-- Description: Test file with existing change history
-- Author: Original Author
-- Created: 2024-01-01
-- Last Modified: 2024-06-15
-- =====================================================
-- SUMMARY OF CHANGES
-- Date(yyyy-mm-dd)    Author              Comments
-- ------------------- ------------------- ------------------------------------------------------------
-- 2024-01-01      Original Author     Initial creation of test procedure.
-- 2024-03-15      Jane Developer      Added error handling and validation.
-- 2024-06-15      John Maintainer     Updated business logic for new requirements.
-- =====================================================

USE DevDB;
GO

CREATE PROCEDURE dbo.TestProcedure
    @Param1 INT,
    @Param2 NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Simple test procedure
    SELECT @Param1 AS Value1, @Param2 AS Value2;
END;
GO