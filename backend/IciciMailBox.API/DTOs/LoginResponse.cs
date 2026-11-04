namespace IciciMailBox.API.DTOs;

public sealed record LoginResponse(string AccessToken, DateTime ExpiresUtc, CurrentUserDto User);
