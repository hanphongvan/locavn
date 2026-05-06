using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>
/// Orchestrate dashboard Leader Retail: gọi data access (SP) → áp warning rule engine → response DTO.
/// </summary>
public interface ILeaderRetailService
{
    Task<LeaderRetailDashboardResponse> GetDashboardAsync(
        int? provinceId,
        bool? status,
        int? managingUnitId,
        CancellationToken cancellationToken = default);

    Task<LeaderRetailManagingUnitsResponse> GetManagingUnitsAsync(
        CancellationToken cancellationToken = default);

    Task<LeaderRetailProvincesResponse> GetProvincesAsync(
        CancellationToken cancellationToken = default);
}
