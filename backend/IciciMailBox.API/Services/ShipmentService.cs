using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;

namespace IciciMailBox.API.Services;

public sealed class ShipmentService(
    IShipmentRepository shipmentRepository,
    ICurrentUser currentUser) : IShipmentService
{
    public Task<DashboardSummaryDto> GetDashboardSummaryAsync(CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        return shipmentRepository.GetDashboardSummaryAsync(BranchScope(scope), cancellationToken);
    }

    public Task<IReadOnlyList<BranchShipmentSummaryDto>> GetBranchShipmentSummaryAsync(CancellationToken cancellationToken)
    {
        if (!currentUser.Require().IsMaster)
        {
            throw new UnauthorizedAccessException("Master user access is required.");
        }

        return shipmentRepository.GetBranchShipmentSummaryAsync(cancellationToken);
    }

    public Task<IReadOnlyList<ShipmentDto>> GetShipmentsAsync(ShipmentQuery query, CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        var effectiveQuery = scope.IsMaster
            ? query
            : new ShipmentQuery
            {
                Direction = query.Direction,
                Search = query.Search,
                Status = query.Status,
                FromUtc = query.FromUtc,
                ToUtc = query.ToUtc,
                Limit = query.Limit
            };
        return shipmentRepository.GetShipmentsAsync(effectiveQuery, BranchScope(scope), cancellationToken);
    }

    public Task<ShipmentDto?> GetShipmentAsync(long shipmentId, CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        return shipmentRepository.GetShipmentAsync(shipmentId, BranchScope(scope), cancellationToken);
    }

    public Task<ShipmentDto> CreateShipmentAsync(CreateShipmentRequest request, CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        var normalized = Normalize(request, scope);
        return shipmentRepository.CreateShipmentAsync(normalized, scope.UserId, cancellationToken);
    }

    public async Task UpdateShipmentStatusAsync(
        long shipmentId,
        UpdateShipmentStatusRequest request,
        CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        var shipment = await shipmentRepository.GetShipmentAsync(shipmentId, BranchScope(scope), cancellationToken);
        if (shipment is null)
        {
            throw new KeyNotFoundException("Shipment was not found or is not available to this user.");
        }

        await shipmentRepository.UpdateShipmentStatusAsync(shipmentId, Normalize(request), scope.UserId, cancellationToken);
    }

    public async Task<IReadOnlyList<ShipmentEventDto>> GetShipmentEventsAsync(long shipmentId, CancellationToken cancellationToken)
    {
        var scope = currentUser.Require();
        var shipment = await shipmentRepository.GetShipmentAsync(shipmentId, BranchScope(scope), cancellationToken);
        if (shipment is null)
        {
            throw new KeyNotFoundException("Shipment was not found or is not available to this user.");
        }

        return await shipmentRepository.GetShipmentEventsAsync(shipmentId, cancellationToken);
    }

    public Task<IReadOnlyList<MasterOptionDto>> GetBranchesAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetBranchesAsync(cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetCustomersAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetCustomersAsync(cancellationToken);

    public Task<IReadOnlyList<MasterOptionDto>> GetPackageCategoriesAsync(CancellationToken cancellationToken) =>
        shipmentRepository.GetPackageCategoriesAsync(cancellationToken);

    private static int? BranchScope(AccessScope scope)
    {
        if (scope.IsMaster)
        {
            return null;
        }

        return scope.BranchId ?? throw new UnauthorizedAccessException("The branch operator has no assigned branch.");
    }

    private static CreateShipmentRequest Normalize(CreateShipmentRequest request, AccessScope scope)
    {
        var direction = request.Direction.Trim();
        var originBranchId = request.OriginBranchId;
        var destinationBranchId = request.DestinationBranchId;

        if (!scope.IsMaster)
        {
            var assignedBranchId = scope.BranchId ?? throw new UnauthorizedAccessException("The branch operator has no assigned branch.");
            if (direction == "Inbound")
            {
                destinationBranchId = assignedBranchId;
            }
            else
            {
                originBranchId = assignedBranchId;
            }
        }

        if (originBranchId == destinationBranchId)
        {
            throw new ArgumentException("Origin and destination branches must be different.");
        }

        return new CreateShipmentRequest
        {
            TrackingNumber = request.TrackingNumber.Trim(),
            Direction = direction,
            SenderName = request.SenderName.Trim(),
            CustomerId = request.CustomerId,
            OriginBranchId = originBranchId,
            DestinationBranchId = destinationBranchId,
            PackageCategoryId = request.PackageCategoryId,
            PackageWeightKg = request.PackageWeightKg,
            PackageDescription = TrimOrNull(request.PackageDescription),
            RecipientName = request.RecipientName.Trim(),
            RecipientAddress = request.RecipientAddress.Trim(),
            CourierServiceProvider = TrimOrNull(request.CourierServiceProvider),
            Remarks = TrimOrNull(request.Remarks),
            ReceivedUtc = request.ReceivedUtc?.ToUniversalTime(),
            SentUtc = request.SentUtc?.ToUniversalTime()
        };
    }

    private static UpdateShipmentStatusRequest Normalize(UpdateShipmentStatusRequest request) => new()
    {
        Status = request.Status.Trim(),
        EventDescription = TrimOrNull(request.EventDescription)
    };

    private static string? TrimOrNull(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
