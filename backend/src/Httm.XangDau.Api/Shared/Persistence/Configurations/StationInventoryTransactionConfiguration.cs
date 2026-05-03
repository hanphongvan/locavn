using Httm.XangDau.Api.Shared.Persistence.Entities;

using Microsoft.EntityFrameworkCore;

using Microsoft.EntityFrameworkCore.Metadata.Builders;



namespace Httm.XangDau.Api.Shared.Persistence.Configurations;



public sealed class StationInventoryTransactionConfiguration : IEntityTypeConfiguration<StationInventoryTransaction>

{

    public void Configure(EntityTypeBuilder<StationInventoryTransaction> b)

    {

        b.ToTable("StationInventoryTransactions");

        b.HasKey(x => x.Id);



        b.Property(x => x.Quantity).HasPrecision(18, 3).IsRequired();

        b.Property(x => x.Amount).HasPrecision(18, 2);

        b.Property(x => x.TransactionDate).HasColumnType("datetime").IsRequired();

        b.Property(x => x.Note).HasMaxLength(500);

        b.Property(x => x.Created).HasColumnType("datetime").IsRequired();

        b.Property(x => x.Modified).HasColumnType("datetime").IsRequired();

        b.Property(x => x.CreatedBy).HasMaxLength(100);

        b.Property(x => x.ModifiedBy).HasMaxLength(100);



        b.HasIndex(x => new { x.DonViId, x.ProductId, x.TransactionDate })

            .IsDescending(false, false, true);

    }

}


