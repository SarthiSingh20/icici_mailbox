using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class UpdateShipmentStatusRequest
{
    [Required, RegularExpression("^(Pending|InTransit|Delivered|Cancelled)$", ErrorMessage = "Status is invalid.")]
    public string Status { get; init; } = string.Empty;

    [StringLength(500)]
    public string? EventDescription { get; init; }
}
