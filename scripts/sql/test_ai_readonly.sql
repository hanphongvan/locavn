/* ============================================================================
   Phase 5A — Test ai_readonly user.
   Section 7.8 + Section 14.1.7 của docs/loca-ai-phase5.md.

   Cách chạy: connect SQL Server với user `ai_readonly` (KHÔNG phải sa/admin),
   rồi mở file này trong SSMS hoặc:

     sqlcmd -S <server> -d <database> -U ai_readonly -P "<password>" \
            -i scripts/sql/test_ai_readonly.sql

   Mục tiêu: PASS = đúng kỳ vọng; FAIL = lệch kỳ vọng (cần điều tra).

     ✓ SELECT 8 view AI + 6 lookup → trả rows
     ✗ SELECT bảng gốc nhạy cảm → ERROR (DENY)
     ✗ INSERT vào view + EXEC SP + DROP VIEW → ERROR (DENY)
============================================================================ */

SET NOCOUNT ON;

PRINT N'===== Phase 5A — Test ai_readonly =====';
PRINT N'  Login: ' + SUSER_SNAME() + N' / DB: ' + DB_NAME();
PRINT N'';

DECLARE @passCnt INT = 0, @failCnt INT = 0;
DECLARE @row INT;

------------------------------------------------------------------------------
-- A) SELECT 8 view AI — phải PASS
------------------------------------------------------------------------------
PRINT N'A) SELECT 8 view AI (kỳ vọng: PASS, có thể trả 0 rows nếu DB trống)';

DECLARE @views TABLE (n SYSNAME);
INSERT INTO @views (n) VALUES
    (N'vw_AiHeadOfficeInventory'),
    (N'vw_AiHeadOfficePrice'),
    (N'vw_AiHeadOfficeFundBalance'),
    (N'vw_AiHeadOfficeImport'),
    (N'vw_AiHeadOfficeDomesticSupply'),
    (N'vw_AiStationPrice'),
    (N'vw_AiStationInventory'),
    (N'vw_AiStationRating');

DECLARE @v SYSNAME, @sql NVARCHAR(MAX);
DECLARE c1 CURSOR LOCAL FAST_FORWARD FOR SELECT n FROM @views;
OPEN c1;
FETCH NEXT FROM c1 INTO @v;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP (1) @r = 1 FROM dbo.' + QUOTENAME(@v) + N';';
    BEGIN TRY
        EXEC sp_executesql @sql, N'@r INT OUTPUT', @r = @row OUTPUT;
        PRINT N'  [PASS] SELECT dbo.' + @v;
        SET @passCnt = @passCnt + 1;
    END TRY
    BEGIN CATCH
        PRINT N'  [FAIL] SELECT dbo.' + @v + N' — ' + ERROR_MESSAGE();
        SET @failCnt = @failCnt + 1;
    END CATCH
    FETCH NEXT FROM c1 INTO @v;
END
CLOSE c1;
DEALLOCATE c1;

------------------------------------------------------------------------------
-- B) SELECT 6 lookup table — phải PASS
------------------------------------------------------------------------------
PRINT N'';
PRINT N'B) SELECT 6 lookup table (kỳ vọng: PASS)';

DECLARE @lookups TABLE (n SYSNAME);
INSERT INTO @lookups (n) VALUES
    (N'DM_Tinh'), (N'DM_XaPhuong'), (N'DM_ThiTruong'),
    (N'DM_NhaCungCap'), (N'FuelProducts'), (N'DM_DonViTinh');

DECLARE c2 CURSOR LOCAL FAST_FORWARD FOR SELECT n FROM @lookups;
OPEN c2;
FETCH NEXT FROM c2 INTO @v;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP (1) @r = 1 FROM dbo.' + QUOTENAME(@v) + N';';
    BEGIN TRY
        EXEC sp_executesql @sql, N'@r INT OUTPUT', @r = @row OUTPUT;
        PRINT N'  [PASS] SELECT dbo.' + @v;
        SET @passCnt = @passCnt + 1;
    END TRY
    BEGIN CATCH
        PRINT N'  [FAIL] SELECT dbo.' + @v + N' — ' + ERROR_MESSAGE();
        SET @failCnt = @failCnt + 1;
    END CATCH
    FETCH NEXT FROM c2 INTO @v;
END
CLOSE c2;
DEALLOCATE c2;

------------------------------------------------------------------------------
-- C) SELECT bảng gốc nhạy cảm — phải bị DENY (lỗi = PASS test)
------------------------------------------------------------------------------
PRINT N'';
PRINT N'C) SELECT bảng gốc nhạy cảm (kỳ vọng: ERROR vì DENY)';

DECLARE @denied TABLE (n SYSNAME);
INSERT INTO @denied (n) VALUES
    (N'DM_DonVi'),
    (N'QT_TK_ThongKe'),
    (N'QT_TK_ThongKeChiTiet'),
    (N'AspNetUsers'),
    (N'StationRatings');

DECLARE c3 CURSOR LOCAL FAST_FORWARD FOR SELECT n FROM @denied;
OPEN c3;
FETCH NEXT FROM c3 INTO @v;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP (1) @r = 1 FROM dbo.' + QUOTENAME(@v) + N';';
    BEGIN TRY
        EXEC sp_executesql @sql, N'@r INT OUTPUT', @r = @row OUTPUT;
        PRINT N'  [FAIL] SELECT dbo.' + @v + N' đã thành công — nhưng phải bị DENY!';
        SET @failCnt = @failCnt + 1;
    END TRY
    BEGIN CATCH
        PRINT N'  [PASS] SELECT dbo.' + @v + N' bị DENY đúng (errno='
              + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N')';
        SET @passCnt = @passCnt + 1;
    END CATCH
    FETCH NEXT FROM c3 INTO @v;
END
CLOSE c3;
DEALLOCATE c3;

------------------------------------------------------------------------------
-- D) Thao tác ghi & DDL — phải bị DENY
------------------------------------------------------------------------------
PRINT N'';
PRINT N'D) Thao tác ghi & DDL (kỳ vọng: ERROR vì DENY)';

-- D1) INSERT vào view
BEGIN TRY
    INSERT INTO dbo.vw_AiHeadOfficeInventory (DonViId) VALUES (-1);
    PRINT N'  [FAIL] INSERT vw_AiHeadOfficeInventory thành công — phải bị DENY!';
    SET @failCnt = @failCnt + 1;
END TRY
BEGIN CATCH
    PRINT N'  [PASS] INSERT vw_AiHeadOfficeInventory bị DENY đúng (errno='
          + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N')';
    SET @passCnt = @passCnt + 1;
END CATCH;

-- D2) EXEC stored procedure (SP gốc dashboard)
BEGIN TRY
    EXEC dbo.sp_Dashboard_Home_InventorySummary;
    PRINT N'  [FAIL] EXEC sp_Dashboard_Home_InventorySummary thành công — phải bị DENY!';
    SET @failCnt = @failCnt + 1;
END TRY
BEGIN CATCH
    PRINT N'  [PASS] EXEC sp_Dashboard_Home_InventorySummary bị DENY đúng (errno='
          + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N')';
    SET @passCnt = @passCnt + 1;
END CATCH;

-- D3) DROP VIEW
BEGIN TRY
    DROP VIEW dbo.vw_AiHeadOfficeInventory;
    PRINT N'  [FAIL] DROP VIEW vw_AiHeadOfficeInventory thành công — phải bị DENY!';
    SET @failCnt = @failCnt + 1;
END TRY
BEGIN CATCH
    PRINT N'  [PASS] DROP VIEW vw_AiHeadOfficeInventory bị DENY đúng (errno='
          + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N')';
    SET @passCnt = @passCnt + 1;
END CATCH;

-- D4) UPDATE bảng metadata Ai*
BEGIN TRY
    UPDATE dbo.AiSchemaCatalog SET IsEnabled = 0 WHERE 1 = 0;
    PRINT N'  [FAIL] UPDATE AiSchemaCatalog thành công — phải bị DENY!';
    SET @failCnt = @failCnt + 1;
END TRY
BEGIN CATCH
    PRINT N'  [PASS] UPDATE AiSchemaCatalog bị DENY đúng (errno='
          + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N')';
    SET @passCnt = @passCnt + 1;
END CATCH;

------------------------------------------------------------------------------
-- Tổng kết
------------------------------------------------------------------------------
PRINT N'';
PRINT N'===== Tổng kết =====';
PRINT N'  PASS: ' + CAST(@passCnt AS NVARCHAR(10));
PRINT N'  FAIL: ' + CAST(@failCnt AS NVARCHAR(10));

IF @failCnt > 0
    RAISERROR(N'Có %d test FAIL — kiểm tra log ở trên.', 16, 1, @failCnt);
ELSE
    PRINT N'  ✓ Tất cả test PASS — ai_readonly đã setup đúng.';
GO
