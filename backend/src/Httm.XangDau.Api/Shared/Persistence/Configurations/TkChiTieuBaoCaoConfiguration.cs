using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkChiTieuBaoCaoConfiguration : IEntityTypeConfiguration<TkChiTieuBaoCao>
{
    public void Configure(EntityTypeBuilder<TkChiTieuBaoCao> b)
    {
        b.ToTable("TK_ChiTieuBaoCao");
        b.HasKey(x => x.Id);

        b.Property(x => x.IdChiTieu).HasColumnName("IDCHITIEU");
        b.Property(x => x.MaReport).HasColumnName("MAREPORT").HasMaxLength(50);
        b.Property(x => x.MaStt).HasColumnName("MASTT").HasMaxLength(50);
        b.Property(x => x.Ma).HasColumnName("MA").HasMaxLength(100);
        b.Property(x => x.Ten).HasColumnName("TEN").HasMaxLength(1000);
        b.Property(x => x.CongMaSo).HasColumnName("CONGMASO").HasMaxLength(300);
        b.Property(x => x.IndexOrder).HasColumnName("INDEXORDER");
        b.Property(x => x.RecordType).HasColumnName("RECORDTYPE");
        b.Property(x => x.IdStyle).HasColumnName("IDSTYLE");
        b.Property(x => x.IdNhom).HasColumnName("IDNHOM");
        b.Property(x => x.Stt).HasColumnName("STT");
        b.Property(x => x.QuyetDinh).HasColumnName("QUYETDINH").HasMaxLength(50);
        b.Property(x => x.TheoThongTu).HasColumnName("THEOTHONGTU").HasMaxLength(50);
        b.Property(x => x.ChuDam).HasColumnName("CHUDAM");
        b.Property(x => x.TenSql).HasColumnName("TENSQL").HasMaxLength(300);
        b.Property(x => x.TenNgoaiNgu).HasColumnName("TENNGOAINGU").HasMaxLength(300);
        b.Property(x => x.Parent).HasColumnName("Parent");
        b.Property(x => x.Cap).HasColumnName("Cap");
        b.Property(x => x.CoCapCon).HasColumnName("CoCapCon");
        b.Property(x => x.MaAo).HasColumnName("MaAo").HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasColumnName("CreatedBy").HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasColumnName("ModifiedBy").HasMaxLength(50);
        b.Property(x => x.Versions).HasColumnName("Versions").IsRowVersion();
        b.Property(x => x.CongMaSo2).HasColumnName("CONGMASO2").HasMaxLength(300);
        b.Property(x => x.HienThi).HasColumnName("HienThi");
        b.Property(x => x.DonViTinhId).HasColumnName("DonViTinhId");
        b.Property(x => x.DonViTinh05Id).HasColumnName("DonViTinh05Id");
        b.Property(x => x.DonViTinh02Id).HasColumnName("DonViTinh02Id");
    }
}
