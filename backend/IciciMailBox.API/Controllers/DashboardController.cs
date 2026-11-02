using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
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
}
