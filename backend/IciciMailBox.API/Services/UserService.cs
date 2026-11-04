using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;

namespace IciciMailBox.API.Services;

public sealed class UserService(IUserRepository userRepository, ICurrentUser currentUser) : IUserService
{
    public Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken)
    {
        RequireMaster();
        return userRepository.GetUsersAsync(cancellationToken);
    }

    public Task<IReadOnlyList<AuditLogDto>> GetAuditLogsAsync(int limit, CancellationToken cancellationToken)
    {
        RequireMaster();
        return userRepository.GetAuditLogsAsync(limit, cancellationToken);
    }

    public Task<int> CreateBranchOperatorAsync(CreateUserRequest request, CancellationToken cancellationToken)
    {
        var scope = RequireMaster();
        var normalized = new CreateUserRequest
        {
            Username = request.Username.Trim(),
            DisplayName = request.DisplayName.Trim(),
            Password = request.Password,
            RoleName = RoleNames.BranchOperator,
            BranchId = request.BranchId
        };
        var (hash, salt, iterations) = PasswordHashing.Hash(normalized.Password);
        return userRepository.CreateUserAsync(normalized, hash, salt, iterations, scope.UserId, cancellationToken);
    }

    public Task SetUserActiveAsync(int userId, SetUserActiveRequest request, CancellationToken cancellationToken)
    {
        var scope = RequireMaster();
        if (scope.UserId == userId && !request.IsActive)
        {
            throw new ArgumentException("You cannot deactivate your own account.");
        }

        return userRepository.SetUserActiveAsync(userId, request.IsActive, scope.UserId, cancellationToken);
    }

    public Task<int> CreateBranchAsync(CreateBranchRequest request, CancellationToken cancellationToken)
    {
        var scope = RequireMaster();
        var normalized = new CreateBranchRequest
        {
            BranchCode = request.BranchCode.Trim().ToUpperInvariant(),
            BranchName = request.BranchName.Trim(),
            City = request.City.Trim()
        };
        return userRepository.CreateBranchAsync(normalized, scope.UserId, cancellationToken);
    }

    private AccessScope RequireMaster()
    {
        var scope = currentUser.Require();
        if (!scope.IsMaster)
        {
            throw new UnauthorizedAccessException("Master user access is required.");
        }

        return scope;
    }
}
