--use LogisticsData
use Applyed_Logistics_database
drop table TravelDistances
--for package data
-- Package Density
ALTER TABLE PackageData
ADD PackageDensity FLOAT;
go
UPDATE PackageData
SET PackageDensity = (depth_cm * height_cm * width_cm) / (
    SELECT distinct ExecutorCapacity
    FROM RouteData
    WHERE RouteData.RouteID = PackageData.RouteID 
);
go
--Creating a Path Temporary Table
SELECT 
    PackageID,
    RouteID,
    StopID,
    planned_service_time_seconds,
    ROW_NUMBER() OVER (PARTITION BY RouteID ORDER BY (SELECT NULL)) AS Seq
INTO TempPackageSequence
FROM PackageData;

--DeliveryTimeUTC
ALTER TABLE PackageData
ADD DeliveryTimeUTC DATETIME;

-- Calculate the delivery time for each parcel 
-- initial state, calculate the delivery time for the first parcel
	SELECT 
        distinct t.RouteID,
		t.PackageID,
        t.StopID,
        CAST(r.Date AS DATETIME) + CAST(r.DepartureTime AS DATETIME) AS StartTime,
        DATEADD(SECOND, t.planned_service_time_seconds, CAST(r.Date AS DATETIME) + CAST(r.DepartureTime AS DATETIME)) AS DeliveryTimeUTC,
        t.planned_service_time_seconds,
        ISNULL(asd.TravelTimeSeconds, 0) AS TravelTimeSeconds,
        t.Seq
	into CTE_PackageDeliveryTime
    FROM 
        TempPackageSequence t
        JOIN RouteData r ON t.RouteID = r.RouteID
        LEFT JOIN actual_sequences_data asd ON t.RouteID = asd.RouteID AND t.StopID = asd.StopID
    WHERE 
        t.Seq = 1
		


DECLARE @maxSeq INT;
SET @maxSeq = (SELECT MAX(Seq) FROM TempPackageSequence);

DECLARE @currentSeq INT;
SET @currentSeq = 2;

WHILE @currentSeq <= @maxSeq
BEGIN
    INSERT INTO CTE_PackageDeliveryTime (RouteID, PackageID, StopID, StartTime, DeliveryTimeUTC, planned_service_time_seconds, TravelTimeSeconds, Seq)
    SELECT 
        t.RouteID,
		t.PackageID,
        t.StopID,
        d.DeliveryTimeUTC AS StartTime,
        DATEADD(SECOND, t.planned_service_time_seconds + ISNULL(asd.TravelTimeSeconds, 0), d.DeliveryTimeUTC) AS DeliveryTimeUTC,
        t.planned_service_time_seconds,
        ISNULL(asd.TravelTimeSeconds, 0) AS TravelTimeSeconds,
        t.Seq
    FROM 
        CTE_PackageDeliveryTime d
        JOIN TempPackageSequence t ON d.RouteID = t.RouteID AND t.Seq = @currentSeq
        LEFT JOIN actual_sequences_data asd ON t.RouteID = asd.RouteID AND t.StopID = asd.StopID
    WHERE 
        d.Seq = @currentSeq - 1;

    SET @currentSeq = @currentSeq + 1;
END;


-- Update the PackageData table
UPDATE pd
SET pd.DeliveryTimeUTC = cte.DeliveryTimeUTC
FROM 
    PackageData pd
    JOIN CTE_PackageDeliveryTime cte ON pd.PackageID = cte.PackageID;
GO


--for route table
--DeliveryTimeUTC

ALTER TABLE RouteData
ADD Sequenced int;

UPDATE RouteData
SET Sequenced = (select TravelTimeSeconds 
				from actual_sequences_data as asd
				where asd.RouteID = RouteData.RouteID and asd.StopID = RouteData.StopID );


--for route_summary table
-- Create a function to calculate the Haversine distance
CREATE FUNCTION dbo.HaversineDistance (
    @lat1 FLOAT, @lon1 FLOAT,
    @lat2 FLOAT, @lon2 FLOAT
) RETURNS FLOAT
AS
BEGIN
    DECLARE @R FLOAT = 6371; -- Earth radius (kilometres)
    DECLARE @dLat FLOAT = RADIANS(@lat2 - @lat1);
    DECLARE @dLon FLOAT = RADIANS(@lon2 - @lon1);
    DECLARE @a FLOAT = SIN(@dLat / 2) * SIN(@dLat / 2) +
                       COS(RADIANS(@lat1)) * COS(RADIANS(@lat2)) *
                       SIN(@dLon / 2) * SIN(@dLon / 2);
    DECLARE @c FLOAT = 2 * ATN2(SQRT(@a), SQRT(1 - @a));
    RETURN @R * @c;
END;

-- Use plurality to determine unique latitude and longitude
WITH LatMode AS (
    SELECT StopID, Latitude,
           ROW_NUMBER() OVER (PARTITION BY StopID ORDER BY COUNT(*) DESC) AS rn
    FROM RouteData
    GROUP BY StopID, Latitude
),
LonMode AS (
    SELECT StopID, Longitude,
           ROW_NUMBER() OVER (PARTITION BY StopID ORDER BY COUNT(*) DESC) AS rn
    FROM RouteData
    GROUP BY StopID, Longitude
)
SELECT ROW_NUMBER() OVER (ORDER BY l.StopID) AS AutoID, l.StopID, l.Latitude, o.Longitude
INTO UniqueStops
FROM LatMode l
JOIN LonMode o ON l.StopID = o.StopID
WHERE l.rn = 1 AND o.rn = 1;

-- Calculate distance using unique site data 
-- Calculate unique site data and assign AutoIDs
WITH LatMode AS (
    SELECT StopID, Latitude,
           ROW_NUMBER() OVER (PARTITION BY StopID ORDER BY COUNT(*) DESC) AS rn
    FROM RouteData
    GROUP BY StopID, Latitude
),
LonMode AS (
    SELECT StopID, Longitude,
           ROW_NUMBER() OVER (PARTITION BY StopID ORDER BY COUNT(*) DESC) AS rn
    FROM RouteData
    GROUP BY StopID, Longitude
)
SELECT ROW_NUMBER() OVER (ORDER BY l.StopID) AS AutoID, l.StopID, l.Latitude, o.Longitude
INTO UniqueStops
FROM LatMode l
JOIN LonMode o ON l.StopID = o.StopID
WHERE l.rn = 1 AND o.rn = 1;

-- Calculate distances using unique site data and change FromStopID and ToStopID to AutoID
SELECT
    tt.RouteID,
    us1.AutoID AS FromStopID,
    us2.AutoID AS ToStopID,
    r.StopType,
    tt.TravelTimeSeconds,
    dbo.HaversineDistance(us1.Latitude, us1.Longitude, us2.Latitude, us2.Longitude) AS DistanceKM
INTO
    TravelDistances
FROM
    TravelTimesData tt
    JOIN UniqueStops us1 ON tt.FromStopID = us1.StopID
    JOIN UniqueStops us2 ON tt.ToStopID = us2.StopID
    JOIN RouteData r ON tt.RouteID = r.RouteID AND tt.ToStopID = r.StopID;


-- Calculation of total transport time and distance for each route
SELECT
    RouteID,
    SUM(TravelTimeSeconds) AS TotalTravelTime,
    SUM(DistanceKM) AS TotalDistanceKM
INTO
    RouteSummary
FROM
    TravelDistances
GROUP BY
    RouteID;
go

-- Calculate the average speed of each route
ALTER TABLE RouteSummary
ADD AverageSpeedKMH FLOAT;

UPDATE RouteSummary
SET AverageSpeedKMH = TotalDistanceKM / (TotalTravelTime / 3600);
go

--Average Packages per Stop
ALTER TABLE RouteSummary
ADD AvgPackagesPerStop INT;

UPDATE RouteSummary
SET AvgPackagesPerStop = (SELECT AvgPackagesPerStop 
                          FROM (SELECT 
									RouteID, 
									ROUND(COUNT(PackageID) * 1.0 / COUNT(DISTINCT StopID), 0) AS AvgPackagesPerStop
								FROM 
									PackageData
								GROUP BY 
									RouteID) as AvgPackages
                          WHERE AvgPackages.RouteID = RouteSummary.RouteID)
go

--Creating a Path Temporary Table
SELECT 
    [RouteID]
    ,[StopID]
    ,[planned_service_time_seconds]
INTO ServiceTime
FROM PackageData
;

--TotalServiceTime
ALTER TABLE RouteSummary
ADD TotalServiceTime INT;
go
UPDATE RouteSummary
SET TotalServiceTime = (SELECT TotalServiceTime
                        FROM (SELECT 
                                RouteID, 
                                SUM(planned_service_time_seconds) AS TotalServiceTime
                              FROM 
                                PackageData
                              GROUP BY 
                                RouteID) AS TotalServices
                        WHERE TotalServices.RouteID = RouteSummary.RouteID);
GO

--Service Time Ratio
ALTER TABLE RouteSummary
ADD ServiceTimeRatio FLOAT;
go
UPDATE RouteSummary
SET ServiceTimeRatio = TotalServiceTime/TotalTravelTime
                       
go
--AverageServiceTimePerStop
ALTER TABLE RouteSummary
ADD AverageServiceTimePerStop FLOAT;
go
UPDATE RouteSummary
SET AverageServiceTimePerStop = TotalServiceTime/ (select StopofNO from 
	(select RouteID,count(distinct StopID) as StopofNO from RouteData group by RouteID) as stopN
	WHERE stopN.RouteID = RouteSummary.RouteID);
go
--TotalPackages
ALTER TABLE RouteSummary
ADD TotalPackages INT;

UPDATE RouteSummary
SET TotalPackages = (SELECT TotalPackages
                     FROM (SELECT 
                             RouteID, 
                             COUNT(PackageID) AS TotalPackages
                           FROM 
                             PackageData
                           GROUP BY 
                             RouteID) AS PackageCounts
                     WHERE PackageCounts.RouteID = RouteSummary.RouteID);
GO
--Total Package Density
ALTER TABLE RouteSummary
ADD TotalPackageDensity FLOAT;
go
UPDATE RouteSummary
SET TotalPackageDensity = (SELECT TotalPackageDensity
                           FROM (SELECT 
                                   RouteID, 
                                   AVG(PackageDensity) AS TotalPackageDensity
                                 FROM 
                                   PackageData
                                 GROUP BY 
                                   RouteID) AS PackageDensities
                           WHERE PackageDensities.RouteID = RouteSummary.RouteID);
GO
--Delivery Success Rate
ALTER TABLE RouteSummary
ADD DeliverySuccessRate FLOAT;
go
UPDATE RouteSummary
SET DeliverySuccessRate = (
    SELECT CAST(SuccessRates.DeliverySuccess AS FLOAT) / CAST(TotalPackages AS FLOAT)
    FROM (
        SELECT 
            RouteID, 
            SUM(CASE WHEN scan_status = 'DELIVERED' THEN 1 ELSE 0 END) AS DeliverySuccess,
            COUNT(*) AS TotalPackages
        FROM 
            PackageData
        GROUP BY 
            RouteID
    ) AS SuccessRates
    WHERE SuccessRates.RouteID = RouteSummary.RouteID
);
GO
ALTER TABLE RouteSummary
ADD StopDensity FLOAT;
go
UPDATE RouteSummary
SET StopDensity = (
    SELECT stopN.StopofNO / RouteSummary.TotalDistanceKM
    FROM (
        SELECT RouteID, COUNT(DISTINCT StopID) AS StopofNO
        FROM RouteData
        GROUP BY RouteID
    ) AS stopN
    WHERE stopN.RouteID = RouteSummary.RouteID
);
go

ALTER TABLE RouteSummary
ADD TimeWindowCompliance FLOAT;
go
UPDATE RouteSummary
SET TimeWindowCompliance = (SELECT TimeWindowCompliance
                            FROM (SELECT 
                                    RouteID, 
                                    SUM(CASE WHEN DeliveryTimeUTC BETWEEN start_time_utc AND end_time_utc THEN 1 ELSE 0 END) * 1.0 / COUNT(PackageID) AS TimeWindowCompliance
                                  FROM 
                                    PackageData
                                  GROUP BY 
                                    RouteID) AS TimeCompliance
                            WHERE TimeCompliance.RouteID = RouteSummary.RouteID);
GO

--InvalidSequenceScore
ALTER TABLE RouteSummary
ADD InvalidSequenceScore FLOAT;
go

UPDATE RouteSummary
SET InvalidSequenceScore = (SELECT InvalidSequenceScore
							FROM InvalidSequenceScores
							where InvalidSequenceScores.RouteID = RouteSummary.RouteID)
go
--InvalidSequenceScore
ALTER TABLE RouteSummary
ADD RouteScore nvarchar(50);
go

UPDATE RouteSummary
SET RouteScore = (SELECT distinct RouteScore
							FROM RouteData
							where RouteData.RouteID = RouteSummary.RouteID)

--for distint route

SELECT
    tt.FromStopID,
    tt.ToStopID,
    avg(tt.TravelTimeSeconds) AS TravelTimeSeconds, -- Selection of average travelling time
    dbo.HaversineDistance(us1.Latitude, us1.Longitude, us2.Latitude, us2.Longitude) AS DistanceKM
INTO
    distinctTravelDistances
FROM
    TravelTimesData tt
    JOIN UniqueStops us1 ON tt.FromStopID = us1.StopID
    JOIN UniqueStops us2 ON tt.ToStopID = us2.StopID
GROUP BY
    tt.FromStopID,
    tt.ToStopID,
    us1.Latitude,
    us1.Longitude,
    us2.Latitude,
    us2.Longitude;
go