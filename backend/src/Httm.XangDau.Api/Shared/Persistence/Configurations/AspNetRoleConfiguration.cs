using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AspNetRoleConfiguration : IEntityTypeConfiguration<AspNetRole>
{
    public void Configure(EntityTypeBuilder<AspNetRole> b)
    {
        b.ToTable("AspNetRoles");
        b.HasKey(x => x.Id);

        b.Property(x => x.Id).HasMaxLength(128);
        b.Property(x => x.Name).HasMaxLength(256).IsRequired();
        b.Property(x => x.SortOrder).HasColumnName("Order");
        b.Property(x => x.Description).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
    }
}
