namespace Httm.XangDau.Api.Features.Leader.Persistence;

public sealed class LeaderMapDistributorUnitSqlRow
{
    public int Id { get; init; }

    public string TenDonVi { get; init; } = string.Empty;

    public string? DiaChi { get; init; }

    public double KinhDo { get; init; }

    public double ViDo { get; init; }

    public string? LogoUrl { get; init; }
}

public sealed class LeaderMapBadReportSqlRow
{
    public int Id { get; init; }

    public string Content { get; init; } = string.Empty;

    public DateTime CreatedAt { get; init; }

    public byte Status { get; init; }
}
