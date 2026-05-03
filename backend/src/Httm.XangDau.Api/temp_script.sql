IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418090842_InitialDmpPortalBaseline'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260418090842_InitialDmpPortalBaseline', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418091940_AddStationOperatingHours'
)
BEGIN
    IF OBJECT_ID(N'dbo.DM_DonVi', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DM_DonVi (
            [Id] int NOT NULL IDENTITY(1, 1),
            [Ma] nvarchar(20) NOT NULL,
            [Ten] nvarchar(200) NOT NULL,
            [TenTiengNuocNgoai] nvarchar(200) NULL,
            [DienThoai] nvarchar(50) NULL,
            [DiaChi] nvarchar(250) NULL,
            [Email] nvarchar(50) NULL,
            [SoTaiKhoan] nvarchar(30) NULL,
            [SapXep] int NULL,
            [UngPhep] bit NULL,
            [CapTrenId] int NULL,
            [Cap] int NULL,
            [MaAo] nvarchar(500) NULL,
            [CoCapCon] int NULL,
            [CongThucId] int NULL,
            [NgayThanhLap] datetime2 NULL,
            [NgayGiaiThe] datetime2 NULL,
            [TenKhongDau] nvarchar(200) NULL,
            [ThuocDonViId] int NULL,
            [PhanLoaiId] int NULL,
            [PhanQuyen] int NULL,
            [TT] int NULL,
            [TN] int NULL,
            [ThuocCap] int NULL,
            [Created] datetime2 NULL,
            [CreatedBy] nvarchar(100) NULL,
            [Modified] datetime2 NULL,
            [ModifiedBy] nvarchar(100) NULL,
            [Version] rowversion,
            [Ky_ThuTruongDonVi] nvarchar(70) NULL,
            [Ky_KeToanTruong] nvarchar(70) NULL,
            [Ky_NguoiLapBaoCao] nvarchar(70) NULL,
            [Ky_ThuKho] nvarchar(70) NULL,
            [Ky_ThuQuy] nvarchar(70) NULL,
            [IdGuid] uniqueidentifier NULL,
            [CapDonViId] int NOT NULL CONSTRAINT [DF_DM_DonVi_CapDonViId] DEFAULT (248),
            [TrangThai] bit NULL,
            [VungMien] int NULL,
            [SoGiayPhep] nvarchar(200) NULL,
            [NgayCap] datetime2 NULL,
            [NgayHetHan] datetime2 NULL,
            [Tinh] int NULL,
            [Xa] int NULL,
            [DiaChiChiTiet] nvarchar(500) NULL,
            [NoiCapId] int NULL,
            [LoaiHinh] int NULL,
            [ThemMoi] int NULL,
            [CapTrenText] nvarchar(500) NULL,
            [ViDo] decimal(9, 6) NULL,
            [KinhDo] decimal(9, 6) NULL,
            CONSTRAINT [PK_DM_DonVi] PRIMARY KEY CLUSTERED ([Id])
        );
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418091940_AddStationOperatingHours'
)
BEGIN
    CREATE TABLE [StationOperatingHours] (
        [Id] int NOT NULL IDENTITY,
        [DonViId] int NOT NULL,
        [DayOfWeek] tinyint NOT NULL,
        [OpensAt] time(0) NULL,
        [ClosesAt] time(0) NULL,
        [IsClosedAllDay] bit NOT NULL,
        CONSTRAINT [PK_StationOperatingHours] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationOperatingHours_DM_DonVi_DonViId] FOREIGN KEY ([DonViId]) REFERENCES [DM_DonVi] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418091940_AddStationOperatingHours'
)
BEGIN
    CREATE UNIQUE INDEX [IX_StationOperatingHours_DonViId_DayOfWeek] ON [StationOperatingHours] ([DonViId], [DayOfWeek]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418091940_AddStationOperatingHours'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260418091940_AddStationOperatingHours', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    CREATE TABLE [StationReviews] (
        [Id] int NOT NULL IDENTITY,
        [StationId] int NOT NULL,
        [Rating] tinyint NOT NULL,
        [Comment] nvarchar(2000) NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_StationReviews] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationReviews_DM_DonVi_StationId] FOREIGN KEY ([StationId]) REFERENCES [DM_DonVi] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    CREATE TABLE [StationReviewImages] (
        [Id] int NOT NULL IDENTITY,
        [ReviewId] int NOT NULL,
        [ImageUrl] nvarchar(2048) NOT NULL,
        CONSTRAINT [PK_StationReviewImages] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationReviewImages_StationReviews_ReviewId] FOREIGN KEY ([ReviewId]) REFERENCES [StationReviews] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    CREATE INDEX [IX_StationReviewImages_ReviewId] ON [StationReviewImages] ([ReviewId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    CREATE INDEX [IX_StationReviews_StationId] ON [StationReviews] ([StationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    CREATE INDEX [IX_StationReviews_StationId_CreatedAt] ON [StationReviews] ([StationId], [CreatedAt]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418095042_AddStationReviews'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260418095042_AddStationReviews', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    CREATE TABLE [StationBadReports] (
        [Id] int NOT NULL IDENTITY,
        [StationId] int NULL,
        [Content] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [Status] tinyint NOT NULL,
        CONSTRAINT [PK_StationBadReports] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationBadReports_DM_DonVi_StationId] FOREIGN KEY ([StationId]) REFERENCES [DM_DonVi] ([Id]) ON DELETE SET NULL
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    CREATE TABLE [StationBadReportImages] (
        [Id] int NOT NULL IDENTITY,
        [ReportId] int NOT NULL,
        [ImageUrl] nvarchar(2048) NOT NULL,
        CONSTRAINT [PK_StationBadReportImages] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationBadReportImages_StationBadReports_ReportId] FOREIGN KEY ([ReportId]) REFERENCES [StationBadReports] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    CREATE INDEX [IX_StationBadReportImages_ReportId] ON [StationBadReportImages] ([ReportId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    CREATE INDEX [IX_StationBadReports_CreatedAt_Id] ON [StationBadReports] ([CreatedAt], [Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    CREATE INDEX [IX_StationBadReports_StationId] ON [StationBadReports] ([StationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418100034_AddStationBadReports'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260418100034_AddStationBadReports', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    ALTER TABLE [DM_DonVi] ADD [CloseTime] time(0) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    ALTER TABLE [DM_DonVi] ADD [OpenTime] time(0) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE TABLE [FuelProducts] (
        [Id] int NOT NULL IDENTITY,
        [Code] nvarchar(50) NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [ParentId] int NULL,
        [UnitId] int NULL,
        [IsActive] bit NOT NULL,
        [SortOrder] int NULL,
        [Description] nvarchar(500) NULL,
        [Created] datetime NOT NULL,
        [CreatedBy] nvarchar(100) NULL,
        [Modified] datetime NOT NULL,
        [ModifiedBy] nvarchar(100) NULL,
        CONSTRAINT [PK_FuelProducts] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE TABLE [StationInventoryTransactions] (
        [Id] int NOT NULL IDENTITY,
        [DonViId] int NOT NULL,
        [ProductId] int NOT NULL,
        [Quantity] decimal(18,3) NOT NULL,
        [Amount] decimal(18,2) NULL,
        [TransactionType] int NOT NULL,
        [TransactionDate] datetime NOT NULL,
        [Note] nvarchar(500) NULL,
        [Created] datetime NOT NULL,
        [CreatedBy] nvarchar(100) NULL,
        [Modified] datetime NOT NULL,
        [ModifiedBy] nvarchar(100) NULL,
        CONSTRAINT [PK_StationInventoryTransactions] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE TABLE [StationProductPrices] (
        [Id] int NOT NULL IDENTITY,
        [DonViId] int NOT NULL,
        [ProductId] int NOT NULL,
        [Price] decimal(18,2) NOT NULL,
        [UnitId] int NULL,
        [EffectiveDate] datetime NOT NULL,
        [IsCurrent] bit NOT NULL,
        [Note] nvarchar(500) NULL,
        [Created] datetime NOT NULL,
        [CreatedBy] nvarchar(100) NULL,
        [Modified] datetime NOT NULL,
        [ModifiedBy] nvarchar(100) NULL,
        CONSTRAINT [PK_StationProductPrices] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_FuelProducts_Code] ON [FuelProducts] ([Code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE INDEX [IX_StationInventoryTransactions_DonViId_ProductId_TransactionDate] ON [StationInventoryTransactions] ([DonViId], [ProductId], [TransactionDate] DESC);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    CREATE INDEX [IX_StationProductPrices_DonViId_ProductId_EffectiveDate] ON [StationProductPrices] ([DonViId], [ProductId], [EffectiveDate] DESC);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260418150537_AddStoreAdminFuelSchema'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260418150537_AddStoreAdminFuelSchema', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419045326_AddStoreAdminInventoryCurrentStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
            FROM dbo.StationInventoryTransactions AS t
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR t.DonViId = @DonViId)
              AND (@ProductId IS NULL OR t.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR t.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419045326_AddStoreAdminInventoryCurrentStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        ;WITH FilteredTx AS (
            SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
            FROM dbo.StationInventoryTransactions AS t
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE t.DonViId = @DonViId
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg
        ORDER BY ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419045326_AddStoreAdminInventoryCurrentStoredProcedures'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419045326_AddStoreAdminInventoryCurrentStoredProcedures', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419050239_FixStoreAdminInventoryCurrentProcCsvSplitCompat'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
            FROM dbo.StationInventoryTransactions AS t
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR t.DonViId = @DonViId)
              AND (@ProductId IS NULL OR t.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR t.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419050239_FixStoreAdminInventoryCurrentProcCsvSplitCompat'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419050239_FixStoreAdminInventoryCurrentProcCsvSplitCompat', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419050847_FixStoreAdminInventoryCurrentListPagedAggCteScope'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
            FROM dbo.StationInventoryTransactions AS t
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR t.DonViId = @DonViId)
              AND (@ProductId IS NULL OR t.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR t.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419050847_FixStoreAdminInventoryCurrentListPagedAggCteScope'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419050847_FixStoreAdminInventoryCurrentListPagedAggCteScope', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419094444_AddHtUsersGetModelPortalStoredProcedure'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_HT_Users_GetModel_Portal
        @CallerUserName NVARCHAR(100),
        @TuKhoa          NVARCHAR(200) = NULL,
        @DonViId         INT           = NULL,
        @Loai            INT           = NULL,
        @KhoaTaiKhoan    BIT           = NULL,
        @PageIndex       INT           = 1,
        @PageSize        INT           = 20,
        @TotalRow        INT           OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @tLoai INT;
        DECLARE @tDon_Vi_Id INT;

        SELECT @tLoai = Loai,
               @tDon_Vi_Id = DonViId
        FROM dbo.AspNetUsers
        WHERE UserName = @CallerUserName;

        IF @tLoai IS NULL
        BEGIN
            SET @TotalRow = 0;
            RETURN;
        END;

        IF @PageIndex < 1 SET @PageIndex = 1;
        IF @PageSize < 1 SET @PageSize = 20;
        IF @PageSize > 500 SET @PageSize = 500;

        DECLARE @Offset INT = (@PageIndex - 1) * @PageSize;

        IF OBJECT_ID('tempdb..#Visible', 'U') IS NOT NULL
            DROP TABLE #Visible;

        SELECT U.*,
               DV.Ten AS DonVi
        INTO #Visible
        FROM dbo.AspNetUsers AS U
        LEFT JOIN dbo.DM_DonVi AS DV ON U.DonViId = DV.Id
        WHERE @tLoai = 1
           OR (@tLoai = 3 AND U.DonViId = @tDon_Vi_Id)
           OR (
                  @tLoai = 2
                  AND U.DonViId IN (
                      SELECT dvu.Don_Vi_Id
                      FROM dbo.HT_Users_DonVi AS dvu
                      INNER JOIN dbo.AspNetUsers AS us ON us.Id = dvu.UserId
                      WHERE us.UserName = @CallerUserName
                  )
              );

        IF OBJECT_ID('tempdb..#Filtered', 'U') IS NOT NULL
            DROP TABLE #Filtered;

        SELECT v.*
        INTO #Filtered
        FROM #Visible AS v
        WHERE (
                  @TuKhoa IS NULL
                  OR LTRIM(RTRIM(@TuKhoa)) = N''
                  OR v.UserName LIKE N'%' + @TuKhoa + N'%'
                  OR ISNULL(v.DisplayName, N'') LIKE N'%' + @TuKhoa + N'%'
                  OR ISNULL(v.Email, N'') LIKE N'%' + @TuKhoa + N'%'
                  OR ISNULL(v.PhoneNumber, N'') LIKE N'%' + @TuKhoa + N'%'
              )
          AND (@DonViId IS NULL OR v.DonViId = @DonViId)
          AND (@Loai IS NULL OR v.Loai = @Loai)
          AND (
                  @KhoaTaiKhoan IS NULL
                  OR (@KhoaTaiKhoan = 1 AND ISNULL(v.LockoutEnabled, 0) = 1)
                  OR (@KhoaTaiKhoan = 0 AND ISNULL(v.LockoutEnabled, 0) = 0)
              );

        SELECT @TotalRow = COUNT(1) FROM #Filtered;

        DECLARE @true BIT = 1;
        DECLARE @false BIT = 0;

        SELECT f.*,
               CASE
                   WHEN f.UserName = N'admin' OR f.UserName = N'system' THEN N'Nhóm quản trị'
                   WHEN f.Loai = 1 THEN N'Nhóm quản trị'
                   WHEN f.Loai = 2 THEN N'Nhóm người dùng quản trị'
                   WHEN f.Loai = 3 THEN N'Nhóm người dùng các đơn vị trực thuộc'
                   ELSE NULL
               END AS LoaiS,
               CASE
                   WHEN f.LockoutEnabled IS NULL OR f.LockoutEnabled = 0 THEN @false
                   ELSE @true
               END AS IsActived
        FROM #Filtered AS f
        ORDER BY f.UserName
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

        DROP TABLE #Filtered;
        DROP TABLE #Visible;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419094444_AddHtUsersGetModelPortalStoredProcedure'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419094444_AddHtUsersGetModelPortalStoredProcedure', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419101044_TenMigration'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419101044_TenMigration', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_DonVi_IsRetailStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
            SELECT CAST(1 AS BIT) AS Ok;
        ELSE
            SELECT CAST(0 AS BIT) AS Ok;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProduct_Exists
        @ProductId INT
    AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
            SELECT CAST(1 AS BIT) AS Ok;
        ELSE
            SELECT CAST(0 AS BIT) AS Ok;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup
        @Search NVARCHAR(200) = NULL,
        @Take INT = 200,
        @DefaultsOnly BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @Take < 1 SET @Take = 1;
        IF @Take > 500 SET @Take = 500;

        SELECT TOP (@Take)
            fp.Id,
            fp.Code,
            fp.Name,
            fp.UnitId,
            fp.SortOrder
        FROM dbo.FuelProducts AS fp
        WHERE fp.IsActive = 1
          AND (@DefaultsOnly = 0 OR fp.SortOrder IS NOT NULL)
          AND (
              @Search IS NULL
              OR LTRIM(RTRIM(@Search)) = N''
              OR fp.Code LIKE N'%' + @Search + N'%'
              OR fp.Name LIKE N'%' + @Search + N'%'
          )
        ORDER BY fp.SortOrder, fp.Name;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @IsCurrent BIT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note
        INTO #Filtered
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR p.DonViId = @DonViId)
          AND (@ProductId IS NULL OR p.ProductId = @ProductId)
          AND (@IsCurrent IS NULL OR p.IsCurrent = @IsCurrent)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR p.DonViId IN (SELECT Id FROM @ScopeIds)
          );

        SELECT @TotalCount = COUNT(1) FROM #Filtered;

        SELECT
            Id,
            DonViId,
            ProductId,
            Price,
            UnitId,
            EffectiveDate,
            IsCurrent,
            Note
        FROM #Filtered
        ORDER BY EffectiveDate DESC, DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId
        ORDER BY p.EffectiveDate DESC, p.ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId AND p.IsCurrent = 1
        ORDER BY p.ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_GetById
        @Id INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT TOP (1)
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.Created,
            p.CreatedBy,
            p.Modified,
            p.ModifiedBy
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.Id = @Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListLatestSubmission
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
            RETURN;

        DECLARE @MaxEd DATETIME;
        SELECT @MaxEd = MAX(p.EffectiveDate)
        FROM dbo.StationProductPrices AS p
        WHERE p.DonViId = @DonViId;

        IF @MaxEd IS NULL
            RETURN;

        SELECT
            p.ProductId,
            p.Price,
            p.UnitId,
            p.Note,
            p.EffectiveDate,
            p.IsCurrent
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId AND p.EffectiveDate = @MaxEd
        ORDER BY p.ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Insert
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @NewId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @NewId = NULL;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1;
            END;

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            VALUES (
                @DonViId,
                @ProductId,
                @Price,
                @UnitId,
                @EffectiveDate,
                @IsCurrent,
                @Note,
                @Now,
                @Actor,
                @Now,
                @Actor);

            SET @NewId = CAST(SCOPE_IDENTITY() AS INT);
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Update
        @Id INT,
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationProductPrices AS p
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE p.Id = @Id)
        BEGIN
            RAISERROR(N'Price row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1 AND Id <> @Id;
            END;

            UPDATE dbo.StationProductPrices
            SET
                DonViId = @DonViId,
                ProductId = @ProductId,
                Price = @Price,
                UnitId = @UnitId,
                EffectiveDate = @EffectiveDate,
                IsCurrent = @IsCurrent,
                Note = @Note,
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @Id;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_BatchInsert
        @DonViId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsJson NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsJson IS NULL OR LTRIM(RTRIM(@RowsJson)) = N'' OR @RowsJson = N'[]'
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
                ProductId INT NOT NULL,
                Price DECIMAL(18, 2) NOT NULL,
                UnitId INT NULL,
                Note NVARCHAR(500) NULL
            );

            INSERT INTO #Rows (ProductId, Price, UnitId, Note)
            SELECT
                JSON_VALUE(j.[value], '$.productId'),
                JSON_VALUE(j.[value], '$.price'),
                JSON_VALUE(j.[value], '$.unitId'),
                JSON_VALUE(j.[value], '$.note')
            FROM OPENJSON(@RowsJson) AS j;

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        CREATE TABLE #CreatedIds (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE p
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                FROM dbo.StationProductPrices AS p
                INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;
            END;

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            OUTPUT INSERTED.Id INTO #CreatedIds (Id)
            SELECT
                @DonViId,
                r.ProductId,
                r.Price,
                r.UnitId,
                @EffectiveDate,
                @IsCurrent,
                r.Note,
                @Now,
                @Actor,
                @Now,
                @Actor
            FROM #Rows AS r
            ORDER BY r.ProductId;

            SELECT Id FROM #CreatedIds ORDER BY Id;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419140652_AddStoreAdminStationProductPriceStoredProcedures', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419145320_UpdateStorePriceFuelLeafAndDonViTinhList'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_DM_DonViTinh_List
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            d.Id,
            d.Ma,
            d.Ten
        FROM dbo.DM_DonViTinh AS d
        ORDER BY d.Ten, d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419145320_UpdateStorePriceFuelLeafAndDonViTinhList'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup
        @Search NVARCHAR(200) = NULL,
        @Take INT = 200,
        @DefaultsOnly BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @Take < 1 SET @Take = 1;
        IF @Take > 500 SET @Take = 500;

        SELECT TOP (@Take)
            fp.Id,
            fp.Code,
            fp.Name,
            fp.UnitId,
            fp.SortOrder
        FROM dbo.FuelProducts AS fp
        WHERE fp.IsActive = 1
          AND NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS c WHERE c.ParentId = fp.Id)
          AND (@DefaultsOnly = 0 OR fp.SortOrder IS NOT NULL)
          AND (
              @Search IS NULL
              OR LTRIM(RTRIM(@Search)) = N''
              OR fp.Code LIKE N'%' + @Search + N'%'
              OR fp.Name LIKE N'%' + @Search + N'%'
          )
        ORDER BY fp.SortOrder, fp.Name;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419145320_UpdateStorePriceFuelLeafAndDonViTinhList'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419145320_UpdateStorePriceFuelLeafAndDonViTinhList', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419155432_FixStoreAdminStationProductPricesBatchInsertRowsXml'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_BatchInsert
        @DonViId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Price DECIMAL(18, 2) NOT NULL,
            UnitId INT NULL,
            Note NVARCHAR(500) NULL
        );

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Price, UnitId, Note)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@price', 'DECIMAL(18,2)'),
            T.c.value('@unitId', 'INT'),
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and price.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        CREATE TABLE #CreatedIds (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE p
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                FROM dbo.StationProductPrices AS p
                INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;
            END;

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            OUTPUT INSERTED.Id INTO #CreatedIds (Id)
            SELECT
                @DonViId,
                r.ProductId,
                r.Price,
                r.UnitId,
                @EffectiveDate,
                @IsCurrent,
                r.Note,
                @Now,
                @Actor,
                @Now,
                @Actor
            FROM #Rows AS r
            ORDER BY r.ProductId;

            SELECT Id FROM #CreatedIds ORDER BY Id;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419155432_FixStoreAdminStationProductPricesBatchInsertRowsXml'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419155432_FixStoreAdminStationProductPricesBatchInsertRowsXml', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    CREATE TABLE [StationPrices] (
        [Id] int NOT NULL IDENTITY,
        [DonViId] int NOT NULL,
        [ActiveDate] datetime NOT NULL,
        [IsActive] bit NOT NULL,
        [Created] datetime NOT NULL,
        [CreatedBy] nvarchar(50) NULL,
        [Modified] datetime NOT NULL,
        [ModifiedBy] nvarchar(50) NULL,
        CONSTRAINT [PK_StationPrices] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    ALTER TABLE [StationProductPrices] ADD [StationPricesId] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    IF EXISTS (SELECT 1 FROM dbo.StationProductPrices)
    BEGIN
        INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
        SELECT
            p.DonViId,
            p.EffectiveDate,
            CAST(CASE WHEN SUM(CASE WHEN p.IsCurrent = 1 THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS BIT),
            MIN(p.Created),
            NULL,
            MAX(p.Modified),
            NULL
        FROM dbo.StationProductPrices AS p
        GROUP BY p.DonViId, p.EffectiveDate;

        ;WITH ranked AS (
            SELECT s.Id,
                   ROW_NUMBER() OVER (PARTITION BY s.DonViId ORDER BY s.ActiveDate DESC, s.Id DESC) AS rn
            FROM dbo.StationPrices AS s
        )
        UPDATE s
        SET s.IsActive = CAST(1 AS BIT)
        FROM dbo.StationPrices AS s
        INNER JOIN ranked AS r ON r.Id = s.Id AND r.rn = 1;

        UPDATE p
        SET p.StationPricesId = s.Id
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.StationPrices AS s ON s.DonViId = p.DonViId AND s.ActiveDate = p.EffectiveDate;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    DECLARE @var nvarchar(max);
    SELECT @var = QUOTENAME([d].[name])
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[StationProductPrices]') AND [c].[name] = N'StationPricesId');
    IF @var IS NOT NULL EXEC(N'ALTER TABLE [StationProductPrices] DROP CONSTRAINT ' + @var + ';');
    ALTER TABLE [StationProductPrices] ALTER COLUMN [StationPricesId] int NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    CREATE INDEX [IX_StationProductPrices_StationPricesId] ON [StationProductPrices] ([StationPricesId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    ALTER TABLE [StationProductPrices] ADD CONSTRAINT [FK_StationProductPrices_StationPrices_StationPricesId] FOREIGN KEY ([StationPricesId]) REFERENCES [StationPrices] ([Id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @IsCurrent BIT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        INTO #Filtered
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR p.DonViId = @DonViId)
          AND (@ProductId IS NULL OR p.ProductId = @ProductId)
          AND (@IsCurrent IS NULL OR p.IsCurrent = @IsCurrent)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR p.DonViId IN (SELECT Id FROM @ScopeIds)
          );

        SELECT @TotalCount = COUNT(1) FROM #Filtered;

        SELECT
            Id,
            DonViId,
            ProductId,
            Price,
            UnitId,
            EffectiveDate,
            IsCurrent,
            Note,
            StationPricesId
        FROM #Filtered
        ORDER BY EffectiveDate DESC, DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId
        ORDER BY p.EffectiveDate DESC, p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
        WHERE p.DonViId = @DonViId AND s.IsActive = 1
        ORDER BY p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_GetById
        @Id INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT TOP (1)
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId,
            p.Created,
            p.CreatedBy,
            p.Modified,
            p.ModifiedBy
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.Id = @Id;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListLatestSubmission
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
            RETURN;

        DECLARE @MaxEd DATETIME;
        SELECT @MaxEd = MAX(p.EffectiveDate)
        FROM dbo.StationProductPrices AS p
        WHERE p.DonViId = @DonViId;

        IF @MaxEd IS NULL
            RETURN;

        SELECT
            p.ProductId,
            p.Price,
            p.UnitId,
            p.Note,
            p.EffectiveDate,
            p.IsCurrent
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId AND p.EffectiveDate = @MaxEd
        ORDER BY p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Insert
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @NewId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @NewId = NULL;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        DECLARE @HeaderId TABLE (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1;
            END;

            INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
            OUTPUT INSERTED.Id INTO @HeaderId
            VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

            DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderId);

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy,
                StationPricesId)
            VALUES (
                @DonViId,
                @ProductId,
                @Price,
                @UnitId,
                @EffectiveDate,
                @IsCurrent,
                @Note,
                @Now,
                @Actor,
                @Now,
                @Actor,
                @StationPricesId);

            SET @NewId = CAST(SCOPE_IDENTITY() AS INT);
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Update
        @Id INT,
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationProductPrices AS p
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE p.Id = @Id)
        BEGIN
            RAISERROR(N'Price row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        DECLARE @StationPricesId INT =
            (SELECT p.StationPricesId FROM dbo.StationProductPrices AS p WHERE p.Id = @Id);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1 AND Id <> @Id;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
            END;

            UPDATE dbo.StationProductPrices
            SET
                DonViId = @DonViId,
                ProductId = @ProductId,
                Price = @Price,
                UnitId = @UnitId,
                EffectiveDate = @EffectiveDate,
                IsCurrent = @IsCurrent,
                Note = @Note,
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @Id;

            UPDATE dbo.StationPrices
            SET
                ActiveDate = @EffectiveDate,
                IsActive = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor50
            WHERE Id = @StationPricesId;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_BatchInsert
        @DonViId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Price DECIMAL(18, 2) NOT NULL,
            UnitId INT NULL,
            Note NVARCHAR(500) NULL
        );

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Price, UnitId, Note)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@price', 'DECIMAL(18,2)'),
            T.c.value('@unitId', 'INT'),
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and price.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        CREATE TABLE #CreatedIds (Id INT NOT NULL);
        DECLARE @HeaderIds TABLE (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                FROM dbo.StationProductPrices AS p
                INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1;
            END;

            INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
            OUTPUT INSERTED.Id INTO @HeaderIds
            VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

            DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderIds);

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy,
                StationPricesId)
            OUTPUT INSERTED.Id INTO #CreatedIds (Id)
            SELECT
                @DonViId,
                r.ProductId,
                r.Price,
                r.UnitId,
                @EffectiveDate,
                @IsCurrent,
                r.Note,
                @Now,
                @Actor,
                @Now,
                @Actor,
                @StationPricesId
            FROM #Rows AS r
            ORDER BY r.ProductId;

            SELECT @StationPricesId AS StationPricesId;
            SELECT Id FROM #CreatedIds ORDER BY Id;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419161134_AddStationPricesAndProductPriceHeaderLink'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419161134_AddStationPricesAndProductPriceHeaderLink', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT,
        @ProductId INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.DonViId = @DonViId
          AND (@ProductId IS NULL OR p.ProductId = @ProductId)
        ORDER BY p.EffectiveDate DESC, p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
        WHERE p.DonViId = @DonViId
          AND s.IsActive = 1
          AND s.ActiveDate <= GETDATE()
        ORDER BY p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @IsActive BIT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        SELECT
            s.Id,
            s.DonViId,
            s.ActiveDate,
            s.IsActive,
            s.Created,
            s.CreatedBy,
            s.Modified,
            s.ModifiedBy
        INTO #Filtered
        FROM dbo.StationPrices AS s
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR s.DonViId = @DonViId)
          AND (@IsActive IS NULL OR s.IsActive = @IsActive)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR s.DonViId IN (SELECT Id FROM @ScopeIds)
          );

        SELECT @TotalCount = COUNT(1) FROM #Filtered;

        SELECT
            Id,
            DonViId,
            ActiveDate,
            IsActive,
            Created,
            CreatedBy,
            Modified,
            ModifiedBy
        FROM #Filtered
        ORDER BY ActiveDate DESC, DonViId, Id
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_GetById
        @Id INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT TOP (1)
            s.Id,
            s.DonViId,
            s.ActiveDate,
            s.IsActive,
            s.Created,
            s.CreatedBy,
            s.Modified,
            s.ModifiedBy
        FROM dbo.StationPrices AS s
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE s.Id = @Id;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_Update
        @Id INT,
        @ActiveDate DATETIME,
        @IsActive BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationPrices AS s
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE s.Id = @Id)
        BEGIN
            RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

        UPDATE dbo.StationPrices
        SET
            ActiveDate = @ActiveDate,
            IsActive = @IsActive,
            Modified = @Now,
            ModifiedBy = @Actor50
        WHERE Id = @Id;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419165629_StorePriceHubStationPricesBoards'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419165629_StorePriceHubStationPricesBoards', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419170701_StorePriceBoardEditorBundle'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_GetBoardEditor
        @StationPricesId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT s.Id AS StationPricesId, s.DonViId, s.ActiveDate, s.IsActive
        FROM dbo.StationPrices AS s
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE s.Id = @StationPricesId;

        SELECT p.Id AS LineId, p.ProductId, p.Price, p.UnitId, p.Note
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE p.StationPricesId = @StationPricesId
        ORDER BY p.ProductId;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419170701_StorePriceBoardEditorBundle'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_UpdateBoardEditor
        @StationPricesId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationPrices AS s
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE s.Id = @StationPricesId)
        BEGIN
            RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        DECLARE @DonViId INT =
            (SELECT s.DonViId FROM dbo.StationPrices AS s WHERE s.Id = @StationPricesId);

        CREATE TABLE #Rows (
            LineId INT NOT NULL,
            ProductId INT NOT NULL,
            Price DECIMAL(18, 2) NOT NULL,
            UnitId INT NULL,
            Note NVARCHAR(500) NULL
        );

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (LineId, ProductId, Price, UnitId, Note)
        SELECT
            T.c.value('@id', 'INT'),
            T.c.value('@productId', 'INT'),
            T.c.value('@price', 'DECIMAL(18,2)'),
            T.c.value('@unitId', 'INT'),
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        DECLARE @Expected INT =
            (SELECT COUNT(1) FROM dbo.StationProductPrices WHERE StationPricesId = @StationPricesId);

        IF (SELECT COUNT(1) FROM #Rows) <> @Expected
        BEGIN
            RAISERROR(N'Row count must match existing lines for this price board.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows AS r
            LEFT JOIN dbo.StationProductPrices AS p ON p.Id = r.LineId AND p.StationPricesId = @StationPricesId
            WHERE p.Id IS NULL)
        BEGIN
            RAISERROR(N'One or more line ids are invalid for this board.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL OR LineId IS NULL)
        BEGIN
            RAISERROR(N'Each row must have id, productId and price.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND IsCurrent = 1 AND StationPricesId <> @StationPricesId;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
            END;

            UPDATE dbo.StationPrices
            SET
                ActiveDate = @EffectiveDate,
                IsActive = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor50
            WHERE Id = @StationPricesId;

            UPDATE p
            SET
                ProductId = r.ProductId,
                Price = r.Price,
                UnitId = r.UnitId,
                Note = r.Note,
                EffectiveDate = @EffectiveDate,
                IsCurrent = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor
            FROM dbo.StationProductPrices AS p
            INNER JOIN #Rows AS r ON r.LineId = p.Id
            WHERE p.StationPricesId = @StationPricesId;

            IF @@ROWCOUNT <> @Expected
            BEGIN
                RAISERROR(N'Line update count mismatch.', 16, 1);
            END;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419170701_StorePriceBoardEditorBundle'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419170701_StorePriceBoardEditorBundle', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419172411_StorePriceBoardDeleteAndHistoryOrder'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT,
        @ProductId INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            p.Id,
            p.DonViId,
            p.ProductId,
            p.Price,
            p.UnitId,
            p.EffectiveDate,
            p.IsCurrent,
            p.Note,
            p.StationPricesId
        FROM dbo.StationProductPrices AS p
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
        INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
        WHERE p.DonViId = @DonViId
          AND (@ProductId IS NULL OR p.ProductId = @ProductId)
        ORDER BY s.ActiveDate DESC, p.ProductId, p.Id;
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419172411_StorePriceBoardDeleteAndHistoryOrder'
)
BEGIN

    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_Delete
        @Id INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        DELETE s
        FROM dbo.StationPrices AS s
        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
        WHERE s.Id = @Id;

        IF @@ROWCOUNT = 0
            RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
    END;

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419172411_StorePriceBoardDeleteAndHistoryOrder'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419172411_StorePriceBoardDeleteAndHistoryOrder', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Insert
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @NewId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @NewId = NULL;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

    DECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        DECLARE @HeaderId TABLE (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1;
            END;

            INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
            OUTPUT INSERTED.Id INTO @HeaderId
            VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

            DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderId);

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy,
                StationPricesId)
            VALUES (
                @DonViId,
                @ProductId,
                @Price,
                @UnitId,
                @EffectiveDate,
                @IsCurrent,
                @Note,
                @Now,
                @Actor,
                @Now,
                @Actor,
                @StationPricesId);

            SET @NewId = CAST(SCOPE_IDENTITY() AS INT);
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Update
        @Id INT,
        @DonViId INT,
        @ProductId INT,
        @Price DECIMAL(18, 2),
        @UnitId INT = NULL,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Note NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationProductPrices AS p
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE p.Id = @Id)
        BEGIN
            RAISERROR(N'Price row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
        BEGIN
            RAISERROR(N'ProductId does not exist.', 16, 1);
            RETURN;
        END;

        IF @Price < 0
        BEGIN
            RAISERROR(N'Price must be >= 0.', 16, 1);
            RETURN;
        END;

    DECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        DECLARE @StationPricesId INT =
            (SELECT p.StationPricesId FROM dbo.StationProductPrices AS p WHERE p.Id = @Id);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1 AND Id <> @Id;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
            END;

            UPDATE dbo.StationProductPrices
            SET
                DonViId = @DonViId,
                ProductId = @ProductId,
                Price = @Price,
                UnitId = @UnitId,
                EffectiveDate = @EffectiveDate,
                IsCurrent = @IsCurrent,
                Note = @Note,
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @Id;

            UPDATE dbo.StationPrices
            SET
                ActiveDate = @EffectiveDate,
                IsActive = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor50
            WHERE Id = @StationPricesId;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_BatchInsert
        @DonViId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Price DECIMAL(18, 2) NOT NULL,
            UnitId INT NULL,
            Note NVARCHAR(500) NULL
        );

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Price, UnitId, Note)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@price', 'DECIMAL(18,2)'),
            T.c.value('@unitId', 'INT'),
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and price.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

    DECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
        CREATE TABLE #CreatedIds (Id INT NOT NULL);
        DECLARE @HeaderIds TABLE (Id INT NOT NULL);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                FROM dbo.StationProductPrices AS p
                INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1;
            END;

            INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
            OUTPUT INSERTED.Id INTO @HeaderIds
            VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

            DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderIds);

            INSERT INTO dbo.StationProductPrices (
                DonViId,
                ProductId,
                Price,
                UnitId,
                EffectiveDate,
                IsCurrent,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy,
                StationPricesId)
            OUTPUT INSERTED.Id INTO #CreatedIds (Id)
            SELECT
                @DonViId,
                r.ProductId,
                r.Price,
                r.UnitId,
                @EffectiveDate,
                @IsCurrent,
                r.Note,
                @Now,
                @Actor,
                @Now,
                @Actor,
                @StationPricesId
            FROM #Rows AS r
            ORDER BY r.ProductId;

            SELECT @StationPricesId AS StationPricesId;
            SELECT Id FROM #CreatedIds ORDER BY Id;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_Update
        @Id INT,
        @ActiveDate DATETIME,
        @IsActive BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationPrices AS s
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE s.Id = @Id)
        BEGIN
            RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

    DECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

        UPDATE dbo.StationPrices
        SET
            ActiveDate = @ActiveDate,
            IsActive = @IsActive,
            Modified = @Now,
            ModifiedBy = @Actor50
        WHERE Id = @Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_UpdateBoardEditor
        @StationPricesId INT,
        @EffectiveDate DATETIME,
        @IsCurrent BIT,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationPrices AS s
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
            WHERE s.Id = @StationPricesId)
        BEGIN
            RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
            RETURN;
        END;

        DECLARE @DonViId INT =
            (SELECT s.DonViId FROM dbo.StationPrices AS s WHERE s.Id = @StationPricesId);

        CREATE TABLE #Rows (
            LineId INT NOT NULL,
            ProductId INT NOT NULL,
            Price DECIMAL(18, 2) NOT NULL,
            UnitId INT NULL,
            Note NVARCHAR(500) NULL
        );

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (LineId, ProductId, Price, UnitId, Note)
        SELECT
            T.c.value('@id', 'INT'),
            T.c.value('@productId', 'INT'),
            T.c.value('@price', 'DECIMAL(18,2)'),
            T.c.value('@unitId', 'INT'),
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        DECLARE @Expected INT =
            (SELECT COUNT(1) FROM dbo.StationProductPrices WHERE StationPricesId = @StationPricesId);

        IF (SELECT COUNT(1) FROM #Rows) <> @Expected
        BEGIN
            RAISERROR(N'Row count must match existing lines for this price board.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows AS r
            LEFT JOIN dbo.StationProductPrices AS p ON p.Id = r.LineId AND p.StationPricesId = @StationPricesId
            WHERE p.Id IS NULL)
        BEGIN
            RAISERROR(N'One or more line ids are invalid for this board.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL OR LineId IS NULL)
        BEGIN
            RAISERROR(N'Each row must have id, productId and price.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
        BEGIN
            RAISERROR(N'Each price must be >= 0.', 16, 1);
            RETURN;
        END;

    DECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

        BEGIN TRANSACTION;
        BEGIN TRY
            IF @IsCurrent = 1
            BEGIN
                UPDATE dbo.StationProductPrices
                SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                WHERE DonViId = @DonViId AND IsCurrent = 1 AND StationPricesId <> @StationPricesId;

                UPDATE dbo.StationPrices
                SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
            END;

            UPDATE dbo.StationPrices
            SET
                ActiveDate = @EffectiveDate,
                IsActive = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor50
            WHERE Id = @StationPricesId;

            UPDATE p
            SET
                ProductId = r.ProductId,
                Price = r.Price,
                UnitId = r.UnitId,
                Note = r.Note,
                EffectiveDate = @EffectiveDate,
                IsCurrent = @IsCurrent,
                Modified = @Now,
                ModifiedBy = @Actor
            FROM dbo.StationProductPrices AS p
            INNER JOIN #Rows AS r ON r.LineId = p.Id
            WHERE p.StationPricesId = @StationPricesId;

            IF @@ROWCOUNT <> @Expected
            BEGIN
                RAISERROR(N'Line update count mismatch.', 16, 1);
            END;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419174252_FixStorePricesVnWallClock'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419174252_FixStorePricesVnWallClock', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE TABLE [StationInventoryTransactionHeaders] (
        [Id] int NOT NULL IDENTITY,
        [DonViId] int NOT NULL,
        [TransactionType] int NOT NULL,
        [TransactionDate] datetime NOT NULL,
        [Note] nvarchar(500) NULL,
        [Created] datetime NOT NULL,
        [CreatedBy] nvarchar(100) NULL,
        [Modified] datetime NOT NULL,
        [ModifiedBy] nvarchar(100) NULL,
        CONSTRAINT [PK_StationInventoryTransactionHeaders] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE TABLE [StationInventoryTransactionDetails] (
        [Id] int NOT NULL IDENTITY,
        [HeaderId] int NOT NULL,
        [ProductId] int NOT NULL,
        [Quantity] decimal(18,3) NOT NULL,
        [Amount] decimal(18,2) NULL,
        [Note] nvarchar(500) NULL,
        CONSTRAINT [PK_StationInventoryTransactionDetails] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_StationInventoryTransactionDetails_FuelProducts_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [FuelProducts] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_StationInventoryTransactionDetails_StationInventoryTransactionHeaders_HeaderId] FOREIGN KEY ([HeaderId]) REFERENCES [StationInventoryTransactionHeaders] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE INDEX [IX_StationInventoryTransactionDetails_HeaderId] ON [StationInventoryTransactionDetails] ([HeaderId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE INDEX [IX_StationInventoryTransactionDetails_ProductId] ON [StationInventoryTransactionDetails] ([ProductId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.StationInventoryTransactions', N'U'))
       AND EXISTS (SELECT 1 FROM dbo.StationInventoryTransactions)
    BEGIN
        INSERT INTO dbo.StationInventoryTransactionHeaders (
            DonViId,
            TransactionType,
            TransactionDate,
            Note,
            Created,
            CreatedBy,
            Modified,
            ModifiedBy)
        SELECT DISTINCT
            t.DonViId,
            t.TransactionType,
            t.TransactionDate,
            t.Note,
            t.Created,
            t.CreatedBy,
            t.Modified,
            t.ModifiedBy
        FROM dbo.StationInventoryTransactions AS t;

        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
        SELECT
            h.Id,
            t.ProductId,
            t.Quantity,
            t.Amount,
            CAST(NULL AS NVARCHAR(500))
        FROM dbo.StationInventoryTransactions AS t
        INNER JOIN dbo.StationInventoryTransactionHeaders AS h
            ON h.DonViId = t.DonViId
           AND h.TransactionType = t.TransactionType
           AND h.TransactionDate = t.TransactionDate
           AND ((h.Note IS NULL AND t.Note IS NULL) OR (h.Note = t.Note))
           AND h.Created = t.Created
           AND ((h.CreatedBy IS NULL AND t.CreatedBy IS NULL) OR (h.CreatedBy = t.CreatedBy))
           AND h.Modified = t.Modified
           AND ((h.ModifiedBy IS NULL AND t.ModifiedBy IS NULL) OR (h.ModifiedBy = t.ModifiedBy));

        TRUNCATE TABLE dbo.StationInventoryTransactions;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX),
        @HeaderId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @HeaderId = NULL;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Quantity <= 0)
        BEGIN
            RAISERROR(N'Each quantity must be > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            INSERT INTO dbo.StationInventoryTransactionHeaders (
                DonViId,
                TransactionType,
                TransactionDate,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            VALUES (
                @DonViId,
                @TransactionType,
                @TransactionDate,
                NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                @Now,
                @Actor,
                @Now,
                @Actor);

            SET @HeaderId = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
        @HeaderId INT,
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL OR Quantity <= 0)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId FROM #Rows r GROUP BY r.ProductId HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            DELETE d
            FROM dbo.StationInventoryTransactionDetails d
            WHERE d.HeaderId = @HeaderId;

            UPDATE dbo.StationInventoryTransactionHeaders
            SET DonViId = @DonViId,
                TransactionType = @TransactionType,
                TransactionDate = @TransactionDate,
                Note = NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @HeaderId;

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @TransactionType INT = NULL,
        @TransactionDateFrom DATETIME = NULL,
        @TransactionDateTo DATETIME = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #H (
            Id INT NOT NULL PRIMARY KEY,
            DonViId INT NOT NULL,
            TransactionType INT NOT NULL,
            TransactionDate DATETIME NOT NULL,
            Note NVARCHAR(500) NULL,
            Created DATETIME NOT NULL,
            CreatedBy NVARCHAR(100) NULL,
            Modified DATETIME NOT NULL,
            ModifiedBy NVARCHAR(100) NULL,
            LineCount INT NOT NULL);

        INSERT INTO #H (
            Id,
            DonViId,
            TransactionType,
            TransactionDate,
            Note,
            Created,
            CreatedBy,
            Modified,
            ModifiedBy,
            LineCount)
        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy,
            LineCount = (
                SELECT COUNT(1)
                FROM dbo.StationInventoryTransactionDetails d0
                WHERE d0.HeaderId = h.Id)
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
          AND (@TransactionType IS NULL OR h.TransactionType = @TransactionType)
          AND (@TransactionDateFrom IS NULL OR h.TransactionDate >= @TransactionDateFrom)
          AND (@TransactionDateTo IS NULL OR h.TransactionDate <= @TransactionDateTo)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR h.DonViId IN (SELECT Id FROM @ScopeIds))
          AND (
              @ProductId IS NULL
              OR EXISTS (
                  SELECT 1
                  FROM dbo.StationInventoryTransactionDetails d
                  WHERE d.HeaderId = h.Id AND d.ProductId = @ProductId));

        SELECT @TotalCount = COUNT(1) FROM #H;

        SELECT
            Id,
            DonViId,
            TransactionType,
            TransactionDate,
            Note,
            LineCount,
            Created,
            CreatedBy,
            Modified,
            ModifiedBy
        FROM #H
        ORDER BY TransactionDate DESC, Id DESC
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT,
        @ProductId INT = NULL,
        @TransactionType INT = NULL,
        @TransactionDateFrom DATETIME = NULL,
        @TransactionDateTo DATETIME = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            LineCount = (
                SELECT COUNT(1)
                FROM dbo.StationInventoryTransactionDetails d0
                WHERE d0.HeaderId = h.Id),
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE h.DonViId = @DonViId
          AND (@ProductId IS NULL OR EXISTS (
              SELECT 1 FROM dbo.StationInventoryTransactionDetails d
              WHERE d.HeaderId = h.Id AND d.ProductId = @ProductId))
          AND (@TransactionType IS NULL OR h.TransactionType = @TransactionType)
          AND (@TransactionDateFrom IS NULL OR h.TransactionDate >= @TransactionDateFrom)
          AND (@TransactionDateTo IS NULL OR h.TransactionDate <= @TransactionDateTo)
        ORDER BY h.TransactionDate DESC, h.Id DESC;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetById
        @HeaderId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE h.Id = @HeaderId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId
        @HeaderId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RETURN;
        END;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        WHERE d.HeaderId = @HeaderId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest
        @DonViId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        DECLARE @HId INT = NULL;

        SELECT TOP (1) @HId = h.Id
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR h.DonViId IN (SELECT Id FROM @ScopeIds))
        ORDER BY h.TransactionDate DESC, h.Id DESC;

        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy
        FROM dbo.StationInventoryTransactionHeaders h
        WHERE @HId IS NOT NULL AND h.Id = @HId;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        WHERE @HId IS NOT NULL AND d.HeaderId = @HId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT h.DonViId, d.ProductId, d.Quantity, h.TransactionType, h.TransactionDate
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
              AND (@ProductId IS NULL OR d.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR h.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        ;WITH FilteredTx AS (
            SELECT h.DonViId, d.ProductId, d.Quantity, h.TransactionType, h.TransactionDate
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.DonViId = @DonViId
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(fp.UnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg
        ORDER BY ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419181209_StationInventoryTransactionHeadersAndDetails'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419181209_StationInventoryTransactionHeadersAndDetails', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    ALTER TABLE [StationInventoryTransactionDetails] ADD [UnitId] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    DECLARE @Liter INT = (
        SELECT TOP (1) [Id]
        FROM [dbo].[DM_DonViTinh]
        WHERE UPPER(LTRIM(RTRIM(ISNULL([Ma], N'')))) IN (N'LIT', N'L', N'LITRE')
           OR LTRIM(RTRIM(ISNULL([Ten], N''))) IN (N'Lít', N'Lit')
        ORDER BY [Id]);
    IF @Liter IS NULL
        SELECT TOP (1) @Liter = [Id] FROM [dbo].[DM_DonViTinh] ORDER BY [Id];
    IF @Liter IS NULL
        THROW 50001, N'DM_DonViTinh is empty; cannot backfill UnitId.', 1;

    UPDATE d
    SET d.UnitId = COALESCE(fp.UnitId, @Liter)
    FROM dbo.StationInventoryTransactionDetails AS d
    INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
    WHERE d.UnitId IS NULL;

    UPDATE dbo.StationInventoryTransactionDetails SET UnitId = @Liter WHERE UnitId IS NULL;

    ALTER TABLE dbo.StationInventoryTransactionDetails ALTER COLUMN UnitId INT NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE INDEX [IX_StationInventoryTransactionDetails_UnitId] ON [StationInventoryTransactionDetails] ([UnitId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    ALTER TABLE [StationInventoryTransactionDetails] ADD CONSTRAINT [FK_StationInventoryTransactionDetails_DM_DonViTinh_UnitId] FOREIGN KEY ([UnitId]) REFERENCES [DM_DonViTinh] ([Id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX),
        @HeaderId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @HeaderId = NULL;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        DECLARE @DefaultUnitId INT = (
            SELECT TOP (1) [Id]
            FROM [dbo].[DM_DonViTinh]
            WHERE UPPER(LTRIM(RTRIM(ISNULL([Ma], N'')))) IN (N'LIT', N'L', N'LITRE')
               OR LTRIM(RTRIM(ISNULL([Ten], N''))) IN (N'Lít', N'Lit')
            ORDER BY [Id]);
        IF @DefaultUnitId IS NULL
            SELECT TOP (1) @DefaultUnitId = [Id] FROM [dbo].[DM_DonViTinh] ORDER BY [Id];
        IF @DefaultUnitId IS NULL
        BEGIN
            RAISERROR(N'DM_DonViTinh has no rows; cannot resolve default unit.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            COALESCE(
                NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                (SELECT fp.UnitId FROM dbo.FuelProducts fp WHERE fp.Id = T.c.value('@productId', 'INT')),
                @DefaultUnitId)
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Quantity <= 0)
        BEGIN
            RAISERROR(N'Each quantity must be > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            INSERT INTO dbo.StationInventoryTransactionHeaders (
                DonViId,
                TransactionType,
                TransactionDate,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            VALUES (
                @DonViId,
                @TransactionType,
                @TransactionDate,
                NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                @Now,
                @Actor,
                @Now,
                @Actor);

            SET @HeaderId = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
        @HeaderId INT,
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        DECLARE @DefaultUnitId INT = (
            SELECT TOP (1) [Id]
            FROM [dbo].[DM_DonViTinh]
            WHERE UPPER(LTRIM(RTRIM(ISNULL([Ma], N'')))) IN (N'LIT', N'L', N'LITRE')
               OR LTRIM(RTRIM(ISNULL([Ten], N''))) IN (N'Lít', N'Lit')
            ORDER BY [Id]);
        IF @DefaultUnitId IS NULL
            SELECT TOP (1) @DefaultUnitId = [Id] FROM [dbo].[DM_DonViTinh] ORDER BY [Id];
        IF @DefaultUnitId IS NULL
        BEGIN
            RAISERROR(N'DM_DonViTinh has no rows; cannot resolve default unit.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            COALESCE(
                NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                (SELECT fp.UnitId FROM dbo.FuelProducts fp WHERE fp.Id = T.c.value('@productId', 'INT')),
                @DefaultUnitId)
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL OR Quantity <= 0)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId FROM #Rows r GROUP BY r.ProductId HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            DELETE d
            FROM dbo.StationInventoryTransactionDetails d
            WHERE d.HeaderId = @HeaderId;

            UPDATE dbo.StationInventoryTransactionHeaders
            SET DonViId = @DonViId,
                TransactionType = @TransactionType,
                TransactionDate = @TransactionDate,
                Note = NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @HeaderId;

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId
        @HeaderId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RETURN;
        END;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.UnitId,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        WHERE d.HeaderId = @HeaderId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest
        @DonViId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        DECLARE @HId INT = NULL;

        SELECT TOP (1) @HId = h.Id
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR h.DonViId IN (SELECT Id FROM @ScopeIds))
        ORDER BY h.TransactionDate DESC, h.Id DESC;

        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy
        FROM dbo.StationInventoryTransactionHeaders h
        WHERE @HId IS NOT NULL AND h.Id = @HId;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.UnitId,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        WHERE @HId IS NOT NULL AND d.HeaderId = @HId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                d.Quantity,
                h.TransactionType,
                h.TransactionDate,
                ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId)
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
              AND (@ProductId IS NULL OR d.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR h.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(ft.ResolvedUnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        ;WITH FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                d.Quantity,
                h.TransactionType,
                h.TransactionDate,
                ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId)
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.DonViId = @DonViId
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(ft.ResolvedUnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg
        ORDER BY ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419190855_StationInventoryTransactionDetailsUnitId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419190855_StationInventoryTransactionDetailsUnitId', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_DM_DonViTinh_Exists
        @UnitId INT
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @UnitId IS NULL OR @UnitId < 1
            SELECT CAST(0 AS BIT);
        ELSE
            SELECT CAST(
                CASE WHEN EXISTS (SELECT 1 FROM dbo.DM_DonViTinh AS u WHERE u.Id = @UnitId) THEN 1 ELSE 0 END
                AS BIT);
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProduct_UnitById
        @ProductId INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT fp.UnitId
        FROM dbo.FuelProducts AS fp
        WHERE fp.Id = @ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX),
        @HeaderId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @HeaderId = NULL;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
        BEGIN
            RAISERROR(N'Each row must include a valid unitId attribute.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Quantity <= 0)
        BEGIN
            RAISERROR(N'Each quantity must be > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            INSERT INTO dbo.StationInventoryTransactionHeaders (
                DonViId,
                TransactionType,
                TransactionDate,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            VALUES (
                @DonViId,
                @TransactionType,
                @TransactionDate,
                NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                @Now,
                @Actor,
                @Now,
                @Actor);

            SET @HeaderId = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
        @HeaderId INT,
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
        BEGIN
            RAISERROR(N'Each row must include a valid unitId attribute.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL OR Quantity <= 0)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId FROM #Rows r GROUP BY r.ProductId HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            DELETE d
            FROM dbo.StationInventoryTransactionDetails d
            WHERE d.HeaderId = @HeaderId;

            UPDATE dbo.StationInventoryTransactionHeaders
            SET DonViId = @DonViId,
                TransactionType = @TransactionType,
                TransactionDate = @TransactionDate,
                Note = NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @HeaderId;

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId
        @HeaderId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RETURN;
        END;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.UnitId,
            u.Ten AS UnitName,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        LEFT JOIN dbo.DM_DonViTinh u ON u.Id = d.UnitId
        WHERE d.HeaderId = @HeaderId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest
        @DonViId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        DECLARE @HId INT = NULL;

        SELECT TOP (1) @HId = h.Id
        FROM dbo.StationInventoryTransactionHeaders h
        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
          AND (
              @DonViScopeCsv IS NULL
              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
              OR h.DonViId IN (SELECT Id FROM @ScopeIds))
        ORDER BY h.TransactionDate DESC, h.Id DESC;

        SELECT
            h.Id,
            h.DonViId,
            h.TransactionType,
            h.TransactionDate,
            h.Note,
            h.Created,
            h.CreatedBy,
            h.Modified,
            h.ModifiedBy
        FROM dbo.StationInventoryTransactionHeaders h
        WHERE @HId IS NOT NULL AND h.Id = @HId;

        SELECT
            d.Id,
            d.HeaderId,
            d.ProductId,
            d.UnitId,
            u.Ten AS UnitName,
            d.Quantity,
            d.Amount,
            d.Note
        FROM dbo.StationInventoryTransactionDetails d
        LEFT JOIN dbo.DM_DonViTinh u ON u.Id = d.UnitId
        WHERE @HId IS NOT NULL AND d.HeaderId = @HId
        ORDER BY d.Id;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419191922_InventoryTransactionDetailsRequireUnitIdXmlAndUnitName', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX),
        @DefaultDetailUnitId INT = NULL,
        @HeaderId INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @HeaderId = NULL;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF @DefaultDetailUnitId IS NOT NULL
           AND (
               @DefaultDetailUnitId < 1
               OR NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh AS u WHERE u.Id = @DefaultDetailUnitId))
        BEGIN
            RAISERROR(N'DefaultDetailUnitId must be NULL or a valid DM_DonViTinh id.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            COALESCE(
                NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                NULLIF(@DefaultDetailUnitId, 0))
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
        BEGIN
            RAISERROR(N'Each row must include a valid unitId attribute (or pass @DefaultDetailUnitId).', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Quantity <= 0)
        BEGIN
            RAISERROR(N'Each quantity must be > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId
            FROM #Rows r
            GROUP BY r.ProductId
            HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            INSERT INTO dbo.StationInventoryTransactionHeaders (
                DonViId,
                TransactionType,
                TransactionDate,
                Note,
                Created,
                CreatedBy,
                Modified,
                ModifiedBy)
            VALUES (
                @DonViId,
                @TransactionType,
                @TransactionDate,
                NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                @Now,
                @Actor,
                @Now,
                @Actor);

            SET @HeaderId = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
        @HeaderId INT,
        @DonViId INT,
        @TransactionType INT,
        @TransactionDate DATETIME,
        @HeaderNote NVARCHAR(500) = NULL,
        @Actor NVARCHAR(100),
        @RetailCapDonViId INT,
        @RowsXml NVARCHAR(MAX),
        @DefaultDetailUnitId INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
        BEGIN
            RAISERROR(N'Rows payload is required.', 16, 1);
            RETURN;
        END;

        IF @TransactionType NOT IN (1, -1)
        BEGIN
            RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.StationInventoryTransactionHeaders h
            INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.Id = @HeaderId)
        BEGIN
            RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
        BEGIN
            RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
            RETURN;
        END;

        IF @DefaultDetailUnitId IS NOT NULL
           AND (
               @DefaultDetailUnitId < 1
               OR NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh AS u WHERE u.Id = @DefaultDetailUnitId))
        BEGIN
            RAISERROR(N'DefaultDetailUnitId must be NULL or a valid DM_DonViTinh id.', 16, 1);
            RETURN;
        END;

        CREATE TABLE #Rows (
            ProductId INT NOT NULL,
            Quantity DECIMAL(18, 3) NOT NULL,
            Amount DECIMAL(18, 2) NULL,
            Note NVARCHAR(500) NULL,
            UnitId INT NOT NULL);

        DECLARE @x XML;
        BEGIN TRY
            SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
        END TRY
        BEGIN CATCH
            RAISERROR(N'Rows payload is not valid XML.', 16, 1);
            RETURN;
        END CATCH;

        INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
        SELECT
            T.c.value('@productId', 'INT'),
            T.c.value('@quantity', 'DECIMAL(18,3)'),
            CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
            NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
            COALESCE(
                NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                NULLIF(@DefaultDetailUnitId, 0))
        FROM @x.nodes('/rows/r') AS T(c);

        IF NOT EXISTS (SELECT 1 FROM #Rows)
        BEGIN
            RAISERROR(N'No valid rows in payload.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
        BEGIN
            RAISERROR(N'Each row must include a valid unitId attribute (or pass @DefaultDetailUnitId).', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL OR Quantity <= 0)
        BEGIN
            RAISERROR(N'Each row must have productId and quantity > 0.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
        BEGIN
            RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT r.ProductId FROM #Rows r GROUP BY r.ProductId HAVING COUNT(1) > 1)
        BEGIN
            RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
        BEGIN
            RAISERROR(N'One or more productId values do not exist.', 16, 1);
            RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM #Rows r
            WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
        BEGIN
            RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
            RETURN;
        END;

        DECLARE @Now DATETIME = SYSUTCDATETIME();

        BEGIN TRANSACTION;
        BEGIN TRY
            DELETE d
            FROM dbo.StationInventoryTransactionDetails d
            WHERE d.HeaderId = @HeaderId;

            UPDATE dbo.StationInventoryTransactionHeaders
            SET DonViId = @DonViId,
                TransactionType = @TransactionType,
                TransactionDate = @TransactionDate,
                Note = NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                Modified = @Now,
                ModifiedBy = @Actor
            WHERE Id = @HeaderId;

            INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
            SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
            FROM #Rows r;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
        @Skip INT,
        @Take INT,
        @DonViId INT = NULL,
        @ProductId INT = NULL,
        @DonViScopeCsv NVARCHAR(MAX) = NULL,
        @RetailCapDonViId INT,
        @TotalCount INT OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

        IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
        BEGIN
            DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
            DECLARE @comma INT;
            DECLARE @piece NVARCHAR(50);

            WHILE LEN(@rest) > 0
            BEGIN
                SET @comma = CHARINDEX(N',', @rest);
                IF @comma = 0
                BEGIN
                    SET @piece = @rest;
                    SET @rest = N'';
                END
                ELSE
                BEGIN
                    SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                    SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                END;

                IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                        INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                END;
            END;
        END;

        CREATE TABLE #Agg (
            DonViId INT NOT NULL,
            ProductId INT NOT NULL,
            CurrentQuantity DECIMAL(18, 4) NOT NULL,
            ProductCode NVARCHAR(4000) NOT NULL,
            ProductName NVARCHAR(4000) NOT NULL,
            UnitId INT NULL,
            UnitMa NVARCHAR(4000) NULL,
            UnitTen NVARCHAR(4000) NULL,
            LastTransactionDate DATETIME2(3) NOT NULL
        );

        ;WITH FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                h.TransactionType,
                h.TransactionDate,
                DetailUnitId = d.UnitId,
                ProductCatalogUnitId = fp.UnitId,
                ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId),
                -- Demo: assume line quantity is already in one comparable base (no cross-unit conversion).
                -- Future: multiply by dbo.fn_StoreAdmin_InventoryLineQtyToProductBase(d.ProductId, d.UnitId, fp.UnitId) when units differ.
                QuantityForStock = CAST(d.Quantity AS DECIMAL(18, 4))
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
              AND (@ProductId IS NULL OR d.ProductId = @ProductId)
              AND (
                  @DonViScopeCsv IS NULL
                  OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                  OR h.DonViId IN (SELECT Id FROM @ScopeIds)
              )
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(ft.ResolvedUnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        INSERT INTO #Agg (
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate)
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg;

        SELECT @TotalCount = COUNT(1) FROM #Agg;

        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM #Agg
        ORDER BY DonViId, ProductId
        OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
        @DonViId INT,
        @RetailCapDonViId INT
    AS
    BEGIN
        SET NOCOUNT ON;

        ;WITH FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                h.TransactionType,
                h.TransactionDate,
                DetailUnitId = d.UnitId,
                ProductCatalogUnitId = fp.UnitId,
                ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId),
                QuantityForStock = CAST(d.Quantity AS DECIMAL(18, 4))
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            WHERE h.DonViId = @DonViId
        ),
        Agg AS (
            SELECT
                ft.DonViId,
                ft.ProductId,
                CurrentQuantity = SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                ProductCode = MAX(ISNULL(fp.Code, N'')),
                ProductName = MAX(ISNULL(fp.Name, N'')),
                UnitId = MAX(ft.ResolvedUnitId),
                UnitMa = MAX(u.Ma),
                UnitTen = MAX(u.Ten),
                LastTransactionDate = MAX(ft.TransactionDate)
            FROM FilteredTx AS ft
            INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
            LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
            GROUP BY ft.DonViId, ft.ProductId
        )
        SELECT
            DonViId,
            ProductId,
            CurrentQuantity,
            ProductCode,
            ProductName,
            UnitId,
            UnitMa,
            UnitTen,
            LastTransactionDate
        FROM Agg
        ORDER BY ProductId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260419192716_InventorySpDefaultDetailUnitIdAndStockQuantityBase', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420025012_AddDemoDataStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_ClearData
        @Tinh INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        SET NOCOUNT ON;

        DELETE h
        FROM dbo.StationInventoryTransactionHeaders AS h
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
        WHERE h.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;

        DELETE sp
        FROM dbo.StationPrices AS sp
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
        WHERE sp.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420025012_AddDemoDataStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_GeneratePrices
        @Tinh INT,
        @ClearOldData BIT,
        @DaysBack INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @DaysBack < 1 SET @DaysBack = 1;
        IF @DaysBack > 400 SET @DaysBack = 400;

        IF @ClearOldData = 1
        BEGIN
            DELETE sp
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;

        IF OBJECT_ID(N'tempdb..#DemoPriceProducts', N'U') IS NOT NULL
            DROP TABLE #DemoPriceProducts;

        ;WITH Grp AS (
            SELECT g.Id, UPPER(LTRIM(RTRIM(g.Code))) AS CodeNorm
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
        ),
        DownTree AS (
            SELECT fp.Id, fp.Code, fp.Name, fp.UnitId, g.CodeNorm AS RootCode
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS g ON fp.ParentId = g.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.Code, c.Name, c.UnitId, d.RootCode
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        Leaf AS (
            SELECT d.Id AS ProductId, d.Code, d.Name, d.UnitId, d.RootCode
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
              AND d.UnitId IS NOT NULL
        )
        SELECT
            l.ProductId,
            l.UnitId,
            CAST(
                CASE
                    WHEN UPPER(l.Name) LIKE N'%RON%95%'
                         OR UPPER(l.Code) LIKE N'%RON95%'
                        THEN 1
                    WHEN UPPER(l.Name) LIKE N'%E5%'
                         OR UPPER(l.Code) LIKE N'%E5%'
                         OR UPPER(l.Name) LIKE N'%A92%'
                        THEN 2
                    WHEN UPPER(l.Name) LIKE N'%DIESEL%'
                         OR UPPER(l.Code) LIKE N'%DIESEL%'
                         OR UPPER(l.Name) LIKE N'%DO 0%'
                         OR UPPER(l.Name) LIKE N'%DẦU%'
                        THEN 3
                    WHEN l.RootCode = N'DAU' THEN 3
                    ELSE 2
                END AS TINYINT) AS PriceBand
        INTO #DemoPriceProducts
        FROM Leaf AS l;

        DECLARE @d INT = 0;
        DECLARE @day DATE;
        DECLARE @donViId INT;
        DECLARE @spId INT;
        DECLARE @isCurrent BIT;

        WHILE @d < @DaysBack
        BEGIN
            SET @day = DATEADD(DAY, -@d, CAST(SYSDATETIME() AS DATE));
            SET @isCurrent = CASE WHEN @d = 0 THEN 1 ELSE 0 END;

            DECLARE c CURSOR LOCAL FAST_FORWARD FOR
                SELECT dv.Id
                FROM dbo.DM_DonVi AS dv
                WHERE dv.CapDonViId = @RetailCapDonViId
                  AND dv.Tinh = @Tinh
                ORDER BY dv.Id;

            OPEN c;
            FETCH NEXT FROM c INTO @donViId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
                VALUES (@donViId, @day, 0, SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                SET @spId = SCOPE_IDENTITY();

                INSERT INTO dbo.StationProductPrices (
                    StationPricesId,
                    DonViId,
                    ProductId,
                    Price,
                    UnitId,
                    EffectiveDate,
                    IsCurrent,
                    Note,
                    Created,
                    CreatedBy,
                    Modified,
                    ModifiedBy)
                SELECT
                    @spId,
                    @donViId,
                    p.ProductId,
                    CAST(
                        CASE p.PriceBand
                            WHEN 1 THEN
                                23800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#1')) % 601)
                            WHEN 2 THEN
                                22800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#2')) % 701)
                            WHEN 3 THEN
                                31700 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#3')) % 801)
                            ELSE
                                22800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#0')) % 701)
                        END AS DECIMAL(18, 2)),
                    p.UnitId,
                    @day,
                    @isCurrent,
                    N'Demo generated',
                    SYSDATETIME(),
                    N'sys_demo',
                    SYSDATETIME(),
                    N'sys_demo'
                FROM #DemoPriceProducts AS p;

                FETCH NEXT FROM c INTO @donViId;
            END;

            CLOSE c;
            DEALLOCATE c;

            SET @d += 1;
        END;

        DROP TABLE #DemoPriceProducts;

        ;WITH mx AS (
            SELECT sp.DonViId, MAX(sp.ActiveDate) AS MaxD
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId
            GROUP BY sp.DonViId
        )
        UPDATE sp
        SET IsActive = CASE WHEN sp.ActiveDate = mx.MaxD THEN 1 ELSE 0 END,
            Modified = SYSDATETIME(),
            ModifiedBy = N'sys_demo'
        FROM dbo.StationPrices AS sp
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
        INNER JOIN mx ON mx.DonViId = sp.DonViId
        WHERE sp.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;

        ;WITH mx2 AS (
            SELECT spp.DonViId, spp.ProductId, MAX(sp.ActiveDate) AS MaxD
            FROM dbo.StationProductPrices AS spp
            INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId
            GROUP BY spp.DonViId, spp.ProductId
        )
        UPDATE spp
        SET IsCurrent = CASE WHEN sp.ActiveDate = mx2.MaxD THEN 1 ELSE 0 END,
            Modified = SYSDATETIME(),
            ModifiedBy = N'sys_demo'
        FROM dbo.StationProductPrices AS spp
        INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
        INNER JOIN mx2
            ON mx2.DonViId = spp.DonViId
           AND mx2.ProductId = spp.ProductId
        WHERE sp.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420025012_AddDemoDataStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_GenerateInventory
        @Tinh INT,
        @ClearOldData BIT,
        @DaysBack INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        /*
         * Demo inventory for heatmap / inventory-current (SUM(Quantity * TransactionType) per product).
         * Writes StationInventoryTransactionHeaders + StationInventoryTransactionDetails (UnitId required).
         * Legacy dbo.StationInventoryTransactions has no UnitId and is not read by store admin SPs.
         */
        SET NOCOUNT ON;
        IF @DaysBack < 1 SET @DaysBack = 1;
        IF @DaysBack > 400 SET @DaysBack = 400;

        IF @ClearOldData = 1
        BEGIN
            DELETE h
            FROM dbo.StationInventoryTransactionHeaders AS h
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
            WHERE h.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;

        IF OBJECT_ID(N'tempdb..#LeafProducts', N'U') IS NOT NULL
            DROP TABLE #LeafProducts;

        ;WITH Grp AS (
            SELECT g.Id
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
        ),
        DownTree AS (
            SELECT fp.Id, fp.Code, fp.Name, fp.UnitId
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS g ON fp.ParentId = g.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.Code, c.Name, c.UnitId
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        Leaf AS (
            SELECT d.Id AS ProductId, d.UnitId
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
              AND d.UnitId IS NOT NULL
        )
        SELECT l.ProductId, l.UnitId
        INTO #LeafProducts
        FROM Leaf AS l;

        IF NOT EXISTS (SELECT 1 FROM #LeafProducts)
            RETURN;

        IF OBJECT_ID(N'tempdb..#StoreCfg', N'U') IS NOT NULL
            DROP TABLE #StoreCfg;

        CREATE TABLE #StoreCfg (
            DonViId INT NOT NULL PRIMARY KEY,
            TTarget INT NOT NULL);

        INSERT INTO #StoreCfg (DonViId, TTarget)
        SELECT
            dv.Id,
            CASE dv.Id % 10
                WHEN 0 THEN -250 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv0')) % 451)
                WHEN 1 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv1')) % 1001)
                WHEN 2 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv2')) % 1001)
                WHEN 3 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv3')) % 3001)
                WHEN 4 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv4')) % 3001)
                WHEN 5 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv5')) % 3001)
                WHEN 6 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv6')) % 3001)
                ELSE 6000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv' + CONVERT(VARCHAR(2), dv.Id % 10))) % 6001)
            END
        FROM dbo.DM_DonVi AS dv
        WHERE dv.CapDonViId = @RetailCapDonViId
          AND dv.Tinh = @Tinh;

        DECLARE @sid INT;
        DECLARE @Tt INT;
        DECLARE @sumW BIGINT;
        DECLARE @cnt INT;
        DECLARE @rem INT;
        DECLARE @off INT;
        DECLARE @pid INT;
        DECLARE @uid INT;
        DECLARE @qty INT;
        DECLARE @dayBase DATE;
        DECLARE @ts DATETIME2(0);
        DECLARE @hId INT;
        DECLARE @pad INT;
        DECLARE @tpi INT;

        DECLARE sCur CURSOR LOCAL FAST_FORWARD FOR
            SELECT DonViId, TTarget FROM #StoreCfg ORDER BY DonViId;

        OPEN sCur;
        FETCH NEXT FROM sCur INTO @sid, @Tt;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF OBJECT_ID(N'tempdb..#Tgt', N'U') IS NOT NULL
                DROP TABLE #Tgt;

            CREATE TABLE #Tgt (
                ProductId INT NOT NULL PRIMARY KEY,
                UnitId INT NOT NULL,
                TargetQty INT NOT NULL);

            SELECT @cnt = COUNT(*), @sumW = COALESCE(SUM(CAST(1 + (ProductId % 5) AS BIGINT)), 0) FROM #LeafProducts;

            IF @cnt > 0 AND @sumW > 0
            BEGIN
            INSERT INTO #Tgt (ProductId, UnitId, TargetQty)
            SELECT
                p.ProductId,
                p.UnitId,
                CAST((CAST(@Tt AS BIGINT) * CAST(1 + (p.ProductId % 5) AS BIGINT)) / @sumW AS INT)
            FROM #LeafProducts AS p;

            SELECT @rem = @Tt - COALESCE(SUM(TargetQty), 0) FROM #Tgt;

            WHILE @rem <> 0
            BEGIN
                IF @rem > 0
                BEGIN
                    UPDATE TOP (1) t
                    SET TargetQty = t.TargetQty + 1
                    FROM #Tgt AS t
                    WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                    SET @rem -= 1;
                END;
                ELSE
                BEGIN
                    UPDATE TOP (1) t
                    SET TargetQty = t.TargetQty - 1
                    FROM #Tgt AS t
                    WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                    SET @rem += 1;
                END;
            END;

            SET @off = @DaysBack - 1;
            WHILE @off >= 1
            BEGIN
                SET @dayBase = DATEADD(DAY, -@off, CAST(SYSDATETIME() AS DATE));

                SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts);
                WHILE @pid IS NOT NULL
                BEGIN
                    SELECT @uid = UnitId FROM #LeafProducts WHERE ProductId = @pid;

                    SET @qty = 40 + (ABS(CHECKSUM(
                        CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#' + CONVERT(VARCHAR(10), @off))) % 121);

                    SET @ts = DATEADD(MINUTE, (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1 + (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts WHERE ProductId > @pid);
                END;

                SET @off -= 1;
            END;

            SET @dayBase = CAST(SYSDATETIME() AS DATE);

            SET @pid = (SELECT MIN(ProductId) FROM #Tgt);
            WHILE @pid IS NOT NULL
            BEGIN
                SELECT @uid = UnitId, @tpi = TargetQty FROM #Tgt WHERE ProductId = @pid;

                SET @pad = 25 + (ABS(CHECKSUM(
                    CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#pad')) % 60);
                SET @ts = DATEADD(MINUTE, 120 + (@pid % 60), CAST(@dayBase AS DATETIME2(0)));

                IF @tpi >= 0
                BEGIN
                    SET @qty = @tpi + @pad;

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1, @ts);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);
                END;
                ELSE
                BEGIN
                    SET @qty = @pad + ABS(@tpi);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1, @ts);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);
                END;

                SET @pid = (SELECT MIN(ProductId) FROM #Tgt WHERE ProductId > @pid);
            END;

            END;

            FETCH NEXT FROM sCur INTO @sid, @Tt;
        END;

        CLOSE sCur;
        DEALLOCATE sCur;

        DROP TABLE #StoreCfg;
        DROP TABLE #LeafProducts;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420025012_AddDemoDataStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_GenerateAll
        @Tinh INT,
        @ClearOldData BIT,
        @DaysBack INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @ClearOldData = 1
            EXEC dbo.sp_Demo_ClearData @Tinh = @Tinh, @RetailCapDonViId = @RetailCapDonViId;

        EXEC dbo.sp_Demo_GeneratePrices
            @Tinh = @Tinh,
            @ClearOldData = 0,
            @DaysBack = @DaysBack,
            @RetailCapDonViId = @RetailCapDonViId;

        EXEC dbo.sp_Demo_GenerateInventory
            @Tinh = @Tinh,
            @ClearOldData = 0,
            @DaysBack = @DaysBack,
            @RetailCapDonViId = @RetailCapDonViId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420025012_AddDemoDataStoredProcedures'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420025012_AddDemoDataStoredProcedures', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420030141_UpdateDemoGeneratePricesProcedure'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_GeneratePrices
        @Tinh INT,
        @ClearOldData BIT,
        @DaysBack INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @DaysBack < 1 SET @DaysBack = 1;
        IF @DaysBack > 400 SET @DaysBack = 400;

        IF @ClearOldData = 1
        BEGIN
            DELETE sp
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;

        IF OBJECT_ID(N'tempdb..#DemoPriceProducts', N'U') IS NOT NULL
            DROP TABLE #DemoPriceProducts;

        ;WITH Grp AS (
            SELECT g.Id, UPPER(LTRIM(RTRIM(g.Code))) AS CodeNorm
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
        ),
        DownTree AS (
            SELECT fp.Id, fp.Code, fp.Name, fp.UnitId, g.CodeNorm AS RootCode
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS g ON fp.ParentId = g.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.Code, c.Name, c.UnitId, d.RootCode
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        Leaf AS (
            SELECT d.Id AS ProductId, d.Code, d.Name, d.UnitId, d.RootCode
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
              AND d.UnitId IS NOT NULL
        )
        SELECT
            l.ProductId,
            l.UnitId,
            CAST(
                CASE
                    WHEN UPPER(l.Name) LIKE N'%RON%95%'
                         OR UPPER(l.Code) LIKE N'%RON95%'
                        THEN 1
                    WHEN UPPER(l.Name) LIKE N'%E5%'
                         OR UPPER(l.Code) LIKE N'%E5%'
                         OR UPPER(l.Name) LIKE N'%A92%'
                        THEN 2
                    WHEN UPPER(l.Name) LIKE N'%DIESEL%'
                         OR UPPER(l.Code) LIKE N'%DIESEL%'
                         OR UPPER(l.Name) LIKE N'%DO 0%'
                         OR UPPER(l.Name) LIKE N'%DẦU%'
                        THEN 3
                    WHEN l.RootCode = N'DAU' THEN 3
                    ELSE 2
                END AS TINYINT) AS PriceBand
        INTO #DemoPriceProducts
        FROM Leaf AS l;

        DECLARE @d INT = 0;
        DECLARE @day DATE;
        DECLARE @donViId INT;
        DECLARE @spId INT;
        DECLARE @isCurrent BIT;

        WHILE @d < @DaysBack
        BEGIN
            SET @day = DATEADD(DAY, -@d, CAST(SYSDATETIME() AS DATE));
            SET @isCurrent = CASE WHEN @d = 0 THEN 1 ELSE 0 END;

            DECLARE c CURSOR LOCAL FAST_FORWARD FOR
                SELECT dv.Id
                FROM dbo.DM_DonVi AS dv
                WHERE dv.CapDonViId = @RetailCapDonViId
                  AND dv.Tinh = @Tinh
                ORDER BY dv.Id;

            OPEN c;
            FETCH NEXT FROM c INTO @donViId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
                VALUES (@donViId, @day, 0, SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                SET @spId = SCOPE_IDENTITY();

                INSERT INTO dbo.StationProductPrices (
                    StationPricesId,
                    DonViId,
                    ProductId,
                    Price,
                    UnitId,
                    EffectiveDate,
                    IsCurrent,
                    Note,
                    Created,
                    CreatedBy,
                    Modified,
                    ModifiedBy)
                SELECT
                    @spId,
                    @donViId,
                    p.ProductId,
                    CAST(
                        CASE p.PriceBand
                            WHEN 1 THEN
                                23800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#1')) % 601)
                            WHEN 2 THEN
                                22800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#2')) % 701)
                            WHEN 3 THEN
                                31700 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#3')) % 801)
                            ELSE
                                22800 + (ABS(CHECKSUM(
                                    CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#0')) % 701)
                        END AS DECIMAL(18, 2)),
                    p.UnitId,
                    @day,
                    @isCurrent,
                    N'Demo generated',
                    SYSDATETIME(),
                    N'sys_demo',
                    SYSDATETIME(),
                    N'sys_demo'
                FROM #DemoPriceProducts AS p;

                FETCH NEXT FROM c INTO @donViId;
            END;

            CLOSE c;
            DEALLOCATE c;

            SET @d += 1;
        END;

        DROP TABLE #DemoPriceProducts;

        ;WITH mx AS (
            SELECT sp.DonViId, MAX(sp.ActiveDate) AS MaxD
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId
            GROUP BY sp.DonViId
        )
        UPDATE sp
        SET IsActive = CASE WHEN sp.ActiveDate = mx.MaxD THEN 1 ELSE 0 END,
            Modified = SYSDATETIME(),
            ModifiedBy = N'sys_demo'
        FROM dbo.StationPrices AS sp
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
        INNER JOIN mx ON mx.DonViId = sp.DonViId
        WHERE sp.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;

        ;WITH mx2 AS (
            SELECT spp.DonViId, spp.ProductId, MAX(sp.ActiveDate) AS MaxD
            FROM dbo.StationProductPrices AS spp
            INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId
            GROUP BY spp.DonViId, spp.ProductId
        )
        UPDATE spp
        SET IsCurrent = CASE WHEN sp.ActiveDate = mx2.MaxD THEN 1 ELSE 0 END,
            Modified = SYSDATETIME(),
            ModifiedBy = N'sys_demo'
        FROM dbo.StationProductPrices AS spp
        INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
        INNER JOIN mx2
            ON mx2.DonViId = spp.DonViId
           AND mx2.ProductId = spp.ProductId
        WHERE sp.CreatedBy = N'sys_demo'
          AND dv.Tinh = @Tinh
          AND dv.CapDonViId = @RetailCapDonViId;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420030141_UpdateDemoGeneratePricesProcedure'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420030141_UpdateDemoGeneratePricesProcedure', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420030806_UpdateDemoGenerateInventoryHeatmap'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Demo_GenerateInventory
        @Tinh INT,
        @ClearOldData BIT,
        @DaysBack INT,
        @RetailCapDonViId INT = 248
    AS
    BEGIN
        /*
         * Demo inventory for heatmap / inventory-current (SUM(Quantity * TransactionType) per product).
         * Writes StationInventoryTransactionHeaders + StationInventoryTransactionDetails (UnitId required).
         * Legacy dbo.StationInventoryTransactions has no UnitId and is not read by store admin SPs.
         */
        SET NOCOUNT ON;
        IF @DaysBack < 1 SET @DaysBack = 1;
        IF @DaysBack > 400 SET @DaysBack = 400;

        IF @ClearOldData = 1
        BEGIN
            DELETE h
            FROM dbo.StationInventoryTransactionHeaders AS h
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
            WHERE h.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;

        IF OBJECT_ID(N'tempdb..#LeafProducts', N'U') IS NOT NULL
            DROP TABLE #LeafProducts;

        ;WITH Grp AS (
            SELECT g.Id
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
        ),
        DownTree AS (
            SELECT fp.Id, fp.Code, fp.Name, fp.UnitId
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS g ON fp.ParentId = g.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.Code, c.Name, c.UnitId
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        Leaf AS (
            SELECT d.Id AS ProductId, d.UnitId
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
              AND d.UnitId IS NOT NULL
        )
        SELECT l.ProductId, l.UnitId
        INTO #LeafProducts
        FROM Leaf AS l;

        IF NOT EXISTS (SELECT 1 FROM #LeafProducts)
            RETURN;

        IF OBJECT_ID(N'tempdb..#StoreCfg', N'U') IS NOT NULL
            DROP TABLE #StoreCfg;

        CREATE TABLE #StoreCfg (
            DonViId INT NOT NULL PRIMARY KEY,
            TTarget INT NOT NULL);

        INSERT INTO #StoreCfg (DonViId, TTarget)
        SELECT
            dv.Id,
            CASE dv.Id % 10
                WHEN 0 THEN -250 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv0')) % 451)
                WHEN 1 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv1')) % 1001)
                WHEN 2 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv2')) % 1001)
                WHEN 3 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv3')) % 3001)
                WHEN 4 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv4')) % 3001)
                WHEN 5 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv5')) % 3001)
                WHEN 6 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv6')) % 3001)
                ELSE 6000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv' + CONVERT(VARCHAR(2), dv.Id % 10))) % 6001)
            END
        FROM dbo.DM_DonVi AS dv
        WHERE dv.CapDonViId = @RetailCapDonViId
          AND dv.Tinh = @Tinh;

        DECLARE @sid INT;
        DECLARE @Tt INT;
        DECLARE @sumW BIGINT;
        DECLARE @cnt INT;
        DECLARE @rem INT;
        DECLARE @off INT;
        DECLARE @pid INT;
        DECLARE @uid INT;
        DECLARE @qty INT;
        DECLARE @dayBase DATE;
        DECLARE @ts DATETIME2(0);
        DECLARE @hId INT;
        DECLARE @pad INT;
        DECLARE @tpi INT;

        DECLARE sCur CURSOR LOCAL FAST_FORWARD FOR
            SELECT DonViId, TTarget FROM #StoreCfg ORDER BY DonViId;

        OPEN sCur;
        FETCH NEXT FROM sCur INTO @sid, @Tt;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF OBJECT_ID(N'tempdb..#Tgt', N'U') IS NOT NULL
                DROP TABLE #Tgt;

            CREATE TABLE #Tgt (
                ProductId INT NOT NULL PRIMARY KEY,
                UnitId INT NOT NULL,
                TargetQty INT NOT NULL);

            SELECT @cnt = COUNT(*), @sumW = COALESCE(SUM(CAST(1 + (ProductId % 5) AS BIGINT)), 0) FROM #LeafProducts;

            IF @cnt > 0 AND @sumW > 0
            BEGIN
            INSERT INTO #Tgt (ProductId, UnitId, TargetQty)
            SELECT
                p.ProductId,
                p.UnitId,
                CAST((CAST(@Tt AS BIGINT) * CAST(1 + (p.ProductId % 5) AS BIGINT)) / @sumW AS INT)
            FROM #LeafProducts AS p;

            SELECT @rem = @Tt - COALESCE(SUM(TargetQty), 0) FROM #Tgt;

            WHILE @rem <> 0
            BEGIN
                IF @rem > 0
                BEGIN
                    UPDATE TOP (1) t
                    SET TargetQty = t.TargetQty + 1
                    FROM #Tgt AS t
                    WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                    SET @rem -= 1;
                END;
                ELSE
                BEGIN
                    UPDATE TOP (1) t
                    SET TargetQty = t.TargetQty - 1
                    FROM #Tgt AS t
                    WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                    SET @rem += 1;
                END;
            END;

            SET @off = @DaysBack - 1;
            WHILE @off >= 1
            BEGIN
                SET @dayBase = DATEADD(DAY, -@off, CAST(SYSDATETIME() AS DATE));

                SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts);
                WHILE @pid IS NOT NULL
                BEGIN
                    SELECT @uid = UnitId FROM #LeafProducts WHERE ProductId = @pid;

                    SET @qty = 40 + (ABS(CHECKSUM(
                        CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#' + CONVERT(VARCHAR(10), @off))) % 121);

                    SET @ts = DATEADD(MINUTE, (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1 + (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts WHERE ProductId > @pid);
                END;

                SET @off -= 1;
            END;

            SET @dayBase = CAST(SYSDATETIME() AS DATE);

            SET @pid = (SELECT MIN(ProductId) FROM #Tgt);
            WHILE @pid IS NOT NULL
            BEGIN
                SELECT @uid = UnitId, @tpi = TargetQty FROM #Tgt WHERE ProductId = @pid;

                SET @pad = 25 + (ABS(CHECKSUM(
                    CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#pad')) % 60);
                SET @ts = DATEADD(MINUTE, 120 + (@pid % 60), CAST(@dayBase AS DATETIME2(0)));

                IF @tpi >= 0
                BEGIN
                    SET @qty = @tpi + @pad;

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1, @ts);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);
                END;
                ELSE
                BEGIN
                    SET @qty = @pad + ABS(@tpi);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);

                    SET @ts = DATEADD(MINUTE, 1, @ts);

                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId, TransactionType, TransactionDate, Note,
                        Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @hId = SCOPE_IDENTITY();
                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                    VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);
                END;

                SET @pid = (SELECT MIN(ProductId) FROM #Tgt WHERE ProductId > @pid);
            END;

            END;

            FETCH NEXT FROM sCur INTO @sid, @Tt;
        END;

        CLOSE sCur;
        DEALLOCATE sCur;

        DROP TABLE #StoreCfg;
        DROP TABLE #LeafProducts;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420030806_UpdateDemoGenerateInventoryHeatmap'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420030806_UpdateDemoGenerateInventoryHeatmap', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420035918_AddStoreAdminInventoryMapStoredProcedure'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode
        @GroupCode NVARCHAR(50)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @GroupCode IS NULL OR LTRIM(RTRIM(@GroupCode)) = N''
        BEGIN
            RAISERROR(N'groupCode is required (XANG or DAU).', 16, 1);
            RETURN;
        END;

        DECLARE @GroupNorm NVARCHAR(50) = UPPER(LTRIM(RTRIM(@GroupCode)));
        IF @GroupNorm NOT IN (N'XANG', N'DAU')
        BEGIN
            RAISERROR(N'groupCode must be XANG or DAU.', 16, 1);
            RETURN;
        END;

        DECLARE @RetailCapDonViId INT = 248;

        -- Ngưỡng "cạn" (demo / nghiệp vụ tại SQL).
        DECLARE @LowStockThreshold DECIMAL(18, 4) = CAST(500 AS DECIMAL(18, 4));

        ;WITH MapStores AS (
            SELECT dv.Id
            FROM dbo.DM_DonVi AS dv
            WHERE dv.CapDonViId = @RetailCapDonViId
              AND dv.ViDo IS NOT NULL
              AND dv.KinhDo IS NOT NULL
        ),
        Grp AS (
            SELECT g.Id
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) = @GroupNorm
        ),
        DownTree AS (
            SELECT fp.Id, fp.ParentId
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS r ON fp.ParentId = r.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.ParentId
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        LeafProducts AS (
            SELECT d.Id AS ProductId
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
        ),
        FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                h.TransactionType,
                CAST(d.Quantity AS DECIMAL(18, 4)) AS QuantityForStock
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            INNER JOIN MapStores AS ms ON ms.Id = h.DonViId
            INNER JOIN LeafProducts AS lp ON lp.ProductId = d.ProductId
        ),
        QtyByStore AS (
            SELECT
                ft.DonViId,
                CAST(SUM(ft.QuantityForStock * CAST(ft.TransactionType AS DECIMAL(18, 4))) AS DECIMAL(18, 4)) AS CurrentQuantity
            FROM FilteredTx AS ft
            GROUP BY ft.DonViId
        ),
        Rows AS (
            SELECT
                dv.Id AS StationId,
                dv.Ma AS StationCode,
                dv.Ten AS StationName,
                Address = NULLIF(
                    LTRIM(RTRIM(CONCAT(ISNULL(dv.DiaChi, N''), N' ', ISNULL(dv.DiaChiChiTiet, N'')))),
                    N''),
                Latitude = CASE WHEN ISNUMERIC(dv.ViDo) = 1 THEN CAST(dv.ViDo AS FLOAT) ELSE NULL END,
                Longitude = CASE WHEN ISNUMERIC(dv.KinhDo) = 1 THEN CAST(dv.KinhDo AS FLOAT) ELSE NULL END,
                RealQty = q.CurrentQuantity,
                HasRealAgg = CASE WHEN q.DonViId IS NOT NULL THEN 1 ELSE 0 END,
                DemoQty = CAST(
                    (ABS(CHECKSUM(dv.Id, BINARY_CHECKSUM(@GroupNorm))) % 9000) AS DECIMAL(18, 4)) / CAST(9.0 AS DECIMAL(18, 4))
            FROM dbo.DM_DonVi AS dv
            INNER JOIN MapStores AS ms ON ms.Id = dv.Id
            LEFT JOIN QtyByStore AS q ON q.DonViId = dv.Id
        )
        SELECT
            r.StationId,
            r.StationCode,
            r.StationName,
            r.Address,
            r.Latitude,
            r.Longitude,
            CurrentQuantity = CAST(
                CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END AS DECIMAL(18, 4)),
            StockStatus = CAST(
                CASE
                    WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) <= 0
                        THEN N'out'
                    WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) < @LowStockThreshold
                        THEN N'low'
                    ELSE N'normal'
                END AS VARCHAR(16))
        FROM Rows AS r
        ORDER BY r.StationName, r.StationCode;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420035918_AddStoreAdminInventoryMapStoredProcedure'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420035918_AddStoreAdminInventoryMapStoredProcedure', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420040538_RefreshStoreAdminInventoryMapSpDemoStores'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode
        @GroupCode NVARCHAR(50)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @GroupCode IS NULL OR LTRIM(RTRIM(@GroupCode)) = N''
        BEGIN
            RAISERROR(N'groupCode is required (XANG or DAU).', 16, 1);
            RETURN;
        END;

        DECLARE @GroupNorm NVARCHAR(50) = UPPER(LTRIM(RTRIM(@GroupCode)));
        IF @GroupNorm NOT IN (N'XANG', N'DAU')
        BEGIN
            RAISERROR(N'groupCode must be XANG or DAU.', 16, 1);
            RETURN;
        END;

        DECLARE @RetailCapDonViId INT = 248;

        -- Ngưỡng "cạn" (demo / nghiệp vụ tại SQL).
        DECLARE @LowStockThreshold DECIMAL(18, 4) = CAST(500 AS DECIMAL(18, 4));

        ;WITH MapStores AS (
            SELECT dv.Id
            FROM dbo.DM_DonVi AS dv
            WHERE dv.CapDonViId = @RetailCapDonViId
              AND dv.ViDo IS NOT NULL
              AND dv.KinhDo IS NOT NULL
        ),
        Grp AS (
            SELECT g.Id
            FROM dbo.FuelProducts AS g
            WHERE UPPER(LTRIM(RTRIM(g.Code))) = @GroupNorm
        ),
        DownTree AS (
            SELECT fp.Id, fp.ParentId
            FROM dbo.FuelProducts AS fp
            INNER JOIN Grp AS r ON fp.ParentId = r.Id
            WHERE fp.IsActive = 1
            UNION ALL
            SELECT c.Id, c.ParentId
            FROM dbo.FuelProducts AS c
            INNER JOIN DownTree AS d ON c.ParentId = d.Id
            WHERE c.IsActive = 1
        ),
        LeafProducts AS (
            SELECT d.Id AS ProductId
            FROM DownTree AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
        ),
        FilteredTx AS (
            SELECT
                h.DonViId,
                d.ProductId,
                h.TransactionType,
                CAST(d.Quantity AS DECIMAL(18, 4)) AS QuantityForStock
            FROM dbo.StationInventoryTransactionDetails AS d
            INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
            INNER JOIN MapStores AS ms ON ms.Id = h.DonViId
            INNER JOIN LeafProducts AS lp ON lp.ProductId = d.ProductId
        ),
        QtyByStore AS (
            SELECT
                ft.DonViId,
                CAST(SUM(ft.QuantityForStock * CAST(ft.TransactionType AS DECIMAL(18, 4))) AS DECIMAL(18, 4)) AS CurrentQuantity
            FROM FilteredTx AS ft
            GROUP BY ft.DonViId
        ),
        Rows AS (
            SELECT
                dv.Id AS StationId,
                dv.Ma AS StationCode,
                dv.Ten AS StationName,
                Address = NULLIF(
                    LTRIM(RTRIM(CONCAT(ISNULL(dv.DiaChi, N''), N' ', ISNULL(dv.DiaChiChiTiet, N'')))),
                    N''),
                Latitude = CASE WHEN ISNUMERIC(dv.ViDo) = 1 THEN CAST(dv.ViDo AS FLOAT) ELSE NULL END,
                Longitude = CASE WHEN ISNUMERIC(dv.KinhDo) = 1 THEN CAST(dv.KinhDo AS FLOAT) ELSE NULL END,
                RealQty = q.CurrentQuantity,
                HasRealAgg = CASE WHEN q.DonViId IS NOT NULL THEN 1 ELSE 0 END,
                DemoQty = CAST(
                    (ABS(CHECKSUM(dv.Id, BINARY_CHECKSUM(@GroupNorm))) % 9000) AS DECIMAL(18, 4)) / CAST(9.0 AS DECIMAL(18, 4))
            FROM dbo.DM_DonVi AS dv
            INNER JOIN MapStores AS ms ON ms.Id = dv.Id
            LEFT JOIN QtyByStore AS q ON q.DonViId = dv.Id
        )
        SELECT
            r.StationId,
            r.StationCode,
            r.StationName,
            r.Address,
            r.Latitude,
            r.Longitude,
            CurrentQuantity = CAST(
                CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END AS DECIMAL(18, 4)),
            StockStatus = CAST(
                CASE
                    WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) <= 0
                        THEN N'out'
                    WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) < @LowStockThreshold
                        THEN N'low'
                    ELSE N'normal'
                END AS VARCHAR(16))
        FROM Rows AS r
        ORDER BY r.StationName, r.StationCode;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420040538_RefreshStoreAdminInventoryMapSpDemoStores'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420040538_RefreshStoreAdminInventoryMapSpDemoStores', N'10.0.0');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420075615_AddReportsStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Reports_GetStationOverview
        @RetailCapDonViId INT,
        @DayOfWeek TINYINT,
        @NowTime TIME(0)
    AS
    BEGIN
        SET NOCOUNT ON;

        ;WITH Stations AS (
            SELECT d.Id, d.Tinh, d.TrangThai
            FROM dbo.DM_DonVi AS d
            WHERE d.CapDonViId = @RetailCapDonViId
        ),
        OpenFlags AS (
            SELECT
                s.Id,
                CASE
                    WHEN (s.TrangThai IS NULL OR s.TrangThai = 1)
                         AND (
                             NOT EXISTS (SELECT 1 FROM dbo.StationOperatingHours AS h0 WHERE h0.DonViId = s.Id)
                             OR NOT EXISTS (
                                 SELECT 1
                                 FROM dbo.StationOperatingHours AS h1
                                 WHERE h1.DonViId = s.Id AND h1.DayOfWeek = @DayOfWeek
                             )
                             OR EXISTS (
                                 SELECT 1
                                 FROM dbo.StationOperatingHours AS h
                                 WHERE h.DonViId = s.Id
                                   AND h.DayOfWeek = @DayOfWeek
                                   AND h.IsClosedAllDay = CAST(0 AS bit)
                                   AND (
                                       (h.OpensAt IS NULL AND h.ClosesAt IS NULL)
                                       OR (
                                           h.OpensAt IS NOT NULL
                                           AND h.ClosesAt IS NOT NULL
                                           AND (
                                               (
                                                   h.ClosesAt >= h.OpensAt
                                                   AND h.OpensAt <= @NowTime
                                                   AND @NowTime <= h.ClosesAt
                                               )
                                               OR (
                                                   h.ClosesAt < h.OpensAt
                                                   AND (h.OpensAt <= @NowTime OR @NowTime <= h.ClosesAt)
                                               )
                                           )
                                       )
                                   )
                             )
                         )
                    THEN 1
                    ELSE 0
                END AS IsOpen
            FROM Stations AS s
        )
        SELECT
            (SELECT COUNT_BIG(*) FROM Stations) AS TotalStations,
            (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 1) AS OpenStations,
            (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 0) AS ClosedStations;

        SELECT
            t.Ma AS ProvinceCode,
            t.Ten AS ProvinceName,
            COUNT_BIG(*) AS StationCount
        FROM Stations AS s
        LEFT JOIN dbo.DM_Tinh AS t ON t.Id = s.Tinh
        GROUP BY t.Ma, t.Ten
        ORDER BY
            CASE WHEN t.Ten IS NULL THEN 1 ELSE 0 END,
            t.Ten,
            t.Ma;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420075615_AddReportsStoredProcedures'
)
BEGIN
    CREATE OR ALTER PROCEDURE dbo.sp_Reports_GetInventorySummary
        @KieuKyBaoCao INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @AnchorKieu INT = NULL;
        DECLARE @AnchorTu DATE = NULL;
        DECLARE @AnchorDen DATE = NULL;

        SELECT TOP (1)
            @AnchorKieu = t.KieuKyBaoCao,
            @AnchorTu = t.TuNgay,
            @AnchorDen = t.DenNgay
        FROM dbo.QT_TK_ThongKe AS t
        WHERE t.Loai = 1
          AND t.don_vi_cap1 IS NOT NULL
          AND (@KieuKyBaoCao IS NULL OR t.KieuKyBaoCao = @KieuKyBaoCao)
        ORDER BY t.DenNgay DESC, t.ThoiGianGui DESC, t.Id DESC;

        IF @AnchorDen IS NULL
        BEGIN
            SELECT
                CAST(NULL AS INT) AS KieuKyBaoCaoId,
                CAST(NULL AS NVARCHAR(100)) AS KieuKyMa,
                CAST(NULL AS NVARCHAR(500)) AS KieuKyTen,
                CAST(NULL AS DATE) AS TuNgay,
                CAST(NULL AS DATE) AS DenNgay;

            SELECT
                CAST(0 AS INT) AS ReportingStationCount,
                CAST(0 AS INT) AS StockLineCount,
                CAST(NULL AS DECIMAL(28, 3)) AS TotalSo01;

            SELECT
                CAST(NULL AS INT) AS Nhom,
                CAST(0 AS INT) AS LineCount,
                CAST(NULL AS DECIMAL(28, 3)) AS SumSo01
            WHERE 1 = 0;

            RETURN;
        END;

        SELECT
            @AnchorKieu AS KieuKyBaoCaoId,
            (SELECT TOP (1) k.Ma FROM dbo.DM_KieuKyBaoCao AS k WHERE k.Id = @AnchorKieu) AS KieuKyMa,
            (SELECT TOP (1) k.Ten FROM dbo.DM_KieuKyBaoCao AS k WHERE k.Id = @AnchorKieu) AS KieuKyTen,
            @AnchorTu AS TuNgay,
            @AnchorDen AS DenNgay;

        DECLARE @TkIds TABLE (Id UNIQUEIDENTIFIER PRIMARY KEY);
        INSERT INTO @TkIds (Id)
        SELECT t.Id
        FROM dbo.QT_TK_ThongKe AS t
        WHERE t.Loai = 1
          AND t.don_vi_cap1 IS NOT NULL
          AND t.DenNgay = @AnchorDen
          AND (
              (@AnchorKieu IS NULL AND t.KieuKyBaoCao IS NULL)
              OR (@AnchorKieu IS NOT NULL AND t.KieuKyBaoCao = @AnchorKieu)
          )
          AND (
              (@AnchorTu IS NULL AND t.TuNgay IS NULL)
              OR (@AnchorTu IS NOT NULL AND t.TuNgay = @AnchorTu)
          );

        SELECT
            (
                SELECT COUNT_BIG(DISTINCT t.don_vi_cap1)
                FROM dbo.QT_TK_ThongKe AS t
                INNER JOIN @TkIds AS i ON i.Id = t.Id
                WHERE t.don_vi_cap1 IS NOT NULL
            ) AS ReportingStationCount,
            (
                SELECT COUNT_BIG(*)
                FROM dbo.QT_TK_ThongKeChiTiet AS l
                INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
                WHERE l.LoaiGia IS NULL
                  AND l.ThoiDiemDinhGia IS NULL
                  AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
                  AND (l.Xoa IS NULL OR l.Xoa = 0)
            ) AS StockLineCount,
            (
                SELECT SUM(CAST(l.So_01 AS DECIMAL(28, 3)))
                FROM dbo.QT_TK_ThongKeChiTiet AS l
                INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
                WHERE l.LoaiGia IS NULL
                  AND l.ThoiDiemDinhGia IS NULL
                  AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
                  AND (l.Xoa IS NULL OR l.Xoa = 0)
            ) AS TotalSo01;

        SELECT
            l.Nhom,
            COUNT_BIG(*) AS LineCount,
            SUM(CAST(l.So_01 AS DECIMAL(28, 3))) AS SumSo01
        FROM dbo.QT_TK_ThongKeChiTiet AS l
        INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
        WHERE l.LoaiGia IS NULL
          AND l.ThoiDiemDinhGia IS NULL
          AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
          AND (l.Xoa IS NULL OR l.Xoa = 0)
        GROUP BY l.Nhom
        ORDER BY l.Nhom;
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260420075615_AddReportsStoredProcedures'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260420075615_AddReportsStoredProcedures', N'10.0.0');
END;

COMMIT;
GO

