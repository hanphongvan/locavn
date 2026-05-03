using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkQuanLyKhoXangDauTonKhoConfiguration : IEntityTypeConfiguration<TkQuanLyKhoXangDauTonKho>
{
    public void Configure(EntityTypeBuilder<TkQuanLyKhoXangDauTonKho> b)
    {
        b.ToTable("TK_QuanLyKhoXangDau_TonKho");
        b.HasKey(x => x.Id);

        b.Property(x => x.SoLuong).HasPrecision(18, 3);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
    }
}
