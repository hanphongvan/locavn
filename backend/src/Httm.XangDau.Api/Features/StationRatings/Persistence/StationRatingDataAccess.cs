using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.StationRatings.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StationRatings.Persistence;

public sealed class StationRatingDataAccess(IConfiguration configuration) : IStationRatingDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(int? RatingId, string? ErrorMessage)> InsertRatingWithImagesAsync(
        int stationId,
        int rating,
        string? comment,
        string? deviceId,
        string? createdBy,
        IReadOnlyList<string> imageUrls,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var tx = (SqlTransaction)await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var insertP = new DynamicParameters();
            insertP.Add("StationId", stationId);
            insertP.Add("Rating", rating);
            insertP.Add("Comment", comment);
            insertP.Add("DeviceId", deviceId);
            insertP.Add("CreatedBy", createdBy);
            insertP.Add("RatingId", dbType: DbType.Int32, direction: ParameterDirection.Output);
            insertP.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

            await conn.ExecuteAsync(
                    new CommandDefinition(
                        "dbo.sp_StationRating_Insert",
                        insertP,
                        transaction: tx,
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var ratingId = insertP.Get<int?>("RatingId");
            var err = insertP.Get<string>("ErrorMessage");
            if (ratingId is null || !string.IsNullOrWhiteSpace(err))
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return (null, string.IsNullOrWhiteSpace(err) ? null : err.Trim());
            }

            foreach (var url in imageUrls)
            {
                var imgP = new DynamicParameters();
                imgP.Add("RatingId", ratingId.Value);
                imgP.Add("ImageUrl", url);
                imgP.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

                await conn.ExecuteAsync(
                        new CommandDefinition(
                            "dbo.sp_StationRatingImage_Insert",
                            imgP,
                            transaction: tx,
                            commandType: CommandType.StoredProcedure,
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false);

                var imgErr = imgP.Get<string>("ErrorMessage");
                if (!string.IsNullOrWhiteSpace(imgErr))
                {
                    await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                    return (null, imgErr.Trim());
                }
            }

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
            return (ratingId, null);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }
    }

    /// <inheritdoc />
    public async Task<StationRatingSummaryDto> GetSummaryAsync(int stationId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var row = await conn.QuerySingleAsync<SummaryRow>(
                new CommandDefinition(
                    "dbo.sp_StationRating_GetSummary",
                    new { StationId = stationId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return new StationRatingSummaryDto(row.StationId, (double)row.AvgRating, row.TotalRatings);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<StationRatingDto>> GetByStationAsync(int stationId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var multi = await conn.QueryMultipleAsync(
                new CommandDefinition(
                    "dbo.sp_StationRating_GetByStation",
                    new { StationId = stationId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var headers = (await multi.ReadAsync<RatingHeaderRow>().ConfigureAwait(false)).ToList();
        var imageRows = (await multi.ReadAsync<RatingImageRow>().ConfigureAwait(false)).ToList();
        var byRating = imageRows.ToLookup(r => r.RatingId);

        return headers
            .Select(h => new StationRatingDto(
                h.Id,
                h.Rating,
                h.Comment,
                h.CreatedAt,
                h.CreatedBy,
                byRating[h.Id].Select(i => i.ImageUrl).ToList()))
            .ToList();
    }

    private sealed class SummaryRow
    {
        public int StationId { get; init; }
        public decimal AvgRating { get; init; }
        public int TotalRatings { get; init; }
    }

    private sealed class RatingHeaderRow
    {
        public int Id { get; init; }
        public int Rating { get; init; }
        public string? Comment { get; init; }
        public DateTime CreatedAt { get; init; }
        public string? CreatedBy { get; init; }
    }

    private sealed class RatingImageRow
    {
        public int RatingId { get; init; }
        public string ImageUrl { get; init; } = "";
    }
}
