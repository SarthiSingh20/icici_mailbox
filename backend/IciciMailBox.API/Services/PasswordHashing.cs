using System.Security.Cryptography;

namespace IciciMailBox.API.Services;

public static class PasswordHashing
{
    public const int DefaultIterations = 210000;

    public static (byte[] Hash, byte[] Salt, int Iterations) Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, DefaultIterations, HashAlgorithmName.SHA256, 32);
        return (hash, salt, DefaultIterations);
    }

    public static bool Verify(string password, byte[] expectedHash, byte[] salt, int iterations)
    {
        var actualHash = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, expectedHash.Length);
        return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
    }
}
