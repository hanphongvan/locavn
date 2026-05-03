namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Stored procedures for portal fuel tracking (Dapper-only from API).</summary>
internal static class FuelStoredProceduresSql
{
    internal const string GetCurrentVehicle =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Fuel_GetCurrentVehicle
            @UserId NVARCHAR(128),
            @DeviceId NVARCHAR(100) = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT TOP (1)
                uv.Id AS VehicleId,
                uv.VehicleName,
                uv.LicensePlate,
                uv.FuelType,
                uv.ImageUrl
            FROM dbo.UserVehicles AS uv
            WHERE uv.UserId = @UserId
            ORDER BY uv.IsDefault DESC, uv.Id ASC;
        END;
        """;

    internal const string GetMonthlySummary =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Fuel_GetMonthlySummary
            @UserId NVARCHAR(128),
            @VehicleId INT,
            @Month INT,
            @Year INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.UserVehicles AS v
                WHERE v.Id = @VehicleId AND v.UserId = @UserId)
            BEGIN
                SELECT
                    CAST(0 AS DECIMAL(18, 2)) AS TotalCost,
                    CAST(0 AS DECIMAL(18, 3)) AS TotalLiters,
                    CAST(0 AS DECIMAL(18, 2)) AS CostPerKm,
                    CAST(0 AS DECIMAL(18, 2)) AS CostChangePercent,
                    CAST(0 AS DECIMAL(18, 2)) AS LiterChangePercent,
                    CAST(0 AS DECIMAL(18, 2)) AS CostPerKmChangePercent;
                RETURN;
            END;

            DECLARE @StartCur DATETIME2 = DATEFROMPARTS(@Year, @Month, 1);
            DECLARE @EndCur DATETIME2 = DATEADD(MONTH, 1, @StartCur);
            DECLARE @StartPrev DATETIME2 = DATEADD(MONTH, -1, @StartCur);
            DECLARE @EndPrev DATETIME2 = @StartCur;

            DECLARE @CurCost DECIMAL(18, 2) = ISNULL((
                SELECT SUM(ft.Amount)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartCur
                  AND ft.TransactionDate < @EndCur), 0);

            DECLARE @PrevCost DECIMAL(18, 2) = ISNULL((
                SELECT SUM(ft.Amount)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartPrev
                  AND ft.TransactionDate < @EndPrev), 0);

            DECLARE @CurLit DECIMAL(18, 3) = ISNULL((
                SELECT SUM(ft.Liters)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartCur
                  AND ft.TransactionDate < @EndCur), 0);

            DECLARE @PrevLit DECIMAL(18, 3) = ISNULL((
                SELECT SUM(ft.Liters)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartPrev
                  AND ft.TransactionDate < @EndPrev), 0);

            DECLARE @MinOCur DECIMAL(18, 1);
            DECLARE @MaxOCur DECIMAL(18, 1);
            SELECT
                @MinOCur = MIN(ft.Odometer),
                @MaxOCur = MAX(ft.Odometer)
            FROM dbo.FuelTransactions AS ft
            WHERE ft.VehicleId = @VehicleId
              AND ft.IsDeleted = 0
              AND ft.TransactionDate >= @StartCur
              AND ft.TransactionDate < @EndCur
              AND ft.Odometer IS NOT NULL;

            DECLARE @KmCur DECIMAL(18, 2) =
                CASE
                    WHEN @MaxOCur IS NOT NULL AND @MinOCur IS NOT NULL AND @MaxOCur > @MinOCur
                        THEN CAST(@MaxOCur - @MinOCur AS DECIMAL(18, 2))
                    ELSE NULL
                END;

            DECLARE @CostPerKm DECIMAL(18, 2) =
                CASE
                    WHEN @KmCur IS NOT NULL AND @KmCur > 0 THEN ROUND(@CurCost / @KmCur, 0)
                    ELSE CAST(0 AS DECIMAL(18, 2))
                END;

            DECLARE @MinOPrev DECIMAL(18, 1);
            DECLARE @MaxOPrev DECIMAL(18, 1);
            SELECT
                @MinOPrev = MIN(ft.Odometer),
                @MaxOPrev = MAX(ft.Odometer)
            FROM dbo.FuelTransactions AS ft
            WHERE ft.VehicleId = @VehicleId
              AND ft.IsDeleted = 0
              AND ft.TransactionDate >= @StartPrev
              AND ft.TransactionDate < @EndPrev
              AND ft.Odometer IS NOT NULL;

            DECLARE @KmPrev DECIMAL(18, 2) =
                CASE
                    WHEN @MaxOPrev IS NOT NULL AND @MinOPrev IS NOT NULL AND @MaxOPrev > @MinOPrev
                        THEN CAST(@MaxOPrev - @MinOPrev AS DECIMAL(18, 2))
                    ELSE NULL
                END;

            DECLARE @CkmPrev DECIMAL(18, 2) =
                CASE
                    WHEN @KmPrev IS NOT NULL AND @KmPrev > 0 THEN ROUND(@PrevCost / @KmPrev, 0)
                    ELSE CAST(0 AS DECIMAL(18, 2))
                END;

            DECLARE @CostChg DECIMAL(18, 2) =
                CASE
                    WHEN @PrevCost > 0 THEN ROUND((@CurCost - @PrevCost) * 100.0 / @PrevCost, 0)
                    WHEN @CurCost > 0 THEN CAST(100 AS DECIMAL(18, 2))
                    ELSE CAST(0 AS DECIMAL(18, 2))
                END;

            DECLARE @LitChg DECIMAL(18, 2) =
                CASE
                    WHEN @PrevLit > 0 THEN ROUND((@CurLit - @PrevLit) * 100.0 / @PrevLit, 0)
                    WHEN @CurLit > 0 THEN CAST(100 AS DECIMAL(18, 2))
                    ELSE CAST(0 AS DECIMAL(18, 2))
                END;

            DECLARE @CkmChg DECIMAL(18, 2) =
                CASE
                    WHEN @CkmPrev > 0 THEN ROUND((@CostPerKm - @CkmPrev) * 100.0 / @CkmPrev, 0)
                    WHEN @CostPerKm > 0 AND (@CkmPrev IS NULL OR @CkmPrev = 0) THEN CAST(100 AS DECIMAL(18, 2))
                    ELSE CAST(0 AS DECIMAL(18, 2))
                END;

            SELECT
                @CurCost AS TotalCost,
                @CurLit AS TotalLiters,
                @CostPerKm AS CostPerKm,
                @CostChg AS CostChangePercent,
                @LitChg AS LiterChangePercent,
                @CkmChg AS CostPerKmChangePercent;
        END;
        """;

    internal const string GetInsights =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Fuel_GetInsights
            @UserId NVARCHAR(128),
            @VehicleId INT,
            @Month INT,
            @Year INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.UserVehicles AS v
                WHERE v.Id = @VehicleId AND v.UserId = @UserId)
            BEGIN
                SELECT
                    CAST(N'' AS NVARCHAR(500)) AS MainText,
                    CAST(N'' AS NVARCHAR(500)) AS SavingText;
                RETURN;
            END;

            DECLARE @StartCur DATETIME2 = DATEFROMPARTS(@Year, @Month, 1);
            DECLARE @EndCur DATETIME2 = DATEADD(MONTH, 1, @StartCur);
            DECLARE @StartPrev DATETIME2 = DATEADD(MONTH, -1, @StartCur);
            DECLARE @EndPrev DATETIME2 = @StartCur;

            DECLARE @CurCost DECIMAL(18, 2) = ISNULL((
                SELECT SUM(ft.Amount)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartCur
                  AND ft.TransactionDate < @EndCur), 0);

            DECLARE @PrevCost DECIMAL(18, 2) = ISNULL((
                SELECT SUM(ft.Amount)
                FROM dbo.FuelTransactions AS ft
                WHERE ft.VehicleId = @VehicleId
                  AND ft.IsDeleted = 0
                  AND ft.TransactionDate >= @StartPrev
                  AND ft.TransactionDate < @EndPrev), 0);

            DECLARE @Diff DECIMAL(18, 2) = @CurCost - @PrevCost;

            DECLARE @MainText NVARCHAR(500);
            IF @PrevCost <= 0 AND @CurCost <= 0
                SET @MainText = N'Chưa có dữ liệu đổ xăng trong tháng này.';
            ELSE IF @PrevCost <= 0 AND @CurCost > 0
                SET @MainText = N'Bạn đã ghi nhận chi phí nhiên liệu trong tháng này.';
            ELSE IF @Diff > 0 AND @PrevCost > 0
                SET @MainText = N'Chi phí nhiên liệu tháng này của bạn cao hơn '
                    + CAST(CAST(ROUND((@Diff * 100.0 / @PrevCost), 0) AS INT) AS NVARCHAR(20))
                    + N'% so với tháng trước.';
            ELSE IF @Diff > 0 AND @PrevCost <= 0
                SET @MainText = N'Chi phí nhiên liệu tháng này cao hơn tháng trước (tháng trước chưa có dữ liệu).';
            ELSE IF @Diff < 0 AND @PrevCost > 0
                SET @MainText = N'Chi phí nhiên liệu tháng này của bạn thấp hơn '
                    + CAST(CAST(ROUND((-@Diff * 100.0 / @PrevCost), 0) AS INT) AS NVARCHAR(20))
                    + N'% so với tháng trước.';
            ELSE IF @Diff < 0 AND @PrevCost <= 0
                SET @MainText = N'Chi phí nhiên liệu tháng này thấp hơn tháng trước (tháng trước chưa có dữ liệu).';
            ELSE
                SET @MainText = N'Chi phí nhiên liệu tháng này tương đương tháng trước.';

            DECLARE @SavingText NVARCHAR(500);
            IF @PrevCost <= 0
                SET @SavingText = N'Dữ liệu tháng trước chưa đủ để so sánh với mức tiêu dùng trung bình.';
            ELSE IF @CurCost < @PrevCost
                SET @SavingText = N'Bạn đang tiết kiệm hơn '
                    + REPLACE(CONVERT(NVARCHAR(30), CAST(ROUND(@PrevCost - @CurCost, 0) AS INT), 1), ',', '.')
                    + N' đ so với tháng trước.';
            ELSE IF @CurCost > @PrevCost
                SET @SavingText = N'Bạn chi nhiều hơn '
                    + REPLACE(CONVERT(NVARCHAR(30), CAST(ROUND(@CurCost - @PrevCost, 0) AS INT), 1), ',', '.')
                    + N' đ so với tháng trước.';
            ELSE
                SET @SavingText = N'Mức chi tháng này ngang với tháng trước.';

            SELECT @MainText AS MainText, @SavingText AS SavingText;
        END;
        """;

    internal const string GetTransactions =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Fuel_GetTransactions
            @UserId NVARCHAR(128),
            @VehicleId INT,
            @PageIndex INT = 1,
            @PageSize INT = 10
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
            IF @PageSize IS NULL OR @PageSize < 1 SET @PageSize = 10;
            IF @PageSize > 100 SET @PageSize = 100;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.UserVehicles AS v
                WHERE v.Id = @VehicleId AND v.UserId = @UserId)
                RETURN;

            DECLARE @Offset INT = (@PageIndex - 1) * @PageSize;

            SELECT
                ft.Id,
                ft.TransactionDate,
                ft.StationId,
                StationName = ISNULL(d.Ten, N''),
                StationLogo = CAST(NULL AS NVARCHAR(500)),
                DistanceText = CAST(NULL AS NVARCHAR(100)),
                ft.Amount,
                ft.Liters,
                PricePerLiter = ISNULL(ft.PricePerLiter, CASE WHEN ft.Liters > 0 THEN ROUND(ft.Amount / ft.Liters, 2) ELSE NULL END),
                ft.Odometer,
                ft.Note,
                TotalCount = COUNT(*) OVER ()
            FROM dbo.FuelTransactions AS ft
            LEFT JOIN dbo.DM_DonVi AS d ON d.Id = ft.StationId
            WHERE ft.VehicleId = @VehicleId
              AND ft.IsDeleted = 0
            ORDER BY ft.TransactionDate DESC, ft.Id DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
        END;
        """;

    internal const string TransactionInsert =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_FuelTransaction_Insert
            @UserId NVARCHAR(128) = NULL,
            @VehicleId INT,
            @StationId INT = NULL,
            @FuelTypeId INT = NULL,
            @Amount DECIMAL(18, 2),
            @Liters DECIMAL(18, 3),
            @Odometer DECIMAL(18, 1) = NULL,
            @TransactionDate DATETIME,
            @Note NVARCHAR(500) = NULL,
            @CreatedBy NVARCHAR(100) = NULL,
            @NewId INT OUTPUT,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @NewId = NULL;
            SET @ErrorMessage = NULL;

            IF @UserId IS NULL OR LTRIM(RTRIM(@UserId)) = N''
            BEGIN
                SET @ErrorMessage = N'Thiếu thông tin người dùng.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.UserVehicles AS v
                WHERE v.Id = @VehicleId AND v.UserId = @UserId)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy xe hoặc xe không thuộc tài khoản.';
                RETURN;
            END;

            IF @Amount IS NULL OR @Amount <= 0
            BEGIN
                SET @ErrorMessage = N'Số tiền phải lớn hơn 0.';
                RETURN;
            END;

            IF @Liters IS NULL OR @Liters <= 0
            BEGIN
                SET @ErrorMessage = N'Số lít phải lớn hơn 0.';
                RETURN;
            END;

            DECLARE @Ppl DECIMAL(18, 2) = ROUND(@Amount / @Liters, 2);

            INSERT INTO dbo.FuelTransactions (
                UserId,
                VehicleId,
                StationId,
                FuelTypeId,
                Amount,
                Liters,
                PricePerLiter,
                Odometer,
                TransactionDate,
                Note,
                CreatedBy,
                IsDeleted)
            VALUES (
                @UserId,
                @VehicleId,
                @StationId,
                @FuelTypeId,
                @Amount,
                @Liters,
                @Ppl,
                @Odometer,
                @TransactionDate,
                NULLIF(LTRIM(RTRIM(@Note)), N''),
                @CreatedBy,
                0);

            SET @NewId = SCOPE_IDENTITY();
        END;
        """;

    internal const string TransactionUpdate =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_FuelTransaction_Update
            @UserId NVARCHAR(128),
            @TransactionId INT,
            @VehicleId INT,
            @Amount DECIMAL(18, 2),
            @Liters DECIMAL(18, 3),
            @Odometer DECIMAL(18, 1) = NULL,
            @TransactionDate DATETIME,
            @Note NVARCHAR(500) = NULL,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF @UserId IS NULL OR LTRIM(RTRIM(@UserId)) = N''
            BEGIN
                SET @ErrorMessage = N'Thiếu thông tin người dùng.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.FuelTransactions AS ft
                INNER JOIN dbo.UserVehicles AS v ON v.Id = ft.VehicleId AND v.UserId = @UserId
                WHERE ft.Id = @TransactionId AND ft.UserId = @UserId AND ft.VehicleId = @VehicleId AND ft.IsDeleted = 0)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy giao dịch.';
                RETURN;
            END;

            IF @Amount IS NULL OR @Amount <= 0
            BEGIN
                SET @ErrorMessage = N'Số tiền phải lớn hơn 0.';
                RETURN;
            END;

            IF @Liters IS NULL OR @Liters <= 0
            BEGIN
                SET @ErrorMessage = N'Số lít phải lớn hơn 0.';
                RETURN;
            END;

            DECLARE @Ppl DECIMAL(18, 2) = ROUND(@Amount / @Liters, 2);

            UPDATE dbo.FuelTransactions
            SET Amount = @Amount,
                Liters = @Liters,
                PricePerLiter = @Ppl,
                Odometer = @Odometer,
                TransactionDate = @TransactionDate,
                Note = NULLIF(LTRIM(RTRIM(@Note)), N'')
            WHERE Id = @TransactionId AND UserId = @UserId AND VehicleId = @VehicleId AND IsDeleted = 0;
        END;
        """;

    internal const string TransactionDelete =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_FuelTransaction_Delete
            @UserId NVARCHAR(128),
            @TransactionId INT,
            @VehicleId INT,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF @UserId IS NULL OR LTRIM(RTRIM(@UserId)) = N''
            BEGIN
                SET @ErrorMessage = N'Thiếu thông tin người dùng.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.FuelTransactions AS ft
                INNER JOIN dbo.UserVehicles AS v ON v.Id = ft.VehicleId AND v.UserId = @UserId
                WHERE ft.Id = @TransactionId AND ft.UserId = @UserId AND ft.VehicleId = @VehicleId AND ft.IsDeleted = 0)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy giao dịch.';
                RETURN;
            END;

            UPDATE dbo.FuelTransactions
            SET IsDeleted = 1
            WHERE Id = @TransactionId AND UserId = @UserId AND VehicleId = @VehicleId AND IsDeleted = 0;
        END;
        """;

    internal const string DropProcedures =
        """
        IF OBJECT_ID(N'dbo.sp_FuelTransaction_Delete', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_FuelTransaction_Delete;
        IF OBJECT_ID(N'dbo.sp_FuelTransaction_Update', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_FuelTransaction_Update;
        IF OBJECT_ID(N'dbo.sp_FuelTransaction_Insert', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_FuelTransaction_Insert;
        IF OBJECT_ID(N'dbo.sp_Fuel_GetTransactions', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Fuel_GetTransactions;
        IF OBJECT_ID(N'dbo.sp_Fuel_GetInsights', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Fuel_GetInsights;
        IF OBJECT_ID(N'dbo.sp_Fuel_GetMonthlySummary', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Fuel_GetMonthlySummary;
        IF OBJECT_ID(N'dbo.sp_Fuel_GetCurrentVehicle', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Fuel_GetCurrentVehicle;
        """;
}
