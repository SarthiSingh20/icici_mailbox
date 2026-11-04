using System.ComponentModel.DataAnnotations;

namespace IciciMailBox.API.DTOs;

public sealed class LoginRequest
{
    [Required, StringLength(80)]
    public string Username { get; init; } = string.Empty;

    [Required, StringLength(256, MinimumLength = 8)]
    public string Password { get; init; } = string.Empty;
}
