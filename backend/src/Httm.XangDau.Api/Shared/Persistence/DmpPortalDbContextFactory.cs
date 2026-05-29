using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Shared.Persistence;

/// <summary>
/// Design-time factory for <c>dotnet ef</c>. Connection string resolution order:
/// <list type="number">
/// <item><description>Environment variable <c>ConnectionStrings__DefaultConnection</c></description></item>
/// <item><description><c>appsettings.json</c> + optional <c>appsettings.{ASPNETCORE_ENVIRONMENT}.json</c> (base path = current directory, typically the API project folder)</description></item>
/// <item><description>LocalDB fallback for a blank machine</description></item>
/// </list>
/// </summary>
public sealed class DmpPortalDbContextFactory : IDesignTimeDbContextFactory<DmpPortalDbContext>
{
    public DmpPortalDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? BuildConfiguration().GetConnectionString("DefaultConnection")
            ?? "Server=(localdb)\\mssqllocaldb;Database=DMPPortal;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

        var options = new DbContextOptionsBuilder<DmpPortalDbContext>()
            .UseSqlServer(connectionString, sql => sql.UseCompatibilityLevel(120))
            .Options;

        return new DmpPortalDbContext(options);
    }

    private static IConfigurationRoot BuildConfiguration()
    {
        var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")
            ?? Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT")
            ?? "Production";

        return new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
            .AddJsonFile($"appsettings.{env}.json", optional: true, reloadOnChange: false)
            .AddEnvironmentVariables()
            .Build();
    }
}
