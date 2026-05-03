namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Tham số hệ thống dạng key/value (cấu hình máy chủ).</summary>
internal static class AppSystemSettingsSchemaSql
{
    internal const string CreateAppSystemSettingsTable =
        """
        IF OBJECT_ID(N'dbo.AppSystemSettings', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AppSystemSettings
            (
                SettingKey NVARCHAR(200) NOT NULL
                    CONSTRAINT PK_AppSystemSettings PRIMARY KEY CLUSTERED,
                SettingValue NVARCHAR(MAX) NULL
            );
        END;
        """;

    /// <summary>Ngày trong tháng (1–28): nếu ngày hiện tại (VN) &gt; mốc này thì kỳ BC08 mới nhất là tháng trước; ngược lại là tháng trước nữa.</summary>
    internal const string SeedStabilizationFundCutoff =
        """
        IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'Leader.StabilizationFund.ReportCutoffDayOfMonth')
            INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
            VALUES (N'Leader.StabilizationFund.ReportCutoffDayOfMonth', N'20');
        """;

    internal const string DropAppSystemSettingsTable =
        """
        DROP TABLE IF EXISTS dbo.AppSystemSettings;
        """;
}
