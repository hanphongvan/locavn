namespace Httm.XangDau.Api.Features.Leader.Contracts;

/// <summary>Đầu mối — <c>DM_DonVi</c> (Cap 235) + tồn / ngày dự trữ từ <c>A_TienIch_BanDo_TonKho_DauMoi</c> khi khớp được.</summary>
/// <param name="TrangThaiXang">0 an toàn, 1 cảnh báo, 2 nguy cơ — cùng quy tắc <c>fn_Leader_Map_DistributorReserveDisplayStatus</c>.</param>
public sealed record LeaderMapDistributorDto(
    int Id,
    string TenDonVi,
    string? DiaChi,
    decimal Lat,
    decimal Lng,
    string? LogoUrl,
    decimal TonXang,
    decimal TonDau,
    int? DaysXang,
    int? DaysDau,
    byte TrangThaiXang,
    byte TrangThaiDau);

public sealed record LeaderMapDistributorsResponse(IReadOnlyList<LeaderMapDistributorDto> Items);

/// <summary>Tồn / ngày dự trữ đầu mối — cùng nguồn ghép <c>A_TienIch_BanDo_TonKho_DauMoi</c> như danh sách bản đồ.</summary>
public sealed record LeaderMapDistributorInventoryResponse(
    int Id,
    string TenDonVi,
    string? DiaChi,
    decimal TonXang,
    decimal TonDau,
    int? DaysXang,
    int? DaysDau,
    byte TrangThaiXang,
    byte TrangThaiDau);

public sealed record LeaderMapBadReportDto(int Id, string Content, DateTime CreatedAt, string Status);

public sealed record LeaderMapViolationsResponse(int StationId, IReadOnlyList<LeaderMapBadReportDto> Items);

public sealed record LeaderMapStationPriceDto(int StationId, decimal? PriceRon95, decimal? PriceDiesel);

public sealed record LeaderMapPricesResponse(IReadOnlyList<LeaderMapStationPriceDto> Items);
