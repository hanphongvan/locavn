using System.Reflection;
using System.Text.RegularExpressions;

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Đọc file SQL HTTM được nhúng làm resource trong assembly (xem &lt;EmbeddedResource&gt; trong csproj),
/// tách theo separator <c>GO</c> để dùng với <c>MigrationBuilder.Sql</c>.
/// </summary>
/// <remarks>
/// LogicalName của resource đã được set thành <c>HttmSqlMigrations.{FileNameWithoutExtension}.sql</c>.
/// Mỗi batch trả về tương ứng một lệnh <c>migrationBuilder.Sql(batch)</c> (EF Core không hiểu <c>GO</c>).
/// </remarks>
internal static class HttmSqlMigrations
{
    private const string ResourcePrefix = "HttmSqlMigrations.";

    /// <summary>Regex match dòng chỉ chứa <c>GO</c> (whitespace tuỳ ý), case-insensitive — convention T-SQL.</summary>
    private static readonly Regex GoSeparator = new(
        @"^\s*GO\s*$",
        RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.Compiled);

    /// <summary>Đọc resource theo tên file (không có đuôi <c>.sql</c>) và trả về danh sách batch không rỗng.</summary>
    public static IReadOnlyList<string> ReadBatches(string fileNameWithoutExtension)
    {
        var resourceName = ResourcePrefix + fileNameWithoutExtension + ".sql";
        var asm = typeof(HttmSqlMigrations).Assembly;
        using var stream = asm.GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException(
                $"HTTM SQL resource '{resourceName}' không tồn tại. Kiểm tra <EmbeddedResource> trong csproj.");
        using var reader = new StreamReader(stream);
        var sql = reader.ReadToEnd();

        var parts = GoSeparator.Split(sql);
        var batches = new List<string>(parts.Length);
        foreach (var raw in parts)
        {
            var trimmed = raw.Trim();
            if (trimmed.Length > 0)
                batches.Add(trimmed);
        }

        return batches;
    }

    /// <summary>Tiện ích: nạp file SQL rồi gọi <c>migrationBuilder.Sql</c> cho từng batch.</summary>
    /// <param name="migrationBuilder">EF MigrationBuilder.</param>
    /// <param name="fileNameWithoutExtension">Tên file SQL không kèm <c>.sql</c>.</param>
    /// <param name="suppressTransaction">
    /// Truyền <c>true</c> với các DDL không cho phép trong transaction (ví dụ
    /// <c>CREATE FULLTEXT CATALOG/INDEX</c>, <c>ALTER DATABASE</c>, <c>CREATE DATABASE</c>).
    /// Khi suppress, từng batch chạy ngoài transaction — phải tự đảm bảo idempotent (IF NOT EXISTS).
    /// </param>
    public static void Apply(
        Microsoft.EntityFrameworkCore.Migrations.MigrationBuilder migrationBuilder,
        string fileNameWithoutExtension,
        bool suppressTransaction = false)
    {
        foreach (var batch in ReadBatches(fileNameWithoutExtension))
            migrationBuilder.Sql(batch, suppressTransaction: suppressTransaction);
    }
}
