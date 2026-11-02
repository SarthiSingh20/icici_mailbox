using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;

namespace IciciMailBox.API.Services;

public sealed class ShipmentService(IShipmentRepository shipmentRepository) : IShipmentService
{
    public Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetDashboardSummaryAsync(cancellationToken);
}
