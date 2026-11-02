using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IShipmentService
{
    Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken);
}
