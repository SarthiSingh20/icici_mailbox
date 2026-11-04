namespace IciciMailBox.API.DTOs;

public sealed record UserDto(
    int UserId,
    string Username,
    string DisplayName,
    bool IsActive,
    string RoleName,
    int? BranchId,
    string? BranchName,
    DateTime? LastLoginUtc,
    DateTime CreatedUtc);
