using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Authorize(Roles = RoleNames.MasterUser)]
[Route("api")]
public sealed class UsersController(IUserService userService) : ControllerBase
{
    [HttpGet("users")]
    [ProducesResponseType<IReadOnlyList<UserDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<UserDto>>> GetUsers(CancellationToken cancellationToken) =>
        Ok(await userService.GetUsersAsync(cancellationToken));

    [HttpGet("audit")]
    [ProducesResponseType<IReadOnlyList<AuditLogDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<AuditLogDto>>> GetAuditLogs(
        [FromQuery] int limit = 100,
        CancellationToken cancellationToken = default)
    {
        if (limit is < 1 or > 500)
        {
            return ValidationProblem("The audit log limit must be between 1 and 500.");
        }

        return Ok(await userService.GetAuditLogsAsync(limit, cancellationToken));
    }

    [HttpPost("users")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request, CancellationToken cancellationToken)
    {
        var userId = await userService.CreateBranchOperatorAsync(request, cancellationToken);
        return Created($"/api/users/{userId}", new { userId });
    }

    [HttpPatch("users/{userId:int}/active")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> SetUserActive(int userId, [FromBody] SetUserActiveRequest request, CancellationToken cancellationToken)
    {
        await userService.SetUserActiveAsync(userId, request, cancellationToken);
        return NoContent();
    }

    [HttpPost("branches")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateBranch([FromBody] CreateBranchRequest request, CancellationToken cancellationToken)
    {
        var branchId = await userService.CreateBranchAsync(request, cancellationToken);
        return Created($"/api/branches/{branchId}", new { branchId });
    }
}
