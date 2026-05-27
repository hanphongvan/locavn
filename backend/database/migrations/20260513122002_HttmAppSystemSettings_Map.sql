-- HTTM Phase 1 — §1.1.5: Cấu hình bản đồ HTTM trong dbo.AppSystemSettings (dự án dùng bảng này thay `system_configs`).

IF OBJECT_ID(N'dbo.AppSystemSettings', N'U') IS NULL
BEGIN
    PRINT N'SKIP: dbo.AppSystemSettings chưa tồn tại — chạy migration AddAppSystemSettings trước.';
    RETURN;
END;

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'httm.map.provider')
    INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
    VALUES (N'httm.map.provider', N'osm');

IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'httm.map.goong_api_key')
    INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
    VALUES (N'httm.map.goong_api_key', N'');

IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'httm.map.default_center_lng')
    INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
    VALUES (N'httm.map.default_center_lng', N'105.8342');

IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'httm.map.default_center_lat')
    INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
    VALUES (N'httm.map.default_center_lat', N'21.0278');

IF NOT EXISTS (SELECT 1 FROM dbo.AppSystemSettings WHERE SettingKey = N'httm.map.default_zoom')
    INSERT INTO dbo.AppSystemSettings (SettingKey, SettingValue)
    VALUES (N'httm.map.default_zoom', N'10');
GO
