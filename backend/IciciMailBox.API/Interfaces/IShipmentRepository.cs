using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IShipmentRepository
{
    Task<DashboardSummaryDto> GetDashboardSummaryAsync(int? branchId, CancellationToken cancellationToken);
    Task<IReadOnlyList<BranchShipmentSummaryDto>> GetBranchShipmentSummaryAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(ShipmentQuery query, int? branchId, CancellationToken cancellationToken);
    Task<ShipmentDto?> GetShipmentAsync(long shipmentId, int? branchId, CancellationToken cancellationToken);
    Task<ShipmentDto> CreateShipmentAsync(CreateShipmentRequest request, int createdByUserId, CancellationToken cancellationToken);
    Task UpdateShipmentStatusAsync(long shipmentId, UpdateShipmentStatusRequest request, int changedByUserId, CancellationToken cancellationToken);
    Task<IReadOnlyList<ShipmentEventDto>> GetShipmentEventsAsync(long shipmentId, CancellationToken cancellationToken);
    Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<MasterOptionDto>> GetPackageCategoriesAsync(CancellationToken cancellationToken);
}
