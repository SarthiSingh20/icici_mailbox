using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class CreateBranchRequest
{
    [Required, StringLength(20)]
    public string BranchCode { get; init; } = string.Empty;

    [Required, StringLength(120)]
    public string BranchName { get; init; } = string.Empty;

    [Required, StringLength(100)]
    public string City { get; init; } = string.Empty;
}
