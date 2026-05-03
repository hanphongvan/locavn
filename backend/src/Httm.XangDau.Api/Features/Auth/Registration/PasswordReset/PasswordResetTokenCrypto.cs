using System.Security.Cryptography;
using System.Text;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

/// <summary>Token thô chỉ tồn tại trong email; DB chỉ lưu hash SHA-256 (hex). Không log token thô.</summary>
public static class PasswordResetTokenCrypto
{
    /// <summary>Sinh token ngẫu nhiên an toàn (Base64url, ~43 ký tự).</summary>
    public static string GenerateRawToken()
    {
        Span<byte> buf = stackalloc byte[32];
        RandomNumberGenerator.Fill(buf);
        return Convert.ToBase64String(buf).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    public static string HashRawToken(string rawToken)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    public static bool SecureEqualsHash(string storedHexLower, string computedHexLower)
    {
        try
        {
            var a = Convert.FromHexString(storedHexLower);
            var b = Convert.FromHexString(computedHexLower);
            return CryptographicOperations.FixedTimeEquals(a, b);
        }
        catch (FormatException)
        {
            return false;
        }
    }
}
