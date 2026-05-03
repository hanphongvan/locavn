using Microsoft.EntityFrameworkCore;



namespace Httm.XangDau.Api.Shared.Persistence;



public static class DatabaseMigrationExtensions

{

    /// <summary>

    /// Applies <b>pending</b> EF Core migrations for <see cref="DmpPortalDbContext"/> using

    /// <see cref="RelationalDatabaseFacadeExtensions.Migrate"/>.

    /// Does <b>not</b> drop, recreate, or call <c>EnsureDeleted</c> / <c>EnsureCreated</c> — only runs <c>Up</c> scripts

    /// for migrations not yet listed in <c>__EFMigrationsHistory</c>. Existing data in untouched tables/columns remains.

    /// </summary>

    public static void ApplyDmpPortalMigrations(this WebApplication app)

    {

        using var scope = app.Services.CreateScope();

        var db = scope.ServiceProvider.GetRequiredService<DmpPortalDbContext>();

        var logger = scope.ServiceProvider.GetRequiredService<ILogger<DmpPortalDbContext>>();



        try

        {

            var pending = db.Database.GetPendingMigrations().ToList();

            if (pending.Count == 0)

            {

                logger.LogInformation("DmpPortalDbContext: no pending EF Core migrations.");

                return;

            }



            logger.LogInformation(

                "DmpPortalDbContext: applying {PendingCount} pending EF Core migration(s): {MigrationIds}",

                pending.Count,

                string.Join(", ", pending));



            db.Database.Migrate();



            logger.LogInformation("DmpPortalDbContext: EF Core migrations applied successfully.");

        }

        catch (Exception ex)

        {

            logger.LogError(ex, "DmpPortalDbContext: failed to apply EF Core migrations. The host will not start.");

            throw;

        }

    }

}


