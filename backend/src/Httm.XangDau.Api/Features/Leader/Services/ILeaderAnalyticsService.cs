using System.Security.Claims;
using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>Đọc biểu đồ Phân tích Lãnh đạo — cùng SP với DMPPortal <c>api/dashboard/*</c>.</summary>
public interface ILeaderAnalyticsService
{
    Task<LeaderAnalyticsInventoryTrendDto> GetInventoryTrendAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default);

    Task<LeaderAnalyticsImportExportTrendDto> GetImportExportTrendAsync(
        ClaimsPrincipal user,
        string window,
        string fuel,
        CancellationToken cancellationToken = default);

    Task<LeaderAnalyticsPriceTrendDto> GetPriceTrendAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default);

    Task<LeaderAnalyticsPeriodComparisonDto> GetPeriodComparisonAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default);

    Task<LeaderAnalyticsMarketInsightDto> GetMarketInsightAsync(
        ClaimsPrincipal user,
        string window,
        string fuel,
        CancellationToken cancellationToken = default);
}
