using System.Data;
using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.Data.SqlClient;

namespace IciciMailBox.API.Repositories;

public sealed class ShipmentRepository(ISqlConnectionFactory connectionFactory) : IShipmentRepository
{
    public async Task<DashboardSummaryDto> GetDashboardSummaryAsync(int? branchId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_GetDashboardSummary");
        command.Parameters.Add("@BranchId", SqlDbType.Int).Value = (object?)branchId ?? DBNull.Value;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return new DashboardSummaryDto(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        }

        return new DashboardSummaryDto(
            reader.GetInt32(reader.GetOrdinal("TotalShipments")),
            reader.GetInt32(reader.GetOrdinal("TotalInbound")),
            reader.GetInt32(reader.GetOrdinal("TotalOutbound")),
            reader.GetInt32(reader.GetOrdinal("PendingShipments")),
            reader.GetInt32(reader.GetOrdinal("InTransitShipments")),
            reader.GetInt32(reader.GetOrdinal("DeliveredShipments")),
            reader.GetInt32(reader.GetOrdinal("ReceivedToday")),
            reader.GetInt32(reader.GetOrdinal("DispatchedToday")),
            reader.GetInt32(reader.GetOrdinal("ActiveBranches")),
            reader.GetInt32(reader.GetOrdinal("ActiveOperators")));
    }

    public async Task<IReadOnlyList<BranchShipmentSummaryDto>> GetBranchShipmentSummaryAsync(CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Dashboard_GetBranchSummary");
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var summaries = new List<BranchShipmentSummaryDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            summaries.Add(new BranchShipmentSummaryDto(
                reader.GetInt32(reader.GetOrdinal("BranchId")),
                reader.GetString(reader.GetOrdinal("BranchCode")),
                reader.GetString(reader.GetOrdinal("BranchName")),
                reader.GetInt64(reader.GetOrdinal("TotalShipments")),
                reader.GetInt64(reader.GetOrdinal("InboundShipments")),
                reader.GetInt64(reader.GetOrdinal("OutboundShipments")),
                reader.GetInt64(reader.GetOrdinal("PendingShipments")),
                reader.GetInt64(reader.GetOrdinal("DeliveredShipments"))));
        }

        return summaries;
    }

    public async Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(
        ShipmentQuery query,
        int? branchId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_GetList");
        AddShipmentListParameters(command, query, branchId ?? query.BranchId, null);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var shipments = new List<ShipmentDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            shipments.Add(ReadShipment(reader));
        }

        return shipments;
    }

    public async Task<ShipmentDto?> GetShipmentAsync(long shipmentId, int? branchId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_GetList");
        AddShipmentListParameters(command, new ShipmentQuery(), branchId, shipmentId);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? ReadShipment(reader) : null;
    }

    public async Task<ShipmentDto> CreateShipmentAsync(
        CreateShipmentRequest request,
        int createdByUserId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_Create");
        command.Parameters.Add("@TrackingNumber", SqlDbType.NVarChar, 50).Value = request.TrackingNumber;
        command.Parameters.Add("@Direction", SqlDbType.NVarChar, 20).Value = request.Direction;
        command.Parameters.Add("@SenderName", SqlDbType.NVarChar, 160).Value = request.SenderName;
        command.Parameters.Add("@CustomerId", SqlDbType.Int).Value = request.CustomerId;
        command.Parameters.Add("@OriginBranchId", SqlDbType.Int).Value = request.OriginBranchId;
        command.Parameters.Add("@DestinationBranchId", SqlDbType.Int).Value = request.DestinationBranchId;
        command.Parameters.Add("@PackageCategoryId", SqlDbType.Int).Value = request.PackageCategoryId;
        var weight = command.Parameters.Add("@PackageWeightKg", SqlDbType.Decimal);
        weight.Precision = 10;
        weight.Scale = 3;
        weight.Value = request.PackageWeightKg;
        command.Parameters.Add("@PackageDescription", SqlDbType.NVarChar, 500).Value = (object?)request.PackageDescription ?? DBNull.Value;
        command.Parameters.Add("@RecipientName", SqlDbType.NVarChar, 160).Value = request.RecipientName;
        command.Parameters.Add("@RecipientAddress", SqlDbType.NVarChar, 500).Value = request.RecipientAddress;
        command.Parameters.Add("@CourierServiceProvider", SqlDbType.NVarChar, 160).Value = (object?)request.CourierServiceProvider ?? DBNull.Value;
        command.Parameters.Add("@Remarks", SqlDbType.NVarChar, 1000).Value = (object?)request.Remarks ?? DBNull.Value;
        command.Parameters.Add("@ReceivedUtc", SqlDbType.DateTime2).Value = (object?)request.ReceivedUtc ?? DBNull.Value;
        command.Parameters.Add("@SentUtc", SqlDbType.DateTime2).Value = (object?)request.SentUtc ?? DBNull.Value;
        command.Parameters.Add("@CreatedByUserId", SqlDbType.Int).Value = createdByUserId;
        command.Parameters.Add("@IsDemo", SqlDbType.Bit).Value = false;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Shipment creation did not return a record.");
        }

        return ReadShipment(reader);
    }

    public async Task UpdateShipmentStatusAsync(
        long shipmentId,
        UpdateShipmentStatusRequest request,
        int changedByUserId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_UpdateStatus");
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = shipmentId;
        command.Parameters.Add("@Status", SqlDbType.NVarChar, 30).Value = request.Status;
        command.Parameters.Add("@EventDescription", SqlDbType.NVarChar, 500).Value = (object?)request.EventDescription ?? DBNull.Value;
        command.Parameters.Add("@ChangedByUserId", SqlDbType.Int).Value = changedByUserId;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<ShipmentEventDto>> GetShipmentEventsAsync(long shipmentId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Shipment_GetEvents");
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = shipmentId;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var events = new List<ShipmentEventDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            events.Add(new ShipmentEventDto(
                reader.GetInt64(reader.GetOrdinal("ShipmentEventId")),
                reader.GetString(reader.GetOrdinal("EventType")),
                StringOrNull(reader, "PreviousStatus"),
                StringOrNull(reader, "NewStatus"),
                StringOrNull(reader, "EventDescription"),
                reader.GetDateTime(reader.GetOrdinal("EventUtc")),
                IntOrNull(reader, "ChangedByUserId"),
                reader.GetString(reader.GetOrdinal("ChangedByName"))));
        }

        return events;
    }

    public Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken) =>
        GetMasterOptionsAsync("dbo.usp_Master_GetBranches", cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken) =>
        GetMasterOptionsAsync("dbo.usp_Master_GetCustomers", cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetPackageCategoriesAsync(CancellationToken cancellationToken) =>
        GetMasterOptionsAsync("dbo.usp_Master_GetPackageCategories", cancellationToken);

    private async Task<IReadOnlyList<MasterOptionDto>> GetMasterOptionsAsync(string procedureName, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, procedureName);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var options = new List<MasterOptionDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            options.Add(new MasterOptionDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetString(reader.GetOrdinal("Code")),
                reader.GetString(reader.GetOrdinal("Name"))));
        }

        return options;
    }

    private static void AddShipmentListParameters(SqlCommand command, ShipmentQuery query, int? branchId, long? shipmentId)
    {
        command.Parameters.Add("@Direction", SqlDbType.NVarChar, 20).Value = (object?)query.Direction ?? DBNull.Value;
        command.Parameters.Add("@Search", SqlDbType.NVarChar, 100).Value = (object?)query.Search ?? DBNull.Value;
        command.Parameters.Add("@Status", SqlDbType.NVarChar, 30).Value = (object?)query.Status ?? DBNull.Value;
        command.Parameters.Add("@BranchId", SqlDbType.Int).Value = (object?)branchId ?? DBNull.Value;
        command.Parameters.Add("@FromUtc", SqlDbType.DateTime2).Value = (object?)query.FromUtc?.ToUniversalTime() ?? DBNull.Value;
        command.Parameters.Add("@ToUtc", SqlDbType.DateTime2).Value = (object?)query.ToUtc?.ToUniversalTime() ?? DBNull.Value;
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = (object?)shipmentId ?? DBNull.Value;
        command.Parameters.Add("@Limit", SqlDbType.Int).Value = (object?)query.Limit ?? DBNull.Value;
    }

    private static SqlCommand Command(SqlConnection connection, string procedureName) =>
        new(procedureName, connection) { CommandType = CommandType.StoredProcedure };

    private static ShipmentDto ReadShipment(SqlDataReader reader) => new(
        reader.GetInt64(reader.GetOrdinal("ShipmentId")),
        reader.GetString(reader.GetOrdinal("Direction")),
        reader.GetString(reader.GetOrdinal("TrackingNumber")),
        reader.GetInt32(reader.GetOrdinal("CustomerId")),
        reader.GetString(reader.GetOrdinal("CustomerName")),
        StringOrNull(reader, "SenderName"),
        reader.GetInt32(reader.GetOrdinal("OriginBranchId")),
        reader.GetString(reader.GetOrdinal("OriginBranchName")),
        reader.GetInt32(reader.GetOrdinal("DestinationBranchId")),
        reader.GetString(reader.GetOrdinal("DestinationBranchName")),
        IntOrNull(reader, "PackageCategoryId"),
        reader.GetString(reader.GetOrdinal("PackageCategoryName")),
        DecimalOrNull(reader, "PackageWeightKg"),
        StringOrNull(reader, "PackageDescription"),
        reader.GetString(reader.GetOrdinal("RecipientName")),
        reader.GetString(reader.GetOrdinal("RecipientAddress")),
        StringOrNull(reader, "CourierServiceProvider"),
        StringOrNull(reader, "Remarks"),
        reader.GetString(reader.GetOrdinal("Status")),
        DateTimeOrNull(reader, "ReceivedUtc"),
        DateTimeOrNull(reader, "SentUtc"),
        IntOrNull(reader, "ReceivedByUserId"),
        StringOrNull(reader, "ReceivedByName"),
        IntOrNull(reader, "SentByUserId"),
        StringOrNull(reader, "SentByName"),
        IntOrNull(reader, "CreatedByUserId"),
        reader.GetString(reader.GetOrdinal("CreatedByName")),
        reader.GetBoolean(reader.GetOrdinal("IsDemo")),
        reader.GetDateTime(reader.GetOrdinal("CreatedUtc")),
        reader.GetDateTime(reader.GetOrdinal("UpdatedUtc")));

    private static string? StringOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetString(reader.GetOrdinal(column));

    private static int? IntOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetInt32(reader.GetOrdinal(column));

    private static decimal? DecimalOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetDecimal(reader.GetOrdinal(column));

    private static DateTime? DateTimeOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetDateTime(reader.GetOrdinal(column));
}
