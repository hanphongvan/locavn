using Httm.XangDau.Api.Shared.Persistence.Seeding;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Shared.Persistence;

public static class FuelCatalogSeedExtensions
{
    /// <summary>Runs <see cref="FuelProductCatalogSeeder.SeedIfNeeded"/> once per startup after migrations.</summary>
    public static void SeedFuelProductCatalogIfNeeded(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<DmpPortalDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>()
            .CreateLogger("Httm.XangDau.Api.FuelProductCatalogSeeder");
        FuelProductCatalogSeeder.SeedIfNeeded(db, logger);
    }
}
