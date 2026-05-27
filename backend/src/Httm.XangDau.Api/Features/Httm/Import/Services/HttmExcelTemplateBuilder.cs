using ClosedXML.Excel;
using Httm.XangDau.Api.Features.Httm.Import.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Import.Services;

/// <summary>
/// Sinh file Excel mẫu <c>.xlsx</c> cho import HTTM. Layout (27 cột — đã bỏ Mã huyện vì sau 2025 VN bỏ cấp huyện):
/// 3 sheet — <c>DanhSach</c> (form data), <c>DanhMuc</c> (code lookup + named ranges cho dropdown), <c>HuongDan</c> (10 quy tắc).
/// Cột <c>Mã tỉnh</c> được pre-fill mã tỉnh của user khi user là cán bộ Sở.
/// 6 cột enum dùng data validation dropdown từ named range trên Sheet DanhMuc.
/// </summary>
public sealed class HttmExcelTemplateBuilder
{
    /// <summary>Số dòng dữ liệu được mở dropdown sẵn (validation range A2..A<c>DataValidationMaxRows</c>).</summary>
    private const int DataValidationMaxRows = 1001;

    public byte[] Build(HttmTemplateBuildInput input)
    {
        using var wb = new XLWorkbook();

        var danhMuc = BuildDanhMucSheet(wb, input);
        BuildDanhSachSheet(wb, input, danhMuc);
        BuildHuongDanSheet(wb);

        // Đặt DanhSach làm sheet active khi mở file
        wb.Worksheet("DanhSach").SetTabActive();

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    private static IXLWorksheet BuildDanhMucSheet(XLWorkbook wb, HttmTemplateBuildInput input)
    {
        var ws = wb.AddWorksheet("DanhMuc");

        // 5 bảng danh mục đặt song song theo cột để dễ define named range:
        // A:B  = httm_types
        // D:E  = statuses
        // G:H  = building_quality
        // J:K  = gps_accuracy
        // M:N  = provinces
        // P:Q  = wards (của tỉnh user — có thể rỗng với national user)

        WriteLookup(ws, startCol: 1, header: "Mã loại hình HTTM", header2: "Tên tiếng Việt",
            rows: new (string, string)[]
            {
                ("market_grade1", "Chợ hạng I"),
                ("market_grade2", "Chợ hạng II"),
                ("market_grade3", "Chợ hạng III"),
                ("supermarket_1", "Siêu thị hạng I"),
                ("supermarket_2", "Siêu thị hạng II"),
                ("supermarket_3", "Siêu thị hạng III"),
                ("mall", "Trung tâm thương mại"),
                ("wholesale_market", "Chợ đầu mối"),
                ("convenience_store", "Cửa hàng tiện lợi / Bán lẻ hiện đại"),
                ("other", "Loại hình khác"),
            },
            namedRange: "lst_httm_types",
            workbook: wb);

        WriteLookup(ws, startCol: 4, header: "Mã trạng thái", header2: "Mô tả",
            rows: new (string, string)[]
            {
                ("active", "Đang hoạt động"),
                ("suspended", "Tạm ngừng hoạt động"),
                ("under_construction", "Đang xây dựng / cải tạo"),
                ("closed", "Đã đóng cửa"),
            },
            namedRange: "lst_statuses",
            workbook: wb);

        WriteLookup(ws, startCol: 7, header: "Mã chất lượng", header2: "Mô tả",
            rows: new (string, string)[]
            {
                ("good", "Tốt"),
                ("average", "Trung bình"),
                ("degraded", "Xuống cấp"),
                ("needs_renovation", "Cần cải tạo"),
            },
            namedRange: "lst_quality",
            workbook: wb);

        WriteLookup(ws, startCol: 10, header: "Mã GPS", header2: "Mô tả",
            rows: new (string, string)[]
            {
                ("exact", "Chính xác"),
                ("approximate", "Xấp xỉ"),
                ("none", "Không có"),
            },
            namedRange: "lst_gps",
            workbook: wb);

        WriteLookup(ws, startCol: 13, header: "Mã tỉnh", header2: "Tên tỉnh",
            rows: input.Provinces.Select(p => (p.Code, p.Name)).ToList(),
            namedRange: "lst_provinces",
            workbook: wb);

        // Wards có thể rỗng — vẫn tạo named range với 1 placeholder để dropdown không lỗi
        var wards = input.Wards.Count > 0
            ? input.Wards.Select(w => (w.Code, w.Name)).ToList()
            : new List<(string, string)> { ("", "(Không có — chọn tỉnh trước)") };
        WriteLookup(ws, startCol: 16, header: "Mã xã/phường", header2: "Tên xã/phường",
            rows: wards,
            namedRange: "lst_wards",
            workbook: wb);

        ws.Columns().AdjustToContents(1, 20);
        return ws;
    }

    private static void WriteLookup(
        IXLWorksheet ws,
        int startCol,
        string header,
        string header2,
        IReadOnlyList<(string Code, string Name)> rows,
        string namedRange,
        XLWorkbook workbook)
    {
        ws.Cell(1, startCol).Value = header;
        ws.Cell(1, startCol + 1).Value = header2;
        ws.Cell(1, startCol).Style.Font.Bold = true;
        ws.Cell(1, startCol + 1).Style.Font.Bold = true;
        ws.Cell(1, startCol).Style.Fill.BackgroundColor = XLColor.LightBlue;
        ws.Cell(1, startCol + 1).Style.Fill.BackgroundColor = XLColor.LightBlue;

        for (var i = 0; i < rows.Count; i++)
        {
            ws.Cell(i + 2, startCol).Value = rows[i].Code;
            ws.Cell(i + 2, startCol + 1).Value = rows[i].Name;
        }

        // Named range trỏ vào cột TÊN (col + 1) — dropdown hiển thị Tên thay vì Mã.
        // Server resolve ngược Tên → Mã qua HttmImportLookups khi validate.
        var startRow = 2;
        var endRow = Math.Max(rows.Count + 1, 2);
        var nameCol = startCol + 1;
        var rangeAddress = $"DanhMuc!${GetColumnLetter(nameCol)}${startRow}:${GetColumnLetter(nameCol)}${endRow}";
        workbook.DefinedNames.Add(namedRange, rangeAddress);
    }

    private static string GetColumnLetter(int col)
    {
        // 1-based: A=1, B=2, ...
        var dividend = col;
        var name = string.Empty;
        while (dividend > 0)
        {
            var modulo = (dividend - 1) % 26;
            name = (char)('A' + modulo) + name;
            dividend = (dividend - modulo) / 26;
        }
        return name;
    }

    private static void BuildDanhSachSheet(XLWorkbook wb, HttmTemplateBuildInput input, IXLWorksheet _)
    {
        var ws = wb.AddWorksheet("DanhSach");

        // 27 cột (đã bỏ Mã huyện). (Header, Comment, Required)
        var cols = new (string Header, string Comment, bool Required)[]
        {
            ("Tên cơ sở (*)", "BẮT BUỘC. Tên đầy đủ của cơ sở HTTM. Tối đa 500 ký tự.", true),
            ("Mã loại hình (*)", "BẮT BUỘC. Chọn từ dropdown. Mô tả các mã xem Sheet 'DanhMuc'.", true),
            ("Mã tỉnh (*)", "BẮT BUỘC. Chọn từ dropdown 63 tỉnh. Cán bộ Sở: đã pre-fill mã tỉnh của bạn — vui lòng không đổi.", true),
            ("Trạng thái", "Tuỳ chọn. Chọn từ dropdown — mặc định 'active' nếu để trống.", false),
            ("Mã xã/phường", "Tuỳ chọn. Chọn từ dropdown (xã thuộc tỉnh của bạn — đã load sẵn trong Sheet 'DanhMuc').", false),
            ("Địa chỉ chi tiết", "Tuỳ chọn. Số nhà, tên đường, khu phố.", false),
            ("Vĩ độ (Lat)", "Tuỳ chọn. Số thập phân từ -90 đến 90. Phải cùng có hoặc cùng không với Kinh độ.", false),
            ("Kinh độ (Lng)", "Tuỳ chọn. Số thập phân từ -180 đến 180.", false),
            ("Độ chính xác GPS", "Tuỳ chọn. Chọn từ dropdown.", false),
            ("Diện tích đất (m²)", "Tuỳ chọn. Số dương.", false),
            ("Diện tích sàn KD (m²)", "Tuỳ chọn. Số dương.", false),
            ("Số tầng", "Tuỳ chọn. Số nguyên.", false),
            ("Số gian hàng", "Tuỳ chọn. Số nguyên.", false),
            ("DT gian hàng TB (m²)", "Tuỳ chọn. Số dương.", false),
            ("Số chỗ đậu xe", "Tuỳ chọn. Số nguyên.", false),
            ("Năm đưa vào hoạt động", "Tuỳ chọn. Năm 4 chữ số, từ 1900 đến năm hiện tại + 5.", false),
            ("Năm cải tạo gần nhất", "Tuỳ chọn. Năm 4 chữ số.", false),
            ("Chủ đầu tư", "Tuỳ chọn. Tối đa 500 ký tự.", false),
            ("Đơn vị quản lý", "Tuỳ chọn. Tối đa 500 ký tự.", false),
            ("Tỷ lệ lấp đầy (%)", "Tuỳ chọn. Từ 0 đến 100.", false),
            ("Số tiểu thương / hộ KD", "Tuỳ chọn. Số nguyên.", false),
            ("Giá thuê TB (triệu/m²/tháng)", "Tuỳ chọn — chỉ ADMIN/HTTM_ADMIN/BCT_STAFF mới được nhập (cán bộ Sở sẽ bị bỏ qua).", false),
            ("Doanh thu năm (tỷ VND)", "Tuỳ chọn — chỉ ADMIN/HTTM_ADMIN/BCT_STAFF mới được nhập.", false),
            ("Có điện dự phòng", "Tuỳ chọn. 1=Có, 0=Không.", false),
            ("Có PCCC", "Tuỳ chọn. 1=Có, 0=Không.", false),
            ("Chất lượng công trình", "Tuỳ chọn. Chọn từ dropdown.", false),
            ("Ghi chú", "Tuỳ chọn.", false),
        };

        // Row 1 = header
        for (var i = 0; i < cols.Length; i++)
        {
            var cell = ws.Cell(1, i + 1);
            cell.Value = cols[i].Header;
            cell.Style.Font.Bold = true;
            cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            cell.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            cell.Style.Alignment.WrapText = true;
            cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            cell.Style.Fill.BackgroundColor = cols[i].Required ? XLColor.LightYellow : XLColor.White;
            cell.CreateComment().AddText(cols[i].Comment);
        }

        ws.Row(1).Height = 36;
        ws.SheetView.FreezeRows(1);

        // 2 sample rows (italic gray — placeholder, user xoá trước khi import).
        // Cell value dùng TÊN (như dropdown) để khớp hành vi: user chọn từ dropdown sẽ ra tên.
        var defaultProvinceName = ResolveDefaultProvinceName(input);
        AddSampleRow(ws, row: 2, sample: new[]
        {
            "Chợ Đồng Xuân (VÍ DỤ — xoá trước khi import)",  // 1. Tên cơ sở
            "Chợ hạng I",                                      // 2. Loại hình
            defaultProvinceName,                                // 3. Mã tỉnh (Tên)
            "Đang hoạt động",                                  // 4. Trạng thái
            "",                                                 // 5. Mã xã/phường (để user chọn)
            "Hàng Khoai, Hoàn Kiếm",                            // 6. Địa chỉ chi tiết
            "21.0379",                                          // 7. Vĩ độ
            "105.8466",                                         // 8. Kinh độ
            "Chính xác",                                        // 9. Độ chính xác GPS
            "6500",                                             // 10. Diện tích đất
            "5800",                                             // 11. Diện tích sàn
            "3",                                                // 12. Số tầng
            "2300",                                             // 13. Số gian hàng
            "2.5",                                              // 14. DT gian hàng TB
            "120",                                              // 15. Số chỗ đậu xe
            "1900",                                             // 16. Năm đưa vào hoạt động
            "2015",                                             // 17. Năm cải tạo
            "UBND TP. Hà Nội",                                  // 18. Chủ đầu tư
            "Cty CP Đồng Xuân",                                 // 19. Đơn vị quản lý
            "92",                                               // 20. Tỷ lệ lấp đầy
            "2300",                                             // 21. Số tiểu thương
            "",                                                 // 22. Giá thuê TB (sensitive)
            "",                                                 // 23. Doanh thu năm (sensitive)
            "1",                                                // 24. Có điện dự phòng
            "1",                                                // 25. Có PCCC
            "Trung bình",                                       // 26. Chất lượng công trình
            "Chợ đầu mối truyền thống",                        // 27. Ghi chú
        });

        AddSampleRow(ws, row: 3, sample: new[]
        {
            "Siêu thị Co.opmart (VÍ DỤ)",   // 1. Tên cơ sở
            "Siêu thị hạng I",               // 2. Loại hình
            defaultProvinceName,              // 3. Mã tỉnh (Tên)
            "Đang hoạt động",                // 4. Trạng thái
            "",                               // 5. Mã xã/phường
            "189C Cống Quỳnh",               // 6. Địa chỉ chi tiết
            "10.7676",                        // 7. Vĩ độ
            "106.6884",                       // 8. Kinh độ
            "Chính xác",                      // 9. Độ chính xác GPS
            "8200",                           // 10. Diện tích đất
            "7500",                           // 11. Diện tích sàn
            "5",                              // 12. Số tầng
            "",                               // 13. Số gian hàng
            "",                               // 14. DT gian hàng TB
            "350",                            // 15. Số chỗ đậu xe
            "1996",                           // 16. Năm đưa vào hoạt động
            "2018",                           // 17. Năm cải tạo
            "Saigon Co.op",                  // 18. Chủ đầu tư
            "Saigon Co.op",                  // 19. Đơn vị quản lý
            "",                               // 20. Tỷ lệ lấp đầy
            "",                               // 21. Số tiểu thương
            "",                               // 22. Giá thuê TB (sensitive)
            "",                               // 23. Doanh thu năm (sensitive)
            "1",                              // 24. Có điện dự phòng
            "1",                              // 25. Có PCCC
            "Tốt",                            // 26. Chất lượng công trình
            "",                               // 27. Ghi chú
        });

        // Data validation dropdown qua named range (chạy từ row 2 → row 1001 — đủ cho 1000 dòng dữ liệu)
        AddDropdownValidation(ws, col: 2, namedRange: "lst_httm_types");
        AddDropdownValidation(ws, col: 3, namedRange: "lst_provinces");
        AddDropdownValidation(ws, col: 4, namedRange: "lst_statuses");
        AddDropdownValidation(ws, col: 5, namedRange: "lst_wards");
        AddDropdownValidation(ws, col: 9, namedRange: "lst_gps");
        AddDropdownValidation(ws, col: 26, namedRange: "lst_quality");

        // Column widths heuristic
        for (var i = 1; i <= cols.Length; i++)
        {
            var letter = GetColumnLetter(i);
            ws.Column(letter).Width = i == 1 ? 32 : (cols[i - 1].Required ? 16 : 14);
        }
    }

    private static string ResolveDefaultProvinceName(HttmTemplateBuildInput input)
    {
        if (string.IsNullOrWhiteSpace(input.DefaultProvinceCode))
            return input.Provinces.Count > 0 ? input.Provinces[0].Name : "Thành phố Hà Nội";
        var match = input.Provinces.FirstOrDefault(p => string.Equals(p.Code, input.DefaultProvinceCode, StringComparison.Ordinal));
        return string.IsNullOrEmpty(match.Name) ? input.DefaultProvinceCode! : match.Name;
    }

    private static void AddSampleRow(IXLWorksheet ws, int row, string[] sample)
    {
        for (var c = 0; c < sample.Length; c++)
        {
            var cell = ws.Cell(row, c + 1);
            cell.Value = sample[c];
            cell.Style.Font.Italic = true;
            cell.Style.Font.FontColor = XLColor.Gray;
        }
    }

    private static void AddDropdownValidation(IXLWorksheet ws, int col, string namedRange)
    {
        var letter = GetColumnLetter(col);
        var range = ws.Range($"{letter}2:{letter}{DataValidationMaxRows}");
        var validation = range.CreateDataValidation();
        validation.List($"={namedRange}", inCellDropdown: true);
        validation.IgnoreBlanks = true;
        validation.ShowErrorMessage = false; // chỉ warning, không block paste
    }

    private static void BuildHuongDanSheet(XLWorkbook wb)
    {
        var ws = wb.AddWorksheet("HuongDan");

        var lines = new[]
        {
            "HƯỚNG DẪN IMPORT HỒ SƠ HTTM",
            "",
            "1. Tải file mẫu này về máy, không đổi tên cột (header).",
            "2. Cột bôi vàng là BẮT BUỘC: Tên cơ sở, Mã loại hình, Mã tỉnh.",
            "3. Các cột Mã loại hình / Mã tỉnh / Mã xã / Trạng thái / GPS / Chất lượng — bấm vào ô để chọn từ dropdown.",
            "4. Vĩ độ + Kinh độ: phải cùng có hoặc cùng không. Nếu có, cùng nằm trong dải hợp lệ (-90..90, -180..180).",
            "5. Số tối đa 1000 dòng / 1 lần import. File phải ≤ 10MB.",
            "6. Hệ thống sẽ kiểm tra trùng theo (Tên + Mã tỉnh + Mã xã) — dòng trùng sẽ bị BỎ QUA, không cập nhật.",
            "7. Cán bộ Sở: Mã tỉnh đã pre-fill — không đổi. Danh sách xã trong dropdown chỉ chứa xã của tỉnh bạn quản lý.",
            "8. Trường nhạy cảm (Giá thuê TB, Doanh thu năm): chỉ Admin / HTTM Admin / Cán bộ BCT mới được nhập.",
            "9. Xoá 2 dòng VÍ DỤ ở Sheet 'DanhSach' trước khi import.",
            "10. Sau khi upload, hệ thống sẽ hiển thị preview dòng hợp lệ và danh sách lỗi (nếu có) để bạn xem trước khi xác nhận.",
        };

        for (var i = 0; i < lines.Length; i++)
        {
            var cell = ws.Cell(i + 1, 1);
            cell.Value = lines[i];
            if (i == 0)
            {
                cell.Style.Font.Bold = true;
                cell.Style.Font.FontSize = 14;
            }
        }

        ws.Column(1).Width = 110;
    }
}
