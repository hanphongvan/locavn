using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Leader.Services;

public sealed class AppSystemSettingsRead(
    IConfiguration configuration,
    ILogger<AppSystemSettingsRead> logger) : IAppSystemSettingsRead
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<string?> GetValueAsync(string settingKey, CancellationToken cancellationToken = default)
    {
        var key = (settingKey ?? string.Empty).Trim();
        if (key.Length == 0)
        {
            return null;
        }

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
            return await conn.QuerySingleOrDefaultAsync<string?>(
                    new CommandDefinition(
                        """
                        SELECT s.SettingValue
                        FROM dbo.AppSystemSettings AS s WITH (NOLOCK)
                        WHERE s.SettingKey = @Key;
                        """,
                        new { Key = key },
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);
        }
        catch (SqlException ex)
        {
            logger.LogWarning(ex, "AppSystemSettings read failed for {Key}", key);
            return null;
        }
    }
}
