namespace IciciMailBox.API.DTOs;

public sealed record AuditLogDto(
    long AuditLogId,
    int? UserId,
    string? Username,
    string? DisplayName,
    string Action,
    string EntityType,
    string? EntityId,
    string? Detail,
    DateTime OccurredUtc);
