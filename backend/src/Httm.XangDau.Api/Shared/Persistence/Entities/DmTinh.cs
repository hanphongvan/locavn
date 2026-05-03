namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>DM_Tinh</c>.</summary>
public sealed class DmTinh
{
    public int Id { get; set; }
    public string Ma { get; set; } = null!;
    public string Ten { get; set; } = null!;
    public string? TenTiengNuocNgoai { get; set; }
    public int? SapXep { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public byte[]? Version { get; set; }
    public int? VungMien { get; set; }
}
