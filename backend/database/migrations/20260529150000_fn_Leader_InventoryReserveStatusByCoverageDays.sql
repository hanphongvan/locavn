-- Phân loại dự trữ chi tiết tồn kho Lãnh đạo (GET /api/leader/dashboard/inventory-detail).
-- Đồng bộ mã với dbo.fn_Leader_Map_DistributorReserveDisplayStatus: 0 = an toàn, 1 = cảnh báo, 2 = nguy cơ.
-- Chỉnh ngưỡng / nhãn tại đây (hoặc qua migration API cùng nội dung).

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
