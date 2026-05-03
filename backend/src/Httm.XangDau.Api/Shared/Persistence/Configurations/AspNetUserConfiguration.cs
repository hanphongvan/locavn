using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AspNetUserConfiguration : IEntityTypeConfiguration<AspNetUser>
{
    public void Configure(EntityTypeBuilder<AspNetUser> b)
    {
        b.ToTable("AspNetUsers");
        b.HasKey(x => x.Id);

        b.Property(x => x.Id).HasMaxLength(128);
        b.Property(x => x.DisplayName).HasMaxLength(255);
        b.Property(x => x.Picture).HasMaxLength(255);
        b.Property(x => x.Email).HasMaxLength(256);
        b.Property(x => x.UserName).HasMaxLength(256).IsRequired();
        b.Property(x => x.Job).HasMaxLength(255);
        b.Property(x => x.Department).HasMaxLength(255);
    }
}
