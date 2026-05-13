using Httm.XangDau.Api.Features.Surveys.Contracts;

namespace Httm.XangDau.Api.Features.Surveys.Persistence;

public interface IHttmSurveyRepository
{
    Task<(Guid Id, string SurveyCode)> InsertAsync(
        string provinceCode,
        string httmType,
        string createdBy,
        CancellationToken cancellationToken = default);

    Task<HttmSurveyDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<HttmSurveySearchPageDto> SearchAsync(
        HttmSurveySearchQuery query,
        string? provinceScope,
        string? createdByFilter,
        CancellationToken cancellationToken = default);

    Task<int> PatchAsync(Guid id, HttmSurveyPatchRequest patch, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Err)> SubmitAsync(Guid id, string performedBy, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Err)> ApproveAsync(
        Guid id,
        string performedBy,
        string? notes,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Err)> RejectAsync(
        Guid id,
        string performedBy,
        string reason,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Err)> EnterReviewingAsync(Guid id, string performedBy, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Err)> DeleteAsync(
        Guid id,
        string performedBy,
        bool forceAdmin,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HttmSurveyHistoryDto>> GetHistoryAsync(Guid surveyId, CancellationToken cancellationToken = default);
}
