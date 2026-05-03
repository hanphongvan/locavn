using Httm.XangDau.Api.Features.Account.Contracts;

namespace Httm.XangDau.Api.Features.Account.Services;

public interface IAccountActivityService
{
    Task<AccountActivitySummaryDto> GetSummaryAsync(string userId, CancellationToken cancellationToken = default);
}
