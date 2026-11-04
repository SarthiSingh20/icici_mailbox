using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;
using Microsoft.IdentityModel.Tokens;

namespace IciciMailBox.API.Services;

public sealed class JwtTokenService(IConfiguration configuration) : IJwtTokenService
{
    public (string Token, DateTime ExpiresUtc) Create(AuthenticatedUser user)
    {
        var signingKey = configuration["Authentication:Jwt:SigningKey"];
        if (string.IsNullOrWhiteSpace(signingKey) || signingKey.Length < 32)
        {
            throw new InvalidOperationException(
                "Authentication:Jwt:SigningKey must be supplied as an environment variable or user secret and be at least 32 characters.");
        }

        var issuer = configuration["Authentication:Jwt:Issuer"] ?? throw new InvalidOperationException("JWT issuer is missing.");
        var audience = configuration["Authentication:Jwt:Audience"] ?? throw new InvalidOperationException("JWT audience is missing.");
        var lifetimeMinutes = configuration.GetValue("Authentication:Jwt:LifetimeMinutes", 480);
        var expiresUtc = DateTime.UtcNow.AddMinutes(lifetimeMinutes);
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new(ClaimTypes.Name, user.Username),
            new("display_name", user.DisplayName),
            new(ClaimTypes.Role, user.RoleName)
        };

        if (user.BranchId is not null)
        {
            claims.Add(new Claim("branch_id", user.BranchId.Value.ToString()));
        }
        if (!string.IsNullOrWhiteSpace(user.BranchName))
        {
            claims.Add(new Claim("branch_name", user.BranchName));
        }

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
            SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: expiresUtc,
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresUtc);
    }
}
