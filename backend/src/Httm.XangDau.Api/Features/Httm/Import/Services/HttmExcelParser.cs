using System.Globalization;
using ClosedXML.Excel;
using Httm.XangDau.Api.Features.Httm.Import.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Import.Services;

/// <summary>
/// Đọc file Excel theo template <c>HttmExcelTemplateBuilder</c> + validate kiểu dữ liệu / dải số.
/// Các cột enum (HttmType, Status, Quality, GPS, Province, Ward) lưu RAW TEXT (Tên hoặc Mã do user chọn);
/// <see cref="HttmImportService"/> sẽ resolve về Code chuẩn qua <see cref="HttmImportLookups"/>.
/// </summary>
public sealed class HttmExcelParser
{
    /// <summary>Số dòng tối đa cho phép trên 1 file (theo decision của user).</summary>
    public const int MaxRows = 1000;

    /// <summary>Kết quả parse 1 file.</summary>
    public sealed class ParseResult
    {
        public List<HttmImportRowDto> ValidRows { get; } = [];
        public List<HttmImportRowErrorDto> Errors { get; } = [];
        public int TotalDataRows { get; set; }
        public string? FileLevelError { get; set; }
    }

    public ParseResult Parse(Stream xlsxStream)
    {
        var result = new ParseResult();
        using var wb = new XLWorkbook(xlsxStream);
        var ws = wb.Worksheets.FirstOrDefault(w =>
            string.Equals(w.Name, "DanhSach", StringComparison.OrdinalIgnoreCase))
            ?? wb.Worksheet(1);

        if (ws is null)
        {
            result.FileLevelError = "Không tìm thấy sheet dữ liệu (DanhSach).";
            return result;
        }

        var range = ws.RangeUsed();
        if (range is null || range.RowCount() < 2)
        {
            result.FileLevelError = "File không có dữ liệu (chỉ có header).";
            return result;
        }

        var dataRows = range.RowCount() - 1; // Trừ header
        if (dataRows > MaxRows)
        {
            result.FileLevelError = $"File vượt giới hạn {MaxRows} dòng (hiện {dataRows}). Vui lòng chia nhỏ.";
            return result;
        }

        result.TotalDataRows = dataRows;

        // Iterate data rows (row 2..end).
        var lastRow = ws.LastRowUsed()?.RowNumber() ?? 1;
        for (var r = 2; r <= lastRow; r++)
        {
            // Bỏ qua dòng trống hoàn toàn.
            if (IsRowBlank(ws, r))
            {
                continue;
            }

            var row = ParseRow(ws, r, result.Errors);
            if (row is not null)
            {
                result.ValidRows.Add(row);
            }
        }

        return result;
    }

    private static bool IsRowBlank(IXLWorksheet ws, int r)
    {
        // 27 cột — đã bỏ cột "Mã huyện" (Việt Nam sau 2025 bỏ cấp huyện).
        for (var c = 1; c <= 27; c++)
        {
            var v = ws.Cell(r, c).GetString();
            if (!string.IsNullOrWhiteSpace(v))
                return false;
        }
        return true;
    }

    private static HttmImportRowDto? ParseRow(IXLWorksheet ws, int r, List<HttmImportRowErrorDto> errors)
    {
        var errCountBefore = errors.Count;

        string? GetText(int c)
        {
            var v = ws.Cell(r, c).GetString().Trim();
            return v.Length == 0 ? null : v;
        }

        double? GetDouble(int c, string col)
        {
            var s = GetText(c);
            if (s is null) return null;
            if (!double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)
                && !double.TryParse(s, NumberStyles.Any, new CultureInfo("vi-VN"), out v))
            {
                errors.Add(new() { RowNumber = r, Column = col, Message = $"Không phải số: '{s}'." });
                return null;
            }
            return v;
        }

        decimal? GetDecimal(int c, string col)
        {
            var d = GetDouble(c, col);
            return d is null ? null : (decimal)d;
        }

        int? GetInt(int c, string col)
        {
            var d = GetDouble(c, col);
            return d is null ? null : (int)Math.Round(d.Value);
        }

        short? GetShort(int c, string col)
        {
            var d = GetDouble(c, col);
            return d is null ? null : (short)Math.Round(d.Value);
        }

        bool? GetBool(int c, string col)
        {
            var s = GetText(c);
            if (s is null) return null;
            if (s is "1" or "true" or "True" or "TRUE" or "Có" or "có" or "X" or "x") return true;
            if (s is "0" or "false" or "False" or "FALSE" or "Không" or "không" or "") return false;
            errors.Add(new() { RowNumber = r, Column = col, Message = $"Boolean phải là 1/0: '{s}'." });
            return null;
        }

        // Layout 27 cột — đã bỏ Mã huyện (post-2025 VN bỏ cấp huyện).
        // Các trường enum (HttmType, Status, GpsAccuracy, BuildingQuality, ProvinceCode, WardCode)
        // chứa raw text (Tên hoặc Mã user chọn từ dropdown); service sẽ resolve sau qua HttmImportLookups.
        var name = GetText(1);
        var httmType = GetText(2);
        var provinceCode = GetText(3);
        var status = GetText(4);
        var wardCode = GetText(5);
        var addressDetail = GetText(6);
        var lat = GetDouble(7, "Vĩ độ");
        var lng = GetDouble(8, "Kinh độ");
        var gpsAccuracy = GetText(9);
        var landArea = GetDecimal(10, "Diện tích đất");
        var floorArea = GetDecimal(11, "Diện tích sàn");
        var floors = GetShort(12, "Số tầng");
        var stallCount = GetInt(13, "Số gian hàng");
        var avgStallArea = GetDecimal(14, "DT gian hàng TB");
        var parkingSlots = GetInt(15, "Số chỗ đậu xe");
        var yearEstablished = GetShort(16, "Năm đưa vào HĐ");
        var yearRenovated = GetShort(17, "Năm cải tạo");
        var ownerName = GetText(18);
        var operatorName = GetText(19);
        var fillRate = GetDecimal(20, "Tỷ lệ lấp đầy");
        var vendorCount = GetInt(21, "Số tiểu thương");
        var avgRentPrice = GetDecimal(22, "Giá thuê TB");
        var annualRevenue = GetDecimal(23, "Doanh thu năm");
        var hasBackupPower = GetBool(24, "Có điện dự phòng");
        var hasFireProtection = GetBool(25, "Có PCCC");
        var buildingQuality = GetText(26);
        var notes = GetText(27);
        string? districtCode = null; // Bỏ cấp huyện — luôn null. Giữ field để DTO/repo signature ổn định.

        // Required field checks
        if (string.IsNullOrWhiteSpace(name))
        {
            errors.Add(new() { RowNumber = r, Column = "Tên cơ sở", Message = "Bắt buộc." });
        }
        if (string.IsNullOrWhiteSpace(httmType))
        {
            errors.Add(new() { RowNumber = r, Column = "Mã loại hình", Message = "Bắt buộc." });
        }
        if (string.IsNullOrWhiteSpace(provinceCode))
        {
            errors.Add(new() { RowNumber = r, Column = "Mã tỉnh", Message = "Bắt buộc." });
        }

        // Range checks
        if (lat is { } latV && (latV < -90 || latV > 90))
            errors.Add(new() { RowNumber = r, Column = "Vĩ độ", Message = "Phải trong [-90, 90]." });
        if (lng is { } lngV && (lngV < -180 || lngV > 180))
            errors.Add(new() { RowNumber = r, Column = "Kinh độ", Message = "Phải trong [-180, 180]." });
        if ((lat is null) != (lng is null))
            errors.Add(new() { RowNumber = r, Column = "Vĩ độ + Kinh độ", Message = "Phải cùng có hoặc cùng không." });

        if (fillRate is { } fr && (fr < 0 || fr > 100))
            errors.Add(new() { RowNumber = r, Column = "Tỷ lệ lấp đầy", Message = "Phải trong [0, 100]." });

        var maxYear = (short)(DateTime.Now.Year + 5);
        if (yearEstablished is { } ye && (ye < 1900 || ye > maxYear))
            errors.Add(new() { RowNumber = r, Column = "Năm đưa vào HĐ", Message = $"Phải trong [1900, {maxYear}]." });
        if (yearRenovated is { } yr && (yr < 1900 || yr > maxYear))
            errors.Add(new() { RowNumber = r, Column = "Năm cải tạo", Message = $"Phải trong [1900, {maxYear}]." });

        // Negative numeric guards
        void EnsureNonNeg<T>(T? value, string col) where T : struct, IComparable<T>
        {
            if (value is { } v && v.CompareTo(default) < 0)
                errors.Add(new() { RowNumber = r, Column = col, Message = "Không được âm." });
        }
        EnsureNonNeg(landArea, "Diện tích đất");
        EnsureNonNeg(floorArea, "Diện tích sàn");
        EnsureNonNeg(floors, "Số tầng");
        EnsureNonNeg(stallCount, "Số gian hàng");
        EnsureNonNeg(avgStallArea, "DT gian hàng TB");
        EnsureNonNeg(parkingSlots, "Số chỗ đậu xe");
        EnsureNonNeg(vendorCount, "Số tiểu thương");
        EnsureNonNeg(avgRentPrice, "Giá thuê TB");
        EnsureNonNeg(annualRevenue, "Doanh thu năm");

        if (errors.Count > errCountBefore)
        {
            return null;
        }

        return new HttmImportRowDto
        {
            RowNumber = r,
            Name = name,
            HttmType = httmType,
            Status = status,
            ProvinceCode = provinceCode,
            DistrictCode = districtCode,
            WardCode = wardCode,
            AddressDetail = addressDetail,
            Lat = lat,
            Lng = lng,
            GpsAccuracy = gpsAccuracy,
            LandArea = landArea,
            FloorArea = floorArea,
            Floors = floors,
            StallCount = stallCount,
            AvgStallArea = avgStallArea,
            ParkingSlots = parkingSlots,
            YearEstablished = yearEstablished,
            YearRenovated = yearRenovated,
            OwnerName = ownerName,
            OperatorName = operatorName,
            FillRate = fillRate,
            VendorCount = vendorCount,
            AvgRentPrice = avgRentPrice,
            AnnualRevenue = annualRevenue,
            HasBackupPower = hasBackupPower,
            HasFireProtection = hasFireProtection,
            BuildingQuality = buildingQuality,
            Notes = notes,
        };
    }
}
