-- Run this script in the IciciMailBox SQL Server database.
-- It is safe to run once on an empty database.

IF OBJECT_ID(N'dbo.Branches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Branches
    (
        BranchId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Branches PRIMARY KEY,
        BranchCode NVARCHAR(20) NOT NULL CONSTRAINT UQ_Branches_BranchCode UNIQUE,
        BranchName NVARCHAR(120) NOT NULL,
        City NVARCHAR(100) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Branches_IsActive DEFAULT (1),
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Branches_CreatedUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        CustomerId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
        CustomerCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_Customers_CustomerCode UNIQUE,
        CustomerName NVARCHAR(160) NOT NULL,
        Email NVARCHAR(254) NULL,
        Phone NVARCHAR(30) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT (1),
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_CreatedUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF OBJECT_ID(N'dbo.Shipments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Shipments
    (
        ShipmentId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Shipments PRIMARY KEY,
        TrackingNumber NVARCHAR(50) NOT NULL CONSTRAINT UQ_Shipments_TrackingNumber UNIQUE,
        Direction NVARCHAR(20) NOT NULL CONSTRAINT DF_Shipments_Direction DEFAULT (N'Outbound'),
        CustomerId INT NOT NULL,
        OriginBranchId INT NOT NULL,
        DestinationBranchId INT NOT NULL,
        PackageWeightKg DECIMAL(10,3) NOT NULL,
        RecipientName NVARCHAR(160) NOT NULL,
        RecipientAddress NVARCHAR(500) NOT NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Shipments_Status DEFAULT (N'Pending'),
        ReceivedUtc DATETIME2(0) NULL,
        SentUtc DATETIME2(0) NULL,
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        UpdatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_UpdatedUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_Shipments_Direction CHECK (Direction IN (N'Inbound', N'Outbound')),
        CONSTRAINT CK_Shipments_PackageWeightKg CHECK (PackageWeightKg > 0),
        CONSTRAINT CK_Shipments_Status CHECK (Status IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')),
        CONSTRAINT FK_Shipments_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
        CONSTRAINT FK_Shipments_OriginBranch FOREIGN KEY (OriginBranchId) REFERENCES dbo.Branches(BranchId),
        CONSTRAINT FK_Shipments_DestinationBranch FOREIGN KEY (DestinationBranchId) REFERENCES dbo.Branches(BranchId)
    );

    CREATE INDEX IX_Shipments_Status ON dbo.Shipments(Status);
    CREATE INDEX IX_Shipments_CreatedUtc ON dbo.Shipments(CreatedUtc DESC);
END;
GO

-- Upgrade an existing starter database created before shipment direction was introduced.
IF COL_LENGTH(N'dbo.Shipments', N'Direction') IS NULL
BEGIN
    ALTER TABLE dbo.Shipments
        ADD Direction NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Shipments_Direction DEFAULT (N'Outbound') WITH VALUES;

    ALTER TABLE dbo.Shipments
        ADD CONSTRAINT CK_Shipments_Direction
            CHECK (Direction IN (N'Inbound', N'Outbound'));
END;
GO

-- Upgrade an existing starter database with parcel weight and handover times.
IF COL_LENGTH(N'dbo.Shipments', N'PackageWeightKg') IS NULL
BEGIN
    ALTER TABLE dbo.Shipments ADD PackageWeightKg DECIMAL(10,3) NULL;
END;

IF COL_LENGTH(N'dbo.Shipments', N'ReceivedUtc') IS NULL
BEGIN
    ALTER TABLE dbo.Shipments ADD ReceivedUtc DATETIME2(0) NULL;
END;

IF COL_LENGTH(N'dbo.Shipments', N'SentUtc') IS NULL
BEGIN
    ALTER TABLE dbo.Shipments ADD SentUtc DATETIME2(0) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Shipments_PackageWeightKg'
      AND parent_object_id = OBJECT_ID(N'dbo.Shipments')
)
BEGIN
    ALTER TABLE dbo.Shipments
        ADD CONSTRAINT CK_Shipments_PackageWeightKg
            CHECK (PackageWeightKg IS NULL OR PackageWeightKg > 0);
END;
GO

IF OBJECT_ID(N'dbo.ShipmentEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentEvents
    (
        ShipmentEventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ShipmentEvents PRIMARY KEY,
        ShipmentId BIGINT NOT NULL,
        EventType NVARCHAR(50) NOT NULL,
        EventDescription NVARCHAR(500) NULL,
        EventUtc DATETIME2(0) NOT NULL CONSTRAINT DF_ShipmentEvents_EventUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_ShipmentEvents_Shipments FOREIGN KEY (ShipmentId) REFERENCES dbo.Shipments(ShipmentId)
    );

    CREATE INDEX IX_ShipmentEvents_ShipmentId_EventUtc ON dbo.ShipmentEvents(ShipmentId, EventUtc DESC);
END;
GO
