using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationInventoryTransactionDetailConfiguration : IEntityTypeConfiguration<StationInventoryTransactionDetail>
{
    public void Configure(EntityTypeBuilder<StationInventoryTransactionDetail> b)
    {
        b.ToTable("StationInventoryTransactionDetails");

        b.HasKey(x => x.Id);

        b.Property(x => x.Quantity).HasPrecision(18, 3).IsRequired();
        b.Property(x => x.Amount).HasPrecision(18, 2);
        b.Property(x => x.Note).HasMaxLength(500);

        b.HasOne(x => x.Header)
            .WithMany(x => x.Details)
            .HasForeignKey(x => x.HeaderId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasOne<FuelProduct>()
            .WithMany()
            .HasForeignKey(x => x.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne(x => x.Unit)
            .WithMany()
            .HasForeignKey(x => x.UnitId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
