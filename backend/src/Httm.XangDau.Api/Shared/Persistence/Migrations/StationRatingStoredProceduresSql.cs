namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Stored procedures for station ratings (Dapper only; see <c>docs/architecture/backend.md</c>).</summary>
internal static class StationRatingStoredProceduresSql
{
    /// <summary>Petrol retail <c>DM_DonVi.CapDonViId</c> — same as <see cref="Httm.XangDau.Api.Shared.Domain.PetrolRetailConstants.CapDonViId"/>.</summary>
    internal const string Insert =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StationRating_Insert
            @StationId INT,
            @Rating INT,
            @Comment NVARCHAR(500) = NULL,
            @DeviceId NVARCHAR(100) = NULL,
            @CreatedBy NVARCHAR(100) = NULL,
            @RatingId INT OUTPUT,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @RatingId = NULL;
            SET @ErrorMessage = NULL;

            IF @Rating < 1 OR @Rating > 5
            BEGIN
                SET @ErrorMessage = N'Điểm đánh giá phải từ 1 đến 5';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.DM_DonVi AS d
                WHERE d.Id = @StationId
                  AND d.CapDonViId = 248
            )
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy cây xăng';
                RETURN;
            END;

            IF @DeviceId IS NOT NULL
               AND EXISTS (
                   SELECT 1
                   FROM dbo.StationRatings AS r
                   WHERE r.StationId = @StationId
                     AND r.IsDeleted = 0
                     AND r.DeviceId = @DeviceId
                     AND CAST(r.CreatedAt AS DATE) = CAST(GETDATE() AS DATE)
               )
            BEGIN
                SET @ErrorMessage = N'Bạn đã đánh giá cây xăng này trong ngày hôm nay';
                RETURN;
            END;

            INSERT INTO dbo.StationRatings (StationId, Rating, Comment, DeviceId, CreatedBy)
            VALUES (@StationId, @Rating, @Comment, @DeviceId, @CreatedBy);

            SET @RatingId = SCOPE_IDENTITY();
        END;
        """;

    internal const string InsertImage =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StationRatingImage_Insert
            @RatingId INT,
            @ImageUrl NVARCHAR(500),
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.StationRatings AS r
                WHERE r.Id = @RatingId
                  AND r.IsDeleted = 0
            )
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy đánh giá để gắn ảnh';
                RETURN;
            END;

            INSERT INTO dbo.StationRatingImages (RatingId, ImageUrl)
            VALUES (@RatingId, @ImageUrl);
        END;
        """;

    internal const string GetSummary =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StationRating_GetSummary
            @StationId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                @StationId AS StationId,
                CAST(ISNULL(AVG(CAST(r.Rating AS DECIMAL(5, 2))), 0) AS DECIMAL(4, 2)) AS AvgRating,
                CAST(COUNT_BIG(*) AS INT) AS TotalRatings
            FROM dbo.StationRatings AS r
            WHERE r.StationId = @StationId
              AND r.IsDeleted = 0;
        END;
        """;

    internal const string GetByStation =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StationRating_GetByStation
            @StationId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                r.Id,
                r.Rating,
                r.Comment,
                r.CreatedAt,
                r.CreatedBy
            FROM dbo.StationRatings AS r
            WHERE r.StationId = @StationId
              AND r.IsDeleted = 0
            ORDER BY r.CreatedAt DESC;

            SELECT
                i.RatingId,
                i.ImageUrl
            FROM dbo.StationRatingImages AS i
            INNER JOIN dbo.StationRatings AS r ON r.Id = i.RatingId
            WHERE r.StationId = @StationId
              AND r.IsDeleted = 0
            ORDER BY i.RatingId, i.Id;
        END;
        """;

    internal const string DropProcedures =
        """
        IF OBJECT_ID(N'dbo.sp_StationRating_GetByStation', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_StationRating_GetByStation;
        IF OBJECT_ID(N'dbo.sp_StationRating_GetSummary', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_StationRating_GetSummary;
        IF OBJECT_ID(N'dbo.sp_StationRatingImage_Insert', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_StationRatingImage_Insert;
        IF OBJECT_ID(N'dbo.sp_StationRating_Insert', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_StationRating_Insert;
        """;

    internal const string DropTables =
        """
        IF OBJECT_ID(N'dbo.StationRatingImages', N'U') IS NOT NULL
            DROP TABLE dbo.StationRatingImages;
        IF OBJECT_ID(N'dbo.StationRatings', N'U') IS NOT NULL
            DROP TABLE dbo.StationRatings;
        """;
}
