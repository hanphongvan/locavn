-- HTTM Phase 1 — Sửa SP sp_Httm_Facility_GetAuditLogs: trả thêm cột PerformedByName
-- (DisplayName / UserName từ AspNetUsers) để tab "Lịch sử thay đổi" ở /httm/:id hiển thị
-- tên thay vì raw GUID. Fallback: PerformedByName = PerformedBy nếu không join được.

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_GetAuditLogs
    @FacilityId UNIQUEIDENTIFIER,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ps INT = CASE
        WHEN @PageSize < 1 THEN 20
        WHEN @PageSize > 100 THEN 100
        ELSE @PageSize
    END;
    DECLARE @Pg INT = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    DECLARE @Off BIGINT = CAST(@Pg - 1 AS BIGINT) * CAST(@Ps AS BIGINT);

    SELECT
        COUNT_BIG(*) OVER () AS TotalCount,
        a.Id,
        a.FacilityId,
        a.Action,
        a.ChangedFields,
        a.PerformedBy,
        COALESCE(NULLIF(LTRIM(RTRIM(u.DisplayName)), N''),
                 NULLIF(LTRIM(RTRIM(u.UserName)), N''),
                 a.PerformedBy)              AS PerformedByName,
        a.PerformedAt,
        a.IpAddress,
        a.UserAgent
    FROM dbo.HttmAuditLogs AS a
    LEFT JOIN dbo.AspNetUsers AS u
        ON u.Id = a.PerformedBy
    WHERE a.FacilityId = @FacilityId
    ORDER BY a.PerformedAt DESC, a.Id DESC
    OFFSET @Off ROWS FETCH NEXT @Ps ROWS ONLY;
END;
GO
