using IciciMailBox.API.DTOs;
using IciciMailBox.API.Models;

namespace IciciMailBox.API.Interfaces;

public interface IUserRepository
{
    Task<AuthenticatedUser?> GetByUsernameAsync(string username, CancellationToken cancellationToken);
    Task UpdateLastLoginAsync(int userId, CancellationToken cancellationToken);
    Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<AuditLogDto>> GetAuditLogsAsync(int limit, CancellationToken cancellationToken);
    Task<int> CreateUserAsync(CreateUserRequest request, byte[] passwordHash, byte[] passwordSalt, int iterations, int createdByUserId, CancellationToken cancellationToken);
    Task SetUserActiveAsync(int userId, bool isActive, int changedByUserId, CancellationToken cancellationToken);
    Task<int> CreateBranchAsync(CreateBranchRequest request, int createdByUserId, CancellationToken cancellationToken);
}
