CREATE PROCEDURE [dbo].[SearchNames]
    @inputString NVARCHAR(150)
AS
BEGIN
    -- Create a temporary table to store the parsed names
    IF OBJECT_ID('tempdb..#NameSearchQuery') IS NOT NULL DROP TABLE #NameSearchQuery;
    CREATE TABLE #NameSearchQuery (
        FirstName NVARCHAR(50),
        MiddleName NVARCHAR(50),
        LastName NVARCHAR(50)
    );

    -- Variables to hold parsed names
    DECLARE @FirstName NVARCHAR(50) = NULL,
            @MiddleName NVARCHAR(50) = NULL,
            @LastName NVARCHAR(50) = NULL;

    -- Determine the structure of the input string
    IF CHARINDEX(',', @inputString) > 0
    BEGIN
        -- Comma found, parse based on comma rules
        IF LEN(@inputString) - LEN(REPLACE(@inputString, ',', '')) = 1
        BEGIN
            -- One comma present, determine position
            IF CHARINDEX(',', @inputString) < CHARINDEX(' ', @inputString)
            BEGIN
                -- LastName, FirstName
                SELECT  @LastName = LTRIM(RTRIM(SUBSTRING(@inputString, 1, CHARINDEX(',', @inputString)-1))),
                        @FirstName = LTRIM(RTRIM(SUBSTRING(@inputString, CHARINDEX(',', @inputString) + 1, LEN(@inputString))))
            END
            ELSE
            BEGIN
                -- FirstName, LastName MiddleName
                SELECT  @FirstName = LTRIM(RTRIM(SUBSTRING(@inputString, 1, CHARINDEX(' ', @inputString)-1))),
                        @MiddleName = LTRIM(RTRIM(SUBSTRING(@inputString, CHARINDEX(' ', @inputString) + 1, LEN(@inputString) - CHARINDEX(',', REVERSE(@inputString)) - CHARINDEX(' ', @inputString)))),
                        @LastName = LTRIM(RTRIM(SUBSTRING(@inputString, LEN(@inputString) - CHARINDEX(',', REVERSE(@inputString)) + 2, LEN(@inputString))));
            END
        END
    END
    ELSE
    BEGIN
        -- No comma, parse based on space
        IF (LEN(@inputString) - LEN(REPLACE(@inputString, ' ', ''))) = 1
        BEGIN
            -- One space, FirstName LastName
            SELECT  @FirstName = LTRIM(RTRIM(SUBSTRING(@inputString, 1, CHARINDEX(' ', @inputString)-1))),
                    @LastName = LTRIM(RTRIM(SUBSTRING(@inputString, CHARINDEX(' ', @inputString) + 1, LEN(@inputString))));
        END
        ELSE IF (LEN(@inputString) - LEN(REPLACE(@inputString, ' ', ''))) = 2
        BEGIN
            -- Two spaces, FirstName MiddleName LastName
            SELECT  @FirstName = LTRIM(RTRIM(SUBSTRING(@inputString, 1, CHARINDEX(' ', @inputString)-1))),
                    @MiddleName = LTRIM(RTRIM(SUBSTRING(@inputString, CHARINDEX(' ', @inputString) + 1, CHARINDEX(' ', @inputString, CHARINDEX(' ', @inputString) + 1) - CHARINDEX(' ', @inputString) - 1))),
                    @LastName = LTRIM(RTRIM(SUBSTRING(@inputString, CHARINDEX(' ', @inputString, CHARINDEX(' ', @inputString) + 1) + 1, LEN(@inputString))));
        END
    END

    -- Insert parsed names into temporary table
    INSERT INTO #NameSearchQuery (FirstName, MiddleName, LastName)
    VALUES (@FirstName, @MiddleName, @LastName);

    -- Example query to use the temporary table for searching
    SELECT p.*
    FROM Names p
    JOIN #NameSearchQuery ns ON p.FirstName = ns.FirstName OR p.MiddleName = ns.MiddleName OR p.LastName = ns.LastName;
END
