using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IShipmentService
{
    Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(string? direction, string? search, CancellationToken cancellationToken);
    Task<ShipmentDto?> GetShipmentAsync(long shipmentId, CancellationToken cancellationToken);
    Task<ShipmentDto> CreateShipmentAsync(CreateShipmentRequest request, CancellationToken cancellationToken);
    Task UpdateShipmentStatusAsync(long shipmentId, UpdateShipmentStatusRequest request, CancellationToken cancellationToken);
    Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken);
}
