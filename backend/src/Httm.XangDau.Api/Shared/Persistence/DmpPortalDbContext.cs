using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.Persistence;

/// <summary>
/// EF Core context for existing <c>DMPPortal</c> tables (read-focused phase 1).
/// Table/column names match <c>docs/architecture/database.md</c>. For ad-hoc SQL tied to <c>TENSQL</c> or heavy aggregates,
/// consider Dapper alongside this context in a later phase.
/// </summary>
public sealed class DmpPortalDbContext : DbContext
{
    public DmpPortalDbContext(DbContextOptions<DmpPortalDbContext> options)
        : base(options)
    {
    }

    public DbSet<AspNetRole> AspNetRoles => Set<AspNetRole>();
    public DbSet<AspNetUserClaim> AspNetUserClaims => Set<AspNetUserClaim>();
    public DbSet<AspNetUserLogin> AspNetUserLogins => Set<AspNetUserLogin>();
    public DbSet<AspNetUserRole> AspNetUserRoles => Set<AspNetUserRole>();
    public DbSet<AspNetUser> AspNetUsers => Set<AspNetUser>();

    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    public DbSet<UserDataDeletionRequest> UserDataDeletionRequests => Set<UserDataDeletionRequest>();

    public DbSet<ClientVersionLog> ClientVersionLogs => Set<ClientVersionLog>();

    public DbSet<AppVersionPolicy> AppVersionPolicies => Set<AppVersionPolicy>();

    public DbSet<DmDonVi> DmDonVis => Set<DmDonVi>();
    public DbSet<DmDonViTinh> DmDonViTinhs => Set<DmDonViTinh>();
    public DbSet<DmTinh> DmTinhs => Set<DmTinh>();
    public DbSet<DmXaPhuong> DmXaPhuongs => Set<DmXaPhuong>();
    public DbSet<DmKieuKyBaoCao> DmKieuKyBaoCaos => Set<DmKieuKyBaoCao>();

    public DbSet<StationOperatingHour> StationOperatingHours => Set<StationOperatingHour>();
    public DbSet<StationStoreService> StationStoreServices => Set<StationStoreService>();
    public DbSet<StationReview> StationReviews => Set<StationReview>();
    public DbSet<StationReviewImage> StationReviewImages => Set<StationReviewImage>();

    public DbSet<StationBadReport> StationBadReports => Set<StationBadReport>();
    public DbSet<StationBadReportImage> StationBadReportImages => Set<StationBadReportImage>();

    public DbSet<AppFeedback> AppFeedbacks => Set<AppFeedback>();
    public DbSet<AppFeedbackImage> AppFeedbackImages => Set<AppFeedbackImage>();

    public DbSet<FuelProduct> FuelProducts => Set<FuelProduct>();
    public DbSet<StationPrice> StationPrices => Set<StationPrice>();
    public DbSet<StationProductPrice> StationProductPrices => Set<StationProductPrice>();
    public DbSet<StationInventoryTransaction> StationInventoryTransactions => Set<StationInventoryTransaction>();
    public DbSet<StationInventoryTransactionHeader> StationInventoryTransactionHeaders => Set<StationInventoryTransactionHeader>();
    public DbSet<StationInventoryTransactionDetail> StationInventoryTransactionDetails => Set<StationInventoryTransactionDetail>();

    public DbSet<QtTkChotSoLieu> QtTkChotSoLieus => Set<QtTkChotSoLieu>();
    public DbSet<QtTkThongKe> QtTkThongKes => Set<QtTkThongKe>();
    public DbSet<QtTkThongKeChiTiet> QtTkThongKeChiTiets => Set<QtTkThongKeChiTiet>();
    public DbSet<QtTkThongKeChiTiet02> QtTkThongKeChiTiet02s => Set<QtTkThongKeChiTiet02>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieu> QtTkThongKeChiTietChuyenDuLieus => Set<QtTkThongKeChiTietChuyenDuLieu>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau02> QtTkThongKeChiTietChuyenDuLieuMau02s => Set<QtTkThongKeChiTietChuyenDuLieuMau02>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau05> QtTkThongKeChiTietChuyenDuLieuMau05s => Set<QtTkThongKeChiTietChuyenDuLieuMau05>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau06> QtTkThongKeChiTietChuyenDuLieuMau06s => Set<QtTkThongKeChiTietChuyenDuLieuMau06>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau07> QtTkThongKeChiTietChuyenDuLieuMau07s => Set<QtTkThongKeChiTietChuyenDuLieuMau07>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau07a> QtTkThongKeChiTietChuyenDuLieuMau07as => Set<QtTkThongKeChiTietChuyenDuLieuMau07a>();
    public DbSet<QtTkThongKeChiTietChuyenDuLieuMau08> QtTkThongKeChiTietChuyenDuLieuMau08s => Set<QtTkThongKeChiTietChuyenDuLieuMau08>();

    public DbSet<TkChiTieuBaoCao> TkChiTieuBaoCaos => Set<TkChiTieuBaoCao>();
    public DbSet<TkGiaoBaoCao> TkGiaoBaoCaos => Set<TkGiaoBaoCao>();
    public DbSet<TkGiaoBaoCaoChiTiet> TkGiaoBaoCaoChiTiets => Set<TkGiaoBaoCaoChiTiet>();
    public DbSet<TkQuanLyGiayPhep> TkQuanLyGiayPheps => Set<TkQuanLyGiayPhep>();
    public DbSet<TkQuanLyKhoXangDau> TkQuanLyKhoXangDaus => Set<TkQuanLyKhoXangDau>();
    public DbSet<TkQuanLyKhoXangDauHopDong> TkQuanLyKhoXangDauHopDongs => Set<TkQuanLyKhoXangDauHopDong>();
    public DbSet<TkQuanLyKhoXangDauPhanBoDungTich> TkQuanLyKhoXangDauPhanBoDungTiches => Set<TkQuanLyKhoXangDauPhanBoDungTich>();
    public DbSet<TkQuanLyKhoXangDauTonKho> TkQuanLyKhoXangDauTonKhos => Set<TkQuanLyKhoXangDauTonKho>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DmpPortalDbContext).Assembly);
    }
}
