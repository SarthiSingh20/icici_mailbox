using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;

namespace IciciMailBox.API.Services;

public sealed class ShipmentService(IShipmentRepository shipmentRepository) : IShipmentService
{
    public Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetDashboardSummaryAsync(cancellationToken);

    public Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(
        string? direction,
        string? search,
        CancellationToken cancellationToken) =>
        shipmentRepository.GetShipmentsAsync(direction, search, cancellationToken);

    public Task<ShipmentDto?> GetShipmentAsync(long shipmentId, CancellationToken cancellationToken) =>
        shipmentRepository.GetShipmentAsync(shipmentId, cancellationToken);

    public Task<ShipmentDto> CreateShipmentAsync(CreateShipmentRequest request, CancellationToken cancellationToken) =>
        shipmentRepository.CreateShipmentAsync(Normalize(request), cancellationToken);

    public Task UpdateShipmentStatusAsync(
        long shipmentId,
        UpdateShipmentStatusRequest request,
        CancellationToken cancellationToken) =>
        shipmentRepository.UpdateShipmentStatusAsync(shipmentId, Normalize(request), cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetBranchesAsync(cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetCustomersAsync(cancellationToken);

    private static CreateShipmentRequest Normalize(CreateShipmentRequest request) => new()
    {
        TrackingNumber = request.TrackingNumber.Trim(),
        Direction = request.Direction.Trim(),
        CustomerId = request.CustomerId,
        OriginBranchId = request.OriginBranchId,
        DestinationBranchId = request.DestinationBranchId,
        PackageWeightKg = request.PackageWeightKg,
        RecipientName = request.RecipientName.Trim(),
        RecipientAddress = request.RecipientAddress.Trim(),
        ReceivedUtc = request.ReceivedUtc?.ToUniversalTime(),
        SentUtc = request.SentUtc?.ToUniversalTime()
    };

    private static UpdateShipmentStatusRequest Normalize(UpdateShipmentStatusRequest request) => new()
    {
        Status = request.Status.Trim(),
        EventDescription = string.IsNullOrWhiteSpace(request.EventDescription)
            ? null
            : request.EventDescription.Trim()
    };
}
