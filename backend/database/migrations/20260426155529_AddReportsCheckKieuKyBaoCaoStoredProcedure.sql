-- Mirrors EF migration 20260426155529_AddReportsCheckKieuKyBaoCaoStoredProcedure (for manual DBA deploys).

IF OBJECT_ID(N'dbo.sp_Reports_CheckKieuKyBaoCaoExists', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Reports_CheckKieuKyBaoCaoExists;
GO

CREATE PROCEDURE dbo.sp_Reports_CheckKieuKyBaoCaoExists
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CAST(
               CASE
                   WHEN EXISTS (SELECT 1 FROM dbo.DM_KieuKyBaoCao WHERE Id = @Id) THEN 1
                   ELSE 0
               END AS BIT) AS [Exists];
END;
GO
