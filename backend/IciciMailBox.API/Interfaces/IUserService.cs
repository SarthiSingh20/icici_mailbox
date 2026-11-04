using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IUserService
{
    Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<AuditLogDto>> GetAuditLogsAsync(int limit, CancellationToken cancellationToken);
    Task<int> CreateBranchOperatorAsync(CreateUserRequest request, CancellationToken cancellationToken);
    Task SetUserActiveAsync(int userId, SetUserActiveRequest request, CancellationToken cancellationToken);
    Task<int> CreateBranchAsync(CreateBranchRequest request, CancellationToken cancellationToken);
}
