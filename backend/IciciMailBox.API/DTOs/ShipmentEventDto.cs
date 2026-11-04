namespace IciciMailBox.API.DTOs;

public sealed record ShipmentEventDto(
    long ShipmentEventId,
    string EventType,
    string? PreviousStatus,
    string? NewStatus,
    string? EventDescription,
    DateTime EventUtc,
    int? ChangedByUserId,
    string ChangedByName);
