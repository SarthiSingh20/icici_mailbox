using System.Security.Claims;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;

namespace IciciMailBox.API.Data;

public sealed class CurrentUser(IHttpContextAccessor httpContextAccessor) : ICurrentUser
{
    public AccessScope Require()
    {
        var principal = httpContextAccessor.HttpContext?.User;
        var userId = principal?.FindFirstValue(ClaimTypes.NameIdentifier);
        var role = principal?.FindFirstValue(ClaimTypes.Role);

        if (!int.TryParse(userId, out var parsedUserId) || string.IsNullOrWhiteSpace(role))
        {
            throw new UnauthorizedAccessException("An authenticated user is required.");
        }

        var authenticatedPrincipal = principal!;
        var branchClaim = authenticatedPrincipal.FindFirstValue("branch_id");
        int? branchId = int.TryParse(branchClaim, out var parsedBranchId) ? parsedBranchId : null;
        return new AccessScope(
            parsedUserId,
            authenticatedPrincipal.FindFirstValue(ClaimTypes.Name) ?? string.Empty,
            authenticatedPrincipal.FindFirstValue("display_name") ?? authenticatedPrincipal.FindFirstValue(ClaimTypes.Name) ?? string.Empty,
            role,
            branchId);
    }
}
