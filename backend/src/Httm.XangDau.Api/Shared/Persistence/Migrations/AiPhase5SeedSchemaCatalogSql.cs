namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5C — Seed <c>AiSchemaCatalog</c> với 8 entity AI được phép truy vấn.
/// Section 8 của <c>docs/loca-ai-phase5.md</c>.
///
/// Mỗi entity gồm: mô tả nghiệp vụ tiếng Việt cho RAG retrieval, danh sách
/// allowedColumns/Filters/Aggregates, allowedJoins (whitelist cross-entity JOIN),
/// 4–8 sampleQuestions để embed vào Qdrant ở Phase 5D, sensitivityLevel=2 (internal).
///
/// Idempotent: DELETE WHERE EntityCode IN (Phase 5C scope) rồi INSERT. Mỗi lần INSERT
/// trigger <c>TR_AiSchemaCatalog_AfterUpsert</c> sẽ enqueue 8 row vào <c>AiReindexQueue</c>
/// để worker Python (Phase 5D) re-index Qdrant.
/// </summary>
internal static class AiPhase5SeedSchemaCatalogSql
{
    /// <summary>
    /// 8 entity:
    /// 5 head_office (inventory, price, fund_balance, import, domestic_supply)
    /// + 3 retail_station (price, inventory, rating).
    /// </summary>
    internal const string Seed =
        """
        DELETE FROM dbo.AiSchemaCatalog
        WHERE EntityCode IN (
            N'head_office_inventory',
            N'head_office_price',
            N'head_office_fund_balance',
            N'head_office_import',
            N'head_office_domestic_supply',
            N'station_price',
            N'station_inventory',
            N'station_rating'
        );

        INSERT INTO dbo.AiSchemaCatalog (
            EntityCode, DisplayName, Description, DataLayer, BaseView, PrimaryKey,
            AllowedColumnsJson, AllowedFiltersJson, AllowedAggregatesJson,
            AllowedJoinsJson, SampleQuestionsJson,
            DefaultLimit, MaxLimit, SensitivityLevel, RequiredRoleLoai, IsEnabled
        ) VALUES
        -- ==================== 1) head_office_inventory ====================
        (N'head_office_inventory',
         N'Tồn kho và nhập xuất doanh nghiệp đầu mối',
         N'Báo cáo nhập xuất tồn xăng dầu của các doanh nghiệp đầu mối (CapDonViId=235). BaoCaoId=''70CDBFE1-9004-423B-88B0-3A9AD9711A78'', kỳ tháng (KieuKyBaoCao=2), chỉ dữ liệu đã chốt (Loai=1, TrangThai=5). Có 4 đại lượng nghiệp vụ: Tồn đầu kỳ, Nhập trong kỳ, Xuất trong kỳ, Tồn cuối kỳ. Loại nhiên liệu chia theo nhóm xăng (Ma=CT2..CT7, CT18) và nhóm dầu (Ma=CT8, CT9, CT10). Loại trừ các đơn vị nhiên liệu bay.',
         N'head_office',
         N'vw_AiHeadOfficeInventory',
         N'ThongKeId',
         N'["DonViId","DonViMa","DonViTen","VungMien","TinhId","Nam","Thang","TuNgay","DenNgay","ChiTieuMa","NhomNhienLieu","TonDauKy","NhapTrongKy","XuatTrongKy","TonCuoiKy"]',
         N'["DonViId","DonViTen","VungMien","TinhId","Nam","Thang","TuNgay","DenNgay","NhomNhienLieu","ChiTieuMa"]',
         N'["SUM","AVG","MIN","MAX","COUNT"]',
         N'[{"view":"DM_Tinh","key":"TinhId = DM_Tinh.Id"}]',
         N'["Doanh nghiệp nào tồn kho xăng cao nhất tháng 5/2026?","So sánh tồn kho xăng dầu của Petrolimex và PVOIL quý 2","Tổng nhập trong kỳ của xăng toàn quốc 6 tháng đầu năm","Đơn vị nào có tồn cuối kỳ giảm hơn 30% so kỳ trước?","Top 5 doanh nghiệp xuất xăng nhiều nhất năm 2026","Tổng tồn kho dầu theo từng vùng miền tháng vừa rồi","Doanh nghiệp nào có tỉ lệ tồn cuối / nhập trong kỳ thấp nhất?","Tổng tồn cuối kỳ của xăng và dầu năm 2025"]',
         100, 1000, 2, 6, 1),

        -- ==================== 2) head_office_price ====================
        (N'head_office_price',
         N'Giá bán xăng dầu doanh nghiệp đầu mối',
         N'Giá bán RON95-III, E5 RON92-II, DIESEL 0.05S do các doanh nghiệp đầu mối báo cáo. BaoCaoId=''F115C290-543A-4E1B-8546-275A2CF8150E''. Mỗi kỳ điều hành có một giá bán mới (filter LoaiGia=1, So_01=1, So_04>0). Dùng để theo dõi biến động giá theo thời gian, so sánh giữa các doanh nghiệp, phân tích xu hướng.',
         N'head_office',
         N'vw_AiHeadOfficePrice',
         N'ThongKeId',
         N'["DonViId","DonViTen","Nam","Thang","ThoiDiemDinhGia","ProductCode","ProductName","GiaBan"]',
         N'["DonViId","Nam","Thang","ThoiDiemDinhGia","ProductCode"]',
         N'["AVG","MIN","MAX","COUNT"]',
         N'[]',
         N'["Giá RON95 trung bình tháng 5/2026 của các doanh nghiệp đầu mối","So sánh giá DIESEL của Petrolimex và PVOIL 3 kỳ gần nhất","Doanh nghiệp nào bán RON95 cao nhất kỳ điều hành mới nhất?","Biến động giá E5 RON92 6 tháng qua","Mức chênh lệch giá giữa doanh nghiệp cao nhất và thấp nhất"]',
         100, 1000, 2, 6, 1),

        -- ==================== 3) head_office_fund_balance ====================
        (N'head_office_fund_balance',
         N'Tồn quỹ bình ổn xăng dầu',
         N'Số dư quỹ bình ổn giá xăng dầu của từng doanh nghiệp đầu mối. BaoCaoId=''4C60DBAA-C69E-4878-B214-933D653D4F44'', kỳ tháng (KieuKyBaoCao=2), chỉ tiêu CT1 (tồn quỹ). Đơn vị: VND. Dùng để giám sát sức khỏe quỹ — doanh nghiệp nào đang có tồn quỹ thấp/cao, biến động qua các kỳ.',
         N'head_office',
         N'vw_AiHeadOfficeFundBalance',
         N'ThongKeId',
         N'["DonViId","DonViMa","DonViTen","VungMien","TinhId","Nam","Thang","TonQuyBinhOn"]',
         N'["DonViId","DonViTen","VungMien","TinhId","Nam","Thang"]',
         N'["SUM","AVG","MIN","MAX","COUNT"]',
         N'[{"view":"DM_Tinh","key":"TinhId = DM_Tinh.Id"}]',
         N'["Tổng tồn quỹ bình ổn toàn quốc tháng 5/2026","Doanh nghiệp nào tồn quỹ bình ổn cao nhất?","So sánh tồn quỹ giữa các kỳ 6 tháng qua","Top 10 doanh nghiệp có tồn quỹ thấp nhất tháng vừa rồi","Tồn quỹ bình ổn của Petrolimex 12 kỳ gần đây","Doanh nghiệp nào có tồn quỹ giảm mạnh nhất so kỳ trước?"]',
         100, 1000, 2, 6, 1),

        -- ==================== 4) head_office_import ====================
        (N'head_office_import',
         N'Nhập khẩu xăng dầu theo quốc gia',
         N'Lượng xăng dầu nhập khẩu từ các quốc gia/thị trường (Singapore, Hàn Quốc, Malaysia, Kuwait...). Dữ liệu từ BaoCaoId=''24BD5439-2CEB-4162-92D4-EBD165323475'', Nhom=1 (chỉ nhập khẩu). Phân theo doanh nghiệp đầu mối và loại nhiên liệu. Hỗ trợ kỳ tháng (KieuKyBaoCao=2), quý (3), năm (4).',
         N'head_office',
         N'vw_AiHeadOfficeImport',
         N'ThongKeId',
         N'["DonViId","DonViTen","Nam","Thang","KieuKyBaoCao","ThiTruongId","ThiTruongTen","ChiTieuMa","NhomNhienLieu","SoLuong"]',
         N'["DonViId","Nam","Thang","KieuKyBaoCao","ThiTruongId","ThiTruongTen","NhomNhienLieu","ChiTieuMa"]',
         N'["SUM","AVG","MIN","MAX","COUNT"]',
         NULL,
         N'["Doanh nghiệp nào nhập khẩu xăng từ Hàn Quốc nhiều nhất 6 tháng qua?","Top 3 thị trường nhập khẩu dầu năm 2026","Tổng lượng xăng nhập khẩu từ Singapore quý vừa rồi","So sánh sản lượng nhập khẩu giữa các quốc gia tháng 5/2026","Cơ cấu thị trường nhập khẩu dầu năm 2025"]',
         100, 1000, 2, 6, 1),

        -- ==================== 5) head_office_domestic_supply ====================
        (N'head_office_domestic_supply',
         N'Mua xăng dầu từ nhà máy trong nước',
         N'Lượng xăng dầu doanh nghiệp đầu mối mua từ các nhà máy lọc dầu trong nước (Bình Sơn, Nghi Sơn). Dữ liệu từ BaoCaoId=''24BD5439-2CEB-4162-92D4-EBD165323475'', Nhom=2. Phân theo doanh nghiệp đầu mối, nhà máy cung cấp và loại nhiên liệu.',
         N'head_office',
         N'vw_AiHeadOfficeDomesticSupply',
         N'ThongKeId',
         N'["DonViId","DonViTen","Nam","Thang","KieuKyBaoCao","NhaCungCapId","NhaCungCapTen","ChiTieuMa","NhomNhienLieu","SoLuong"]',
         N'["DonViId","Nam","Thang","KieuKyBaoCao","NhaCungCapId","NhaCungCapTen","NhomNhienLieu","ChiTieuMa"]',
         N'["SUM","AVG","MIN","MAX","COUNT"]',
         NULL,
         N'["Doanh nghiệp nào mua xăng từ Bình Sơn nhiều nhất tháng vừa rồi?","So sánh sản lượng cung cấp giữa Nghi Sơn và Bình Sơn năm 2026","Cơ cấu nguồn cung xăng dầu trong nước quý 2","Tổng lượng dầu mua từ Nghi Sơn 6 tháng đầu năm"]',
         100, 1000, 2, 6, 1),

        -- ==================== 6) station_price ====================
        (N'station_price',
         N'Giá bán cửa hàng bán lẻ',
         N'Giá bán xăng dầu hiện hành tại các cửa hàng bán lẻ (CapDonViId=248). Bao gồm các loại RON95, E5 RON92, DIESEL theo FuelProducts. Mỗi cửa hàng có thể có nhiều bảng giá theo thời điểm; sp.IsActive=1 = bảng giá hiệu lực hiện tại.',
         N'retail_station',
         N'vw_AiStationPrice',
         N'PriceDetailId',
         N'["StationId","StationCode","StationName","TinhId","ProductId","ProductCode","ProductName","Price","EffectiveDate","IsActive"]',
         N'["StationId","StationCode","TinhId","ProductCode","EffectiveDate","IsActive"]',
         N'["AVG","MIN","MAX","COUNT"]',
         N'[{"view":"DM_Tinh","key":"TinhId = DM_Tinh.Id"}]',
         N'["Giá RON95 trung bình các cửa hàng tỉnh Hà Nội hôm nay","Cửa hàng nào bán DIESEL thấp nhất Hải Phòng?","So sánh giá RON95 giữa các tỉnh miền Bắc","Cửa hàng nào tăng giá nhiều nhất tuần qua?"]',
         100, 1000, 2, 6, 1),

        -- ==================== 7) station_inventory ====================
        (N'station_inventory',
         N'Nhập xuất cửa hàng bán lẻ',
         N'Phiếu nhập xuất kho của cửa hàng bán lẻ (CapDonViId=248). TransactionType=1 là nhập, -1 là xuất. Mỗi phiếu có nhiều dòng chi tiết theo sản phẩm + đơn vị tính. Đơn vị tại lớp cửa hàng mặc định là lít.',
         N'retail_station',
         N'vw_AiStationInventory',
         N'DetailId',
         N'["StationId","StationCode","StationName","TinhId","TransactionType","TransactionDate","ProductCode","ProductName","Quantity","Amount","UnitName"]',
         N'["StationId","TinhId","TransactionType","TransactionDate","ProductCode"]',
         N'["SUM","AVG","MIN","MAX","COUNT"]',
         NULL,
         N'["Tổng lượng xăng nhập của cửa hàng X tháng vừa rồi","Cửa hàng nào xuất nhiều RON95 nhất tỉnh Hà Nội tuần này?","Tổng số phiếu xuất tháng 5/2026 toàn quốc","Top 10 cửa hàng có sản lượng xuất cao nhất quý vừa rồi"]',
         100, 1000, 2, 6, 1),

        -- ==================== 8) station_rating ====================
        (N'station_rating',
         N'Đánh giá cửa hàng bán lẻ',
         N'Điểm đánh giá (1–5 sao) của khách hàng cho các cửa hàng bán lẻ. KHÔNG bao gồm comment chi tiết — comment là PII level 3, đã ẩn khỏi vw_AiStationRating. Chỉ trả các đánh giá chưa bị soft-delete (IsDeleted=0).',
         N'retail_station',
         N'vw_AiStationRating',
         N'RatingId',
         N'["StationId","StationCode","StationName","TinhId","Rating","CreatedAt"]',
         N'["StationId","TinhId","Rating","CreatedAt"]',
         N'["AVG","MIN","MAX","COUNT"]',
         NULL,
         N'["Cửa hàng nào có điểm đánh giá cao nhất tỉnh Hà Nội?","Tổng số đánh giá nhận được trong tháng vừa rồi","Top 10 cửa hàng được đánh giá tốt nhất toàn quốc"]',
         100, 1000, 2, 6, 1);
        """;

    /// <summary>Down — xoá 8 entity đã seed (theo EntityCode scope của Phase 5C).</summary>
    internal const string Unseed =
        """
        DELETE FROM dbo.AiSchemaCatalog
        WHERE EntityCode IN (
            N'head_office_inventory',
            N'head_office_price',
            N'head_office_fund_balance',
            N'head_office_import',
            N'head_office_domestic_supply',
            N'station_price',
            N'station_inventory',
            N'station_rating'
        );
        """;
}
