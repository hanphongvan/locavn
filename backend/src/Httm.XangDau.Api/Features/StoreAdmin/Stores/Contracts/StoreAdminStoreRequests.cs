using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;

/// <summary>Body for POST/PUT — only fields managed by store admin (DB column names).</summary>
public sealed class StoreAdminStoreUpsertRequest
{
    [Required]
    [MaxLength(20)]
    public string Ma { get; set; } = null!;

    [Required]
    [MaxLength(200)]
    public string Ten { get; set; } = null!;

    [MaxLength(50)]
    public string? DienThoai { get; set; }

    [MaxLength(250)]
    public string? DiaChi { get; set; }

    [MaxLength(50)]
    public string? Email { get; set; }

    public bool? TrangThai { get; set; }

    public int? Tinh { get; set; }

    public int? Xa { get; set; }

    [MaxLength(500)]
    public string? DiaChiChiTiet { get; set; }

    public decimal? ViDo { get; set; }

    public decimal? KinhDo { get; set; }

    public TimeOnly? OpenTime { get; set; }

    public TimeOnly? CloseTime { get; set; }
}
