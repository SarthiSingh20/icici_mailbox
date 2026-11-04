using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class ShipmentQuery
{
    [RegularExpression("^(Inbound|Outbound)$")]
    public string? Direction { get; init; }

    [StringLength(100)]
    public string? Search { get; init; }

    [RegularExpression("^(Pending|InTransit|Delivered|Cancelled)$")]
    public string? Status { get; init; }

    [Range(1, int.MaxValue)]
    public int? BranchId { get; init; }

    [Range(1, 500)]
    public int? Limit { get; init; }

    public DateTime? FromUtc { get; init; }
    public DateTime? ToUtc { get; init; }
}
