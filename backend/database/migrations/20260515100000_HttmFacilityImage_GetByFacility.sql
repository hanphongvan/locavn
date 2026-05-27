-- HTTM — SP list ảnh theo facility, dùng cho Tab Hình ảnh trong /httm/:id.
-- Trả kèm ngày upload + UploadedBy để FE hiển thị metadata.

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityImage_GetByFacility
    @FacilityId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.Id,
        i.FacilityId,
        i.ImageUrl,
        i.ImageType,
        i.Caption,
        i.TakenDate,
        i.SortOrder,
        i.UploadedBy,
        i.CreatedAt
    FROM dbo.HttmFacilityImages AS i
    WHERE i.FacilityId = @FacilityId
    ORDER BY i.SortOrder ASC, i.CreatedAt DESC;
END;
GO
