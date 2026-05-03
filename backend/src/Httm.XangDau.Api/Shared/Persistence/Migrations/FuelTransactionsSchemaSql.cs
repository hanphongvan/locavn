namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Portal fuel fill-up ledger (<c>FuelTransactions</c> → <c>UserVehicles</c>, <c>AspNetUsers</c>).</summary>
internal static class FuelTransactionsSchemaSql
{
    internal const string Tables =
        """
        IF OBJECT_ID(N'dbo.FuelTransactions', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.FuelTransactions (
                Id INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_FuelTransactions PRIMARY KEY,
                UserId NVARCHAR(128) NOT NULL,
                VehicleId INT NOT NULL,
                StationId INT NULL,
                FuelTypeId INT NULL,
                Amount DECIMAL(18, 2) NOT NULL,
                Liters DECIMAL(18, 3) NOT NULL,
                PricePerLiter DECIMAL(18, 2) NULL,
                Odometer DECIMAL(18, 1) NULL,
                TransactionDate DATETIME NOT NULL,
                CreatedAt DATETIME NOT NULL CONSTRAINT DF_FuelTransactions_CreatedAt DEFAULT (GETDATE()),
                CreatedBy NVARCHAR(100) NULL,
                IsDeleted BIT NOT NULL CONSTRAINT DF_FuelTransactions_IsDeleted DEFAULT (0),
                Note NVARCHAR(500) NULL,
                CONSTRAINT FK_FuelTransactions_UserVehicles FOREIGN KEY (VehicleId) REFERENCES dbo.UserVehicles (Id)
            );

            CREATE NONCLUSTERED INDEX IX_FuelTransactions_VehicleId_TransactionDate
                ON dbo.FuelTransactions (VehicleId, TransactionDate DESC)
                INCLUDE (Amount, Liters, IsDeleted);
        END;
        """;

    internal const string DropTable =
        """
        IF OBJECT_ID(N'dbo.FuelTransactions', N'U') IS NOT NULL
            DROP TABLE dbo.FuelTransactions;
        """;
}
