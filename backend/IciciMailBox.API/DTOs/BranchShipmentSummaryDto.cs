namespace IciciMailBox.API.DTOs;

public sealed record BranchShipmentSummaryDto(
    int BranchId,
    string BranchCode,
    string BranchName,
    long TotalShipments,
    long InboundShipments,
    long OutboundShipments,
    long PendingShipments,
    long DeliveredShipments);
