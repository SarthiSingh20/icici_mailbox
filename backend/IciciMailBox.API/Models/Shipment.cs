namespace IciciMailBox.API.Models;

public sealed class Shipment
{
    public long ShipmentId { get; init; }
    public string TrackingNumber { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public DateTime CreatedUtc { get; init; }
}
