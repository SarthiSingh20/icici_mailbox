namespace IciciMailBox.API.DTOs;

public sealed record DashboardSummaryDto(
    int TotalShipments,
    int TotalInbound,
    int TotalOutbound,
    int PendingShipments,
    int InTransitShipments,
    int DeliveredShipments,
    int ReceivedToday,
    int DispatchedToday,
    int ActiveBranches,
    int ActiveOperators);
