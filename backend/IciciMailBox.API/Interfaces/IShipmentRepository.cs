using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IShipmentRepository
{
    Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken);
}
