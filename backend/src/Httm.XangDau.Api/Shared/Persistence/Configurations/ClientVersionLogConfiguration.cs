using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class ClientVersionLogConfiguration : IEntityTypeConfiguration<ClientVersionLog>
{
    public void Configure(EntityTypeBuilder<ClientVersionLog> b)
    {
        b.ToTable("ClientVersionLog");
        b.HasKey(x => x.Id);

        b.Property(x => x.Id).UseIdentityColumn();
        b.Property(x => x.RequestTime).HasColumnType("datetime2(0)").HasDefaultValueSql("SYSUTCDATETIME()");
        b.Property(x => x.AppVersion).HasMaxLength(40).IsRequired();
        b.Property(x => x.AppBuild).HasMaxLength(40);
        b.Property(x => x.Platform).HasMaxLength(10).IsRequired();
        b.Property(x => x.ClientId).HasMaxLength(64);
        b.Property(x => x.RemoteIp).HasMaxLength(45);
        b.Property(x => x.Path).HasMaxLength(200);

        b.HasIndex(x => x.RequestTime);
        b.HasIndex(x => new { x.AppVersion, x.Platform });
        b.HasIndex(x => x.ClientId);
    }
}
