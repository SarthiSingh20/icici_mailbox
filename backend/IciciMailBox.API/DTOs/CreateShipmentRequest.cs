using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class CreateShipmentRequest
{
    [Required, StringLength(50)]
    public string TrackingNumber { get; init; } = string.Empty;

    [Required, RegularExpression("^(Inbound|Outbound)$", ErrorMessage = "Direction must be Inbound or Outbound.")]
    public string Direction { get; init; } = string.Empty;

    [Range(1, int.MaxValue)]
    public int CustomerId { get; init; }

    [Range(1, int.MaxValue)]
    public int OriginBranchId { get; init; }

    [Range(1, int.MaxValue)]
    public int DestinationBranchId { get; init; }

    [Range(typeof(decimal), "0.001", "1000000")]
    public decimal PackageWeightKg { get; init; }

    [Required, StringLength(160)]
    public string RecipientName { get; init; } = string.Empty;

    [Required, StringLength(500)]
    public string RecipientAddress { get; init; } = string.Empty;

    public DateTime? ReceivedUtc { get; init; }

    public DateTime? SentUtc { get; init; }
}
