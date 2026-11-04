using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class CreateUserRequest
{
    [Required, StringLength(80, MinimumLength = 3)]
    public string Username { get; init; } = string.Empty;

    [Required, StringLength(160)]
    public string DisplayName { get; init; } = string.Empty;

    [Required, StringLength(256, MinimumLength = 12)]
    public string Password { get; init; } = string.Empty;

    [Required, RegularExpression("^BranchOperator$")]
    public string RoleName { get; init; } = "BranchOperator";

    [Range(1, int.MaxValue)]
    public int BranchId { get; init; }
}
