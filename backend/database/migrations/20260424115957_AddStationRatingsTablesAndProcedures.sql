-- Mirror of EF migration AddStationRatingsTablesAndProcedures.
-- Source of truth: Shared/Persistence/Migrations/StationRatingSchemaSql.cs + StationRatingStoredProceduresSql.cs

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
GO

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
GO

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
GO

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
GO

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
GO
