using System.Security.Claims;
using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(IAuthService authService) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType<LoginResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await authService.LoginAsync(request, cancellationToken);
        return response is null ? Unauthorized(new { message = "Invalid username or password." }) : Ok(response);
    }

    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType<CurrentUserDto>(StatusCodes.Status200OK)]
    public ActionResult<CurrentUserDto> Me()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        int? branchId = int.TryParse(User.FindFirstValue("branch_id"), out var parsedBranchId) ? parsedBranchId : null;
        return Ok(new CurrentUserDto(
            userId,
            User.FindFirstValue(ClaimTypes.Name) ?? string.Empty,
            User.FindFirstValue("display_name") ?? string.Empty,
            User.FindFirstValue(ClaimTypes.Role) ?? string.Empty,
            branchId,
            User.FindFirstValue("branch_name")));
    }
}
