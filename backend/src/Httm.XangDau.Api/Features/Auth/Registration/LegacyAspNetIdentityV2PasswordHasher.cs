using System.Security.Cryptography;
using System.Text;

namespace Httm.XangDau.Api.Features.Auth.Registration;

/// <summary>
/// Produces <c>AspNetUsers.PasswordHash</c> values compatible with <b>Microsoft.AspNet.Identity v2</b>
/// (<c>Microsoft.AspNet.Identity.Crypto.HashPassword</c> on .NET Framework: PBKDF2 + HMAC-SHA1, 1000 iterations,
/// 128-bit random salt, 256-bit subkey, format byte <c>0x00</c>, Base64).
/// </summary>
/// <remarks>
/// Do <b>not</b> replace with ASP.NET Core <see cref="Microsoft.AspNetCore.Identity.PasswordHasher{TUser}"/> without
/// verifying byte-for-byte compatibility on your legacy database.
/// </remarks>
public static class LegacyAspNetIdentityV2PasswordHasher
{
    private const byte FormatMarker = 0x00;
    private const int SaltSize = 16;
    private const int SubkeySize = 32;
    private const int Iterations = 1000;

    /// <summary>Same contract as legacy <c>UserManager.PasswordHasher.HashPassword(password)</c> for Identity v2.</summary>
    public static string HashPassword(string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        var salt = new byte[SaltSize];
        RandomNumberGenerator.Fill(salt);

        // .NET Framework Identity v2 uses UTF-16LE code units for the password string with Rfc2898DeriveBytes.
        var passwordBytes = Encoding.Unicode.GetBytes(password);
        var subKey = Rfc2898DeriveBytes.Pbkdf2(
            passwordBytes,
            salt,
            Iterations,
            HashAlgorithmName.SHA1,
            SubkeySize);

        var payload = new byte[1 + SaltSize + SubkeySize];
        payload[0] = FormatMarker;
        Buffer.BlockCopy(salt, 0, payload, 1, SaltSize);
        Buffer.BlockCopy(subKey, 0, payload, 1 + SaltSize, SubkeySize);
        return Convert.ToBase64String(payload);
    }

    /// <summary>Verifies a password against a hash produced by <see cref="HashPassword"/> (Identity v2 layout).</summary>
    /// <returns><see langword="false"/> if <paramref name="base64Hash"/> is not a v2 payload (wrong length or format byte).</returns>
    public static bool VerifyPassword(string base64Hash, string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        if (string.IsNullOrEmpty(base64Hash))
        {
            return false;
        }

        byte[] bytes;
        try
        {
            bytes = Convert.FromBase64String(base64Hash);
        }
        catch (FormatException)
        {
            return false;
        }

        if (bytes.Length != 1 + SaltSize + SubkeySize || bytes[0] != FormatMarker)
        {
            return false;
        }

        var salt = new byte[SaltSize];
        Buffer.BlockCopy(bytes, 1, salt, 0, SaltSize);
        var expectedSubkey = new byte[SubkeySize];
        Buffer.BlockCopy(bytes, 1 + SaltSize, expectedSubkey, 0, SubkeySize);

        var passwordBytes = Encoding.Unicode.GetBytes(password);
        var actualSubkey = Rfc2898DeriveBytes.Pbkdf2(
            passwordBytes,
            salt,
            Iterations,
            HashAlgorithmName.SHA1,
            SubkeySize);

        return CryptographicOperations.FixedTimeEquals(actualSubkey, expectedSubkey);
    }
}
