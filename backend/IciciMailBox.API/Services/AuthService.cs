using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;

namespace IciciMailBox.API.Services;

public sealed class AuthService(
    IUserRepository userRepository,
    IJwtTokenService jwtTokenService) : IAuthService
{
    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var user = await userRepository.GetByUsernameAsync(request.Username.Trim(), cancellationToken);
        if (user is null || !user.IsActive || !PasswordHashing.Verify(request.Password, user.PasswordHash, user.PasswordSalt, user.PasswordIterations))
        {
            return null;
        }

        var (token, expiresUtc) = jwtTokenService.Create(user);
        await userRepository.UpdateLastLoginAsync(user.UserId, cancellationToken);
        return new LoginResponse(
            token,
            expiresUtc,
            new CurrentUserDto(user.UserId, user.Username, user.DisplayName, user.RoleName, user.BranchId, user.BranchName));
    }
}
