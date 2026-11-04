-- Run this script in the existing IciciMailBox SQL Server database.
-- It creates a new installation and upgrades the original starter schema in place.

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RoleId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        RoleName NVARCHAR(40) NOT NULL CONSTRAINT UQ_Roles_RoleName UNIQUE,
        Description NVARCHAR(200) NULL,
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Roles_CreatedUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO

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

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        Username NVARCHAR(80) NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
        DisplayName NVARCHAR(160) NOT NULL,
        PasswordHash VARBINARY(64) NOT NULL,
        PasswordSalt VARBINARY(32) NOT NULL,
        PasswordIterations INT NOT NULL,
        RoleId INT NOT NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
        LastLoginUtc DATETIME2(0) NULL,
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(RoleId),
        CONSTRAINT FK_Users_Branches FOREIGN KEY (BranchId) REFERENCES dbo.Branches(BranchId)
    );

    CREATE INDEX IX_Users_BranchId_IsActive ON dbo.Users(BranchId, IsActive);
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

IF OBJECT_ID(N'dbo.PackageCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PackageCategories
    (
        PackageCategoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PackageCategories PRIMARY KEY,
        CategoryCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_PackageCategories_CategoryCode UNIQUE,
        CategoryName NVARCHAR(100) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_PackageCategories_IsActive DEFAULT (1),
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_PackageCategories_CreatedUtc DEFAULT (SYSUTCDATETIME())
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
        SenderName NVARCHAR(160) NOT NULL,
        OriginBranchId INT NOT NULL,
        DestinationBranchId INT NOT NULL,
        PackageCategoryId INT NOT NULL,
        PackageWeightKg DECIMAL(10,3) NOT NULL,
        PackageDescription NVARCHAR(500) NULL,
        RecipientName NVARCHAR(160) NOT NULL,
        RecipientAddress NVARCHAR(500) NOT NULL,
        CourierServiceProvider NVARCHAR(160) NULL,
        Remarks NVARCHAR(1000) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Shipments_Status DEFAULT (N'Pending'),
        ReceivedUtc DATETIME2(0) NULL,
        SentUtc DATETIME2(0) NULL,
        ReceivedByUserId INT NULL,
        SentByUserId INT NULL,
        CreatedByUserId INT NOT NULL,
        IsDemo BIT NOT NULL CONSTRAINT DF_Shipments_IsDemo DEFAULT (0),
        CreatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        UpdatedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_UpdatedUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_Shipments_Direction CHECK (Direction IN (N'Inbound', N'Outbound')),
        CONSTRAINT CK_Shipments_PackageWeightKg CHECK (PackageWeightKg > 0),
        CONSTRAINT CK_Shipments_SenderName CHECK (LEN(LTRIM(RTRIM(SenderName))) > 0),
        CONSTRAINT CK_Shipments_Status CHECK (Status IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')),
        CONSTRAINT FK_Shipments_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
        CONSTRAINT FK_Shipments_OriginBranch FOREIGN KEY (OriginBranchId) REFERENCES dbo.Branches(BranchId),
        CONSTRAINT FK_Shipments_DestinationBranch FOREIGN KEY (DestinationBranchId) REFERENCES dbo.Branches(BranchId),
        CONSTRAINT FK_Shipments_PackageCategories FOREIGN KEY (PackageCategoryId) REFERENCES dbo.PackageCategories(PackageCategoryId),
        CONSTRAINT FK_Shipments_ReceivedByUsers FOREIGN KEY (ReceivedByUserId) REFERENCES dbo.Users(UserId),
        CONSTRAINT FK_Shipments_SentByUsers FOREIGN KEY (SentByUserId) REFERENCES dbo.Users(UserId),
        CONSTRAINT FK_Shipments_CreatedByUsers FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(UserId)
    );

    CREATE INDEX IX_Shipments_OriginBranchId_CreatedUtc ON dbo.Shipments(OriginBranchId, CreatedUtc DESC);
    CREATE INDEX IX_Shipments_DestinationBranchId_CreatedUtc ON dbo.Shipments(DestinationBranchId, CreatedUtc DESC);
    CREATE INDEX IX_Shipments_Status_CreatedUtc ON dbo.Shipments(Status, CreatedUtc DESC);
    CREATE INDEX IX_Shipments_Direction_CreatedUtc ON dbo.Shipments(Direction, CreatedUtc DESC);
END;
GO

-- Upgrade the starter Shipments table. Legacy rows retain NULL for newly captured data.
IF COL_LENGTH(N'dbo.Shipments', N'SenderName') IS NULL
    ALTER TABLE dbo.Shipments ADD SenderName NVARCHAR(160) NULL;

IF COL_LENGTH(N'dbo.Shipments', N'Direction') IS NULL
BEGIN
    ALTER TABLE dbo.Shipments ADD Direction NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Shipments_Direction DEFAULT (N'Outbound') WITH VALUES;
    ALTER TABLE dbo.Shipments ADD CONSTRAINT CK_Shipments_Direction
        CHECK (Direction IN (N'Inbound', N'Outbound'));
END;

IF COL_LENGTH(N'dbo.Shipments', N'PackageWeightKg') IS NULL
    ALTER TABLE dbo.Shipments ADD PackageWeightKg DECIMAL(10,3) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'PackageCategoryId') IS NULL
    ALTER TABLE dbo.Shipments ADD PackageCategoryId INT NULL;
IF COL_LENGTH(N'dbo.Shipments', N'PackageDescription') IS NULL
    ALTER TABLE dbo.Shipments ADD PackageDescription NVARCHAR(500) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'CourierServiceProvider') IS NULL
    ALTER TABLE dbo.Shipments ADD CourierServiceProvider NVARCHAR(160) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'Remarks') IS NULL
    ALTER TABLE dbo.Shipments ADD Remarks NVARCHAR(1000) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'ReceivedUtc') IS NULL
    ALTER TABLE dbo.Shipments ADD ReceivedUtc DATETIME2(0) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'SentUtc') IS NULL
    ALTER TABLE dbo.Shipments ADD SentUtc DATETIME2(0) NULL;
IF COL_LENGTH(N'dbo.Shipments', N'ReceivedByUserId') IS NULL
    ALTER TABLE dbo.Shipments ADD ReceivedByUserId INT NULL;
IF COL_LENGTH(N'dbo.Shipments', N'SentByUserId') IS NULL
    ALTER TABLE dbo.Shipments ADD SentByUserId INT NULL;
IF COL_LENGTH(N'dbo.Shipments', N'CreatedByUserId') IS NULL
    ALTER TABLE dbo.Shipments ADD CreatedByUserId INT NULL;
IF COL_LENGTH(N'dbo.Shipments', N'IsDemo') IS NULL
    ALTER TABLE dbo.Shipments ADD IsDemo BIT NOT NULL CONSTRAINT DF_Shipments_IsDemo DEFAULT (0) WITH VALUES;

UPDATE s
SET SenderName = c.CustomerName
FROM dbo.Shipments AS s
INNER JOIN dbo.Customers AS c ON c.CustomerId = s.CustomerId
WHERE s.SenderName IS NULL OR LEN(LTRIM(RTRIM(s.SenderName))) = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Users_BranchId_IsActive' AND object_id = OBJECT_ID(N'dbo.Users'))
    CREATE INDEX IX_Users_BranchId_IsActive ON dbo.Users(BranchId, IsActive);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipments_OriginBranchId_CreatedUtc' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE INDEX IX_Shipments_OriginBranchId_CreatedUtc ON dbo.Shipments(OriginBranchId, CreatedUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipments_DestinationBranchId_CreatedUtc' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE INDEX IX_Shipments_DestinationBranchId_CreatedUtc ON dbo.Shipments(DestinationBranchId, CreatedUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipments_Status_CreatedUtc' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE INDEX IX_Shipments_Status_CreatedUtc ON dbo.Shipments(Status, CreatedUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipments_Direction_CreatedUtc' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE INDEX IX_Shipments_Direction_CreatedUtc ON dbo.Shipments(Direction, CreatedUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Shipments_CreatedUtc' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE INDEX IX_Shipments_CreatedUtc ON dbo.Shipments(CreatedUtc DESC);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Shipments_SenderName' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT CK_Shipments_SenderName
        CHECK (SenderName IS NULL OR LEN(LTRIM(RTRIM(SenderName))) > 0);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Shipments_PackageWeightKg' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT CK_Shipments_PackageWeightKg
        CHECK (PackageWeightKg IS NULL OR PackageWeightKg > 0);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Shipments_Direction' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT CK_Shipments_Direction
        CHECK (Direction IN (N'Inbound', N'Outbound'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Shipments_Status' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT CK_Shipments_Status
        CHECK (Status IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled'));

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Shipments_TrackingNumber' AND object_id = OBJECT_ID(N'dbo.Shipments'))
    CREATE UNIQUE INDEX UQ_Shipments_TrackingNumber ON dbo.Shipments(TrackingNumber);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_Customers' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_Customers
        FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_OriginBranch' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_OriginBranch
        FOREIGN KEY (OriginBranchId) REFERENCES dbo.Branches(BranchId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_DestinationBranch' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_DestinationBranch
        FOREIGN KEY (DestinationBranchId) REFERENCES dbo.Branches(BranchId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_PackageCategories' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_PackageCategories
        FOREIGN KEY (PackageCategoryId) REFERENCES dbo.PackageCategories(PackageCategoryId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_ReceivedByUsers' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_ReceivedByUsers
        FOREIGN KEY (ReceivedByUserId) REFERENCES dbo.Users(UserId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_SentByUsers' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_SentByUsers
        FOREIGN KEY (SentByUserId) REFERENCES dbo.Users(UserId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Shipments_CreatedByUsers' AND parent_object_id = OBJECT_ID(N'dbo.Shipments'))
    ALTER TABLE dbo.Shipments WITH CHECK ADD CONSTRAINT FK_Shipments_CreatedByUsers
        FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(UserId);
GO

IF OBJECT_ID(N'dbo.ShipmentEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentEvents
    (
        ShipmentEventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ShipmentEvents PRIMARY KEY,
        ShipmentId BIGINT NOT NULL,
        EventType NVARCHAR(50) NOT NULL,
        PreviousStatus NVARCHAR(30) NULL,
        NewStatus NVARCHAR(30) NULL,
        EventDescription NVARCHAR(500) NULL,
        ChangedByUserId INT NULL,
        EventUtc DATETIME2(0) NOT NULL CONSTRAINT DF_ShipmentEvents_EventUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_ShipmentEvents_Shipments FOREIGN KEY (ShipmentId) REFERENCES dbo.Shipments(ShipmentId),
        CONSTRAINT FK_ShipmentEvents_Users FOREIGN KEY (ChangedByUserId) REFERENCES dbo.Users(UserId)
    );

    CREATE INDEX IX_ShipmentEvents_ShipmentId_EventUtc ON dbo.ShipmentEvents(ShipmentId, EventUtc DESC);
END;
GO

IF COL_LENGTH(N'dbo.ShipmentEvents', N'PreviousStatus') IS NULL
    ALTER TABLE dbo.ShipmentEvents ADD PreviousStatus NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.ShipmentEvents', N'NewStatus') IS NULL
    ALTER TABLE dbo.ShipmentEvents ADD NewStatus NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.ShipmentEvents', N'ChangedByUserId') IS NULL
    ALTER TABLE dbo.ShipmentEvents ADD ChangedByUserId INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ShipmentEvents_ShipmentId_EventUtc' AND object_id = OBJECT_ID(N'dbo.ShipmentEvents'))
    CREATE INDEX IX_ShipmentEvents_ShipmentId_EventUtc ON dbo.ShipmentEvents(ShipmentId, EventUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ShipmentEvents_Users' AND parent_object_id = OBJECT_ID(N'dbo.ShipmentEvents'))
    ALTER TABLE dbo.ShipmentEvents WITH CHECK ADD CONSTRAINT FK_ShipmentEvents_Users
        FOREIGN KEY (ChangedByUserId) REFERENCES dbo.Users(UserId);
GO

IF OBJECT_ID(N'dbo.ShipmentAttachments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentAttachments
    (
        ShipmentAttachmentId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ShipmentAttachments PRIMARY KEY,
        ShipmentId BIGINT NOT NULL,
        FileName NVARCHAR(260) NOT NULL,
        ContentType NVARCHAR(100) NOT NULL,
        StorageReference NVARCHAR(1000) NOT NULL,
        UploadedByUserId INT NOT NULL,
        UploadedUtc DATETIME2(0) NOT NULL CONSTRAINT DF_ShipmentAttachments_UploadedUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_ShipmentAttachments_Shipments FOREIGN KEY (ShipmentId) REFERENCES dbo.Shipments(ShipmentId),
        CONSTRAINT FK_ShipmentAttachments_Users FOREIGN KEY (UploadedByUserId) REFERENCES dbo.Users(UserId)
    );
END;
GO

IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        AuditLogId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLogs PRIMARY KEY,
        UserId INT NULL,
        Action NVARCHAR(100) NOT NULL,
        EntityType NVARCHAR(80) NOT NULL,
        EntityId NVARCHAR(80) NULL,
        Detail NVARCHAR(1000) NULL,
        OccurredUtc DATETIME2(0) NOT NULL CONSTRAINT DF_AuditLogs_OccurredUtc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_AuditLogs_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
    );

    CREATE INDEX IX_AuditLogs_OccurredUtc ON dbo.AuditLogs(OccurredUtc DESC);
    CREATE INDEX IX_AuditLogs_UserId_OccurredUtc ON dbo.AuditLogs(UserId, OccurredUtc DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_OccurredUtc' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_OccurredUtc ON dbo.AuditLogs(OccurredUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_UserId_OccurredUtc' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_UserId_OccurredUtc ON dbo.AuditLogs(UserId, OccurredUtc DESC);
GO
