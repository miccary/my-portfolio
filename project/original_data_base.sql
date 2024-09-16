USE LogisticsData;
--USE Applyed_Logistics_database
CREATE TABLE PackageData (
    RouteID VARCHAR(255),
    StopID VARCHAR(255),
    PackageID VARCHAR(255),
    ScanStatus VARCHAR(50),
    StartTimeUTC DATETIME,
    EndTimeUTC DATETIME,
    PlannedServiceTimeSeconds FLOAT,
    DepthCM FLOAT,
    HeightCM FLOAT,
    WidthCM FLOAT
);

CREATE TABLE RouteData (
    RouteID VARCHAR(255),
    StationCode VARCHAR(50),
    DepartureDate DATE,
    DepartureTimeUTC DATETIME,
    ExecutorCapacityCM3 INT,
    RouteScore VARCHAR(50),
    StopID VARCHAR(255),
    Latitude FLOAT,
    Longitude FLOAT,
    StopType VARCHAR(50),
    ZoneID VARCHAR(50)
);

CREATE TABLE TravelTimesData (
    RouteID VARCHAR(255),
    FromStopID VARCHAR(255),
    ToStopID VARCHAR(255),
    TravelTimeSeconds FLOAT
);

CREATE TABLE InvalidSequenceScores (
    RouteID VARCHAR(255),
    InvalidSequenceScore FLOAT
);

CREATE TABLE ActualSequencesData (
    RouteID VARCHAR(255),
    StopID VARCHAR(255),
    Sequence INT
);
