namespace Httm.XangDau.Api.Features.Httm.Contracts;

/// <summary>Hồ sơ cơ sở HTTM — đầy đủ trường (map từ <c>sp_Httm_Facility_GetById</c> + API).</summary>
public sealed class HttmFacilityDto
{
    public Guid Id { get; init; }

    public string Name { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;

    public string ProvinceCode { get; init; } = string.Empty;
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? AddressDetail { get; init; }

    public double? Lat { get; init; }
    public double? Lng { get; init; }
    public string? GpsAccuracy { get; init; }

    public decimal? LandArea { get; init; }
    public decimal? FloorArea { get; init; }
    public short? Floors { get; init; }
    public int? StallCount { get; init; }
    public decimal? AvgStallArea { get; init; }
    public int? ParkingSlots { get; init; }

    public short? YearEstablished { get; init; }
    public short? YearRenovated { get; init; }
    public string? OwnerName { get; init; }
    public string? OperatorName { get; init; }
    public string? OperatorUserId { get; init; }

    public decimal? FillRate { get; init; }
    public int? VendorCount { get; init; }

    /// <summary>Chỉ có giá trị khi caller được phép xem dữ liệu nhạy cảm (BCT/ADMIN/HTTM_ADMIN).</summary>
    public decimal? AvgRentPrice { get; set; }

    /// <summary>Chỉ có giá trị khi caller được phép xem dữ liệu nhạy cảm.</summary>
    public decimal? AnnualRevenue { get; set; }

    public bool HasBackupPower { get; init; }
    public bool HasFireProtection { get; init; }
    public string? BuildingQuality { get; init; }

    public Guid? SourceSurveyId { get; init; }
    public string? Notes { get; init; }

    public string CreatedBy { get; init; } = string.Empty;
    public string? UpdatedBy { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }

    /// <summary>Bản sao cờ từ SP: client biết response đã gồm trường nhạy cảm hay chưa.</summary>
    public bool IsSensitiveVisible { get; init; }
}

/// <summary>Bản ghi nhẹ cho danh sách / tìm kiếm.</summary>
public sealed class HttmFacilityListItemDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string ProvinceCode { get; init; } = string.Empty;
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? AddressDetail { get; init; }
    public decimal? LandArea { get; init; }
    public decimal? FloorArea { get; init; }
    public int? StallCount { get; init; }
    public short? YearEstablished { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

/// <summary>Body tạo mới — <c>CreatedBy</c> do service gán từ user đăng nhập.</summary>
public sealed class HttmFacilityCreateRequest
{
    public string Name { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string ProvinceCode { get; init; } = string.Empty;
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? AddressDetail { get; init; }

    /// <summary>Vĩ độ. Mutable để service chuẩn hoá toạ độ 0 → null (xem NormalizeCoordinates).</summary>
    public double? Lat { get; set; }

    /// <summary>Kinh độ. Mutable cùng lý do với <see cref="Lat"/>.</summary>
    public double? Lng { get; set; }
    public string? GpsAccuracy { get; init; }
    public decimal? LandArea { get; init; }
    public decimal? FloorArea { get; init; }
    public short? Floors { get; init; }
    public int? StallCount { get; init; }
    public decimal? AvgStallArea { get; init; }
    public int? ParkingSlots { get; init; }
    public short? YearEstablished { get; init; }
    public short? YearRenovated { get; init; }
    public string? OwnerName { get; init; }
    public string? OperatorName { get; init; }
    public string? OperatorUserId { get; init; }
    public decimal? FillRate { get; init; }
    public int? VendorCount { get; init; }
    public decimal? AvgRentPrice { get; init; }
    public decimal? AnnualRevenue { get; init; }
    public bool? HasBackupPower { get; init; }
    public bool? HasFireProtection { get; init; }
    public string? BuildingQuality { get; init; }
    public Guid? SourceSurveyId { get; init; }
    public string? Notes { get; init; }
}

/// <summary>Body cập nhật một phần — mọi trường nullable: null = không đổi.</summary>
public sealed class HttmFacilityUpdateRequest
{
    public string? Name { get; init; }
    public string? HttmType { get; init; }
    public string? Status { get; init; }
    public string? ProvinceCode { get; init; }
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? AddressDetail { get; init; }

    /// <summary>Vĩ độ. Mutable để service chuẩn hoá toạ độ 0 → null (xem NormalizeCoordinates).</summary>
    public double? Lat { get; set; }

    /// <summary>Kinh độ. Mutable cùng lý do với <see cref="Lat"/>.</summary>
    public double? Lng { get; set; }
    /// <summary>Khi <c>true</c>, xóa toạ độ (map tới <c>@ClearLocation</c> trong SP).</summary>
    public bool ClearLocation { get; init; }
    public string? GpsAccuracy { get; init; }
    public decimal? LandArea { get; init; }
    public decimal? FloorArea { get; init; }
    public short? Floors { get; init; }
    public int? StallCount { get; init; }
    public decimal? AvgStallArea { get; init; }
    public int? ParkingSlots { get; init; }
    public short? YearEstablished { get; init; }
    public short? YearRenovated { get; init; }
    public string? OwnerName { get; init; }
    public string? OperatorName { get; init; }
    public string? OperatorUserId { get; init; }
    public decimal? FillRate { get; init; }
    public int? VendorCount { get; init; }

    /// <summary>Giá thuê TB. Mutable để service ép giá trị cũ khi caller không có quyền xem sensitive (chống wipe-by-null).</summary>
    public decimal? AvgRentPrice { get; set; }

    /// <summary>Doanh thu hàng năm. Mutable cùng lý do với <see cref="AvgRentPrice"/>.</summary>
    public decimal? AnnualRevenue { get; set; }

    public bool? HasBackupPower { get; init; }
    public bool? HasFireProtection { get; init; }
    public string? BuildingQuality { get; init; }
    public Guid? SourceSurveyId { get; init; }
    public string? Notes { get; init; }
}

/// <summary>Query tìm kiếm (query string).</summary>
public sealed class HttmFacilitySearchQuery
{
    public string? Q { get; init; }
    public string? HttmType { get; init; }
    public string? ProvinceCode { get; init; }
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? Status { get; init; }
    public decimal? AreaMin { get; init; }
    public decimal? AreaMax { get; init; }
    public int? StallMin { get; init; }
    public int? StallMax { get; init; }
    public short? YearFrom { get; init; }
    public short? YearTo { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}

/// <summary>
/// Chuẩn hoá toạ độ trước khi validate/ghi DB. Nghiệp vụ coi <c>Lat=0</c> hoặc <c>Lng=0</c> là
/// "chưa nhập" (form/app gửi 0 thay vì để trống) → ép null để không vướng ràng buộc
/// "Lat và Lng phải cùng có hoặc cùng không". An toàn cho VN vì toạ độ thực luôn lat≈8–23, lng≈102–110,
/// không bao giờ đúng 0.
/// </summary>
public static class HttmCoordinateNormalizer
{
    public static void NormalizeCoordinates(this HttmFacilityCreateRequest r)
    {
        if (r.Lat == 0) r.Lat = null;
        if (r.Lng == 0) r.Lng = null;
    }

    public static void NormalizeCoordinates(this HttmFacilityUpdateRequest r)
    {
        if (r.Lat == 0) r.Lat = null;
        if (r.Lng == 0) r.Lng = null;
    }
}
