-- HTTM Phase 2 — Sửa SP sp_Httm_Survey_GetHistory: trả thêm cột PerformedByName
-- (DisplayName / UserName từ AspNetUsers) để giao diện /surveys/:id hiển thị "bởi <tên>"
-- thay vì raw GUID. Fallback: nếu không join được (PerformedBy không thuộc AspNetUsers)
-- thì PerformedByName = PerformedBy (giữ nguyên giá trị gốc — vẫn có ích cho audit).

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_GetHistory
    @SurveyId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        h.Id,
        h.SurveyId,
        h.FromStatus,
        h.ToStatus,
        h.Action,
        h.Notes,
        h.PerformedBy,
        COALESCE(NULLIF(LTRIM(RTRIM(u.DisplayName)), N''),
                 NULLIF(LTRIM(RTRIM(u.UserName)), N''),
                 h.PerformedBy)              AS PerformedByName,
        h.PerformedAt
    FROM dbo.HttmSurveyHistories AS h
    LEFT JOIN dbo.AspNetUsers AS u
        ON u.Id = h.PerformedBy
    WHERE h.SurveyId = @SurveyId
    ORDER BY h.PerformedAt DESC;
END;
GO
