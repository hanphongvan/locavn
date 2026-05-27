using System.Globalization;

namespace Httm.XangDau.Api.Features.Httm.Import.Services;

/// <summary>
/// Lookup table chuyển <b>Tên hiển thị</b> trong Excel (do user chọn từ dropdown) thành <b>Code</b> để lưu DB.
/// Mỗi dictionary chấp nhận cả Tên lẫn Code (fallback khi user gõ tay mã thay vì chọn dropdown).
/// Wards là cache per provinceCode — load on-demand qua <see cref="GetWardsAsync"/>.
/// </summary>
public sealed class HttmImportLookups
{
    /// <summary>Static lookup: <c>httm_types</c> (10 mã).</summary>
    public Dictionary<string, string> HttmTypes { get; } = BuildStatic(new (string Code, string Name)[]
    {
        ("market_grade1", "Chợ hạng I"),
        ("market_grade2", "Chợ hạng II"),
        ("market_grade3", "Chợ hạng III"),
        ("supermarket_1", "Siêu thị hạng I"),
        ("supermarket_2", "Siêu thị hạng II"),
        ("supermarket_3", "Siêu thị hạng III"),
        ("mall", "Trung tâm thương mại"),
        ("wholesale_market", "Chợ đầu mối"),
        ("convenience_store", "Cửa hàng tiện lợi / Bán lẻ hiện đại"),
        ("other", "Loại hình khác"),
    });

    public Dictionary<string, string> Statuses { get; } = BuildStatic(new (string Code, string Name)[]
    {
        ("active", "Đang hoạt động"),
        ("suspended", "Tạm ngừng hoạt động"),
        ("under_construction", "Đang xây dựng / cải tạo"),
        ("closed", "Đã đóng cửa"),
    });

    public Dictionary<string, string> Quality { get; } = BuildStatic(new (string Code, string Name)[]
    {
        ("good", "Tốt"),
        ("average", "Trung bình"),
        ("degraded", "Xuống cấp"),
        ("needs_renovation", "Cần cải tạo"),
    });

    public Dictionary<string, string> Gps { get; } = BuildStatic(new (string Code, string Name)[]
    {
        ("exact", "Chính xác"),
        ("approximate", "Xấp xỉ"),
        ("none", "Không có"),
    });

    /// <summary>Provinces — load 1 lần khi build lookups, key = lower(Tên|Code) → Code.</summary>
    public Dictionary<string, string> Provinces { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Wards cache theo provinceCode: provinceCode → (lower(Tên|Code) → Code). Load on-demand.</summary>
    public Dictionary<string, Dictionary<string, string>> WardsByProvince { get; } =
        new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Resolve raw text (Tên hoặc Code) thành Code chuẩn. Trả <c>null</c> nếu không khớp.</summary>
    public static string? Resolve(Dictionary<string, string> lookup, string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return null;
        return lookup.TryGetValue(raw.Trim().ToLower(CultureInfo.InvariantCulture), out var code) ? code : null;
    }

    private static Dictionary<string, string> BuildStatic(IReadOnlyList<(string Code, string Name)> rows)
    {
        var d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in rows)
        {
            d[r.Code.ToLower(CultureInfo.InvariantCulture)] = r.Code;
            d[r.Name.ToLower(CultureInfo.InvariantCulture)] = r.Code;
        }
        return d;
    }

    /// <summary>Helper: xây dict (Code|Name lower → Code) cho danh sách runtime (provinces, wards).</summary>
    public static Dictionary<string, string> BuildDynamic(IEnumerable<(string Code, string Name)> rows)
    {
        var d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in rows)
        {
            if (!string.IsNullOrWhiteSpace(r.Code))
                d[r.Code.ToLower(CultureInfo.InvariantCulture)] = r.Code;
            if (!string.IsNullOrWhiteSpace(r.Name))
                d[r.Name.ToLower(CultureInfo.InvariantCulture)] = r.Code;
        }
        return d;
    }
}
