using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>
/// Lookup brand bằng <c>ParentDonViId</c> (= <c>DM_DonVi.CapTrenId</c> của trạm cấp 248).
/// Cấu hình ở <c>appsettings.json</c> section <c>StationBranding:Brands</c>:
/// <code>
/// "StationBranding": {
///   "Brands": [
///     { "ParentDonViId": 123, "Key": "petrolimex", "LogoUrl": null },
///     { "ParentDonViId": 124, "Key": "pvoil",      "LogoUrl": null },
///     { "ParentDonViId": 125, "Key": "saigon_petro","LogoUrl": null }
///   ]
/// }
/// </code>
/// Slug (<c>Key</c>) là hợp đồng với mobile: client dùng nó vừa làm cache key, vừa map sang asset
/// <c>assets/map_markers/brands/&lt;key&gt;.png</c>. Đổi slug = vô hiệu cache mobile → chỉ đổi khi cần.
/// </summary>
public sealed class StationBrandRegistry : IStationBrandRegistry
{
    private readonly Dictionary<int, StationBrandInfo> _byParentId;

    public StationBrandRegistry(IOptions<StationBrandingOptions> options)
    {
        _byParentId = new Dictionary<int, StationBrandInfo>();
        foreach (var b in options.Value.Brands)
        {
            if (b.ParentDonViId <= 0) continue;
            if (string.IsNullOrWhiteSpace(b.Key)) continue;
            _byParentId[b.ParentDonViId] = new StationBrandInfo(b.Key.Trim(), b.LogoUrl);
        }
    }

    public StationBrandInfo? Resolve(int? parentDonViId)
    {
        if (parentDonViId is null) return null;
        return _byParentId.TryGetValue(parentDonViId.Value, out var info) ? info : null;
    }
}

public sealed class StationBrandingOptions
{
    public const string SectionName = "StationBranding";

    public List<StationBrandOption> Brands { get; init; } = new();
}

public sealed class StationBrandOption
{
    public int ParentDonViId { get; init; }
    public string Key { get; init; } = string.Empty;
    public string? LogoUrl { get; init; }
}
