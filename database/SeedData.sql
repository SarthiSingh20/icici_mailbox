-- Development/demo data only. Remove or rotate these accounts before production use.
-- All seeded shipment records are explicitly marked IsDemo = 1.

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'MasterUser')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES (N'MasterUser', N'Head office administrator');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'BranchOperator')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES (N'BranchOperator', N'Branch-level shipment operator');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'MUM')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'MUM', N'Mumbai Hub', N'Mumbai');
IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'DEL')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'DEL', N'Delhi Hub', N'New Delhi');
IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'BLR')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'BLR', N'Bengaluru Branch', N'Bengaluru');
IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE BranchCode = N'MAA')
    INSERT INTO dbo.Branches (BranchCode, BranchName, City) VALUES (N'MAA', N'Chennai Branch', N'Chennai');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PackageCategories WHERE CategoryCode = N'DOC')
    INSERT INTO dbo.PackageCategories (CategoryCode, CategoryName) VALUES (N'DOC', N'Confidential documents');
IF NOT EXISTS (SELECT 1 FROM dbo.PackageCategories WHERE CategoryCode = N'IT')
    INSERT INTO dbo.PackageCategories (CategoryCode, CategoryName) VALUES (N'IT', N'IT equipment');
IF NOT EXISTS (SELECT 1 FROM dbo.PackageCategories WHERE CategoryCode = N'CARD')
    INSERT INTO dbo.PackageCategories (CategoryCode, CategoryName) VALUES (N'CARD', N'Banking cards');
IF NOT EXISTS (SELECT 1 FROM dbo.PackageCategories WHERE CategoryCode = N'KIT')
    INSERT INTO dbo.PackageCategories (CategoryCode, CategoryName) VALUES (N'KIT', N'Branch operations kit');
IF NOT EXISTS (SELECT 1 FROM dbo.PackageCategories WHERE CategoryCode = N'OTHER')
    INSERT INTO dbo.PackageCategories (CategoryCode, CategoryName) VALUES (N'OTHER', N'Other parcel');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerCode = N'DEMO-001')
    INSERT INTO dbo.Customers (CustomerCode, CustomerName, Email, Phone) VALUES (N'DEMO-001', N'Demo Corporate Services', N'demo.corporate@example.test', N'+91-90000-00001');
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerCode = N'DEMO-002')
    INSERT INTO dbo.Customers (CustomerCode, CustomerName, Email, Phone) VALUES (N'DEMO-002', N'Demo Retail Operations', N'demo.retail@example.test', N'+91-90000-00002');
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerCode = N'DEMO-003')
    INSERT INTO dbo.Customers (CustomerCode, CustomerName, Email, Phone) VALUES (N'DEMO-003', N'Demo Treasury Office', N'demo.treasury@example.test', N'+91-90000-00003');
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerCode = N'DEMO-004')
    INSERT INTO dbo.Customers (CustomerCode, CustomerName, Email, Phone) VALUES (N'DEMO-004', N'Demo External Sender', N'demo.external@example.test', N'+91-90000-00004');
GO

-- Password for the local development accounts below: ChangeMe!2026
-- The values are PBKDF2-SHA256 hashes generated with a unique 16-byte salt and 210,000 iterations.
DECLARE @MasterRoleId INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'MasterUser');
DECLARE @OperatorRoleId INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'BranchOperator');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'ho.admin')
    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (N'ho.admin', N'Head Office Administrator', 0x027A73C31A2C7BEC9976D2E3E686620A60F987082E84F98722463DC732FC619E, 0x65B9F74941AFB7D21A5FBEDFFBB92741, 210000, @MasterRoleId, NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'mumbai.operator')
    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (N'mumbai.operator', N'Mumbai Branch Operator', 0x32185B9B575B5224489B6343BEE9AE6682B1493E49D18C2CD372C19FD59B2550, 0x862C015C1188E3800EE28DD80D3E181D, 210000, @OperatorRoleId, (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'MUM'));
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'delhi.operator')
    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (N'delhi.operator', N'Delhi Branch Operator', 0xDFB8269A50DB47AEC0CD9F91B7B751B39BDCB2CE37A81A661F521C9225F1F767, 0x33EF7DD7CA32816B9A6922A053BA2290, 210000, @OperatorRoleId, (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'DEL'));
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'bengaluru.operator')
    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (N'bengaluru.operator', N'Bengaluru Branch Operator', 0x7C520DD45D011F7774EF63E554C83062C19B4A104999439CE05701A36609B365, 0xC04C3517BB544E24CE0B9C959E246369, 210000, @OperatorRoleId, (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'BLR'));
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'chennai.operator')
    INSERT INTO dbo.Users (Username, DisplayName, PasswordHash, PasswordSalt, PasswordIterations, RoleId, BranchId)
    VALUES (N'chennai.operator', N'Chennai Branch Operator', 0x56CA40CB5B5B5ED97E5B0D37EB97C38A39B3373192B6F6F501490CD21B051CFD, 0xF72BA8CC9A4ECFC568AC191FE135B1B4, 210000, @OperatorRoleId, (SELECT BranchId FROM dbo.Branches WHERE BranchCode = N'MAA'));
GO

DECLARE @DemoShipments TABLE
(
    TrackingNumber NVARCHAR(50) PRIMARY KEY,
    Direction NVARCHAR(20),
    CustomerCode NVARCHAR(30),
    OriginCode NVARCHAR(20),
    DestinationCode NVARCHAR(20),
    CategoryCode NVARCHAR(30),
    WeightKg DECIMAL(10,3),
    PackageDescription NVARCHAR(500),
    RecipientName NVARCHAR(160),
    RecipientAddress NVARCHAR(500),
    Courier NVARCHAR(160),
    Remarks NVARCHAR(1000),
    DaysAgo INT,
    Status NVARCHAR(30)
);

INSERT INTO @DemoShipments VALUES
(N'ICICI-DEMO-1001', N'Inbound',  N'DEMO-001', N'DEL', N'MUM', N'DOC',   0.450, N'KYC document packet', N'Aditi Shah', N'Mumbai Hub records desk', N'ICICI Internal Logistics', N'DEMO RECORD', 1, N'Delivered'),
(N'ICICI-DEMO-1002', N'Inbound',  N'DEMO-002', N'BLR', N'MUM', N'CARD',  0.300, N'Replacement card dispatch', N'Rahul Mehta', N'Mumbai Hub retail desk', N'ICICI Internal Logistics', N'DEMO RECORD', 2, N'InTransit'),
(N'ICICI-DEMO-1003', N'Inbound',  N'DEMO-003', N'MAA', N'MUM', N'KIT',   2.150, N'Treasury operations kit', N'Kavita Iyer', N'Mumbai Hub treasury desk', N'SecureExpress', N'DEMO RECORD', 3, N'Pending'),
(N'ICICI-DEMO-1004', N'Inbound',  N'DEMO-004', N'DEL', N'BLR', N'IT',    3.700, N'Encrypted laptop return', N'Venkatesh Rao', N'Bengaluru Branch IT desk', N'BlueDart', N'DEMO RECORD', 4, N'Delivered'),
(N'ICICI-DEMO-1005', N'Inbound',  N'DEMO-001', N'MUM', N'BLR', N'DOC',   0.650, N'Audit correspondence', N'Priya Nair', N'Bengaluru Branch audit desk', N'ICICI Internal Logistics', N'DEMO RECORD', 5, N'InTransit'),
(N'ICICI-DEMO-1006', N'Inbound',  N'DEMO-002', N'MAA', N'BLR', N'CARD',  0.250, N'Card stock allocation', N'Arjun Kumar', N'Bengaluru Branch retail desk', N'SecureExpress', N'DEMO RECORD', 6, N'Pending'),
(N'ICICI-DEMO-1007', N'Inbound',  N'DEMO-003', N'MUM', N'DEL', N'KIT',   1.850, N'Branch operations kit', N'Neha Gupta', N'Delhi Hub operations desk', N'ICICI Internal Logistics', N'DEMO RECORD', 7, N'Delivered'),
(N'ICICI-DEMO-1008', N'Inbound',  N'DEMO-004', N'BLR', N'DEL', N'OTHER', 0.900, N'Customer correspondence', N'Rohit Bansal', N'Delhi Hub service desk', N'BlueDart', N'DEMO RECORD', 8, N'Cancelled'),
(N'ICICI-DEMO-1009', N'Inbound',  N'DEMO-001', N'MUM', N'MAA', N'DOC',   0.500, N'Compliance document file', N'Meera Krishnan', N'Chennai Branch compliance desk', N'ICICI Internal Logistics', N'DEMO RECORD', 9, N'Delivered'),
(N'ICICI-DEMO-1010', N'Inbound',  N'DEMO-002', N'DEL', N'MAA', N'CARD',  0.330, N'Priority card packet', N'Sanjay Pillai', N'Chennai Branch retail desk', N'SecureExpress', N'DEMO RECORD', 10, N'InTransit'),
(N'ICICI-DEMO-1011', N'Outbound', N'DEMO-003', N'MUM', N'DEL', N'DOC',   0.425, N'Head office compliance response', N'Head Office Compliance', N'Delhi Hub head office bag', N'ICICI Internal Logistics', N'DEMO RECORD', 1, N'Delivered'),
(N'ICICI-DEMO-1012', N'Outbound', N'DEMO-004', N'MUM', N'BLR', N'IT',    4.200, N'Branch printer component', N'Bengaluru IT Operations', N'Bengaluru Branch', N'BlueDart', N'DEMO RECORD', 2, N'InTransit'),
(N'ICICI-DEMO-1013', N'Outbound', N'DEMO-001', N'MUM', N'MAA', N'KIT',   2.600, N'Cash handling consumables', N'Chennai Operations', N'Chennai Branch', N'SecureExpress', N'DEMO RECORD', 3, N'Pending'),
(N'ICICI-DEMO-1014', N'Outbound', N'DEMO-002', N'DEL', N'MUM', N'CARD',  0.280, N'Card personalization batch', N'Mumbai Retail Operations', N'Mumbai Hub', N'ICICI Internal Logistics', N'DEMO RECORD', 4, N'Delivered'),
(N'ICICI-DEMO-1015', N'Outbound', N'DEMO-003', N'DEL', N'BLR', N'DOC',   0.720, N'Treasury reconciliation file', N'Bengaluru Treasury Desk', N'Bengaluru Branch', N'BlueDart', N'DEMO RECORD', 5, N'InTransit'),
(N'ICICI-DEMO-1016', N'Outbound', N'DEMO-004', N'DEL', N'MAA', N'OTHER', 1.100, N'Signed customer forms', N'Chennai Customer Service', N'Chennai Branch', N'SecureExpress', N'DEMO RECORD', 6, N'Pending'),
(N'ICICI-DEMO-1017', N'Outbound', N'DEMO-001', N'BLR', N'MUM', N'IT',    3.350, N'Network appliance return', N'Mumbai IT Operations', N'Mumbai Hub', N'BlueDart', N'DEMO RECORD', 7, N'Delivered'),
(N'ICICI-DEMO-1018', N'Outbound', N'DEMO-002', N'BLR', N'DEL', N'CARD',  0.310, N'Card fulfilment package', N'Delhi Retail Operations', N'Delhi Hub', N'ICICI Internal Logistics', N'DEMO RECORD', 8, N'Cancelled'),
(N'ICICI-DEMO-1019', N'Outbound', N'DEMO-003', N'MAA', N'MUM', N'DOC',   0.580, N'Branch audit evidence', N'Mumbai Audit Desk', N'Mumbai Hub', N'SecureExpress', N'DEMO RECORD', 9, N'Delivered'),
(N'ICICI-DEMO-1020', N'Outbound', N'DEMO-004', N'MAA', N'BLR', N'KIT',   1.950, N'Customer onboarding kit', N'Bengaluru Service Desk', N'Bengaluru Branch', N'ICICI Internal Logistics', N'DEMO RECORD', 10, N'InTransit');

DECLARE @TrackingNumber NVARCHAR(50), @Direction NVARCHAR(20), @CustomerCode NVARCHAR(30), @OriginCode NVARCHAR(20), @DestinationCode NVARCHAR(20), @CategoryCode NVARCHAR(30), @WeightKg DECIMAL(10,3), @PackageDescription NVARCHAR(500), @RecipientName NVARCHAR(160), @RecipientAddress NVARCHAR(500), @Courier NVARCHAR(160), @Remarks NVARCHAR(1000), @DaysAgo INT, @Status NVARCHAR(30);
DECLARE @OriginBranchId INT, @DestinationBranchId INT, @OperatorBranchId INT, @CreatedByUserId INT;
DECLARE @CustomerId INT, @SenderName NVARCHAR(160), @PackageCategoryId INT, @ShipmentId BIGINT;
DECLARE @RecordedUtc DATETIME2(0), @ReceivedUtc DATETIME2(0), @SentUtc DATETIME2(0);
DECLARE demo_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT TrackingNumber, Direction, CustomerCode, OriginCode, DestinationCode, CategoryCode, WeightKg, PackageDescription, RecipientName, RecipientAddress, Courier, Remarks, DaysAgo, Status FROM @DemoShipments;
OPEN demo_cursor;
FETCH NEXT FROM demo_cursor INTO @TrackingNumber, @Direction, @CustomerCode, @OriginCode, @DestinationCode, @CategoryCode, @WeightKg, @PackageDescription, @RecipientName, @RecipientAddress, @Courier, @Remarks, @DaysAgo, @Status;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Shipments WHERE TrackingNumber = @TrackingNumber)
    BEGIN
        SELECT @OriginBranchId = NULL, @DestinationBranchId = NULL, @CreatedByUserId = NULL,
               @CustomerId = NULL, @SenderName = NULL, @PackageCategoryId = NULL, @ShipmentId = NULL;
        SELECT @OriginBranchId = BranchId FROM dbo.Branches WHERE BranchCode = @OriginCode;
        SELECT @DestinationBranchId = BranchId FROM dbo.Branches WHERE BranchCode = @DestinationCode;
        SET @OperatorBranchId = IIF(@Direction = N'Inbound', @DestinationBranchId, @OriginBranchId);
        SELECT TOP (1) @CreatedByUserId = UserId FROM dbo.Users
        WHERE BranchId = @OperatorBranchId AND Username LIKE N'%.operator';
        SELECT @CustomerId = CustomerId, @SenderName = CustomerName
        FROM dbo.Customers WHERE CustomerCode = @CustomerCode;
        SELECT @PackageCategoryId = PackageCategoryId
        FROM dbo.PackageCategories WHERE CategoryCode = @CategoryCode;
        SET @RecordedUtc = DATEADD(day, -@DaysAgo, SYSUTCDATETIME());
        SET @ReceivedUtc = IIF(@Direction = N'Inbound', @RecordedUtc, NULL);
        SET @SentUtc = IIF(@Direction = N'Outbound', @RecordedUtc, NULL);

        IF @OriginBranchId IS NULL OR @DestinationBranchId IS NULL OR @CustomerId IS NULL
           OR @PackageCategoryId IS NULL OR @CreatedByUserId IS NULL
            THROW 50010, 'Demo seed prerequisites are missing.', 1;

        EXEC dbo.usp_Shipment_Create
            @TrackingNumber = @TrackingNumber,
            @Direction = @Direction,
            @SenderName = @SenderName,
            @CustomerId = @CustomerId,
            @OriginBranchId = @OriginBranchId,
            @DestinationBranchId = @DestinationBranchId,
            @PackageCategoryId = @PackageCategoryId,
            @PackageWeightKg = @WeightKg,
            @PackageDescription = @PackageDescription,
            @RecipientName = @RecipientName,
            @RecipientAddress = @RecipientAddress,
            @CourierServiceProvider = @Courier,
            @Remarks = @Remarks,
            @ReceivedUtc = @ReceivedUtc,
            @SentUtc = @SentUtc,
            @CreatedByUserId = @CreatedByUserId,
            @IsDemo = 1;

        IF @Status <> N'Pending'
        BEGIN
            SELECT @ShipmentId = ShipmentId FROM dbo.Shipments WHERE TrackingNumber = @TrackingNumber;
            EXEC dbo.usp_Shipment_UpdateStatus
                @ShipmentId = @ShipmentId,
                @Status = @Status,
                @EventDescription = N'DEMO RECORD status update.',
                @ChangedByUserId = @CreatedByUserId;
        END;
    END;

    FETCH NEXT FROM demo_cursor INTO @TrackingNumber, @Direction, @CustomerCode, @OriginCode, @DestinationCode, @CategoryCode, @WeightKg, @PackageDescription, @RecipientName, @RecipientAddress, @Courier, @Remarks, @DaysAgo, @Status;
END;

CLOSE demo_cursor;
DEALLOCATE demo_cursor;
GO
