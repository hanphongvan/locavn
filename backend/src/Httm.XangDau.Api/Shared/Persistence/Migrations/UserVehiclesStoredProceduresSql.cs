namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Stored procedures for <c>UserVehicles</c> (Dapper-only access from API).</summary>
internal static class UserVehiclesStoredProceduresSql
{
    internal const string GetByUser =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_GetByUser
            @UserId NVARCHAR(128),
            @LicensePlateSearch NVARCHAR(20) = NULL,
            @FuelType NVARCHAR(50) = NULL,
            @Page INT = 1,
            @PageSize INT = 0
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @Page IS NULL OR @Page < 1 SET @Page = 1;
            IF @PageSize IS NULL SET @PageSize = 0;
            IF @PageSize > 500 SET @PageSize = 500;

            ;WITH Base AS (
                SELECT
                    v.Id,
                    v.UserId,
                    v.LicensePlate,
                    v.VehicleName,
                    v.FuelType,
                    v.FuelLevel,
                    v.TotalKm,
                    v.[Year],
                    v.IsDefault,
                    v.ImageUrl,
                    v.CreatedDate,
                    v.UpdatedDate,
                    TotalCount = COUNT(*) OVER (),
                    RowNum = ROW_NUMBER() OVER (ORDER BY v.IsDefault DESC, v.Id ASC)
                FROM dbo.UserVehicles AS v
                WHERE v.UserId = @UserId
                  AND (
                      @LicensePlateSearch IS NULL
                      OR LTRIM(RTRIM(@LicensePlateSearch)) = N''
                      OR v.LicensePlate LIKE N'%' + LTRIM(RTRIM(@LicensePlateSearch)) + N'%'
                  )
                  AND (
                      @FuelType IS NULL
                      OR LTRIM(RTRIM(@FuelType)) = N''
                      OR v.FuelType = @FuelType
                  )
            )
            SELECT
                b.Id,
                b.UserId,
                b.LicensePlate,
                b.VehicleName,
                b.FuelType,
                b.FuelLevel,
                b.TotalKm,
                b.[Year],
                b.IsDefault,
                b.ImageUrl,
                b.CreatedDate,
                b.UpdatedDate,
                b.TotalCount
            FROM Base AS b
            WHERE @PageSize <= 0
               OR (b.RowNum > (@Page - 1) * @PageSize AND b.RowNum <= @Page * @PageSize)
            ORDER BY b.IsDefault DESC, b.Id ASC;
        END;
        """;

    internal const string GetById =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_GetById
            @Id INT,
            @UserId NVARCHAR(128)
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                v.Id,
                v.UserId,
                v.LicensePlate,
                v.VehicleName,
                v.FuelType,
                v.FuelLevel,
                v.TotalKm,
                v.[Year],
                v.IsDefault,
                v.ImageUrl,
                v.CreatedDate,
                v.UpdatedDate
            FROM dbo.UserVehicles AS v
            WHERE v.Id = @Id
              AND v.UserId = @UserId;
        END;
        """;

    internal const string Create =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_Create
            @UserId NVARCHAR(128),
            @LicensePlate NVARCHAR(20),
            @VehicleName NVARCHAR(100) = NULL,
            @FuelType NVARCHAR(50) = NULL,
            @FuelLevel INT = NULL,
            @TotalKm INT = NULL,
            @Year INT = NULL,
            @IsDefault BIT,
            @ImageUrl NVARCHAR(500) = NULL,
            @NewId INT OUTPUT,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @NewId = NULL;
            SET @ErrorMessage = NULL;

            IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers AS u WHERE u.Id = @UserId)
            BEGIN
                SET @ErrorMessage = N'Người dùng không tồn tại.';
                RETURN;
            END;

            IF @LicensePlate IS NULL OR LTRIM(RTRIM(@LicensePlate)) = N''
            BEGIN
                SET @ErrorMessage = N'Biển số không hợp lệ.';
                RETURN;
            END;

            DECLARE @Cnt INT = (SELECT COUNT_BIG(*) FROM dbo.UserVehicles AS v WHERE v.UserId = @UserId);
            DECLARE @HasDefault BIT = CASE
                WHEN EXISTS (SELECT 1 FROM dbo.UserVehicles AS v2 WHERE v2.UserId = @UserId AND v2.IsDefault = 1) THEN 1
                ELSE 0
            END;
            DECLARE @EffDefault BIT;

            IF @Cnt = 0
                SET @EffDefault = 1;
            ELSE IF @IsDefault = 1
                SET @EffDefault = 1;
            ELSE IF @HasDefault = 0
                SET @EffDefault = 1;
            ELSE
                SET @EffDefault = 0;

            IF @EffDefault = 1
            BEGIN
                UPDATE dbo.UserVehicles
                SET IsDefault = 0, UpdatedDate = GETDATE()
                WHERE UserId = @UserId;
            END;

            INSERT INTO dbo.UserVehicles (
                UserId,
                LicensePlate,
                VehicleName,
                FuelType,
                FuelLevel,
                TotalKm,
                [Year],
                IsDefault,
                ImageUrl
            )
            VALUES (
                @UserId,
                LTRIM(RTRIM(@LicensePlate)),
                @VehicleName,
                @FuelType,
                @FuelLevel,
                @TotalKm,
                @Year,
                @EffDefault,
                @ImageUrl
            );

            SET @NewId = SCOPE_IDENTITY();
        END;
        """;

    internal const string Update =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_Update
            @Id INT,
            @UserId NVARCHAR(128),
            @LicensePlate NVARCHAR(20),
            @VehicleName NVARCHAR(100) = NULL,
            @FuelType NVARCHAR(50) = NULL,
            @FuelLevel INT = NULL,
            @TotalKm INT = NULL,
            @Year INT = NULL,
            @IsDefault BIT,
            @ImageUrl NVARCHAR(500) = NULL,
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF NOT EXISTS (SELECT 1 FROM dbo.UserVehicles AS v WHERE v.Id = @Id AND v.UserId = @UserId)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy xe.';
                RETURN;
            END;

            IF @LicensePlate IS NULL OR LTRIM(RTRIM(@LicensePlate)) = N''
            BEGIN
                SET @ErrorMessage = N'Biển số không hợp lệ.';
                RETURN;
            END;

            DECLARE @OnlyOne BIT = CASE
                WHEN (SELECT COUNT_BIG(*) FROM dbo.UserVehicles AS v2 WHERE v2.UserId = @UserId) = 1 THEN 1
                ELSE 0
            END;
            DECLARE @EffIsDefault BIT = CASE WHEN @OnlyOne = 1 THEN 1 ELSE @IsDefault END;

            IF @EffIsDefault = 1
            BEGIN
                UPDATE dbo.UserVehicles
                SET IsDefault = 0, UpdatedDate = GETDATE()
                WHERE UserId = @UserId AND Id <> @Id;

                UPDATE dbo.UserVehicles
                SET
                    LicensePlate = LTRIM(RTRIM(@LicensePlate)),
                    VehicleName = @VehicleName,
                    FuelType = @FuelType,
                    FuelLevel = @FuelLevel,
                    TotalKm = @TotalKm,
                    [Year] = @Year,
                    IsDefault = 1,
                    ImageUrl = @ImageUrl,
                    UpdatedDate = GETDATE()
                WHERE Id = @Id AND UserId = @UserId;
            END
            ELSE
            BEGIN
                IF EXISTS (SELECT 1 FROM dbo.UserVehicles AS v3 WHERE v3.Id = @Id AND v3.UserId = @UserId AND v3.IsDefault = 1)
                   AND EXISTS (SELECT 1 FROM dbo.UserVehicles AS v4 WHERE v4.UserId = @UserId AND v4.Id <> @Id)
                BEGIN
                    DECLARE @PromoteId INT = (
                        SELECT TOP (1) u.Id
                        FROM dbo.UserVehicles AS u
                        WHERE u.UserId = @UserId AND u.Id <> @Id
                        ORDER BY u.Id ASC
                    );

                    UPDATE dbo.UserVehicles SET IsDefault = 0, UpdatedDate = GETDATE() WHERE UserId = @UserId;
                    UPDATE dbo.UserVehicles SET IsDefault = 1, UpdatedDate = GETDATE() WHERE Id = @PromoteId;
                END;

                UPDATE dbo.UserVehicles
                SET
                    LicensePlate = LTRIM(RTRIM(@LicensePlate)),
                    VehicleName = @VehicleName,
                    FuelType = @FuelType,
                    FuelLevel = @FuelLevel,
                    TotalKm = @TotalKm,
                    [Year] = @Year,
                    IsDefault = CASE WHEN @OnlyOne = 1 THEN 1 ELSE 0 END,
                    ImageUrl = @ImageUrl,
                    UpdatedDate = GETDATE()
                WHERE Id = @Id AND UserId = @UserId;
            END;

            IF (SELECT COUNT_BIG(*) FROM dbo.UserVehicles AS x WHERE x.UserId = @UserId AND x.IsDefault = 1) = 0
               AND (SELECT COUNT_BIG(*) FROM dbo.UserVehicles AS y WHERE y.UserId = @UserId) > 0
            BEGIN
                DECLARE @FixId INT = (
                    SELECT TOP (1) u2.Id FROM dbo.UserVehicles AS u2 WHERE u2.UserId = @UserId ORDER BY u2.Id ASC
                );
                UPDATE dbo.UserVehicles
                SET IsDefault = CASE WHEN Id = @FixId THEN 1 ELSE 0 END, UpdatedDate = GETDATE()
                WHERE UserId = @UserId;
            END;
        END;
        """;

    internal const string Delete =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_Delete
            @Id INT,
            @UserId NVARCHAR(128),
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF NOT EXISTS (SELECT 1 FROM dbo.UserVehicles AS v WHERE v.Id = @Id AND v.UserId = @UserId)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy xe.';
                RETURN;
            END;

            DECLARE @Cnt INT = (SELECT COUNT_BIG(*) FROM dbo.UserVehicles AS v2 WHERE v2.UserId = @UserId);
            IF @Cnt <= 1
            BEGIN
                SET @ErrorMessage = N'Không thể xóa xe duy nhất.';
                RETURN;
            END;

            IF EXISTS (
                SELECT 1
                FROM dbo.UserVehicles AS v3
                WHERE v3.Id = @Id AND v3.UserId = @UserId AND v3.IsDefault = 1
            )
            BEGIN
                DECLARE @PromoteId2 INT = (
                    SELECT TOP (1) u.Id
                    FROM dbo.UserVehicles AS u
                    WHERE u.UserId = @UserId AND u.Id <> @Id
                    ORDER BY u.Id ASC
                );
                UPDATE dbo.UserVehicles SET IsDefault = 0, UpdatedDate = GETDATE() WHERE UserId = @UserId;
                UPDATE dbo.UserVehicles SET IsDefault = 1, UpdatedDate = GETDATE() WHERE Id = @PromoteId2;
            END;

            DELETE FROM dbo.UserVehicles WHERE Id = @Id AND UserId = @UserId;
        END;
        """;

    internal const string SetDefault =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_UserVehicles_SetDefault
            @Id INT,
            @UserId NVARCHAR(128),
            @ErrorMessage NVARCHAR(500) OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @ErrorMessage = NULL;

            IF NOT EXISTS (SELECT 1 FROM dbo.UserVehicles AS v WHERE v.Id = @Id AND v.UserId = @UserId)
            BEGIN
                SET @ErrorMessage = N'Không tìm thấy xe.';
                RETURN;
            END;

            UPDATE dbo.UserVehicles SET IsDefault = 0, UpdatedDate = GETDATE() WHERE UserId = @UserId;
            UPDATE dbo.UserVehicles SET IsDefault = 1, UpdatedDate = GETDATE() WHERE Id = @Id AND UserId = @UserId;
        END;
        """;

    internal const string DropProcedures =
        """
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_GetByUser;
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_GetById;
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_Create;
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_Update;
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_Delete;
        DROP PROCEDURE IF EXISTS dbo.sp_UserVehicles_SetDefault;
        """;
}
