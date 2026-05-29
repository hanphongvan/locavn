using Httm.XangDau.Api.Features.Httm.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Persistence;

public interface IHttmFacilityRepository
{
    Task<HttmFacilitySearchPageDto> SearchAsync(
        HttmFacilitySearchQuery query,
        string? provinceCodesCsv = null,
        CancellationToken cancellationToken = default);

    Task<HttmFacilityDto?> GetByIdAsync(Guid id, bool canViewSensitive, CancellationToken cancellationToken = default);

    Task<Guid> InsertAsync(HttmFacilityCreateRequest request, string createdBy, CancellationToken cancellationToken = default);

    Task UpdateAsync(Guid id, HttmFacilityUpdateRequest request, string? updatedBy, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HttmMapFeatureDto>> GetMapDataAsync(
        double west,
        double south,
        double east,
        double north,
        string? typesCsv,
        string? provinceCode,
        int maxRows,
        string? provinceCodesCsv = null,
        CancellationToken cancellationToken = default);

    Task<HttmAuditLogsPageDto> GetAuditLogsAsync(
        Guid facilityId,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<Guid> InsertImageAsync(
        Guid facilityId,
        string imageUrl,
        string imageType,
        string? caption,
        DateOnly? takenDate,
        short sortOrder,
        string? uploadedBy,
        CancellationToken cancellationToken = default);

    Task<int> DeleteImageAsync(Guid imageId, Guid facilityId, CancellationToken cancellationToken = default);

    /// <summary>List ảnh theo facility — sort theo SortOrder ASC, CreatedAt DESC.</summary>
    Task<IReadOnlyList<HttmFacilityImageDto>> ListImagesAsync(Guid facilityId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HttmFacilityLicenseDto>> ListLicensesAsync(Guid facilityId, CancellationToken cancellationToken = default);

    Task<Guid> UpsertLicenseAsync(
        Guid facilityId,
        HttmFacilityLicenseUpsertRequest request,
        CancellationToken cancellationToken = default);

    Task<int> DeleteLicenseAsync(Guid licenseId, Guid facilityId, CancellationToken cancellationToken = default);

    /// <summary>Chỉ để kiểm tra phạm vi tỉnh (Sở).</summary>
    Task<string?> GetProvinceCodeAsync(Guid facilityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Tìm facility theo "khoá tự nhiên" (Name + ProvinceCode + WardCode) — dùng cho flow Import để
    /// skip duplicate. VN sau 2025 chỉ còn tỉnh + xã nên khoá dùng WardCode thay vì DistrictCode.
    /// Trả về <c>null</c> nếu không tìm thấy. Name so sánh không phân biệt hoa thường.
    /// </summary>
    Task<Guid?> FindIdByNaturalKeyAsync(
        string name,
        string provinceCode,
        string? wardCode,
        CancellationToken cancellationToken = default);

    /// <summary>Gán <c>SourceSurveyId</c> và <c>HttmSurveys.LinkedFacilityId</c> (SP Phase 2).</summary>
    Task<(bool Ok, string? Error)> LinkSourceSurveyAsync(
        Guid facilityId,
        Guid surveyId,
        CancellationToken cancellationToken = default);
}
