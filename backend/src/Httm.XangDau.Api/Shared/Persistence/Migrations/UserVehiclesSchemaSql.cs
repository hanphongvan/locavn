namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>DDL for portal user-owned vehicles (<c>UserVehicles</c> → <c>AspNetUsers.Id</c>).</summary>
internal static class UserVehiclesSchemaSql
{
    internal const string Tables =
        """
        IF OBJECT_ID(N'dbo.UserVehicles', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.UserVehicles (
                Id INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_UserVehicles PRIMARY KEY,
                UserId NVARCHAR(128) NOT NULL,
                LicensePlate NVARCHAR(20) NOT NULL,
                VehicleName NVARCHAR(100) NULL,
                FuelType NVARCHAR(50) NULL,
                FuelLevel INT NULL,
                TotalKm INT NULL,
                [Year] INT NULL,
                IsDefault BIT NOT NULL CONSTRAINT DF_UserVehicles_IsDefault DEFAULT (0),
                ImageUrl NVARCHAR(500) NULL,
                CreatedDate DATETIME NOT NULL CONSTRAINT DF_UserVehicles_CreatedDate DEFAULT (GETDATE()),
                UpdatedDate DATETIME NULL,
                CONSTRAINT FK_UserVehicles_AspNetUsers FOREIGN KEY (UserId) REFERENCES dbo.AspNetUsers (Id)
            );

            CREATE NONCLUSTERED INDEX IX_UserVehicles_UserId ON dbo.UserVehicles (UserId);
            CREATE NONCLUSTERED INDEX IX_UserVehicles_UserId_IsDefault ON dbo.UserVehicles (UserId, IsDefault);
        END;
        """;

    internal const string DropTables =
        """
        IF OBJECT_ID(N'dbo.UserVehicles', N'U') IS NOT NULL
            DROP TABLE dbo.UserVehicles;
        """;
}
