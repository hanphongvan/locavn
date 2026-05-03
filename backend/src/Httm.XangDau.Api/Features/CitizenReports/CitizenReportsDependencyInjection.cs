namespace Httm.XangDau.Api.Features.CitizenReports;

public static class CitizenReportsDependencyInjection
{
    public static IServiceCollection AddCitizenReportsFeature(this IServiceCollection services)
    {
        // TODO phase 2: persistence gap — no complaint table in docs/architecture/database.md; integrate external API or new approved table only
        return services;
    }
}
