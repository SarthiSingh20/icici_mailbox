using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Authorize]
[Route("api/masters")]
public sealed class MastersController(IShipmentService shipmentService) : ControllerBase
{
    [HttpGet("branches")]
    [ProducesResponseType<IReadOnlyList<MasterOptionDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<MasterOptionDto>>> GetBranches(CancellationToken cancellationToken) =>
        Ok(await shipmentService.GetBranchesAsync(cancellationToken));

    [HttpGet("customers")]
    [ProducesResponseType<IReadOnlyList<MasterOptionDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<MasterOptionDto>>> GetCustomers(CancellationToken cancellationToken) =>
        Ok(await shipmentService.GetCustomersAsync(cancellationToken));

    [HttpGet("package-categories")]
    [ProducesResponseType<IReadOnlyList<MasterOptionDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<MasterOptionDto>>> GetPackageCategories(CancellationToken cancellationToken) =>
        Ok(await shipmentService.GetPackageCategoriesAsync(cancellationToken));
}
