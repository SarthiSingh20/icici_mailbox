namespace IciciMailBox.API.DTOs;

public sealed record DashboardSummaryDto(
    int TotalShipments,
    int PendingShipments,
    int InTransitShipments,
    int DeliveredShipments);
