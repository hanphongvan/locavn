using System.Globalization;

namespace Httm.XangDau.Api.Features.Stations.Services;

public static class StationReadValidator
{
    public const int MaxTake = 100;
    public const int DefaultTake = 20;
    public const int MaxKeywordLength = 200;

    /// <summary>Cap riêng cho viewport queries — bbox có thể chứa hàng trăm trạm ở zoom thấp/vừa.</summary>
    public const int MaxTakeBounds = 1000;

    public static string? ValidatePagination(int skip, int take, int maxTake = MaxTake)
    {
        if (skip < 0)
            return "skip must be >= 0.";
        if (take < 1 || take > maxTake)
            return $"take must be between 1 and {maxTake}.";
        return null;
    }

    /// <summary>Visitor filter: <c>all</c> (default), <c>open</c>, <c>closed</c> — Vietnam time + <c>StationOperatingHours</c> when present.</summary>
    public static string? ValidateStatus(string? status)
    {
        if (string.IsNullOrWhiteSpace(status))
            return null;
        var s = status.Trim();
        if (s.Equals("all", StringComparison.OrdinalIgnoreCase)
            || s.Equals("open", StringComparison.OrdinalIgnoreCase)
            || s.Equals("closed", StringComparison.OrdinalIgnoreCase))
            return null;
        return "status must be 'all', 'open', or 'closed'.";
    }

    public static bool TryParseDistrictCode(string? districtCode, out int quanHuyenId, out string? error)
    {
        quanHuyenId = default;
        error = null;
        if (string.IsNullOrWhiteSpace(districtCode))
            return true;
        if (!int.TryParse(districtCode.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out quanHuyenId))
        {
            error = "districtCode must be a numeric QuanHuyenId (DM_XaPhuong.QuanHuyenId) until DM_QuanHuyen is fully documented.";
            return false;
        }

        return true;
    }

    /// <summary>Giới hạn khung nhìn bản đồ (tránh truy vấn toàn quốc một lần).</summary>
    public static string? ValidateMapBounds(double minLat, double maxLat, double minLng, double maxLng)
    {
        if (minLat >= maxLat)
            return "minLat must be less than maxLat.";
        if (minLng >= maxLng)
            return "minLng must be less than maxLng.";
        if (minLat < -90 || maxLat > 90)
            return "latitude out of allowed range.";
        if (minLng < -180 || maxLng > 180)
            return "longitude out of allowed range.";
        const double maxSpan = 28;
        if (maxLat - minLat > maxSpan || maxLng - minLng > maxSpan)
            return $"each viewport axis span must be at most {maxSpan} degrees.";
        return null;
    }
}
