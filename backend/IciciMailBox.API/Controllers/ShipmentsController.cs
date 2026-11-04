using System.Text;
using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IciciMailBox.API.Controllers;

[ApiController]
[Authorize]
[Route("api/shipments")]
public sealed class ShipmentsController(IShipmentService shipmentService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<ShipmentDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ShipmentDto>>> GetShipments(
        [FromQuery] ShipmentQuery query,
        CancellationToken cancellationToken)
    {
        if (!IsValidDirection(query.Direction) || !IsValidStatus(query.Status))
        {
            return ValidationProblem("The requested direction or status is invalid.");
        }
        if (query.FromUtc.HasValue && query.ToUtc.HasValue && query.FromUtc > query.ToUtc)
        {
            return ValidationProblem("The start date must not be later than the end date.");
        }

        return Ok(await shipmentService.GetShipmentsAsync(query, cancellationToken));
    }

    [HttpGet("export")]
    [Produces("text/csv")]
    public async Task<IActionResult> Export([FromQuery] ShipmentQuery query, CancellationToken cancellationToken)
    {
        if (query.FromUtc.HasValue && query.ToUtc.HasValue && query.FromUtc > query.ToUtc)
        {
            return ValidationProblem("The start date must not be later than the end date.");
        }

        var shipments = await shipmentService.GetShipmentsAsync(query, cancellationToken);
        var csv = new StringBuilder("TrackingNumber,Direction,SenderName,SenderOrganization,OriginBranch,DestinationBranch,Recipient,Category,WeightKg,Status,CreatedUtc\n");
        foreach (var shipment in shipments)
        {
            csv.AppendLine(string.Join(',', new[]
            {
                Csv(shipment.TrackingNumber), Csv(shipment.Direction), Csv(shipment.SenderName ?? shipment.CustomerName),
                Csv(shipment.CustomerName),
                Csv(shipment.OriginBranchName), Csv(shipment.DestinationBranchName), Csv(shipment.RecipientName),
                Csv(shipment.PackageCategoryName), shipment.PackageWeightKg?.ToString("0.000", System.Globalization.CultureInfo.InvariantCulture) ?? string.Empty,
                Csv(shipment.Status), shipment.CreatedUtc.ToString("O")
            }));
        }

        return File(Encoding.UTF8.GetBytes(csv.ToString()), "text/csv", "shipment-report.csv");
    }

    [HttpGet("{shipmentId:long}")]
    [ProducesResponseType<ShipmentDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ShipmentDto>> GetShipment(long shipmentId, CancellationToken cancellationToken)
    {
        var shipment = await shipmentService.GetShipmentAsync(shipmentId, cancellationToken);
        return shipment is null ? NotFound() : Ok(shipment);
    }

    [HttpGet("{shipmentId:long}/events")]
    [ProducesResponseType<IReadOnlyList<ShipmentEventDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ShipmentEventDto>>> GetShipmentEvents(long shipmentId, CancellationToken cancellationToken) =>
        Ok(await shipmentService.GetShipmentEventsAsync(shipmentId, cancellationToken));

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
    public async Task<IActionResult> UpdateStatus(
        long shipmentId,
        [FromBody] UpdateShipmentStatusRequest request,
        CancellationToken cancellationToken)
    {
        await shipmentService.UpdateShipmentStatusAsync(shipmentId, request, cancellationToken);
        return NoContent();
    }

    private static bool IsValidDirection(string? direction) =>
        string.IsNullOrWhiteSpace(direction) || direction is "Inbound" or "Outbound";

    private static bool IsValidStatus(string? status) =>
        string.IsNullOrWhiteSpace(status) || status is "Pending" or "InTransit" or "Delivered" or "Cancelled";

    private static string Csv(string value)
    {
        var safeValue = value.Length > 0 && value[0] is '=' or '+' or '-' or '@' or '\t' or '\r'
            ? $"'{value}"
            : value;
        return $"\"{safeValue.Replace("\"", "\"\"")}\"";
    }
}
