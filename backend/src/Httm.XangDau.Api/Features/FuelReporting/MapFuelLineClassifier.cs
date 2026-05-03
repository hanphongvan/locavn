namespace Httm.XangDau.Api.Features.FuelReporting;

/// <summary>Heuristic match on <c>QT_TK_ThongKeChiTiet.TenThongKe</c> / <c>MaSo</c> for map price chips.</summary>
public static class MapFuelLineClassifier
{
    public static bool MatchesRon95(string? tenThongKe, string? maSo)
    {
        var t = tenThongKe ?? string.Empty;
        var m = maSo ?? string.Empty;
        if (t.Length == 0 && m.Length == 0)
            return false;

        if (t.Contains("RON95", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("RON 95", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("RON-95", StringComparison.OrdinalIgnoreCase))
            return true;
        if (m.Contains("RON95", StringComparison.OrdinalIgnoreCase))
            return true;

        return t.Contains("RON", StringComparison.OrdinalIgnoreCase)
               && t.Contains("95", StringComparison.OrdinalIgnoreCase);
    }

    public static bool MatchesDiesel(string? tenThongKe, string? maSo)
    {
        var t = tenThongKe ?? string.Empty;
        var m = maSo ?? string.Empty;
        if (t.Length == 0 && m.Length == 0)
            return false;

        if (t.Contains("DIESEL", StringComparison.OrdinalIgnoreCase))
            return true;
        if (m.Contains("DIESEL", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("ĐIÊZEN", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("DẦU DIESEL", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("DAU DIESEL", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("DO 0,", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("DO 0.", StringComparison.OrdinalIgnoreCase))
            return true;
        if (t.Contains("DO0,", StringComparison.OrdinalIgnoreCase))
            return true;

        return t.Contains("DẦU DO", StringComparison.OrdinalIgnoreCase)
               || t.Contains("DAU DO", StringComparison.OrdinalIgnoreCase);
    }
}
