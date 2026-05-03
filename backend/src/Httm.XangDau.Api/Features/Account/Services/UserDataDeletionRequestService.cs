using Httm.XangDau.Api.Features.Account.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Account.Services;

public sealed class UserDataDeletionRequestService(DmpPortalDbContext db) : IUserDataDeletionRequestService
{
    public async Task<RequestDeletePersonalDataResponse> DeleteAccountImmediatelyAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var exists = await db.AspNetUsers
            .AsNoTracking()
            .AnyAsync(x => x.Id == userId, cancellationToken)
            .ConfigureAwait(false);

        if (!exists)
        {
            return new RequestDeletePersonalDataResponse
            {
                Success = true,
                Message = "Tài khoản đã được xoá.",
            };
        }

        await using var tx = await db.Database
            .BeginTransactionAsync(cancellationToken)
            .ConfigureAwait(false);

        // FK Restrict — phải xoá thủ công các bảng dưới đây trước khi xoá AspNetUsers.
        // FuelTransactions FK vào UserVehicles.Id ⇒ xoá fuel trước vehicles.
        // StationReviews / StationBadReports / AspNetUserClaims / Logins / Roles auto-cascade
        // (SetNull / Cascade theo migration → không cần xử lý thủ công).
        await db.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.FuelTransactions WHERE UserId = {userId}",
            cancellationToken).ConfigureAwait(false);

        await db.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.UserVehicles WHERE UserId = {userId}",
            cancellationToken).ConfigureAwait(false);

        await db.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.PasswordResetTokens WHERE UserId = {userId}",
            cancellationToken).ConfigureAwait(false);

        await db.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.UserDataDeletionRequests WHERE UserId = {userId}",
            cancellationToken).ConfigureAwait(false);

        await db.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.AspNetUsers WHERE Id = {userId}",
            cancellationToken).ConfigureAwait(false);

        await tx.CommitAsync(cancellationToken).ConfigureAwait(false);

        return new RequestDeletePersonalDataResponse
        {
            Success = true,
            Message = "Tài khoản và dữ liệu cá nhân của bạn đã được xoá.",
        };
    }
}
