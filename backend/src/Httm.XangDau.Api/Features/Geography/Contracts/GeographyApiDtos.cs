namespace Httm.XangDau.Api.Features.Geography.Contracts;

public sealed record ProvinceResponseDto(int Id, string Code, string Name, int? SapXep, int? VungMien);

/// <summary>
/// District list is derived from distinct <c>DM_XaPhuong.QuanHuyenId</c> for the province.
/// <c>DistrictCode</c> is the numeric id string until <c>DM_QuanHuyen</c> master is documented with Ma/Ten.
/// </summary>
public sealed record DistrictResponseDto(int DistrictId, string DistrictCode, string? DistrictName);

public sealed record WardResponseDto(string Code, string Name, int? TinhId, int? QuanHuyenId);
