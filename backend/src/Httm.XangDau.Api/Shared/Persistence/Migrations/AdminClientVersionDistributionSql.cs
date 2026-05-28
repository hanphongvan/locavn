namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// <c>GET /api/admin/analytics/client-versions</c> — phân phối phiên bản mobile theo log
/// (<c>dbo.ClientVersionLog</c>) trong khoảng thời gian. Dùng <c>ClientId</c> để đếm unique;
/// fallback <c>RemoteIp</c> khi <c>ClientId</c> NULL (legacy app không gửi header).
/// </summary>
internal static class AdminClientVersionDistributionSql
{
    internal const string CreateProcedure =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Admin_ClientVersion_Distribution
            @FromDate DATETIME2(0),
            @ToDate   DATETIME2(0)
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Result set 1: phân phối theo (AppVersion, Platform)
            SELECT
                AppVersion,
                Platform,
                COUNT(DISTINCT COALESCE(ClientId, RemoteIp)) AS UniqueClients,
                COUNT_BIG(*) AS SampleCount
            FROM dbo.ClientVersionLog
            WHERE RequestTime >= @FromDate AND RequestTime < @ToDate
            GROUP BY AppVersion, Platform
            ORDER BY COUNT(DISTINCT COALESCE(ClientId, RemoteIp)) DESC, AppVersion;

            -- Result set 2: tổng + breakdown legacy vs versioned
            SELECT
                COUNT(DISTINCT COALESCE(ClientId, RemoteIp)) AS TotalUniqueClients,
                COUNT_BIG(*) AS TotalSamples,
                SUM(CASE WHEN AppVersion = N'legacy' THEN 1 ELSE 0 END) AS LegacySamples,
                SUM(CASE WHEN AppVersion <> N'legacy' THEN 1 ELSE 0 END) AS VersionedSamples
            FROM dbo.ClientVersionLog
            WHERE RequestTime >= @FromDate AND RequestTime < @ToDate;
        END;
        """;
}
