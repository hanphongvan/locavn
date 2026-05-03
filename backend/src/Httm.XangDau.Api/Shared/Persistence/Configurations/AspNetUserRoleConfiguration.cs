using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AspNetUserRoleConfiguration : IEntityTypeConfiguration<AspNetUserRole>
{
    public void Configure(EntityTypeBuilder<AspNetUserRole> b)
    {
        b.ToTable("AspNetUserRoles");
        b.HasKey(x => new { x.UserId, x.RoleId });

        b.Property(x => x.UserId).HasMaxLength(128);
        b.Property(x => x.RoleId).HasMaxLength(128);

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        b.HasOne<AspNetRole>()
            .WithMany()
            .HasForeignKey(x => x.RoleId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
