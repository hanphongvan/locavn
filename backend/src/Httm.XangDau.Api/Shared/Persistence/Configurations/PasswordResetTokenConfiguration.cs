using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class PasswordResetTokenConfiguration : IEntityTypeConfiguration<PasswordResetToken>
{
    public void Configure(EntityTypeBuilder<PasswordResetToken> b)
    {
        b.ToTable("PasswordResetTokens");

        b.HasKey(x => x.Id);
        b.Property(x => x.Id).ValueGeneratedOnAdd();

        b.Property(x => x.UserId).HasMaxLength(128).IsRequired();
        b.Property(x => x.TokenHash).HasMaxLength(256).IsRequired();
        b.Property(x => x.ExpiresAt).IsRequired();
        b.Property(x => x.CreatedAt).IsRequired();
        b.Property(x => x.CreatedIp).HasMaxLength(50);
        b.Property(x => x.UserAgent).HasMaxLength(500);

        b.HasIndex(x => x.TokenHash).HasDatabaseName("IX_PasswordResetTokens_TokenHash");
        b.HasIndex(x => x.UserId).HasDatabaseName("IX_PasswordResetTokens_UserId");
        b.HasIndex(x => x.ExpiresAt).HasDatabaseName("IX_PasswordResetTokens_ExpiresAt");

        b.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
