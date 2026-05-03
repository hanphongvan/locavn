using Httm.XangDau.Api.Features.Account.Contracts;
using Httm.XangDau.Api.Features.Fuel.Persistence;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Account.Services;

public sealed class AccountActivityService(DmpPortalDbContext db, IFuelDataAccess fuel) : IAccountActivityService
{
    /// <inheritdoc />
    public async Task<AccountActivitySummaryDto> GetSummaryAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return new AccountActivitySummaryDto(0, 0, 0);

        var uid = userId.Trim();

        var reviewsCount = await db.StationReviews.AsNoTracking()
            .CountAsync(r => r.ReviewerUserId == uid, cancellationToken)
            .ConfigureAwait(false);

        var reportsCount = await db.StationBadReports.AsNoTracking()
            .CountAsync(r => r.ReporterUserId == uid, cancellationToken)
            .ConfigureAwait(false);

        var fuelCount = await fuel.CountTransactionsByUserAsync(uid, cancellationToken).ConfigureAwait(false);

        return new AccountActivitySummaryDto(reviewsCount, reportsCount, fuelCount);
    }
}
