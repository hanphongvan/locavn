namespace Httm.XangDau.Api.Features.Httm;

/// <summary>JWT / <c>AspNetUserClaims</c> claim types cho phạm vi tỉnh (cán bộ Sở).</summary>
public static class HttmClaims
{
    /// <summary>Danh sách mã tỉnh ĐVHCVN, phân tách bởi dấu phẩy (ví dụ <c>01,79</c>).</summary>
    public const string ProvinceCodes = "httm_province_codes";
}
