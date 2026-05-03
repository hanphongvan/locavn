namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>SQL scripts for EF migration <c>AddDemoDataStoredProcedures</c> (mirrored under <c>backend/database/migrations</c>).</summary>
internal static class DemoDataStoredProceduresSql
{
    internal const string SpClear = """
        CREATE OR ALTER PROCEDURE dbo.sp_Demo_ClearData
            @Tinh INT,
            @RetailCapDonViId INT = 248
        AS
        BEGIN
            SET NOCOUNT ON;

            DELETE h
            FROM dbo.StationInventoryTransactionHeaders AS h
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
            WHERE h.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;

            DELETE sp
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;
        """;

    internal const string SpGeneratePrices = """
        CREATE OR ALTER PROCEDURE dbo.sp_Demo_GeneratePrices
            @Tinh INT,
            @ClearOldData BIT,
            @DaysBack INT,
            @RetailCapDonViId INT = 248
        AS
        BEGIN
            SET NOCOUNT ON;
            IF @DaysBack < 1 SET @DaysBack = 1;
            IF @DaysBack > 400 SET @DaysBack = 400;

            IF @ClearOldData = 1
            BEGIN
                DELETE sp
                FROM dbo.StationPrices AS sp
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
                WHERE sp.CreatedBy = N'sys_demo'
                  AND dv.Tinh = @Tinh
                  AND dv.CapDonViId = @RetailCapDonViId;
            END;

            IF OBJECT_ID(N'tempdb..#DemoPriceProducts', N'U') IS NOT NULL
                DROP TABLE #DemoPriceProducts;

            ;WITH Grp AS (
                SELECT g.Id, UPPER(LTRIM(RTRIM(g.Code))) AS CodeNorm
                FROM dbo.FuelProducts AS g
                WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
            ),
            DownTree AS (
                SELECT fp.Id, fp.Code, fp.Name, fp.UnitId, g.CodeNorm AS RootCode
                FROM dbo.FuelProducts AS fp
                INNER JOIN Grp AS g ON fp.ParentId = g.Id
                WHERE fp.IsActive = 1
                UNION ALL
                SELECT c.Id, c.Code, c.Name, c.UnitId, d.RootCode
                FROM dbo.FuelProducts AS c
                INNER JOIN DownTree AS d ON c.ParentId = d.Id
                WHERE c.IsActive = 1
            ),
            Leaf AS (
                SELECT d.Id AS ProductId, d.Code, d.Name, d.UnitId, d.RootCode
                FROM DownTree AS d
                WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
                  AND d.UnitId IS NOT NULL
            )
            SELECT
                l.ProductId,
                l.UnitId,
                CAST(
                    CASE
                        WHEN UPPER(l.Name) LIKE N'%RON%95%'
                             OR UPPER(l.Code) LIKE N'%RON95%'
                            THEN 1
                        WHEN UPPER(l.Name) LIKE N'%E5%'
                             OR UPPER(l.Code) LIKE N'%E5%'
                             OR UPPER(l.Name) LIKE N'%A92%'
                            THEN 2
                        WHEN UPPER(l.Name) LIKE N'%DIESEL%'
                             OR UPPER(l.Code) LIKE N'%DIESEL%'
                             OR UPPER(l.Name) LIKE N'%DO 0%'
                             OR UPPER(l.Name) LIKE N'%DẦU%'
                            THEN 3
                        WHEN l.RootCode = N'DAU' THEN 3
                        ELSE 2
                    END AS TINYINT) AS PriceBand
            INTO #DemoPriceProducts
            FROM Leaf AS l;

            DECLARE @d INT = 0;
            DECLARE @day DATE;
            DECLARE @donViId INT;
            DECLARE @spId INT;
            DECLARE @isCurrent BIT;

            WHILE @d < @DaysBack
            BEGIN
                SET @day = DATEADD(DAY, -@d, CAST(SYSDATETIME() AS DATE));
                SET @isCurrent = CASE WHEN @d = 0 THEN 1 ELSE 0 END;

                DECLARE c CURSOR LOCAL FAST_FORWARD FOR
                    SELECT dv.Id
                    FROM dbo.DM_DonVi AS dv
                    WHERE dv.CapDonViId = @RetailCapDonViId
                      AND dv.Tinh = @Tinh
                    ORDER BY dv.Id;

                OPEN c;
                FETCH NEXT FROM c INTO @donViId;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
                    VALUES (@donViId, @day, 0, SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                    SET @spId = SCOPE_IDENTITY();

                    INSERT INTO dbo.StationProductPrices (
                        StationPricesId,
                        DonViId,
                        ProductId,
                        Price,
                        UnitId,
                        EffectiveDate,
                        IsCurrent,
                        Note,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy)
                    SELECT
                        @spId,
                        @donViId,
                        p.ProductId,
                        CAST(
                            CASE p.PriceBand
                                WHEN 1 THEN
                                    23800 + (ABS(CHECKSUM(
                                        CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#1')) % 601)
                                WHEN 2 THEN
                                    22800 + (ABS(CHECKSUM(
                                        CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#2')) % 701)
                                WHEN 3 THEN
                                    31700 + (ABS(CHECKSUM(
                                        CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#3')) % 801)
                                ELSE
                                    22800 + (ABS(CHECKSUM(
                                        CONVERT(VARCHAR(11), @donViId) + N'#' + CONVERT(VARCHAR(11), p.ProductId) + N'#0')) % 701)
                            END AS DECIMAL(18, 2)),
                        p.UnitId,
                        @day,
                        @isCurrent,
                        N'Demo generated',
                        SYSDATETIME(),
                        N'sys_demo',
                        SYSDATETIME(),
                        N'sys_demo'
                    FROM #DemoPriceProducts AS p;

                    FETCH NEXT FROM c INTO @donViId;
                END;

                CLOSE c;
                DEALLOCATE c;

                SET @d += 1;
            END;

            DROP TABLE #DemoPriceProducts;

            ;WITH mx AS (
                SELECT sp.DonViId, MAX(sp.ActiveDate) AS MaxD
                FROM dbo.StationPrices AS sp
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
                WHERE sp.CreatedBy = N'sys_demo'
                  AND dv.Tinh = @Tinh
                  AND dv.CapDonViId = @RetailCapDonViId
                GROUP BY sp.DonViId
            )
            UPDATE sp
            SET IsActive = CASE WHEN sp.ActiveDate = mx.MaxD THEN 1 ELSE 0 END,
                Modified = SYSDATETIME(),
                ModifiedBy = N'sys_demo'
            FROM dbo.StationPrices AS sp
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            INNER JOIN mx ON mx.DonViId = sp.DonViId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;

            ;WITH mx2 AS (
                SELECT spp.DonViId, spp.ProductId, MAX(sp.ActiveDate) AS MaxD
                FROM dbo.StationProductPrices AS spp
                INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
                WHERE sp.CreatedBy = N'sys_demo'
                  AND dv.Tinh = @Tinh
                  AND dv.CapDonViId = @RetailCapDonViId
                GROUP BY spp.DonViId, spp.ProductId
            )
            UPDATE spp
            SET IsCurrent = CASE WHEN sp.ActiveDate = mx2.MaxD THEN 1 ELSE 0 END,
                Modified = SYSDATETIME(),
                ModifiedBy = N'sys_demo'
            FROM dbo.StationProductPrices AS spp
            INNER JOIN dbo.StationPrices AS sp ON sp.Id = spp.StationPricesId
            INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = sp.DonViId
            INNER JOIN mx2
                ON mx2.DonViId = spp.DonViId
               AND mx2.ProductId = spp.ProductId
            WHERE sp.CreatedBy = N'sys_demo'
              AND dv.Tinh = @Tinh
              AND dv.CapDonViId = @RetailCapDonViId;
        END;
        """;

    internal const string SpGenerateInventory = """
        CREATE OR ALTER PROCEDURE dbo.sp_Demo_GenerateInventory
            @Tinh INT,
            @ClearOldData BIT,
            @DaysBack INT,
            @RetailCapDonViId INT = 248
        AS
        BEGIN
            /*
             * Demo inventory for heatmap / inventory-current (SUM(Quantity * TransactionType) per product).
             * Writes StationInventoryTransactionHeaders + StationInventoryTransactionDetails (UnitId required).
             * Legacy dbo.StationInventoryTransactions has no UnitId and is not read by store admin SPs.
             */
            SET NOCOUNT ON;
            IF @DaysBack < 1 SET @DaysBack = 1;
            IF @DaysBack > 400 SET @DaysBack = 400;

            IF @ClearOldData = 1
            BEGIN
                DELETE h
                FROM dbo.StationInventoryTransactionHeaders AS h
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
                WHERE h.CreatedBy = N'sys_demo'
                  AND dv.Tinh = @Tinh
                  AND dv.CapDonViId = @RetailCapDonViId;
            END;

            IF OBJECT_ID(N'tempdb..#LeafProducts', N'U') IS NOT NULL
                DROP TABLE #LeafProducts;

            ;WITH Grp AS (
                SELECT g.Id
                FROM dbo.FuelProducts AS g
                WHERE UPPER(LTRIM(RTRIM(g.Code))) IN (N'XANG', N'DAU')
            ),
            DownTree AS (
                SELECT fp.Id, fp.Code, fp.Name, fp.UnitId
                FROM dbo.FuelProducts AS fp
                INNER JOIN Grp AS g ON fp.ParentId = g.Id
                WHERE fp.IsActive = 1
                UNION ALL
                SELECT c.Id, c.Code, c.Name, c.UnitId
                FROM dbo.FuelProducts AS c
                INNER JOIN DownTree AS d ON c.ParentId = d.Id
                WHERE c.IsActive = 1
            ),
            Leaf AS (
                SELECT d.Id AS ProductId, d.UnitId
                FROM DownTree AS d
                WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
                  AND d.UnitId IS NOT NULL
            )
            SELECT l.ProductId, l.UnitId
            INTO #LeafProducts
            FROM Leaf AS l;

            IF NOT EXISTS (SELECT 1 FROM #LeafProducts)
                RETURN;

            IF OBJECT_ID(N'tempdb..#StoreCfg', N'U') IS NOT NULL
                DROP TABLE #StoreCfg;

            CREATE TABLE #StoreCfg (
                DonViId INT NOT NULL PRIMARY KEY,
                TTarget INT NOT NULL);

            INSERT INTO #StoreCfg (DonViId, TTarget)
            SELECT
                dv.Id,
                CASE dv.Id % 10
                    WHEN 0 THEN -250 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv0')) % 451)
                    WHEN 1 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv1')) % 1001)
                    WHEN 2 THEN 500 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv2')) % 1001)
                    WHEN 3 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv3')) % 3001)
                    WHEN 4 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv4')) % 3001)
                    WHEN 5 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv5')) % 3001)
                    WHEN 6 THEN 2000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv6')) % 3001)
                    ELSE 6000 + (ABS(CHECKSUM(CONVERT(VARCHAR(20), dv.Id) + N'#inv' + CONVERT(VARCHAR(2), dv.Id % 10))) % 6001)
                END
            FROM dbo.DM_DonVi AS dv
            WHERE dv.CapDonViId = @RetailCapDonViId
              AND dv.Tinh = @Tinh;

            DECLARE @sid INT;
            DECLARE @Tt INT;
            DECLARE @sumW BIGINT;
            DECLARE @cnt INT;
            DECLARE @rem INT;
            DECLARE @off INT;
            DECLARE @pid INT;
            DECLARE @uid INT;
            DECLARE @qty INT;
            DECLARE @dayBase DATE;
            DECLARE @ts DATETIME2(0);
            DECLARE @hId INT;
            DECLARE @pad INT;
            DECLARE @tpi INT;

            DECLARE sCur CURSOR LOCAL FAST_FORWARD FOR
                SELECT DonViId, TTarget FROM #StoreCfg ORDER BY DonViId;

            OPEN sCur;
            FETCH NEXT FROM sCur INTO @sid, @Tt;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF OBJECT_ID(N'tempdb..#Tgt', N'U') IS NOT NULL
                    DROP TABLE #Tgt;

                CREATE TABLE #Tgt (
                    ProductId INT NOT NULL PRIMARY KEY,
                    UnitId INT NOT NULL,
                    TargetQty INT NOT NULL);

                SELECT @cnt = COUNT(*), @sumW = COALESCE(SUM(CAST(1 + (ProductId % 5) AS BIGINT)), 0) FROM #LeafProducts;

                IF @cnt > 0 AND @sumW > 0
                BEGIN
                INSERT INTO #Tgt (ProductId, UnitId, TargetQty)
                SELECT
                    p.ProductId,
                    p.UnitId,
                    CAST((CAST(@Tt AS BIGINT) * CAST(1 + (p.ProductId % 5) AS BIGINT)) / @sumW AS INT)
                FROM #LeafProducts AS p;

                SELECT @rem = @Tt - COALESCE(SUM(TargetQty), 0) FROM #Tgt;

                WHILE @rem <> 0
                BEGIN
                    IF @rem > 0
                    BEGIN
                        UPDATE TOP (1) t
                        SET TargetQty = t.TargetQty + 1
                        FROM #Tgt AS t
                        WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                        SET @rem -= 1;
                    END;
                    ELSE
                    BEGIN
                        UPDATE TOP (1) t
                        SET TargetQty = t.TargetQty - 1
                        FROM #Tgt AS t
                        WHERE t.ProductId = (SELECT MAX(x.ProductId) FROM #Tgt AS x);
                        SET @rem += 1;
                    END;
                END;

                SET @off = @DaysBack - 1;
                WHILE @off >= 1
                BEGIN
                    SET @dayBase = DATEADD(DAY, -@off, CAST(SYSDATETIME() AS DATE));

                    SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts);
                    WHILE @pid IS NOT NULL
                    BEGIN
                        SELECT @uid = UnitId FROM #LeafProducts WHERE ProductId = @pid;

                        SET @qty = 40 + (ABS(CHECKSUM(
                            CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#' + CONVERT(VARCHAR(10), @off))) % 121);

                        SET @ts = DATEADD(MINUTE, (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                        SET @ts = DATEADD(MINUTE, 1 + (@pid % 90), CAST(@dayBase AS DATETIME2(0)));

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                        SET @pid = (SELECT MIN(ProductId) FROM #LeafProducts WHERE ProductId > @pid);
                    END;

                    SET @off -= 1;
                END;

                SET @dayBase = CAST(SYSDATETIME() AS DATE);

                SET @pid = (SELECT MIN(ProductId) FROM #Tgt);
                WHILE @pid IS NOT NULL
                BEGIN
                    SELECT @uid = UnitId, @tpi = TargetQty FROM #Tgt WHERE ProductId = @pid;

                    SET @pad = 25 + (ABS(CHECKSUM(
                        CONVERT(VARCHAR(20), @sid) + N'#' + CONVERT(VARCHAR(20), @pid) + N'#pad')) % 60);
                    SET @ts = DATEADD(MINUTE, 120 + (@pid % 60), CAST(@dayBase AS DATETIME2(0)));

                    IF @tpi >= 0
                    BEGIN
                        SET @qty = @tpi + @pad;

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);

                        SET @ts = DATEADD(MINUTE, 1, @ts);

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);
                    END;
                    ELSE
                    BEGIN
                        SET @qty = @pad + ABS(@tpi);

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, 1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@pad AS DECIMAL(18, 3)), NULL, NULL);

                        SET @ts = DATEADD(MINUTE, 1, @ts);

                        INSERT INTO dbo.StationInventoryTransactionHeaders (
                            DonViId, TransactionType, TransactionDate, Note,
                            Created, CreatedBy, Modified, ModifiedBy)
                        VALUES (@sid, -1, @ts, N'Demo generated', SYSDATETIME(), N'sys_demo', SYSDATETIME(), N'sys_demo');
                        SET @hId = SCOPE_IDENTITY();
                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                        VALUES (@hId, @pid, @uid, CAST(@qty AS DECIMAL(18, 3)), NULL, NULL);
                    END;

                    SET @pid = (SELECT MIN(ProductId) FROM #Tgt WHERE ProductId > @pid);
                END;

                END;

                FETCH NEXT FROM sCur INTO @sid, @Tt;
            END;

            CLOSE sCur;
            DEALLOCATE sCur;

            DROP TABLE #StoreCfg;
            DROP TABLE #LeafProducts;
        END;
        """;

    internal const string SpGenerateAll = """
        CREATE OR ALTER PROCEDURE dbo.sp_Demo_GenerateAll
            @Tinh INT,
            @ClearOldData BIT,
            @DaysBack INT,
            @RetailCapDonViId INT = 248
        AS
        BEGIN
            SET NOCOUNT ON;
            IF @ClearOldData = 1
                EXEC dbo.sp_Demo_ClearData @Tinh = @Tinh, @RetailCapDonViId = @RetailCapDonViId;

            EXEC dbo.sp_Demo_GeneratePrices
                @Tinh = @Tinh,
                @ClearOldData = 0,
                @DaysBack = @DaysBack,
                @RetailCapDonViId = @RetailCapDonViId;

            EXEC dbo.sp_Demo_GenerateInventory
                @Tinh = @Tinh,
                @ClearOldData = 0,
                @DaysBack = @DaysBack,
                @RetailCapDonViId = @RetailCapDonViId;
        END;
        """;

    internal const string DropAll = """
        IF OBJECT_ID(N'dbo.sp_Demo_GenerateAll', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Demo_GenerateAll;
        IF OBJECT_ID(N'dbo.sp_Demo_GenerateInventory', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Demo_GenerateInventory;
        IF OBJECT_ID(N'dbo.sp_Demo_GeneratePrices', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Demo_GeneratePrices;
        IF OBJECT_ID(N'dbo.sp_Demo_ClearData', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Demo_ClearData;
        """;
}
