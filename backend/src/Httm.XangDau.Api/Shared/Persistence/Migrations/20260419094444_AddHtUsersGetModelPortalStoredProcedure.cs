using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Creates <c>dbo.sp_HT_Users_GetModel_Portal</c> for admin user grid (filters + paging on SQL Server).
/// Legacy <c>sp_HT_Users_GetModel</c> often accepts only <c>@UserName</c>; this proc keeps the same visibility rules.
/// </summary>
public partial class AddHtUsersGetModelPortalStoredProcedure : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            """
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
            """);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            """
            IF OBJECT_ID(N'dbo.sp_HT_Users_GetModel_Portal', N'P') IS NOT NULL
                DROP PROCEDURE dbo.sp_HT_Users_GetModel_Portal;
            """);
    }
}
