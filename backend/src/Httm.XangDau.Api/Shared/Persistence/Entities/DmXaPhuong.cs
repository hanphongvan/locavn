namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>DM_XaPhuong</c>.</summary>
public sealed class DmXaPhuong
{
    public int Id { get; set; }
    public string Ma { get; set; } = null!;
    public string Ten { get; set; } = null!;
    public string? TenTiengNuocNgoai { get; set; }
    public int? QuanHuyenId { get; set; }
    public int? TinhId { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public byte[]? Version { get; set; }
    public string? MaTinh { get; set; }
}
