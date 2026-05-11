namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

public interface IFuelVoiceFeatureToggle
{
    /// <summary>
    /// Trả <c>true</c> nếu setting <c>loca.donhienlieu</c> trong <c>dbo.AppSystemSettings</c>
    /// có <c>SettingValue = '1'</c>. Mọi giá trị khác (kể cả không có row) → <c>false</c>.
    /// Có cache trong 5 phút để tránh query liên tục.
    /// </summary>
    Task<bool> IsEnabledAsync(CancellationToken cancellationToken = default);
}
