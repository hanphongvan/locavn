namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Phân loại dự trữ cho chi tiết tồn kho Lãnh đạo — chỉnh ngưỡng/nhãn trên SQL Server.</summary>
internal static class LeaderInventoryReserveStatusSql
{
    /// <summary>
    /// TVF một dòng: <c>status_code</c> đồng bộ <c>fn_Leader_Map_DistributorReserveDisplayStatus</c> (0=an toàn, 1=cảnh báo, 2=nguy cơ),
    /// <c>status_label</c> cho hiển thị.
    /// </summary>
    internal const string CreateInventoryReserveStatusByCoverageDaysFunction =
        """
        CREATE OR ALTER FUNCTION dbo.fn_Leader_InventoryReserveStatusByCoverageDays (@coverageDays DECIMAL(18, 4))
        RETURNS TABLE
        AS
        RETURN
        (
            SELECT
                CAST(
                    CASE
                        WHEN @coverageDays IS NULL THEN 1
                        WHEN @coverageDays > 10 THEN 0
                        WHEN @coverageDays >= 5 AND @coverageDays <= 10 THEN 1
                        ELSE 2
                    END AS TINYINT) AS status_code,
                CAST(
                    CASE
                        WHEN @coverageDays IS NULL THEN N'Cảnh báo'
                        WHEN @coverageDays > 10 THEN N'An toàn'
                        WHEN @coverageDays >= 5 AND @coverageDays <= 10 THEN N'Cảnh báo'
                        ELSE N'Nguy cơ'
                    END AS NVARCHAR(30)) AS status_label
        );
        """;

    internal const string DropInventoryReserveStatusByCoverageDaysFunction =
        "DROP FUNCTION IF EXISTS dbo.fn_Leader_InventoryReserveStatusByCoverageDays;";
}
