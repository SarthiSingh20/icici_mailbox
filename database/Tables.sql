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
        CustomerId INT NOT NULL,
        OriginBranchId INT NOT NULL,
        DestinationBranchId INT NOT NULL,
        RecipientName NVARCHAR(160) NOT NULL,
        RecipientAddress NVARCHAR(500) NOT NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Shipments_Status DEFAULT (N'Pending'),
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        UpdatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_UpdatedUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_Shipments_Status CHECK (Status IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')),
        CONSTRAINT FK_Shipments_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
        CONSTRAINT FK_Shipments_OriginBranch FOREIGN KEY (OriginBranchId) REFERENCES dbo.Branches(BranchId),
        CONSTRAINT FK_Shipments_DestinationBranch FOREIGN KEY (DestinationBranchId) REFERENCES dbo.Branches(BranchId)
    );

    CREATE INDEX IX_Shipments_Status ON dbo.Shipments(Status);
    CREATE INDEX IX_Shipments_CreatedUtc ON dbo.Shipments(CreatedUtc DESC);
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
