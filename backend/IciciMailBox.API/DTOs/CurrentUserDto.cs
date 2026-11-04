namespace IciciMailBox.API.DTOs;

public sealed record CurrentUserDto(
    int UserId,
    string Username,
    string DisplayName,
    string RoleName,
    int? BranchId,
    string? BranchName);
