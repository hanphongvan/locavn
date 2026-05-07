using System.Globalization;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Resolve userId int từ claim — handle cả 2 dạng <c>nameidentifier</c>:
/// <list type="bullet">
///   <item><description>Số nguyên trực tiếp (legacy / non-Identity backends).</description></item>
///   <item><description>GUID string của ASP.NET Identity (<c>AspNetUsers.Id</c>) —
///     hash SHA-256 → stable Int32 dương để fit schema <c>AiConversations.UserId INT</c>.</description></item>
/// </list>
/// </summary>
/// <remarks>
/// Đây là adapter Phase 4 để patch design flaw Phase 1A: schema dùng INT
/// trong khi Identity dùng GUID string. Phase 5 sẽ migration đổi sang
/// <c>NVARCHAR(450)</c> cho đúng chuẩn — khi đó adapter này được loại bỏ.
///
/// SHA-256 → Int32 dương: collision lý thuyết ~2^31 user, đủ cho 1 hệ thống
/// ngành xăng dầu Việt Nam (~thousands users). Khi migration string xong,
/// id collision không còn là vấn đề.
/// </remarks>
public static class UserIdentityResolver
{
    /// <summary>Trả userId int + raw claim string. Cả 2 đều null khi không xác định.</summary>
    public static bool TryResolve(ClaimsPrincipal user, out int userId, out string? rawClaim)
    {
        userId = 0;
        rawClaim = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");

        if (string.IsNullOrEmpty(rawClaim))
            return false;

        // Nhanh path: claim đã là int.
        if (int.TryParse(rawClaim, NumberStyles.Integer, CultureInfo.InvariantCulture, out userId))
            return true;

        // Identity GUID → stable hash Int32.
        if (Guid.TryParse(rawClaim, out _))
        {
            userId = HashToPositiveInt(rawClaim);
            return true;
        }

        // String khác (email, username, ...) — vẫn hash để có id stable.
        userId = HashToPositiveInt(rawClaim);
        return true;
    }

    /// <summary>SHA-256 → first 4 bytes → Int32 dương (mask bit dấu).</summary>
    private static int HashToPositiveInt(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        var raw = BitConverter.ToInt32(bytes, 0);
        return raw & 0x7FFFFFFF;
    }
}
