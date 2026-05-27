namespace Httm.XangDau.Api.Features.Httm;

/// <summary>JWT / <c>AspNetUserClaims</c> claim types cho phạm vi tỉnh (cán bộ Sở).</summary>
/// <remarks>
/// Claim này được seed vào <c>dbo.AspNetUserClaims</c> (UserId, ClaimType, ClaimValue).
/// <see cref="Shared.Security.OAuth.ApplicationOAuthProvider.BuildClaimsAsync"/> đọc toàn bộ row
/// của user vào JWT khi đăng nhập — nên không cần custom code ở token issuer.
/// Để gán/gỡ qua SQL: dùng <c>sp_Httm_SoStaff_SetProvinceClaim</c>.
/// </remarks>
public static class HttmClaims
{
    /// <summary>Danh sách mã tỉnh ĐVHCVN, phân tách bởi dấu phẩy (ví dụ <c>01,79</c>).</summary>
    public const string ProvinceCodes = "httm_province_codes";
}
