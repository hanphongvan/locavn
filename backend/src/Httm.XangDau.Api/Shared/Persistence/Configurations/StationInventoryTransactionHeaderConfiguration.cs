using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationInventoryTransactionHeaderConfiguration : IEntityTypeConfiguration<StationInventoryTransactionHeader>
{
    public void Configure(EntityTypeBuilder<StationInventoryTransactionHeader> b)
    {
        b.ToTable("StationInventoryTransactionHeaders");

        b.HasKey(x => x.Id);

        b.Property(x => x.TransactionDate).HasColumnType("datetime").IsRequired();
        b.Property(x => x.Note).HasMaxLength(500);
        b.Property(x => x.Created).HasColumnType("datetime").IsRequired();
        b.Property(x => x.Modified).HasColumnType("datetime").IsRequired();
        b.Property(x => x.CreatedBy).HasMaxLength(100);
        b.Property(x => x.ModifiedBy).HasMaxLength(100);
    }
}
