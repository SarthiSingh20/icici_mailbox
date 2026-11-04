CREATE OR ALTER PROCEDURE dbo.usp_Shipment_GetDashboardSummary
    @BranchId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ScopedShipments AS
    (
        SELECT *
        FROM dbo.Shipments
        WHERE @BranchId IS NULL
           OR (Direction = N'Inbound' AND DestinationBranchId = @BranchId)
           OR (Direction = N'Outbound' AND OriginBranchId = @BranchId)
    )
    SELECT
        TotalShipments = COUNT(*),
        TotalInbound = COALESCE(SUM(CASE WHEN Direction = N'Inbound' THEN 1 ELSE 0 END), 0),
        TotalOutbound = COALESCE(SUM(CASE WHEN Direction = N'Outbound' THEN 1 ELSE 0 END), 0),
        PendingShipments = COALESCE(SUM(CASE WHEN Status = N'Pending' THEN 1 ELSE 0 END), 0),
        InTransitShipments = COALESCE(SUM(CASE WHEN Status = N'InTransit' THEN 1 ELSE 0 END), 0),
        DeliveredShipments = COALESCE(SUM(CASE WHEN Status = N'Delivered' THEN 1 ELSE 0 END), 0),
        ReceivedToday = COALESCE(SUM(CASE WHEN ReceivedUtc >= CONVERT(date, SYSUTCDATETIME()) THEN 1 ELSE 0 END), 0),
        DispatchedToday = COALESCE(SUM(CASE WHEN SentUtc >= CONVERT(date, SYSUTCDATETIME()) THEN 1 ELSE 0 END), 0),
        ActiveBranches = CASE WHEN @BranchId IS NULL
            THEN (SELECT COUNT(*) FROM dbo.Branches WHERE IsActive = 1)
            ELSE 1 END,
        ActiveOperators = CASE WHEN @BranchId IS NULL
            THEN (SELECT COUNT(*) FROM dbo.Users AS u INNER JOIN dbo.Roles AS r ON r.RoleId = u.RoleId WHERE u.IsActive = 1 AND r.RoleName = N'BranchOperator')
            ELSE (SELECT COUNT(*) FROM dbo.Users AS u INNER JOIN dbo.Roles AS r ON r.RoleId = u.RoleId WHERE u.IsActive = 1 AND r.RoleName = N'BranchOperator' AND u.BranchId = @BranchId) END
    FROM ScopedShipments;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_GetList
    @Direction NVARCHAR(20) = NULL,
    @Search NVARCHAR(100) = NULL,
    @Status NVARCHAR(30) = NULL,
    @BranchId INT = NULL,
    @FromUtc DATETIME2(0) = NULL,
    @ToUtc DATETIME2(0) = NULL,
    @ShipmentId BIGINT = NULL,
    @Limit INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Direction IS NOT NULL AND @Direction NOT IN (N'Inbound', N'Outbound')
        THROW 50003, 'Invalid shipment direction.', 1;

    IF @Status IS NOT NULL AND @Status NOT IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')
        THROW 50001, 'Invalid shipment status.', 1;
    IF @Limit IS NOT NULL AND (@Limit < 1 OR @Limit > 500)
        THROW 50011, 'The shipment result limit must be between 1 and 500.', 1;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');

    SELECT TOP (ISNULL(@Limit, 2147483647))
        s.ShipmentId,
        s.Direction,
        s.TrackingNumber,
        s.CustomerId,
        c.CustomerName,
        s.SenderName,
        s.OriginBranchId,
        originBranch.BranchName AS OriginBranchName,
        s.DestinationBranchId,
        destinationBranch.BranchName AS DestinationBranchName,
        s.PackageCategoryId,
        COALESCE(category.CategoryName, N'Legacy uncategorized') AS PackageCategoryName,
        s.PackageWeightKg,
        s.PackageDescription,
        s.RecipientName,
        s.RecipientAddress,
        s.CourierServiceProvider,
        s.Remarks,
        s.Status,
        s.ReceivedUtc,
        s.SentUtc,
        s.ReceivedByUserId,
        receivedBy.DisplayName AS ReceivedByName,
        s.SentByUserId,
        sentBy.DisplayName AS SentByName,
        s.CreatedByUserId,
        COALESCE(createdBy.DisplayName, N'Legacy import') AS CreatedByName,
        s.IsDemo,
        s.CreatedUtc,
        s.UpdatedUtc
    FROM dbo.Shipments AS s
    INNER JOIN dbo.Customers AS c ON c.CustomerId = s.CustomerId
    INNER JOIN dbo.Branches AS originBranch ON originBranch.BranchId = s.OriginBranchId
    INNER JOIN dbo.Branches AS destinationBranch ON destinationBranch.BranchId = s.DestinationBranchId
    LEFT JOIN dbo.PackageCategories AS category ON category.PackageCategoryId = s.PackageCategoryId
    LEFT JOIN dbo.Users AS receivedBy ON receivedBy.UserId = s.ReceivedByUserId
    LEFT JOIN dbo.Users AS sentBy ON sentBy.UserId = s.SentByUserId
    LEFT JOIN dbo.Users AS createdBy ON createdBy.UserId = s.CreatedByUserId
    WHERE (@ShipmentId IS NULL OR s.ShipmentId = @ShipmentId)
      AND (@Direction IS NULL OR s.Direction = @Direction)
      AND (@Status IS NULL OR s.Status = @Status)
      AND (
          @BranchId IS NULL
          OR (@Direction = N'Inbound' AND s.DestinationBranchId = @BranchId)
          OR (@Direction = N'Outbound' AND s.OriginBranchId = @BranchId)
          OR (@Direction IS NULL AND (s.OriginBranchId = @BranchId OR s.DestinationBranchId = @BranchId))
      )
      AND (@FromUtc IS NULL OR COALESCE(s.ReceivedUtc, s.SentUtc, s.CreatedUtc) >= @FromUtc)
      AND (@ToUtc IS NULL OR COALESCE(s.ReceivedUtc, s.SentUtc, s.CreatedUtc) < DATEADD(day, 1, @ToUtc))
      AND (
          @Search IS NULL
          OR s.TrackingNumber LIKE N'%' + @Search + N'%'
          OR s.SenderName LIKE N'%' + @Search + N'%'
          OR c.CustomerName LIKE N'%' + @Search + N'%'
          OR s.RecipientName LIKE N'%' + @Search + N'%'
          OR s.PackageDescription LIKE N'%' + @Search + N'%'
      )
    ORDER BY s.CreatedUtc DESC, s.ShipmentId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Dashboard_GetBranchSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BranchId,
        b.BranchCode,
        b.BranchName,
        COUNT_BIG(s.ShipmentId) AS TotalShipments,
        COALESCE(SUM(CASE WHEN s.Direction = N'Inbound' AND s.DestinationBranchId = b.BranchId THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END), 0) AS InboundShipments,
        COALESCE(SUM(CASE WHEN s.Direction = N'Outbound' AND s.OriginBranchId = b.BranchId THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END), 0) AS OutboundShipments,
        COALESCE(SUM(CASE WHEN s.Status = N'Pending' THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END), 0) AS PendingShipments,
        COALESCE(SUM(CASE WHEN s.Status = N'Delivered' THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END), 0) AS DeliveredShipments
    FROM dbo.Branches AS b
    LEFT JOIN dbo.Shipments AS s
      ON (s.Direction = N'Inbound' AND s.DestinationBranchId = b.BranchId)
      OR (s.Direction = N'Outbound' AND s.OriginBranchId = b.BranchId)
    WHERE b.IsActive = 1
    GROUP BY b.BranchId, b.BranchCode, b.BranchName
    ORDER BY b.BranchName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_Create
    @TrackingNumber NVARCHAR(50),
    @Direction NVARCHAR(20),
    @SenderName NVARCHAR(160),
    @CustomerId INT,
    @OriginBranchId INT,
    @DestinationBranchId INT,
    @PackageCategoryId INT,
    @PackageWeightKg DECIMAL(10,3),
    @PackageDescription NVARCHAR(500) = NULL,
    @RecipientName NVARCHAR(160),
    @RecipientAddress NVARCHAR(500),
    @CourierServiceProvider NVARCHAR(160) = NULL,
    @Remarks NVARCHAR(1000) = NULL,
    @ReceivedUtc DATETIME2(0) = NULL,
    @SentUtc DATETIME2(0) = NULL,
    @CreatedByUserId INT,
    @IsDemo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Direction NOT IN (N'Inbound', N'Outbound')
        THROW 50003, 'Invalid shipment direction.', 1;
    IF NULLIF(LTRIM(RTRIM(@SenderName)), N'') IS NULL
        THROW 50009, 'Sender name is required.', 1;
    IF @PackageWeightKg <= 0
        THROW 50004, 'Package weight must be greater than zero.', 1;
    IF (@Direction = N'Inbound' AND @ReceivedUtc IS NULL)
       OR (@Direction = N'Outbound' AND @SentUtc IS NULL)
        THROW 50005, 'Inbound shipments require a receiving time and outbound shipments require a send time.', 1;

    IF @Direction = N'Inbound'
        SET @SentUtc = NULL;
    ELSE
        SET @ReceivedUtc = NULL;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Shipments
    (
        TrackingNumber, Direction, CustomerId, SenderName, OriginBranchId, DestinationBranchId,
        PackageCategoryId, PackageWeightKg, PackageDescription, RecipientName,
        RecipientAddress, CourierServiceProvider, Remarks, Status, ReceivedUtc,
        SentUtc, ReceivedByUserId, SentByUserId, CreatedByUserId, IsDemo
    )
    VALUES
    (
        @TrackingNumber, @Direction, @CustomerId, LTRIM(RTRIM(@SenderName)), @OriginBranchId, @DestinationBranchId,
        @PackageCategoryId, @PackageWeightKg, @PackageDescription, @RecipientName,
        @RecipientAddress, @CourierServiceProvider, @Remarks, N'Pending', @ReceivedUtc,
        @SentUtc,
        CASE WHEN @Direction = N'Inbound' THEN @CreatedByUserId ELSE NULL END,
        CASE WHEN @Direction = N'Outbound' THEN @CreatedByUserId ELSE NULL END,
        @CreatedByUserId, @IsDemo
    );

    DECLARE @ShipmentId BIGINT = SCOPE_IDENTITY();

    INSERT INTO dbo.ShipmentEvents (ShipmentId, EventType, NewStatus, EventDescription, ChangedByUserId)
    VALUES (@ShipmentId, N'Created', N'Pending', N'Shipment created.', @CreatedByUserId);

    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@CreatedByUserId, N'Create', N'Shipment', CONVERT(NVARCHAR(80), @ShipmentId), N'Shipment created.');

    COMMIT TRANSACTION;

    EXEC dbo.usp_Shipment_GetList @ShipmentId = @ShipmentId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_UpdateStatus
    @ShipmentId BIGINT,
    @Status NVARCHAR(30),
    @EventDescription NVARCHAR(500) = NULL,
    @ChangedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Status NOT IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')
        THROW 50001, 'Invalid shipment status.', 1;

    BEGIN TRANSACTION;

    DECLARE @PreviousStatus NVARCHAR(30);
    SELECT @PreviousStatus = Status
    FROM dbo.Shipments WITH (UPDLOCK, HOLDLOCK)
    WHERE ShipmentId = @ShipmentId;
    IF @PreviousStatus IS NULL
        THROW 50002, 'Shipment was not found.', 1;

    UPDATE dbo.Shipments
    SET Status = @Status, UpdatedUtc = SYSUTCDATETIME()
    WHERE ShipmentId = @ShipmentId;

    INSERT INTO dbo.ShipmentEvents (ShipmentId, EventType, PreviousStatus, NewStatus, EventDescription, ChangedByUserId)
    VALUES (@ShipmentId, N'StatusChanged', @PreviousStatus, @Status, @EventDescription, @ChangedByUserId);

    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@ChangedByUserId, N'UpdateStatus', N'Shipment', CONVERT(NVARCHAR(80), @ShipmentId), CONCAT(@PreviousStatus, N' to ', @Status));

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_GetEvents
    @ShipmentId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ShipmentEventId, e.EventType, e.PreviousStatus, e.NewStatus,
           e.EventDescription, e.EventUtc, e.ChangedByUserId,
           COALESCE(u.DisplayName, N'Legacy import') AS ChangedByName
    FROM dbo.ShipmentEvents AS e
    LEFT JOIN dbo.Users AS u ON u.UserId = e.ChangedByUserId
    WHERE e.ShipmentId = @ShipmentId
    ORDER BY e.EventUtc DESC, e.ShipmentEventId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Master_GetBranches
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BranchId AS Id, BranchCode AS Code, BranchName AS Name
    FROM dbo.Branches WHERE IsActive = 1 ORDER BY BranchName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Master_GetCustomers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CustomerId AS Id, CustomerCode AS Code, CustomerName AS Name
    FROM dbo.Customers WHERE IsActive = 1 ORDER BY CustomerName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Master_GetPackageCategories
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PackageCategoryId AS Id, CategoryCode AS Code, CategoryName AS Name
    FROM dbo.PackageCategories WHERE IsActive = 1 ORDER BY CategoryName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_User_GetByUsername
    @Username NVARCHAR(80)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.DisplayName, u.PasswordHash, u.PasswordSalt,
           u.PasswordIterations, u.IsActive, u.BranchId, b.BranchName,
           r.RoleName
    FROM dbo.Users AS u
    INNER JOIN dbo.Roles AS r ON r.RoleId = u.RoleId
    LEFT JOIN dbo.Branches AS b ON b.BranchId = u.BranchId
    WHERE u.Username = @Username;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_User_UpdateLastLogin
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    UPDATE dbo.Users SET LastLoginUtc = SYSUTCDATETIME() WHERE UserId = @UserId;
    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@UserId, N'Login', N'User', CONVERT(NVARCHAR(80), @UserId), N'User login succeeded.');

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_User_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.DisplayName, u.IsActive, u.BranchId,
           b.BranchName, r.RoleName, u.LastLoginUtc, u.CreatedUtc
    FROM dbo.Users AS u
    INNER JOIN dbo.Roles AS r ON r.RoleId = u.RoleId
    LEFT JOIN dbo.Branches AS b ON b.BranchId = u.BranchId
    ORDER BY r.RoleName, u.DisplayName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_User_Create
    @Username NVARCHAR(80),
    @DisplayName NVARCHAR(160),
    @PasswordHash VARBINARY(64),
    @PasswordSalt VARBINARY(32),
    @PasswordIterations INT,
    @RoleName NVARCHAR(40),
    @BranchId INT = NULL,
    @CreatedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RoleId INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = @RoleName);
    IF @RoleId IS NULL THROW 50006, 'Role was not found.', 1;
    IF @RoleName <> N'BranchOperator' THROW 50013, 'Only branch operator accounts may be created through this operation.', 1;
    IF @RoleName = N'BranchOperator' AND @BranchId IS NULL THROW 50007, 'A branch operator must be assigned to a branch.', 1;
    IF @RoleName = N'BranchOperator' AND NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchId = @BranchId AND IsActive = 1)
        THROW 50014, 'An active branch must be assigned to the branch operator.', 1;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (@Username, @DisplayName, @PasswordHash, @PasswordSalt, @PasswordIterations, @RoleId, @BranchId);

    DECLARE @UserId INT = SCOPE_IDENTITY();
    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@CreatedByUserId, N'Create', N'User', CONVERT(NVARCHAR(80), @UserId), N'Branch operator account created.');

    COMMIT TRANSACTION;

    SELECT @UserId AS UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_User_SetActive
    @UserId INT,
    @IsActive BIT,
    @ChangedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Users AS u
        INNER JOIN dbo.Roles AS r ON r.RoleId = u.RoleId
        WHERE u.UserId = @UserId AND r.RoleName = N'BranchOperator'
    )
        THROW 50015, 'Only branch operator accounts may be activated or deactivated.', 1;

    UPDATE dbo.Users SET IsActive = @IsActive WHERE UserId = @UserId;
    IF @@ROWCOUNT = 0 THROW 50008, 'User was not found.', 1;

    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@ChangedByUserId, N'SetActive', N'User', CONVERT(NVARCHAR(80), @UserId), IIF(@IsActive = 1, N'Activated', N'Deactivated'));

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Branch_Create
    @BranchCode NVARCHAR(20),
    @BranchName NVARCHAR(120),
    @City NVARCHAR(100),
    @CreatedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (@BranchCode, @BranchName, @City);
    DECLARE @BranchId INT = SCOPE_IDENTITY();
    INSERT INTO dbo.AuditLogs (UserId, Action, EntityType, EntityId, Detail)
    VALUES (@CreatedByUserId, N'Create', N'Branch', CONVERT(NVARCHAR(80), @BranchId), @BranchName);

    COMMIT TRANSACTION;

    SELECT @BranchId AS BranchId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AuditLog_GetRecent
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    IF @Limit < 1 OR @Limit > 500
        THROW 50012, 'The audit log result limit must be between 1 and 500.', 1;

    SELECT TOP (@Limit)
        a.AuditLogId,
        a.UserId,
        u.Username,
        u.DisplayName,
        a.Action,
        a.EntityType,
        a.EntityId,
        a.Detail,
        a.OccurredUtc
    FROM dbo.AuditLogs AS a
    LEFT JOIN dbo.Users AS u ON u.UserId = a.UserId
    ORDER BY a.OccurredUtc DESC, a.AuditLogId DESC;
END;
GO
