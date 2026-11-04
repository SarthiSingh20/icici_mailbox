using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Route("api/shipments")]
public sealed class ShipmentsController(IShipmentService shipmentService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<ShipmentDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ShipmentDto>>> GetShipments(
        [FromQuery] string? direction,
        [FromQuery] string? search,
        CancellationToken cancellationToken)
    {
        if (!IsValidDirection(direction))
        {
            ModelState.AddModelError(nameof(direction), "Direction must be Inbound or Outbound.");
            return ValidationProblem(ModelState);
        }

        return Ok(await shipmentService.GetShipmentsAsync(direction, search, cancellationToken));
    }

    [HttpGet("{shipmentId:long}")]
    [ProducesResponseType<ShipmentDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ShipmentDto>> GetShipment(long shipmentId, CancellationToken cancellationToken)
    {
        var shipment = await shipmentService.GetShipmentAsync(shipmentId, cancellationToken);
        return shipment is null ? NotFound() : Ok(shipment);
    }

    [HttpPost]
    [ProducesResponseType<ShipmentDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ShipmentDto>> CreateShipment(
        [FromBody] CreateShipmentRequest request,
        CancellationToken cancellationToken)
    {
        if (request.Direction == "Inbound" && request.ReceivedUtc is null)
        {
            ModelState.AddModelError(nameof(request.ReceivedUtc), "Receiving time is required for inbound shipments.");
        }

        if (request.Direction == "Outbound" && request.SentUtc is null)
        {
            ModelState.AddModelError(nameof(request.SentUtc), "Send time is required for outbound shipments.");
        }

        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var shipment = await shipmentService.CreateShipmentAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetShipment), new { shipmentId = shipment.ShipmentId }, shipment);
    }

    [HttpPatch("{shipmentId:long}/status")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateStatus(
        long shipmentId,
        [FromBody] UpdateShipmentStatusRequest request,
        CancellationToken cancellationToken)
    {
        await shipmentService.UpdateShipmentStatusAsync(shipmentId, request, cancellationToken);
        return NoContent();
    }

    private static bool IsValidDirection(string? direction) =>
        string.IsNullOrWhiteSpace(direction) ||
        direction is "Inbound" or "Outbound";
}
