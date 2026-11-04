using IciciMailBox.API.DTOs;

namespace IciciMailBox.API.Interfaces;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
}
