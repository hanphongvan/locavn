using ClosedXML.Excel;
using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Services;

/// <summary>
/// Xuất danh sách đề xuất cập nhật hạ tầng (submissions) ra file Excel <c>.xlsx</c> — 1 sheet "DeXuat".
/// Dữ liệu là TOÀN BỘ dòng khớp filter hiện tại (không phân trang), do service truyền vào.
/// </summary>
public sealed class HttmSubmissionExcelExporter
{
    private static readonly IReadOnlyDictionary<string, string> HttmTypeNames = new Dictionary<string, string>
    {
        ["market_grade1"] = "Chợ hạng I",
        ["market_grade2"] = "Chợ hạng II",
        ["market_grade3"] = "Chợ hạng III",
        ["supermarket_1"] = "Siêu thị hạng I",
        ["supermarket_2"] = "Siêu thị hạng II",
        ["supermarket_3"] = "Siêu thị hạng III",
        ["mall"] = "Trung tâm thương mại",
        ["wholesale_market"] = "Chợ đầu mối",
        ["convenience_store"] = "Cửa hàng tiện lợi / Bán lẻ hiện đại",
        ["other"] = "Loại hình khác",
    };

    public byte[] Build(IReadOnlyList<HttmSubmissionListItemDto> items)
    {
        using var wb = new XLWorkbook();
        var ws = wb.AddWorksheet("DeXuat");

        string[] headers =
        [
            "STT",
            "Gửi lúc",
            "Loại",
            "Trạng thái",
            "Tên cơ sở",
            "Loại hình HTTM",
            "Mã tỉnh",
            "Mã xã/phường",
            "Người gửi",
            "Số điện thoại",
            "Email",
            "Người duyệt",
            "Duyệt lúc",
            "Mã đề xuất",
        ];

        for (var i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(1, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.LightBlue;
            cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        }

        ws.SheetView.FreezeRows(1);

        for (var i = 0; i < items.Count; i++)
        {
            var r = items[i];
            var row = i + 2;
            ws.Cell(row, 1).Value = i + 1;
            ws.Cell(row, 2).Value = r.SubmittedAt.DateTime;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/mm/yyyy hh:mm";
            ws.Cell(row, 3).Value = SubmissionTypeName(r.SubmissionType);
            ws.Cell(row, 4).Value = StatusName(r.Status);
            ws.Cell(row, 5).Value = r.Name;
            ws.Cell(row, 6).Value = HttmTypeName(r.HttmType);
            ws.Cell(row, 7).Value = r.ProvinceCode ?? string.Empty;
            ws.Cell(row, 8).Value = r.WardCode ?? string.Empty;
            ws.Cell(row, 9).Value = r.SubmitterName;
            // Để text giữ số 0 đầu của SĐT
            ws.Cell(row, 10).Value = r.SubmitterPhone;
            ws.Cell(row, 10).Style.NumberFormat.Format = "@";
            ws.Cell(row, 11).Value = r.SubmitterEmail ?? string.Empty;
            ws.Cell(row, 12).Value = r.ReviewedBy ?? string.Empty;
            if (r.ReviewedAt is { } reviewedAt)
            {
                ws.Cell(row, 13).Value = reviewedAt.DateTime;
                ws.Cell(row, 13).Style.DateFormat.Format = "dd/mm/yyyy hh:mm";
            }

            ws.Cell(row, 14).Value = r.Id.ToString();
        }

        ws.Columns().AdjustToContents(1, headers.Length);
        // AdjustToContents có thể cho cột Tên quá rộng — kẹp lại
        if (ws.Column(5).Width > 50) ws.Column(5).Width = 50;

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    /// <summary>
    /// Xuất CHI TIẾT 1 đề xuất ra Excel — 1 sheet: khối thông tin chung + người gửi,
    /// bảng so sánh Hiện tại vs Đề xuất (highlight dòng thay đổi), danh sách giấy phép + ảnh đính kèm.
    /// </summary>
    public byte[] BuildDetail(HttmSubmissionDetailDto d)
    {
        using var wb = new XLWorkbook();
        var ws = wb.AddWorksheet("ChiTiet");
        ws.Column(1).Width = 24;
        ws.Column(2).Width = 48;
        ws.Column(3).Width = 48;
        ws.Column(4).Width = 12;

        var row = 1;

        // ===== Khối thông tin chung =====
        WriteSectionTitle(ws, row++, "THÔNG TIN ĐỀ XUẤT");
        row = WriteKeyValue(ws, row, "Mã đề xuất", d.Id.ToString());
        row = WriteKeyValue(ws, row, "Loại", SubmissionTypeName(d.SubmissionType));
        row = WriteKeyValue(ws, row, "Trạng thái", StatusName(d.Status));
        row = WriteKeyValue(ws, row, "Gửi lúc", d.SubmittedAt.DateTime.ToString("dd/MM/yyyy HH:mm"));
        row = WriteKeyValue(ws, row, "IP người gửi", d.SubmitterIp);
        if (!string.IsNullOrEmpty(d.ReviewedBy))
            row = WriteKeyValue(ws, row, "Người duyệt", d.ReviewedBy);
        if (d.ReviewedAt is { } reviewedAt)
            row = WriteKeyValue(ws, row, "Duyệt lúc", reviewedAt.DateTime.ToString("dd/MM/yyyy HH:mm"));
        if (!string.IsNullOrEmpty(d.ReviewNotes))
            row = WriteKeyValue(ws, row, "Ghi chú duyệt", d.ReviewNotes);
        if (d.MergedFacilityId is { } mfid)
            row = WriteKeyValue(ws, row, "Facility đã merge", mfid.ToString());
        row++;

        // ===== Người gửi =====
        WriteSectionTitle(ws, row++, "NGƯỜI GỬI");
        row = WriteKeyValue(ws, row, "Họ tên", d.Submitter.Name);
        row = WriteKeyValue(ws, row, "Số điện thoại", d.Submitter.Phone);
        row = WriteKeyValue(ws, row, "Email", d.Submitter.Email);
        if (!string.IsNullOrEmpty(d.Submitter.Notes))
            row = WriteKeyValue(ws, row, "Ghi chú gửi cán bộ", d.Submitter.Notes);
        row++;

        // ===== Bảng so sánh =====
        WriteSectionTitle(ws, row++, "SO SÁNH DỮ LIỆU (dòng tô vàng = thay đổi)");
        var headerRow = row++;
        string[] diffHeaders = ["Trường", "Hiện tại", "Đề xuất", "Thay đổi"];
        for (var i = 0; i < diffHeaders.Length; i++)
        {
            var cell = ws.Cell(headerRow, i + 1);
            cell.Value = diffHeaders[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.LightBlue;
            cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        }

        var p = d.Proposed;
        var c = d.Current;
        var fields = new (string Label, string? Current, string? Proposed)[]
        {
            ("Tên cơ sở", c?.Name, p.Name),
            ("Loại hình", HttmTypeName(c?.HttmType), HttmTypeName(p.HttmType)),
            ("Trạng thái", c?.Status, p.Status),
            ("Mã tỉnh", c?.ProvinceCode, p.ProvinceCode),
            ("Mã xã/phường", c?.WardCode, p.WardCode),
            ("Địa chỉ chi tiết", c?.AddressDetail, p.AddressDetail),
            ("Vĩ độ", Num(c?.Lat), Num(p.Lat)),
            ("Kinh độ", Num(c?.Lng), Num(p.Lng)),
            ("Độ chính xác GPS", c?.GpsAccuracy, p.GpsAccuracy),
            ("Diện tích đất", Num(c?.LandArea), Num(p.LandArea)),
            ("Diện tích sàn", Num(c?.FloorArea), Num(p.FloorArea)),
            ("Số tầng", Num(c?.Floors), Num(p.Floors)),
            ("Số gian hàng", Num(c?.StallCount), Num(p.StallCount)),
            ("Năm đưa vào HĐ", Num(c?.YearEstablished), Num(p.YearEstablished)),
            ("Năm cải tạo", Num(c?.YearRenovated), Num(p.YearRenovated)),
            ("Chủ đầu tư", c?.OwnerName, p.OwnerName),
            ("Đơn vị quản lý", c?.OperatorName, p.OperatorName),
            ("Tỷ lệ lấp đầy", Num(c?.FillRate), Num(p.FillRate)),
            ("Số tiểu thương", Num(c?.VendorCount), Num(p.VendorCount)),
            ("Giá thuê TB", Num(c?.AvgRentPrice), Num(p.AvgRentPrice)),
            ("Doanh thu năm", Num(c?.AnnualRevenue), Num(p.AnnualRevenue)),
            ("Có điện dự phòng", Bool(c?.HasBackupPower), Bool(p.HasBackupPower)),
            ("Có PCCC", Bool(c?.HasFireProtection), Bool(p.HasFireProtection)),
            ("Chất lượng công trình", c?.BuildingQuality, p.BuildingQuality),
            ("Ghi chú", c?.Notes, p.Notes),
        };

        foreach (var f in fields)
        {
            var changed = f.Current != f.Proposed;
            ws.Cell(row, 1).Value = f.Label;
            ws.Cell(row, 1).Style.Font.Bold = true;
            ws.Cell(row, 2).Value = f.Current ?? string.Empty;
            ws.Cell(row, 3).Value = f.Proposed ?? string.Empty;
            ws.Cell(row, 4).Value = changed ? "✓" : string.Empty;
            ws.Cell(row, 4).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            if (changed)
            {
                ws.Cell(row, 2).Style.Fill.BackgroundColor = XLColor.LightYellow;
                ws.Cell(row, 3).Style.Fill.BackgroundColor = XLColor.LightYellow;
            }

            row++;
        }

        row++;

        // ===== Giấy phép =====
        if (d.ProposedLicenses.Count > 0)
        {
            WriteSectionTitle(ws, row++, $"GIẤY PHÉP PHÁP LÝ ĐỀ XUẤT ({d.ProposedLicenses.Count})");
            string[] licHeaders = ["Loại giấy phép", "Số GP / Cấp bởi", "Ngày cấp / Hết hạn", "Tệp"];
            for (var i = 0; i < licHeaders.Length; i++)
            {
                var cell = ws.Cell(row, i + 1);
                cell.Value = licHeaders[i];
                cell.Style.Font.Bold = true;
                cell.Style.Fill.BackgroundColor = XLColor.LightBlue;
            }

            row++;
            foreach (var lic in d.ProposedLicenses)
            {
                ws.Cell(row, 1).Value = LicenseTypeName(lic.LicenseType);
                ws.Cell(row, 2).Value = Join(lic.LicenseNumber, lic.IssuedBy);
                ws.Cell(row, 3).Value = Join(DateOnlyStr(lic.IssuedDate), DateOnlyStr(lic.ExpiryDate));
                ws.Cell(row, 4).Value = lic.FileUrl ?? string.Empty;
                row++;
            }

            row++;
        }

        // ===== Ảnh =====
        if (d.ProposedImages.Count > 0)
        {
            WriteSectionTitle(ws, row++, $"HÌNH ẢNH ĐỀ XUẤT ({d.ProposedImages.Count})");
            string[] imgHeaders = ["Loại ảnh", "Chú thích", "Đường dẫn"];
            for (var i = 0; i < imgHeaders.Length; i++)
            {
                var cell = ws.Cell(row, i + 1);
                cell.Value = imgHeaders[i];
                cell.Style.Font.Bold = true;
                cell.Style.Fill.BackgroundColor = XLColor.LightBlue;
            }

            row++;
            foreach (var img in d.ProposedImages)
            {
                ws.Cell(row, 1).Value = ImageTypeName(img.ImageType);
                ws.Cell(row, 2).Value = img.Caption ?? string.Empty;
                ws.Cell(row, 3).Value = img.Url;
                row++;
            }
        }

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    private static void WriteSectionTitle(IXLWorksheet ws, int row, string title)
    {
        var cell = ws.Cell(row, 1);
        cell.Value = title;
        cell.Style.Font.Bold = true;
        cell.Style.Font.FontSize = 12;
        cell.Style.Fill.BackgroundColor = XLColor.LightGray;
        ws.Range(row, 1, row, 4).Merge();
    }

    private static int WriteKeyValue(IXLWorksheet ws, int row, string key, string? value)
    {
        ws.Cell(row, 1).Value = key;
        ws.Cell(row, 1).Style.Font.Bold = true;
        ws.Cell(row, 2).Value = value ?? string.Empty;
        ws.Range(row, 2, row, 4).Merge();
        return row + 1;
    }

    /// <summary>Định dạng giá trị số (giống FE: null/rỗng → trống, số → chuỗi invariant).</summary>
    private static string? Num(double? v) => v?.ToString(System.Globalization.CultureInfo.InvariantCulture);
    private static string? Num(decimal? v) => v?.ToString(System.Globalization.CultureInfo.InvariantCulture);
    private static string? Num(short? v) => v?.ToString(System.Globalization.CultureInfo.InvariantCulture);
    private static string? Num(int? v) => v?.ToString(System.Globalization.CultureInfo.InvariantCulture);
    private static string? Bool(bool? v) => v is null ? null : v.Value ? "Có" : "Không";

    private static string DateOnlyStr(DateOnly? d) => d?.ToString("dd/MM/yyyy") ?? string.Empty;

    private static string Join(string? a, string? b)
    {
        var parts = new[] { a, b }.Where(s => !string.IsNullOrWhiteSpace(s));
        return string.Join(" / ", parts);
    }

    private static string LicenseTypeName(string? code) => code switch
    {
        "business" => "Giấy phép kinh doanh",
        "fire_protection" => "Giấy chứng nhận PCCC",
        "food_safety" => "Giấy chứng nhận ATVSTP",
        _ => "Khác",
    };

    private static string ImageTypeName(string? code) => code switch
    {
        "exterior" => "Mặt ngoài",
        "interior" => "Bên trong",
        "infrastructure" => "Hạ tầng kỹ thuật",
        _ => "Khác",
    };

    private static string SubmissionTypeName(string type) => type switch
    {
        "create_new" => "Tạo mới",
        "update" => "Cập nhật",
        _ => type,
    };

    private static string StatusName(string status) => status switch
    {
        "pending" => "Chờ duyệt",
        "approved" => "Đã duyệt",
        "rejected" => "Từ chối",
        _ => status,
    };

    private static string HttmTypeName(string? code) =>
        string.IsNullOrEmpty(code) ? string.Empty
        : HttmTypeNames.TryGetValue(code, out var name) ? name
        : code;
}
