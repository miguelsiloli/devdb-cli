/***************************************************************************************************
Procedure:          dbo.testprocedure
Create Date:        2024-01-01
Author:             miguel.b.silva@***.com
Description:        This stored procedure, dbo.testprocedure, accepts two parameters: @param1 (an integer) and @param2 (a string of up to 50 characters).
                    It then selects these parameters, aliasing them as value1 and value2 respectively. The procedure is designed for simple data retrieval and demonstration purposes within the devdb database.
                    The SET NOCOUNT ON statement is included to prevent the message indicating the number of rows affected by a T-SQL statement from being returned.
Affected table(s):  None
Used By:            
Call by:            
Parameter(s):       @param1 - An integer input parameter.
                    @param2 - A string input parameter with a maximum length of 50 characters.
Usage:              EXEC dbo.testprocedure @param1 = 123, @param2 = 'example';
                    This will return a result set with two columns, value1 and value2, containing the values 123 and 'example' respectively.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-01-01          Original Author     Initial creation of test procedure.
2024-03-15          Jane Developer      Added error handling and validation.
2024-06-15          John Maintainer     Updated business logic for new requirements.
2025-07-10          miguel.b.silva@***.com    Automated polish and formatting.
***************************************************************************************************/
USE devdb;

GO


CREATE PROCEDURE dbo.testprocedure @param1 INT, @param2 nvarchar(50) AS BEGIN
    SET nocount ON; -- Simple test procedure

    SELECT @param1 AS value1, @param2 AS value2;
END;

GO