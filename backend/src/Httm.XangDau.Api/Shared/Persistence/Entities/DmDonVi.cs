namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>DM_DonVi</c> — columns per <c>docs/architecture/database.md</c>.</summary>
public sealed class DmDonVi
{
    public int Id { get; set; }
    public string Ma { get; set; } = null!;
    public string Ten { get; set; } = null!;
    public string? TenTiengNuocNgoai { get; set; }
    public string? DienThoai { get; set; }
    public string? DiaChi { get; set; }
    public string? Email { get; set; }
    public string? SoTaiKhoan { get; set; }
    public int? SapXep { get; set; }
    public bool? UngPhep { get; set; }
    public int? CapTrenId { get; set; }
    public int? Cap { get; set; }
    public string? MaAo { get; set; }
    public int? CoCapCon { get; set; }
    public int? CongThucId { get; set; }
    public DateTime? NgayThanhLap { get; set; }
    public DateTime? NgayGiaiThe { get; set; }
    public string? TenKhongDau { get; set; }
    public int? ThuocDonViId { get; set; }
    public int? PhanLoaiId { get; set; }
    public int? PhanQuyen { get; set; }
    public int? TT { get; set; }
    public int? TN { get; set; }
    public int? ThuocCap { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public byte[]? Version { get; set; }
    public string? Ky_ThuTruongDonVi { get; set; }
    public string? Ky_KeToanTruong { get; set; }
    public string? Ky_NguoiLapBaoCao { get; set; }
    public string? Ky_ThuKho { get; set; }
    public string? Ky_ThuQuy { get; set; }
    public Guid? IdGuid { get; set; }
    public int CapDonViId { get; set; }
    public bool? TrangThai { get; set; }
    public int? VungMien { get; set; }
    public string? SoGiayPhep { get; set; }
    public DateTime? NgayCap { get; set; }
    public DateTime? NgayHetHan { get; set; }
    public int? Tinh { get; set; }
    public int? Xa { get; set; }
    public string? DiaChiChiTiet { get; set; }
    public int? NoiCapId { get; set; }
    public int? LoaiHinh { get; set; }
    public int? ThemMoi { get; set; }
    public string? CapTrenText { get; set; }
    /// <summary>Latitude (<c>ViDo</c>, <c>DECIMAL(9,6)</c> per schema).</summary>
    public decimal? ViDo { get; set; }
    /// <summary>Longitude (<c>KinhDo</c>, <c>DECIMAL(9,6)</c> per schema).</summary>
    public decimal? KinhDo { get; set; }

    /// <summary>Giờ mở cửa (<c>time</c> per store-admin extension in <c>docs/architecture/database.md</c>).</summary>
    public TimeOnly? OpenTime { get; set; }

    /// <summary>Giờ đóng cửa (<c>time</c> per store-admin extension).</summary>
    public TimeOnly? CloseTime { get; set; }

    /// <summary>Optional weekly hours (<c>StationOperatingHours</c> table, app extension).</summary>
    public ICollection<StationOperatingHour> OperatingHours { get; set; } = new List<StationOperatingHour>();

    /// <summary>Optional retail services (<c>StationStoreServices</c> table, app extension).</summary>
    public ICollection<StationStoreService> StoreServices { get; set; } = new List<StationStoreService>();

    /// <summary>Public reviews (<c>StationReviews</c> table, app extension).</summary>
    public ICollection<StationReview> Reviews { get; set; } = new List<StationReview>();
}
