-- HTTM Phase 1 — §1.1.1: FULLTEXT trên HttmFacilities.Name (thay GIN/tsvector PostgreSQL).
-- Yêu cầu: Full-Text Search được cài trên SQL Server instance.

IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
BEGIN
    RAISERROR(N'HttmFacilities chưa tồn tại — chạy 20260513100000_HttmFacilities_Create.sql trước.', 16, 1);
    RETURN;
END;
GO

IF SERVERPROPERTY('IsFullTextInstalled') <> 1
BEGIN
    PRINT N'SKIP: Full-Text Search chưa cài trên instance — bỏ qua tạo fulltext index HttmFacilities.';
    RETURN;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.fulltext_catalogs
    WHERE name = N'FT_Httm'
)
BEGIN
    CREATE FULLTEXT CATALOG FT_Httm;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.fulltext_indexes
    WHERE object_id = OBJECT_ID(N'dbo.HttmFacilities', N'U')
)
BEGIN
    -- Bỏ qua khoản LANGUAGE để SQL Server dùng default_language của instance.
    -- Lý do: LCID 1066 (Vietnamese) không có sẵn trên mọi SQL Server build (cần Vietnamese FTS language pack);
    --   1068 thực ra là Azerbaijani (Latin), không phải Vietnamese.
    -- Tên HTTM tiếng Việt vẫn search OK ở character level với tokenizer mặc định.
    CREATE FULLTEXT INDEX ON dbo.HttmFacilities (Name)
        KEY INDEX PK_HttmFacilities
        ON FT_Httm
        WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM);
END;
GO
