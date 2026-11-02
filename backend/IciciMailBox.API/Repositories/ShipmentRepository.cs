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
}
