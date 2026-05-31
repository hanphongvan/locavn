namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// <c>GET /api/stations/{id}/v2</c> — detail cây xăng cho citizen (V2).
/// Trả về 2 result sets:
///   1. 1 row station info (DM_DonVi JOIN DM_Tinh + DM_XaPhuong).
///   2. N rows price list từ <c>StationStoreServices</c> lọc theo
///      <c>ServiceCode LIKE 'E5%' / 'E10%' / 'DIESEL%' / 'RON%'</c> (case-insensitive
///      theo collation mặc định SQL Server VN), sort theo <c>SortOrder, DisplayName</c>.
/// V1 (<c>GET /api/stations/{id}</c>) giữ nguyên cho app đã release.
/// </summary>
internal static class ApiStationDetailGetByIdV2Sql
{
    internal const string CreateProcedure =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_StationDetail_GetById_V2
            @StationId INT,
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Result set 1: thông tin station + tỉnh + xã (1 row, hoặc 0 row nếu không tồn tại).
            SELECT TOP (1)
                d.Id AS StationId,
                d.Ma AS StationCode,
                d.Ten AS StationName,
                d.DienThoai AS Phone,
                d.Email AS Email,
                COALESCE(d.DiaChiChiTiet, d.DiaChi) AS AddressLine,
                d.SoGiayPhep AS LicenseNumber,
                d.NgayCap AS LicenseDate,
                d.NgayHetHan AS LicenseExpiryDate,
                CAST(d.ViDo AS float) AS Latitude,
                CAST(d.KinhDo AS float) AS Longitude,
                t.Ma AS ProvinceCode,
                t.Ten AS ProvinceName,
                x.Ma AS WardCode,
                x.Ten AS WardName,
                x.QuanHuyenId AS DistrictId,
                d.TrangThai AS IsActive,
                d.OpenTime,
                d.CloseTime,
                d.CapTrenId AS ParentDonViId
            FROM dbo.DM_DonVi AS d
            LEFT JOIN dbo.DM_Tinh AS t ON t.Id = d.Tinh
            LEFT JOIN dbo.DM_XaPhuong AS x ON x.Id = d.Xa
            WHERE d.Id = @StationId
              AND d.CapDonViId = @RetailCapDonViId;

            -- Result set 2: danh sách giá nhiên liệu (lọc ServiceCode bắt đầu E5/E10/DIESEL/RON).
            -- Anh có thể edit pattern LIKE trực tiếp ở đây khi cần thêm/bớt nhóm fuel.
            SELECT
                s.ServiceCode,
                s.DisplayName,
                s.Price,
                s.SortOrder
            FROM dbo.StationStoreServices AS s
            WHERE s.DonViId = @StationId
              AND s.IsActive = CAST(1 AS BIT)
              AND (
                  s.ServiceCode LIKE 'E5%'
                  OR s.ServiceCode LIKE 'E10%'
                  OR s.ServiceCode LIKE 'DIESEL%'
                  OR s.ServiceCode LIKE 'RON%'
              )
            ORDER BY s.SortOrder, s.DisplayName;
        END;
        """;
}
