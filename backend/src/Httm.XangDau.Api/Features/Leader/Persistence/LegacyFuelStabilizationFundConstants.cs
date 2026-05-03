namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <summary>Tham chiếu portal Angular / <c>DashboardController.GetFuelStabilizationFund</c> (DMPPortal).</summary>
internal static class LegacyFuelStabilizationFundConstants
{
    /// <summary>Biểu 08 — báo cáo quỹ bình ổn giá xăng dầu (cố định trong portal cũ).</summary>
    internal static readonly Guid BaoCaoId = Guid.Parse("4C60DBAA-C69E-4878-B214-933D653D4F44");

    internal const string StoredProcedureName = "dbo.sp_Dashboard_FuelStabilizationFund";

    /// <summary>Kỳ mặc định trên dashboard cũ (<c>home.component.ts</c>).</summary>
    internal const string PeriodThang = "THANG";
}
