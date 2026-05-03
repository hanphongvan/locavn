using Httm.XangDau.Api.Features.Account.Contracts;

namespace Httm.XangDau.Api.Features.Account.Services;

public interface IUserDataDeletionRequestService
{
    /// <summary>
    /// Xoá ngay tài khoản và toàn bộ dữ liệu cá nhân của user (idempotent — đã xoá thì trả Success).
    /// Đánh giá / báo cáo công khai được giữ lại nhưng đặt UserId = NULL (anonymize qua FK SetNull).
    /// </summary>
    Task<RequestDeletePersonalDataResponse> DeleteAccountImmediatelyAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
