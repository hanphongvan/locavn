namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — 5 trigger cache invalidation. Section 10A.3 của <c>docs/loca-ai-phase5.md</c>.
/// Khi nguồn dữ liệu đổi → bump <c>AiDataVersion.Version + 1</c> theo <c>BaoCaoCode</c> tương ứng,
/// làm cache key cũ trong Redis (Phase 5C+) tự động không hit nữa.
/// </summary>
internal static class AiCacheInvalidationTriggersSql
{
    /// <summary>Bump <c>NhapXuatTon</c> / <c>GiaBan</c> / <c>NhapKhauNguonCung</c> / <c>QuyBinhOn</c> khi báo cáo chuyển sang chốt (<c>TrangThai → 5</c>).</summary>
    internal const string TR_QT_TK_ThongKe_AfterUpdate =
        """
        CREATE OR ALTER TRIGGER dbo.TR_QT_TK_ThongKe_AfterUpdate
        ON dbo.QT_TK_ThongKe
        AFTER UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            IF NOT UPDATE(TrangThai)
                RETURN;

            UPDATE v
            SET Version     = v.Version + 1,
                LastUpdated = SYSUTCDATETIME(),
                UpdatedBy   = N'tr_qt_tk_thongke_afterupdate'
            FROM dbo.AiDataVersion AS v
            INNER JOIN dbo.AiBaoCaoConstants AS c ON c.BaoCaoCode = v.BaoCaoCode
            WHERE EXISTS (
                SELECT 1
                FROM inserted AS i
                INNER JOIN deleted AS d ON d.Id = i.Id
                WHERE i.TrangThai = 5
                  AND ISNULL(d.TrangThai, -1) <> 5
                  AND i.BaoCaoId = c.BaoCaoId
            );
        END
        """;

    /// <summary>Bump <c>StationPrice</c> khi giá header thay đổi.</summary>
    internal const string TR_StationPrices_AfterUpsert =
        """
        CREATE OR ALTER TRIGGER dbo.TR_StationPrices_AfterUpsert
        ON dbo.StationPrices
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            UPDATE dbo.AiDataVersion
            SET Version     = Version + 1,
                LastUpdated = SYSUTCDATETIME(),
                UpdatedBy   = N'tr_stationprices_afterupsert'
            WHERE BaoCaoCode = N'StationPrice';
        END
        """;

    /// <summary>Bump <c>StationPrice</c> khi giá detail từng sản phẩm thay đổi.</summary>
    internal const string TR_StationProductPrices_AfterUpsert =
        """
        CREATE OR ALTER TRIGGER dbo.TR_StationProductPrices_AfterUpsert
        ON dbo.StationProductPrices
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            UPDATE dbo.AiDataVersion
            SET Version     = Version + 1,
                LastUpdated = SYSUTCDATETIME(),
                UpdatedBy   = N'tr_stationproductprices_afterupsert'
            WHERE BaoCaoCode = N'StationPrice';
        END
        """;

    /// <summary>Bump <c>StationInventory</c> khi phiếu nhập/xuất cửa hàng thay đổi.</summary>
    internal const string TR_StationInventoryTransactionHeaders_AfterUpsert =
        """
        CREATE OR ALTER TRIGGER dbo.TR_StationInventoryTransactionHeaders_AfterUpsert
        ON dbo.StationInventoryTransactionHeaders
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            UPDATE dbo.AiDataVersion
            SET Version     = Version + 1,
                LastUpdated = SYSUTCDATETIME(),
                UpdatedBy   = N'tr_stationinventoryheaders_afterupsert'
            WHERE BaoCaoCode = N'StationInventory';
        END
        """;

    /// <summary>Bump <c>StationRating</c> khi đánh giá cửa hàng thay đổi.</summary>
    internal const string TR_StationRatings_AfterUpsert =
        """
        CREATE OR ALTER TRIGGER dbo.TR_StationRatings_AfterUpsert
        ON dbo.StationRatings
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            UPDATE dbo.AiDataVersion
            SET Version     = Version + 1,
                LastUpdated = SYSUTCDATETIME(),
                UpdatedBy   = N'tr_stationratings_afterupsert'
            WHERE BaoCaoCode = N'StationRating';
        END
        """;

    /// <summary>Drop 5 trigger (Down).</summary>
    internal const string DropAll =
        """
        IF OBJECT_ID(N'dbo.TR_StationRatings_AfterUpsert',                       N'TR') IS NOT NULL DROP TRIGGER dbo.TR_StationRatings_AfterUpsert;
        IF OBJECT_ID(N'dbo.TR_StationInventoryTransactionHeaders_AfterUpsert',   N'TR') IS NOT NULL DROP TRIGGER dbo.TR_StationInventoryTransactionHeaders_AfterUpsert;
        IF OBJECT_ID(N'dbo.TR_StationProductPrices_AfterUpsert',                 N'TR') IS NOT NULL DROP TRIGGER dbo.TR_StationProductPrices_AfterUpsert;
        IF OBJECT_ID(N'dbo.TR_StationPrices_AfterUpsert',                        N'TR') IS NOT NULL DROP TRIGGER dbo.TR_StationPrices_AfterUpsert;
        IF OBJECT_ID(N'dbo.TR_QT_TK_ThongKe_AfterUpdate',                        N'TR') IS NOT NULL DROP TRIGGER dbo.TR_QT_TK_ThongKe_AfterUpdate;
        """;
}
