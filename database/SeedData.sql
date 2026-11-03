IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'MUM')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'MUM', N'Mumbai Hub', N'Mumbai');

IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'DEL')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'DEL', N'Delhi Hub', N'New Delhi');

IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerCode = N'DEMO-001')
    INSERT INTO dbo.Customers (CustomerCode, CustomerName, Email, Phone)
    VALUES (N'DEMO-001', N'Demo Customer', N'demo@example.com', N'+91-90000-00000');
GO

DECLARE @CustomerId INT = (SELECT CustomerId FROM dbo.Customers WHERE CustomerCode = N'DEMO-001');
DECLARE @MumbaiBranchId INT = (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'MUM');
DECLARE @DelhiBranchId INT = (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'DEL');

IF NOT EXISTS (SELECT 1 FROM dbo.Shipments WHERE TrackingNumber = N'ICICI-DEMO-0001')
BEGIN
    EXEC dbo.usp_Shipment_Create
        @TrackingNumber = N'ICICI-DEMO-0001',
        @CustomerId = @CustomerId,
        @OriginBranchId = @MumbaiBranchId,
        @DestinationBranchId = @DelhiBranchId,
        @RecipientName = N'Demo Recipient',
        @RecipientAddress = N'1 Demo Street, New Delhi',
        @Direction = N'Outbound';

    EXEC dbo.usp_Shipment_UpdateStatus
        @ShipmentId = (SELECT ShipmentId FROM dbo.Shipments WHERE TrackingNumber = N'ICICI-DEMO-0001'),
        @Status = N'InTransit',
        @EventDescription = N'Dispatched from Mumbai Hub.';
END;
GO
