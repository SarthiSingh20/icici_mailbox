namespace IciciMailBox.API.Models;

public sealed record AuthenticatedUser(
    int UserId,
    string Username,
    string DisplayName,
    byte[] PasswordHash,
    byte[] PasswordSalt,
    int PasswordIterations,
    bool IsActive,
    string RoleName,
    int? BranchId,
    string? BranchName);
