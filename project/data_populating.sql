DECLARE @i INT = 1;
DECLARE @filename NVARCHAR(255);
DECLARE @path NVARCHAR(255) = 'C:\Users\Thinkpad\travel_times_splitted_files\';
DECLARE @sql NVARCHAR(MAX);

WHILE @i <= 22
BEGIN
    SET @filename = @path + 'part_' + CAST(@i AS NVARCHAR(50)) + '.csv';

    PRINT 'Importing ' + @filename;

    SET @sql = 'BULK INSERT dbo.TravelTimesData FROM ''' + @filename + ''' WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', FIRSTROW = 2)';

    BEGIN TRY
        EXEC sp_executesql @sql;
        PRINT 'Successfully imported ' + @filename;
    END TRY
    BEGIN CATCH
        PRINT 'Error importing ' + @filename + ': ' + ERROR_MESSAGE();
    END CATCH;

    SET @i = @i + 1;
END;
