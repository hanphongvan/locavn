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
    -- LCID 1068 = Vietnamese (Windows)
    CREATE FULLTEXT INDEX ON dbo.HttmFacilities (Name LANGUAGE 1068)
        KEY INDEX PK_HttmFacilities
        ON FT_Httm
        WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM);
END;
GO
