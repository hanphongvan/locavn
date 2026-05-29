using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Services;

public interface IPublicSubmissionFileStorage
{
    /// <summary>Lưu file upload từ public form. Trả URL relative (bắt đầu <c>/uploads/httm-submissions/</c>).</summary>
    Task<(string RelativeUrl, string? Error)> SaveAsync(
        IFormFile file,
        SubmissionFileKind kind,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(string relativeUrl, CancellationToken cancellationToken = default);
}

public enum SubmissionFileKind
{
    /// <summary>Ảnh hạ tầng (jpg/jpeg/png/webp), max 10MB.</summary>
    Image,
    /// <summary>Giấy tờ pháp lý (pdf hoặc ảnh scan), max 20MB.</summary>
    Document,
}

/// <summary>
/// Lưu file vào <c>wwwroot/uploads/httm-submissions/{yyyy-MM}/</c>. Tách bạch với
/// <c>HttmImageStorage</c> (admin upload trực tiếp vào HttmFacilityImages) — file ở đây CHƯA được duyệt.
/// </summary>
public sealed class PublicSubmissionFileStorage(
    IWebHostEnvironment env,
    ILogger<PublicSubmissionFileStorage> logger) : IPublicSubmissionFileStorage
{
    private const string UploadsPrefix = "/uploads/httm-submissions/";
    private const int MaxImageBytes = 10 * 1024 * 1024;       // 10 MB
    private const int MaxDocumentBytes = 20 * 1024 * 1024;    // 20 MB

    private static readonly HashSet<string> ImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp",
    };

    private static readonly HashSet<string> DocumentExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".jpg", ".jpeg", ".png", ".webp",
    };

    public async Task<(string RelativeUrl, string? Error)> SaveAsync(
        IFormFile file,
        SubmissionFileKind kind,
        CancellationToken cancellationToken = default)
    {
        if (file is null || file.Length == 0)
            return (string.Empty, "File rỗng.");

        var maxBytes = kind == SubmissionFileKind.Image ? MaxImageBytes : MaxDocumentBytes;
        if (file.Length > maxBytes)
            return (string.Empty, $"File vượt giới hạn {maxBytes / (1024 * 1024)}MB.");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = kind == SubmissionFileKind.Image ? ImageExtensions : DocumentExtensions;
        if (string.IsNullOrEmpty(ext) || !allowed.Contains(ext))
            return (string.Empty, $"Định dạng không hỗ trợ. Cho phép: {string.Join(", ", allowed)}.");

        // Magic byte check — chống đổi đuôi file độc hại thành ảnh.
        if (!await VerifyMagicByteAsync(file, ext, cancellationToken).ConfigureAwait(false))
            return (string.Empty, "Nội dung file không khớp định dạng.");

        var root = ResolveWebRoot();
        var monthFolder = DateTime.Now.ToString("yyyy-MM");
        var dir = Path.Combine(root, "uploads", "httm-submissions", monthFolder);
        Directory.CreateDirectory(dir);

        var name = $"{Guid.NewGuid():N}{ext}";
        var full = Path.Combine(dir, name);

        try
        {
            await using var fs = new FileStream(full, FileMode.CreateNew, FileAccess.Write, FileShare.None, 65536, useAsync: true);
            await file.CopyToAsync(fs, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Public submission file save failed");
            return (string.Empty, "Không lưu được file.");
        }

        var url = $"{UploadsPrefix}{monthFolder}/{name}";
        return (url, null);
    }

    public Task DeleteAsync(string relativeUrl, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(relativeUrl) || !relativeUrl.StartsWith(UploadsPrefix, StringComparison.Ordinal))
            return Task.CompletedTask;

        var rel = relativeUrl[UploadsPrefix.Length..];
        if (rel.Contains("..") || Path.IsPathRooted(rel))
            return Task.CompletedTask;

        var full = Path.Combine(ResolveWebRoot(), "uploads", "httm-submissions", rel.Replace('/', Path.DirectorySeparatorChar));
        try
        {
            if (File.Exists(full))
                File.Delete(full);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Submission file cleanup failed: {Path}", full);
        }
        return Task.CompletedTask;
    }

    private string ResolveWebRoot()
    {
        var root = env.WebRootPath;
        if (string.IsNullOrEmpty(root))
            root = Path.Combine(env.ContentRootPath, "wwwroot");
        return root;
    }

    /// <summary>
    /// Đọc 8 byte đầu để verify signature. Chặn upload .exe / script đổi đuôi thành .png / .pdf.
    /// </summary>
    private static async Task<bool> VerifyMagicByteAsync(IFormFile file, string ext, CancellationToken ct)
    {
        await using var stream = file.OpenReadStream();
        var buffer = new byte[12];
        var read = await stream.ReadAsync(buffer.AsMemory(0, 12), ct).ConfigureAwait(false);
        stream.Position = 0; // reset cho CopyToAsync sau đó

        if (read < 4) return false;

        return ext switch
        {
            ".pdf" => buffer[0] == 0x25 && buffer[1] == 0x50 && buffer[2] == 0x44 && buffer[3] == 0x46, // %PDF
            ".jpg" or ".jpeg" => buffer[0] == 0xFF && buffer[1] == 0xD8 && buffer[2] == 0xFF,
            ".png" => buffer[0] == 0x89 && buffer[1] == 0x50 && buffer[2] == 0x4E && buffer[3] == 0x47,
            ".webp" => read >= 12 &&
                       buffer[0] == 0x52 && buffer[1] == 0x49 && buffer[2] == 0x46 && buffer[3] == 0x46 &&  // RIFF
                       buffer[8] == 0x57 && buffer[9] == 0x45 && buffer[10] == 0x42 && buffer[11] == 0x50,  // WEBP
            _ => false,
        };
    }
}
