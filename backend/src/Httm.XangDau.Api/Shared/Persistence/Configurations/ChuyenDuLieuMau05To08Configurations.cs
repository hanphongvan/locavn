using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkThongKeChiTietChuyenDuLieuMau05Configuration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieuMau05>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau05> b) =>
        ChuyenDuLieuMau05To08Configurations.ConfigureExtended(b, "QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau05");
}

public sealed class QtTkThongKeChiTietChuyenDuLieuMau06Configuration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieuMau06>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau06> b) =>
        ChuyenDuLieuMau05To08Configurations.ConfigureExtended(b, "QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau06");
}

public sealed class QtTkThongKeChiTietChuyenDuLieuMau07Configuration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieuMau07>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau07> b) =>
        ChuyenDuLieuMau05To08Configurations.ConfigureExtended(b, "QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07");
}

public sealed class QtTkThongKeChiTietChuyenDuLieuMau07aConfiguration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieuMau07a>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau07a> b) =>
        ChuyenDuLieuMau05To08Configurations.ConfigureExtended(b, "QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07a");
}

public sealed class QtTkThongKeChiTietChuyenDuLieuMau08Configuration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieuMau08>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau08> b) =>
        ChuyenDuLieuMau05To08Configurations.ConfigureExtended(b, "QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau08");
}

internal static class ChuyenDuLieuMau05To08Configurations
{
    internal static void ConfigureExtended(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau05> b, string table) =>
        ConfigureExtendedCore(
            b,
            table,
            x => x.Nhom,
            x => x.DonViId,
            x => x.ThoiGian,
            x => x.KieuKyBaoCao,
            x => x.Created,
            x => x.CreatedBy,
            x => x.TenThongKe,
            x => x.MaSo,
            x => x.Dvt,
            x => x.ThiTruong,
            x => x.So_01,
            x => x.So_02,
            x => x.So_03,
            x => x.So_04,
            x => x.So_05,
            x => x.So_06,
            x => x.So_07,
            x => x.So_08,
            x => x.So_09,
            x => x.So_10,
            x => x.So_11,
            x => x.So_12,
            x => x.So_13,
            x => x.So_14,
            x => x.So_15,
            x => x.So_16,
            x => x.So_17,
            x => x.So_18,
            x => x.So_19,
            x => x.So_20);

    internal static void ConfigureExtended(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau06> b, string table) =>
        ConfigureExtendedCore(
            b,
            table,
            x => x.Nhom,
            x => x.DonViId,
            x => x.ThoiGian,
            x => x.KieuKyBaoCao,
            x => x.Created,
            x => x.CreatedBy,
            x => x.TenThongKe,
            x => x.MaSo,
            x => x.Dvt,
            x => x.ThiTruong,
            x => x.So_01,
            x => x.So_02,
            x => x.So_03,
            x => x.So_04,
            x => x.So_05,
            x => x.So_06,
            x => x.So_07,
            x => x.So_08,
            x => x.So_09,
            x => x.So_10,
            x => x.So_11,
            x => x.So_12,
            x => x.So_13,
            x => x.So_14,
            x => x.So_15,
            x => x.So_16,
            x => x.So_17,
            x => x.So_18,
            x => x.So_19,
            x => x.So_20);

    internal static void ConfigureExtended(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau07> b, string table) =>
        ConfigureExtendedCore(
            b,
            table,
            x => x.Nhom,
            x => x.DonViId,
            x => x.ThoiGian,
            x => x.KieuKyBaoCao,
            x => x.Created,
            x => x.CreatedBy,
            x => x.TenThongKe,
            x => x.MaSo,
            x => x.Dvt,
            x => x.ThiTruong,
            x => x.So_01,
            x => x.So_02,
            x => x.So_03,
            x => x.So_04,
            x => x.So_05,
            x => x.So_06,
            x => x.So_07,
            x => x.So_08,
            x => x.So_09,
            x => x.So_10,
            x => x.So_11,
            x => x.So_12,
            x => x.So_13,
            x => x.So_14,
            x => x.So_15,
            x => x.So_16,
            x => x.So_17,
            x => x.So_18,
            x => x.So_19,
            x => x.So_20);

    internal static void ConfigureExtended(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau07a> b, string table) =>
        ConfigureExtendedCore(
            b,
            table,
            x => x.Nhom,
            x => x.DonViId,
            x => x.ThoiGian,
            x => x.KieuKyBaoCao,
            x => x.Created,
            x => x.CreatedBy,
            x => x.TenThongKe,
            x => x.MaSo,
            x => x.Dvt,
            x => x.ThiTruong,
            x => x.So_01,
            x => x.So_02,
            x => x.So_03,
            x => x.So_04,
            x => x.So_05,
            x => x.So_06,
            x => x.So_07,
            x => x.So_08,
            x => x.So_09,
            x => x.So_10,
            x => x.So_11,
            x => x.So_12,
            x => x.So_13,
            x => x.So_14,
            x => x.So_15,
            x => x.So_16,
            x => x.So_17,
            x => x.So_18,
            x => x.So_19,
            x => x.So_20);

    internal static void ConfigureExtended(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieuMau08> b, string table) =>
        ConfigureExtendedCore(
            b,
            table,
            x => x.Nhom,
            x => x.DonViId,
            x => x.ThoiGian,
            x => x.KieuKyBaoCao,
            x => x.Created,
            x => x.CreatedBy,
            x => x.TenThongKe,
            x => x.MaSo,
            x => x.Dvt,
            x => x.ThiTruong,
            x => x.So_01,
            x => x.So_02,
            x => x.So_03,
            x => x.So_04,
            x => x.So_05,
            x => x.So_06,
            x => x.So_07,
            x => x.So_08,
            x => x.So_09,
            x => x.So_10,
            x => x.So_11,
            x => x.So_12,
            x => x.So_13,
            x => x.So_14,
            x => x.So_15,
            x => x.So_16,
            x => x.So_17,
            x => x.So_18,
            x => x.So_19,
            x => x.So_20);

    private static void ConfigureExtendedCore<TEntity>(
        EntityTypeBuilder<TEntity> b,
        string table,
        System.Linq.Expressions.Expression<Func<TEntity, int?>> nhom,
        System.Linq.Expressions.Expression<Func<TEntity, int?>> donViId,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> thoiGian,
        System.Linq.Expressions.Expression<Func<TEntity, int?>> kieuKyBaoCao,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> created,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> createdBy,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> tenThongKe,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> maSo,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> dvt,
        System.Linq.Expressions.Expression<Func<TEntity, string?>> thiTruong,
        params System.Linq.Expressions.Expression<Func<TEntity, decimal?>>[] so)
        where TEntity : class
    {
        b.ToTable(table);
        b.HasNoKey();

        b.Property(nhom);
        b.Property(donViId);
        b.Property(thoiGian).HasMaxLength(200);
        b.Property(kieuKyBaoCao);
        b.Property(created).HasMaxLength(50);
        b.Property(createdBy).HasMaxLength(50);
        b.Property(tenThongKe).HasMaxLength(200);
        b.Property(maSo).HasMaxLength(50);
        b.Property(dvt).HasColumnName("DVT").HasMaxLength(200);
        b.Property(thiTruong).HasMaxLength(200);

        foreach (var p in so)
            b.Property(p).HasPrecision(28, 3);
    }
}
