CREATE OR ALTER PROCEDURE dbo.usp_Shipment_GetDashboardSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TotalShipments = COUNT(*),
        PendingShipments = COALESCE(SUM(CASE WHEN Status = N'Pending' THEN 1 ELSE 0 END), 0),
        InTransitShipments = COALESCE(SUM(CASE WHEN Status = N'InTransit' THEN 1 ELSE 0 END), 0),
        DeliveredShipments = COALESCE(SUM(CASE WHEN Status = N'Delivered' THEN 1 ELSE 0 END), 0)
    FROM dbo.Shipments;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_Create
    @TrackingNumber NVARCHAR(50),
    @CustomerId INT,
    @OriginBranchId INT,
    @DestinationBranchId INT,
    @RecipientName NVARCHAR(160),
    @RecipientAddress NVARCHAR(500),
    @Direction NVARCHAR(20) = N'Outbound'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Direction NOT IN (N'Inbound', N'Outbound')
    BEGIN
        THROW 50003, 'Invalid shipment direction.', 1;
    END;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Shipments
    (
        TrackingNumber,
        Direction,
        CustomerId,
        OriginBranchId,
        DestinationBranchId,
        RecipientName,
        RecipientAddress,
        Status
    )
    VALUES
    (
        @TrackingNumber,
        @Direction,
        @CustomerId,
        @OriginBranchId,
        @DestinationBranchId,
        @RecipientName,
        @RecipientAddress,
        N'Pending'
    );

    DECLARE @ShipmentId BIGINT = SCOPE_IDENTITY();

    INSERT INTO dbo.ShipmentEvents (ShipmentId, EventType, EventDescription)
    VALUES (@ShipmentId, N'Created', N'Shipment created.');

    COMMIT TRANSACTION;

    SELECT
        s.ShipmentId,
        s.Direction,
        s.TrackingNumber,
        s.CustomerId,
        c.CustomerName,
        s.OriginBranchId,
        originBranch.BranchName AS OriginBranchName,
        s.DestinationBranchId,
        destinationBranch.BranchName AS DestinationBranchName,
        s.RecipientName,
        s.RecipientAddress,
        s.Status,
        s.CreatedUtc,
        s.UpdatedUtc
    FROM dbo.Shipments AS s
    INNER JOIN dbo.Customers AS c ON c.CustomerId = s.CustomerId
    INNER JOIN dbo.Branches AS originBranch ON originBranch.BranchId = s.OriginBranchId
    INNER JOIN dbo.Branches AS destinationBranch ON destinationBranch.BranchId = s.DestinationBranchId
    WHERE s.ShipmentId = @ShipmentId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_GetList
    @Direction NVARCHAR(20) = NULL,
    @Search NVARCHAR(100) = NULL,
    @ShipmentId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Direction IS NOT NULL AND @Direction NOT IN (N'Inbound', N'Outbound')
    BEGIN
        THROW 50003, 'Invalid shipment direction.', 1;
    END;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');

    SELECT
        s.ShipmentId,
        s.Direction,
        s.TrackingNumber,
        s.CustomerId,
        c.CustomerName,
        s.OriginBranchId,
        originBranch.BranchName AS OriginBranchName,
        s.DestinationBranchId,
        destinationBranch.BranchName AS DestinationBranchName,
        s.RecipientName,
        s.RecipientAddress,
        s.Status,
        s.CreatedUtc,
        s.UpdatedUtc
    FROM dbo.Shipments AS s
    INNER JOIN dbo.Customers AS c ON c.CustomerId = s.CustomerId
    INNER JOIN dbo.Branches AS originBranch ON originBranch.BranchId = s.OriginBranchId
    INNER JOIN dbo.Branches AS destinationBranch ON destinationBranch.BranchId = s.DestinationBranchId
    WHERE (@ShipmentId IS NULL OR s.ShipmentId = @ShipmentId)
      AND (@Direction IS NULL OR s.Direction = @Direction)
      AND (
          @Search IS NULL
          OR s.TrackingNumber LIKE N'%' + @Search + N'%'
          OR c.CustomerName LIKE N'%' + @Search + N'%'
          OR s.RecipientName LIKE N'%' + @Search + N'%'
      )
    ORDER BY s.CreatedUtc DESC, s.ShipmentId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Master_GetBranches
AS
BEGIN
    SET NOCOUNT ON;

    SELECT BranchId AS Id, BranchCode AS Code, BranchName AS Name
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY BranchName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Master_GetCustomers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CustomerId AS Id, CustomerCode AS Code, CustomerName AS Name
    FROM dbo.Customers
    WHERE IsActive = 1
    ORDER BY CustomerName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Shipment_UpdateStatus
    @ShipmentId BIGINT,
    @Status NVARCHAR(30),
    @EventDescription NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Status NOT IN (N'Pending', N'InTransit', N'Delivered', N'Cancelled')
    BEGIN
        THROW 50001, 'Invalid shipment status.', 1;
    END;

    BEGIN TRANSACTION;

    UPDATE dbo.Shipments
    SET Status = @Status,
        UpdatedUtc = SYSUTCDATETIME()
    WHERE ShipmentId = @ShipmentId;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50002, 'Shipment was not found.', 1;
    END;

    INSERT INTO dbo.ShipmentEvents (ShipmentId, EventType, EventDescription)
    VALUES (@ShipmentId, @Status, @EventDescription);

    COMMIT TRANSACTION;
END;
GO
