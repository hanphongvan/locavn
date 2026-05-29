namespace Httm.XangDau.Api.Features.Httm.Import.Contracts;

/// <summary>Tham số sinh file template Excel — load runtime để pre-fill tỉnh + dropdown xã của user.</summary>
public sealed class HttmTemplateBuildInput
{
    /// <summary>Mã tỉnh mặc định pre-fill 2 dòng sample (cán bộ Sở). <c>null</c> với role toàn quốc.</summary>
    public string? DefaultProvinceCode { get; init; }

    /// <summary>Danh sách 63 tỉnh (Code + Tên) — đổ vào Sheet DanhMuc + dropdown cột Mã tỉnh.</summary>
    public IReadOnlyList<(string Code, string Name)> Provinces { get; init; } = [];

    /// <summary>Danh sách xã của tỉnh mặc định (nếu có) — đổ vào Sheet DanhMuc + dropdown cột Mã xã.
    /// Để rỗng nếu user là toàn quốc (national role) — họ sẽ phải nhập tay hoặc copy từ trang tham chiếu.</summary>
    public IReadOnlyList<(string Code, string Name)> Wards { get; init; } = [];
}

/// <summary>1 dòng trong file import — đã parse từ Excel, sẵn sàng map sang <c>HttmFacilityCreateRequest</c>.</summary>
public sealed class HttmImportRowDto
{
    /// <summary>Số dòng trong Excel (1-based, tính cả header). Dùng để hiển thị lỗi cho user.</summary>
    public int RowNumber { get; init; }

    public string? Name { get; init; }
    public string? HttmType { get; init; }
    public string? Status { get; init; }
    public string? ProvinceCode { get; init; }
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
    public decimal? FillRate { get; init; }
    public int? VendorCount { get; init; }
    public decimal? AvgRentPrice { get; init; }
    public decimal? AnnualRevenue { get; init; }
    public bool? HasBackupPower { get; init; }
    public bool? HasFireProtection { get; init; }
    public string? BuildingQuality { get; init; }
    public string? Notes { get; init; }
}

/// <summary>Lỗi parse/validate cho 1 cell hoặc 1 dòng.</summary>
public sealed class HttmImportRowErrorDto
{
    public int RowNumber { get; init; }
    public string? Column { get; init; }
    public string Message { get; init; } = string.Empty;
}

/// <summary>Response của <c>POST /api/httm/import/validate</c>.</summary>
public sealed class HttmImportValidateResponse
{
    /// <summary>Token để gọi <c>confirm</c> trong vòng 10 phút.</summary>
    public string SessionToken { get; init; } = string.Empty;

    public int TotalRows { get; init; }
    public int ValidCount { get; init; }
    public int ErrorCount { get; init; }
    public int SkippedDuplicateCount { get; init; }

    /// <summary>Các dòng hợp lệ — preview cho user (giới hạn 100 dòng đầu).</summary>
    public IReadOnlyList<HttmImportRowDto> ValidRowsPreview { get; init; } = [];

    /// <summary>Các lỗi validate — preview cho user (giới hạn 200 lỗi đầu).</summary>
    public IReadOnlyList<HttmImportRowErrorDto> Errors { get; init; } = [];
}

/// <summary>Body của <c>POST /api/httm/import/confirm</c>.</summary>
public sealed class HttmImportConfirmRequest
{
    public string SessionToken { get; init; } = string.Empty;

    /// <summary>Nếu <c>true</c>: bỏ qua các dòng lỗi, chỉ tạo các dòng hợp lệ.
    /// Nếu <c>false</c>: chỉ confirm khi không có lỗi nào (mặc định).</summary>
    public bool SkipErrors { get; init; }
}

/// <summary>Response của <c>POST /api/httm/import/confirm</c>.</summary>
public sealed class HttmImportConfirmResponse
{
    public int Created { get; init; }
    public int SkippedDuplicates { get; init; }
    public int SkippedErrors { get; init; }
    public IReadOnlyList<HttmImportRowErrorDto> PerRowErrors { get; init; } = [];
}
