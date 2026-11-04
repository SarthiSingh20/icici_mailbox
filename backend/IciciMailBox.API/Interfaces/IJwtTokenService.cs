using IciciMailBox.API.Models;

namespace IciciMailBox.API.Interfaces;

public interface IJwtTokenService
{
    (string Token, DateTime ExpiresUtc) Create(AuthenticatedUser user);
}
