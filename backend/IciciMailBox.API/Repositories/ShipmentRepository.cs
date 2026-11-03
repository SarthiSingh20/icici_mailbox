using System.Data;
using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.Data.SqlClient;

namespace IciciMailBox.API.Repositories;

public sealed class ShipmentRepository(ISqlConnectionFactory connectionFactory) : IShipmentRepository
{
    public async Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.usp_Shipment_GetDashboardSummary", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return new DashboardSummaryDto(0, 0, 0, 0);
        }

        return new DashboardSummaryDto(
            reader.GetInt32(reader.GetOrdinal("TotalShipments")),
            reader.GetInt32(reader.GetOrdinal("PendingShipments")),
            reader.GetInt32(reader.GetOrdinal("InTransitShipments")),
            reader.GetInt32(reader.GetOrdinal("DeliveredShipments")));
    }

    public async Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(
        string? direction,
        string? search,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateStoredProcedureCommand(connection, "dbo.usp_Shipment_GetList");
        command.Parameters.Add("@Direction", SqlDbType.NVarChar, 20).Value = (object?)direction ?? DBNull.Value;
        command.Parameters.Add("@Search", SqlDbType.NVarChar, 100).Value = (object?)search ?? DBNull.Value;
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = DBNull.Value;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var shipments = new List<ShipmentDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            shipments.Add(ReadShipment(reader));
        }

        return shipments;
    }

    public async Task<ShipmentDto?> GetShipmentAsync(long shipmentId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateStoredProcedureCommand(connection, "dbo.usp_Shipment_GetList");
        command.Parameters.Add("@Direction", SqlDbType.NVarChar, 20).Value = DBNull.Value;
        command.Parameters.Add("@Search", SqlDbType.NVarChar, 100).Value = DBNull.Value;
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = shipmentId;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        return await reader.ReadAsync(cancellationToken) ? ReadShipment(reader) : null;
    }

    public async Task<ShipmentDto> CreateShipmentAsync(CreateShipmentRequest request, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateStoredProcedureCommand(connection, "dbo.usp_Shipment_Create");
        command.Parameters.Add("@TrackingNumber", SqlDbType.NVarChar, 50).Value = request.TrackingNumber;
        command.Parameters.Add("@CustomerId", SqlDbType.Int).Value = request.CustomerId;
        command.Parameters.Add("@OriginBranchId", SqlDbType.Int).Value = request.OriginBranchId;
        command.Parameters.Add("@DestinationBranchId", SqlDbType.Int).Value = request.DestinationBranchId;
        command.Parameters.Add("@RecipientName", SqlDbType.NVarChar, 160).Value = request.RecipientName;
        command.Parameters.Add("@RecipientAddress", SqlDbType.NVarChar, 500).Value = request.RecipientAddress;
        command.Parameters.Add("@Direction", SqlDbType.NVarChar, 20).Value = request.Direction;

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
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateStoredProcedureCommand(connection, "dbo.usp_Shipment_UpdateStatus");
        command.Parameters.Add("@ShipmentId", SqlDbType.BigInt).Value = shipmentId;
        command.Parameters.Add("@Status", SqlDbType.NVarChar, 30).Value = request.Status;
        command.Parameters.Add("@EventDescription", SqlDbType.NVarChar, 500).Value =
            (object?)request.EventDescription ?? DBNull.Value;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken) =>
        GetMasterOptionsAsync("dbo.usp_Master_GetBranches", cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken) =>
        GetMasterOptionsAsync("dbo.usp_Master_GetCustomers", cancellationToken);

    private async Task<IReadOnlyList<MasterOptionDto>> GetMasterOptionsAsync(
        string procedureName,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateStoredProcedureCommand(connection, procedureName);

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

    private static SqlCommand CreateStoredProcedureCommand(SqlConnection connection, string procedureName) =>
        new(procedureName, connection) { CommandType = CommandType.StoredProcedure };

    private static ShipmentDto ReadShipment(SqlDataReader reader) => new(
        reader.GetInt64(reader.GetOrdinal("ShipmentId")),
        reader.GetString(reader.GetOrdinal("Direction")),
        reader.GetString(reader.GetOrdinal("TrackingNumber")),
        reader.GetInt32(reader.GetOrdinal("CustomerId")),
        reader.GetString(reader.GetOrdinal("CustomerName")),
        reader.GetInt32(reader.GetOrdinal("OriginBranchId")),
        reader.GetString(reader.GetOrdinal("OriginBranchName")),
        reader.GetInt32(reader.GetOrdinal("DestinationBranchId")),
        reader.GetString(reader.GetOrdinal("DestinationBranchName")),
        reader.GetString(reader.GetOrdinal("RecipientName")),
        reader.GetString(reader.GetOrdinal("RecipientAddress")),
        reader.GetString(reader.GetOrdinal("Status")),
        reader.GetDateTime(reader.GetOrdinal("CreatedUtc")),
        reader.GetDateTime(reader.GetOrdinal("UpdatedUtc")));
}
