-- HTTM Phase 1 — Bug #7: helper SP để admin gán/gỡ phạm vi tỉnh cho cán bộ Sở (Loai=12).
-- Claim được lưu trong dbo.AspNetUserClaims với ClaimType = 'httm_province_codes',
-- ClaimValue = CSV mã tỉnh ĐVHCVN (ví dụ '01' hoặc '01,79').
--
-- ApplicationOAuthProvider.BuildClaimsAsync đã đọc toàn bộ AspNetUserClaims của user
-- vào JWT, nên thay đổi qua các SP này có hiệu lực ngay lần login kế tiếp.
--
-- Lưu ý: caller (.NET service hoặc DBA) chịu trách nhiệm chuẩn hoá CSV (TRIM, dedupe, sort)
-- để giữ SP đơn giản và tương thích nhiều compat level SQL Server.

CREATE OR ALTER PROCEDURE dbo.sp_Httm_SoStaff_SetProvinceClaim
    @UserId NVARCHAR(128),
    @ProvinceCodesCsv NVARCHAR(MAX) = NULL -- CSV mã tỉnh; rỗng/NULL sẽ xoá claim.
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClaimType NVARCHAR(256);
    SET @ClaimType = N'httm_province_codes';

    DECLARE @Trimmed NVARCHAR(MAX);
    SET @Trimmed = LTRIM(RTRIM(ISNULL(@ProvinceCodesCsv, N'')));

    IF LEN(@Trimmed) = 0
    BEGIN
        DELETE FROM dbo.AspNetUserClaims
        WHERE UserId = @UserId AND ClaimType = @ClaimType;
        RETURN;
    END;

    -- Upsert: nếu đã tồn tại thì update, ngược lại insert.
    IF EXISTS (
        SELECT 1
        FROM dbo.AspNetUserClaims
        WHERE UserId = @UserId AND ClaimType = @ClaimType
    )
    BEGIN
        UPDATE dbo.AspNetUserClaims
        SET ClaimValue = @Trimmed
        WHERE UserId = @UserId AND ClaimType = @ClaimType;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.AspNetUserClaims (UserId, ClaimType, ClaimValue)
        VALUES (@UserId, @ClaimType, @Trimmed);
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_SoStaff_GetProvinceClaim
    @UserId NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        c.UserId,
        c.ClaimType,
        c.ClaimValue
    FROM dbo.AspNetUserClaims AS c
    WHERE c.UserId = @UserId
      AND c.ClaimType = N'httm_province_codes';
END;
GO

-- Ví dụ sử dụng:
--   EXEC dbo.sp_Httm_SoStaff_SetProvinceClaim @UserId = N'{userId}', @ProvinceCodesCsv = N'01,79';
--   EXEC dbo.sp_Httm_SoStaff_GetProvinceClaim @UserId = N'{userId}';
--   EXEC dbo.sp_Httm_SoStaff_SetProvinceClaim @UserId = N'{userId}', @ProvinceCodesCsv = NULL; -- xoá
