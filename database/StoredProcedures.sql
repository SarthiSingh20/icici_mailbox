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
    @RecipientAddress NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Shipments
    (
        TrackingNumber,
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

    SELECT ShipmentId, TrackingNumber, Status, CreatedUtc
    FROM dbo.Shipments
    WHERE ShipmentId = @ShipmentId;
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
