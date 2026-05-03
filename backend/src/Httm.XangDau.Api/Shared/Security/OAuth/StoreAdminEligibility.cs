using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>
/// Quy tắc store admin: <c>AspNetUsers.DonViId</c> + <c>DM_DonVi</c> với <c>CapDonViId = 248</c> (xăng dầu bán lẻ).
/// Dùng bởi <see cref="ApplicationOAuthProvider"/> (OAuth) và <c>StoreAdminMeReadService</c> (Bearer /me).
/// </summary>
public static class StoreAdminEligibility
{
    /// <summary><c>AspNetUsers.UserName</c> (không phân biệt hoa thường) được phép store admin không cần <c>DM_DonVi</c> bán lẻ.</summary>
    public const string RootUserName = "system";

    /// <summary>Tài khoản gốc (vd. <see cref="RootUserName"/>) — không bắt buộc <c>DonViId</c> / <c>CapDonViId</c>.</summary>
    public static bool IsRootStoreAdminUser(string? userName) =>
        string.Equals(userName?.Trim(), RootUserName, StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// Khác <c>null</c> nghĩa là không đủ điều kiện store admin; dùng cho <c>invalid_grant</c> hoặc 403 <c>ProblemDetails</c>.
    /// </summary>
    /// <param name="donViId"><c>AspNetUsers.DonViId</c> khi đã biết.</param>
    /// <param name="donVi">Dòng <c>DM_DonVi</c> theo <paramref name="donViId"/> (tải không lọc theo <c>CapDonViId</c> trước).</param>
    /// <param name="userName"><c>AspNetUsers.UserName</c>; tài khoản root thì luôn đạt.</param>
    public static string? GetFailureReason(int? donViId, DmDonVi? donVi, string? userName = null)
    {
        if (IsRootStoreAdminUser(userName))
            return null;

        if (!donViId.HasValue)
            return "User is not linked to a store (AspNetUsers.DonViId is required for store admin).";

        if (donVi is null)
            return "User DonViId does not match an existing DM_DonVi row.";

        if (donVi.CapDonViId != StoreAdminAccessRules.RequiredCapDonViId)
            return $"Store admin is limited to DM_DonVi with CapDonViId = {StoreAdminAccessRules.RequiredCapDonViId}.";

        return null;
    }
}
