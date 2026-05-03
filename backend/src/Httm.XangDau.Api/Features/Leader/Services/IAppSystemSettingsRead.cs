namespace Httm.XangDau.Api.Features.Leader.Services;

public interface IAppSystemSettingsRead
{
    /// <summary>Đọc <c>SettingValue</c> theo <paramref name="settingKey"/>; <paramref name="defaultValue"/> khi không có hoặc lỗi.</summary>
    Task<string?> GetValueAsync(string settingKey, CancellationToken cancellationToken = default);
}
