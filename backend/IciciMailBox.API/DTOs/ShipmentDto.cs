namespace IciciMailBox.API.DTOs;

public sealed record ShipmentDto(
    long ShipmentId,
    string Direction,
    string TrackingNumber,
    int CustomerId,
    string CustomerName,
    int OriginBranchId,
    string OriginBranchName,
    int DestinationBranchId,
    string DestinationBranchName,
    string RecipientName,
    string RecipientAddress,
    string Status,
    DateTime CreatedUtc,
    DateTime UpdatedUtc);
