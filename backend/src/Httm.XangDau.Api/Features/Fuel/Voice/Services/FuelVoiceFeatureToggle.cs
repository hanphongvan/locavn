using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.Extensions.Caching.Memory;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

public sealed class FuelVoiceFeatureToggle(
    IAppSystemSettingsRead settings,
    IMemoryCache cache) : IFuelVoiceFeatureToggle
{
    /// <summary>Setting key đã thoả thuận với business: bảng <c>AppSystemSettings</c>.</summary>
    public const string SettingKey = "loca.donhienlieu";

    private const string CacheKey = "fuel-voice-feature-enabled";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(5);

    public async Task<bool> IsEnabledAsync(CancellationToken cancellationToken = default)
    {
        if (cache.TryGetValue<bool>(CacheKey, out var cached))
            return cached;

        var value = await settings.GetValueAsync(SettingKey, cancellationToken).ConfigureAwait(false);
        var enabled = string.Equals(value?.Trim(), "1", StringComparison.Ordinal);

        cache.Set(CacheKey, enabled, CacheTtl);
        return enabled;
    }
}
