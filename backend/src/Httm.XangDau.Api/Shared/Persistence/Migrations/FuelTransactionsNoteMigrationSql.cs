namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Adds optional <c>Note</c> to <c>FuelTransactions</c> for portal fuel entry.</summary>
internal static class FuelTransactionsNoteMigrationSql
{
    internal const string AddNoteColumnIfMissing =
        """
        IF COL_LENGTH(N'dbo.FuelTransactions', N'Note') IS NULL
        BEGIN
            ALTER TABLE dbo.FuelTransactions ADD Note NVARCHAR(500) NULL;
        END
        """;
}
