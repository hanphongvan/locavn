using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AspNetUserClaimConfiguration : IEntityTypeConfiguration<AspNetUserClaim>
{
    public void Configure(EntityTypeBuilder<AspNetUserClaim> b)
    {
        b.ToTable("AspNetUserClaims");
        b.HasKey(x => x.Id);

        b.Property(x => x.UserId).HasMaxLength(128).IsRequired();

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
