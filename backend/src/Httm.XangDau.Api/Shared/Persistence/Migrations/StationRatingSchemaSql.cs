namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>DDL for <c>StationRatings</c> / <c>StationRatingImages</c> (EF migration + mirror under <c>backend/database/migrations</c>).</summary>
internal static class StationRatingSchemaSql
{
    /// <summary><c>StationId</c> → <c>DM_DonVi.Id</c> (retail cap 248 enforced in write SP only).</summary>
    internal const string Tables =
        """
        IF OBJECT_ID(N'dbo.StationRatings', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.StationRatings (
                Id INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_StationRatings PRIMARY KEY,
                StationId INT NOT NULL,
                Rating INT NOT NULL,
                Comment NVARCHAR(500) NULL,
                DeviceId NVARCHAR(100) NULL,
                CreatedBy NVARCHAR(100) NULL,
                CreatedAt DATETIME NOT NULL CONSTRAINT DF_StationRatings_CreatedAt DEFAULT (GETDATE()),
                IsDeleted BIT NOT NULL CONSTRAINT DF_StationRatings_IsDeleted DEFAULT (0),
                CONSTRAINT FK_StationRatings_DM_DonVi FOREIGN KEY (StationId) REFERENCES dbo.DM_DonVi (Id),
                CONSTRAINT CK_StationRatings_Rating CHECK (Rating >= 1 AND Rating <= 5)
            );

            CREATE TABLE dbo.StationRatingImages (
                Id INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_StationRatingImages PRIMARY KEY,
                RatingId INT NOT NULL,
                ImageUrl NVARCHAR(500) NOT NULL,
                CreatedAt DATETIME NOT NULL CONSTRAINT DF_StationRatingImages_CreatedAt DEFAULT (GETDATE()),
                CONSTRAINT FK_StationRatingImages_StationRatings FOREIGN KEY (RatingId) REFERENCES dbo.StationRatings (Id)
            );

            CREATE NONCLUSTERED INDEX IX_StationRatings_StationId_IsDeleted_CreatedAt
                ON dbo.StationRatings (StationId, IsDeleted, CreatedAt DESC);

            CREATE NONCLUSTERED INDEX IX_StationRatingImages_RatingId ON dbo.StationRatingImages (RatingId);
        END;
        """;
}
