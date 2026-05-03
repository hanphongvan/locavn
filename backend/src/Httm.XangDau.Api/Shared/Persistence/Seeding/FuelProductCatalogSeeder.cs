using System.Data;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.Persistence.Seeding;

/// <summary>
/// Idempotent catalog rows for <c>FuelProducts</c>. Does not insert <c>DM_DonVi</c> (stores).
/// <c>UnitId</c> is resolved from legacy <c>dbo.DM_DonViTinh</c> when a liter-like row exists (read-only SQL).
/// </summary>
public static class FuelProductCatalogSeeder
{
    private const string SeedActor = "seed";

    /// <summary>Attempts to find a liter unit in <c>DM_DonViTinh</c> using common <c>Ma</c>/<c>Ten</c> values (DMP-style lookup table).</summary>
    public static int? TryResolveLiterDonViTinhId(DmpPortalDbContext db, ILogger logger)
    {
        try
        {
            var connection = db.Database.GetDbConnection();
            var openedHere = false;
            if (connection.State != ConnectionState.Open)
            {
                db.Database.OpenConnection();
                openedHere = true;
            }

            try
            {
                using var cmd = connection.CreateCommand();
                cmd.CommandText =
                    """
                    SELECT TOP (1) [Id]
                    FROM [dbo].[DM_DonViTinh]
                    WHERE UPPER(LTRIM(RTRIM(ISNULL([Ma], N'')))) IN (N'LIT', N'L', N'LITRE')
                       OR LTRIM(RTRIM(ISNULL([Ten], N''))) IN (N'Lít', N'Lit')
                    ORDER BY [Id];
                    """;

                var scalar = cmd.ExecuteScalar();
                if (scalar is int i)
                    return i;
                if (scalar is long l)
                    return (int)l;
            }
            finally
            {
                if (openedHere)
                    db.Database.CloseConnection();
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Could not resolve a liter unit from dbo.DM_DonViTinh; leaf FuelProducts will use null UnitId.");
        }

        return null;
    }

    /// <summary>Inserts missing rows keyed by <see cref="FuelProduct.Code"/>; safe to run on every startup.</summary>
    public static void SeedIfNeeded(DmpPortalDbContext db, ILogger logger)
    {
        var literUnitId = TryResolveLiterDonViTinhId(db, logger);
        var now = DateTime.UtcNow;
        var anyAdded = false;

        void AddIfMissing(string code, string name, string? parentCode, int? unitId, int sortOrder)
        {
            if (db.FuelProducts.AsNoTracking().Any(p => p.Code == code))
                return;

            int? parentId = null;
            if (parentCode is not null)
            {
                parentId = db.FuelProducts.AsNoTracking()
                    .Where(p => p.Code == parentCode)
                    .Select(p => (int?)p.Id)
                    .FirstOrDefault();
                if (parentId is null)
                {
                    logger.LogWarning(
                        "FuelProducts seed: skip {Code} because parent {ParentCode} is not in the database.",
                        code,
                        parentCode);
                    return;
                }
            }

            db.FuelProducts.Add(new FuelProduct
            {
                Code = code,
                Name = name,
                ParentId = parentId,
                UnitId = unitId,
                IsActive = true,
                SortOrder = sortOrder,
                Description = null,
                Created = now,
                Modified = now,
                CreatedBy = SeedActor,
                ModifiedBy = SeedActor,
            });
            db.SaveChanges();
            anyAdded = true;
        }

        // Tree: NHIEN_LIEU → XANG / DAU → leaves (RON95, E5RON92 under XANG; DIESEL under DAU)
        AddIfMissing("NHIEN_LIEU", "Nhiên liệu", parentCode: null, unitId: null, sortOrder: 1);
        AddIfMissing("XANG", "Xăng", "NHIEN_LIEU", null, 2);
        AddIfMissing("DAU", "Dầu", "NHIEN_LIEU", null, 3);
        AddIfMissing("RON95", "RON95", "XANG", literUnitId, 10);
        AddIfMissing("E5RON92", "E5RON92", "XANG", literUnitId, 11);
        AddIfMissing("DIESEL", "Diesel", "DAU", literUnitId, 20);

        if (anyAdded)
            logger.LogInformation("FuelProducts catalog seed: inserted one or more default rows (see docs/architecture/schema-extension.md).");
    }
}
