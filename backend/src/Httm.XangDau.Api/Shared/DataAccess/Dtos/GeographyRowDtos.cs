namespace Httm.XangDau.Api.Shared.DataAccess.Dtos;

public sealed record ProvinceRowDto(int Id, string Ma, string Ten, int? SapXep, int? VungMien);

public sealed record ProvinceSummaryRowDto(int Id, string Ma, string Ten);

public sealed record WardRowDto(string Ma, string Ten, int? TinhId, int? QuanHuyenId);
