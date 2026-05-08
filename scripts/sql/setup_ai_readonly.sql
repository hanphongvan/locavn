/* ============================================================================
   Phase 5A — Setup user database `ai_readonly` (chạy thủ công bởi DBA).
   Section 7.8 của docs/loca-ai-phase5.md.

   File này KHÔNG phải EF migration vì việc tạo LOGIN/USER cần password
   không được commit vào source. DBA chạy script này một lần trên DB dev/staging/prod
   sau khi đã apply 5 migration Phase 5A.

   Cách dùng (thay <PASSWORD> bằng mật khẩu mạnh thực tế trước khi chạy):

     sqlcmd -S <server> -d <database> -E -i scripts/sql/setup_ai_readonly.sql \
            -v Pwd="<PASSWORD>"

   Hoặc trong SSMS: tìm chuỗi $(Pwd) bên dưới và replace bằng mật khẩu bằng tay
   (KHÔNG commit lại file đã replace vào git).

   Idempotent: chạy lại để cập nhật quyền không lỗi.
============================================================================ */

SET NOCOUNT ON;

-- 1) Tạo LOGIN ở master --------------------------------------------------------
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ai_readonly')
BEGIN
    DECLARE @sql NVARCHAR(MAX) =
        N'CREATE LOGIN ai_readonly WITH PASSWORD = ''$(Pwd)'', ' +
        N'CHECK_POLICY = ON, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [' +
        DB_NAME() + N'];';
    EXEC sp_executesql @sql;
    PRINT N'  [+] LOGIN ai_readonly đã được tạo.';
END
ELSE
BEGIN
    PRINT N'  [=] LOGIN ai_readonly đã tồn tại — bỏ qua tạo mới (đổi password thủ công nếu cần).';
END;
GO

-- 2) Tạo USER trong DB hiện tại + GRANT/DENY ----------------------------------
-- Switch context sang DB ứng dụng. Khi chạy bằng sqlcmd với -d, biến :setvar không có.
-- Để portable, đổi tên DB ở dòng dưới nếu khác.
DECLARE @AppDb NVARCHAR(128) = DB_NAME();
PRINT N'  [i] Đang setup ai_readonly trong DB: ' + @AppDb;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ai_readonly')
BEGIN
    CREATE USER ai_readonly FOR LOGIN ai_readonly;
    PRINT N'  [+] USER ai_readonly đã được tạo trong DB hiện tại.';
END
ELSE
BEGIN
    PRINT N'  [=] USER ai_readonly đã tồn tại — chỉ cập nhật GRANT/DENY.';
END;
GO

-- 3) GRANT SELECT trên 8 view AI ----------------------------------------------
GRANT SELECT ON dbo.vw_AiHeadOfficeInventory       TO ai_readonly;
GRANT SELECT ON dbo.vw_AiHeadOfficePrice           TO ai_readonly;
GRANT SELECT ON dbo.vw_AiHeadOfficeFundBalance     TO ai_readonly;
GRANT SELECT ON dbo.vw_AiHeadOfficeImport          TO ai_readonly;
GRANT SELECT ON dbo.vw_AiHeadOfficeDomesticSupply  TO ai_readonly;
GRANT SELECT ON dbo.vw_AiStationPrice              TO ai_readonly;
GRANT SELECT ON dbo.vw_AiStationInventory          TO ai_readonly;
GRANT SELECT ON dbo.vw_AiStationRating             TO ai_readonly;
PRINT N'  [+] GRANT SELECT trên 8 view AI hoàn tất.';
GO

-- 4) GRANT SELECT trên 6 lookup table -----------------------------------------
GRANT SELECT ON dbo.DM_Tinh        TO ai_readonly;
GRANT SELECT ON dbo.DM_XaPhuong    TO ai_readonly;
GRANT SELECT ON dbo.DM_ThiTruong   TO ai_readonly;
GRANT SELECT ON dbo.DM_NhaCungCap  TO ai_readonly;
GRANT SELECT ON dbo.FuelProducts   TO ai_readonly;
GRANT SELECT ON dbo.DM_DonViTinh   TO ai_readonly;
PRINT N'  [+] GRANT SELECT trên 6 lookup table hoàn tất.';
GO

-- 5) DENY mọi thao tác ghi và DDL ở scope database ----------------------------
DENY INSERT     TO ai_readonly;
DENY UPDATE     TO ai_readonly;
DENY DELETE     TO ai_readonly;
DENY ALTER      TO ai_readonly;
DENY EXECUTE    TO ai_readonly;
DENY REFERENCES TO ai_readonly;
PRINT N'  [+] DENY DML/DDL/EXECUTE/REFERENCES toàn DB hoàn tất.';
GO

-- 6) DENY SELECT trên các bảng gốc nhạy cảm -----------------------------------
-- Lưu ý: nếu bảng nào không tồn tại trên môi trường, statement DENY sẽ fail.
-- Bọc trong sp_executesql + dynamic check để chạy idempotent qua các môi trường.
DECLARE @denyTables TABLE (TableName SYSNAME);
INSERT INTO @denyTables (TableName) VALUES
    (N'DM_DonVi'),
    (N'QT_TK_ThongKe'),
    (N'QT_TK_ThongKeChiTiet'),
    (N'QT_TK_ThongKeChiTiet02'),
    (N'AspNetUsers'),
    (N'AspNetUserClaims'),
    (N'AspNetUserLogins'),
    (N'AspNetUserRoles'),
    (N'AspNetRoles'),
    (N'StationRatings'),
    (N'StationRatingImages'),
    (N'UserVehicles'),
    (N'FuelTransactions'),
    (N'UserDataDeletionRequests'),
    (N'PasswordResetTokens');

DECLARE @t SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName FROM @denyTables;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @t, N'U') IS NOT NULL
    BEGIN
        SET @sql = N'DENY SELECT ON dbo.' + QUOTENAME(@t) + N' TO ai_readonly;';
        EXEC sp_executesql @sql;
        PRINT N'    [-] DENY SELECT dbo.' + @t;
    END
    ELSE
    BEGIN
        PRINT N'    [.] dbo.' + @t + N' không tồn tại trên môi trường này — bỏ qua.';
    END
    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;
GO

PRINT N'';
PRINT N'==== Setup ai_readonly hoàn tất. ====';
PRINT N'Verify: chạy scripts/sql/test_ai_readonly.sql với connection string của ai_readonly.';
GO
