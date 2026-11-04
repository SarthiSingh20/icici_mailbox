using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class DashboardController(IShipmentService shipmentService) : ControllerBase
{
    [HttpGet("summary")]
    [ProducesResponseType<DashboardSummaryDto>(StatusCodes.Status200OK)]
    public async Task<ActionResult<DashboardSummaryDto>> GetSummary(CancellationToken cancellationToken)
    {
        var summary = await shipmentService.GetDashboardSummaryAsync(cancellationToken);
        return Ok(summary);
    }

    [HttpGet("branches")]
    [Authorize(Roles = RoleNames.MasterUser)]
    [ProducesResponseType<IReadOnlyList<BranchShipmentSummaryDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BranchShipmentSummaryDto>>> GetBranchSummary(CancellationToken cancellationToken) =>
        Ok(await shipmentService.GetBranchShipmentSummaryAsync(cancellationToken));
}
