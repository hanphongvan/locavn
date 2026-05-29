namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>
/// Resolve một mã đầu mối (<c>DM_DonVi.CapTrenId</c> của trạm cấp 248) sang brand slug
/// ổn định mà mobile dùng làm cache key + asset lookup.
/// </summary>
public interface IStationBrandRegistry
{
    /// <summary>
    /// Trả về (BrandKey, BrandLogoUrl) khi đầu mối được cấu hình trong appsettings, ngược lại null.
    /// </summary>
    StationBrandInfo? Resolve(int? parentDonViId);
}

public sealed record StationBrandInfo(string Key, string? LogoUrl);
