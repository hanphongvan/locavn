using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.Httm.Services;

public interface IHttmImageStorage
{
    /// <summary>Lưu file và trả URL tuyệt đối tương đối web (bắt đầu bằng <c>/uploads/httm/</c>).</summary>
    Task<(string RelativeUrl, string? Error)> SaveAsync(IFormFile file, CancellationToken cancellationToken = default);
}

public sealed class LocalHttmImageStorage(IWebHostEnvironment env, ILogger<LocalHttmImageStorage> logger) : IHttmImageStorage
{
    public async Task<(string RelativeUrl, string? Error)> SaveAsync(
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        var root = env.WebRootPath;
        if (string.IsNullOrEmpty(root))
        {
            logger.LogWarning("WebRootPath empty; using ContentRootPath/wwwroot for HTTM uploads.");
            root = Path.Combine(env.ContentRootPath, "wwwroot");
        }

        var dir = Path.Combine(root, "uploads", "httm");
        Directory.CreateDirectory(dir);

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext))
            ext = ".bin";

        var name = $"{Guid.NewGuid():N}{ext}";
        var full = Path.Combine(dir, name);

        try
        {
            await using var fs = new FileStream(full, FileMode.CreateNew, FileAccess.Write, FileShare.None, 65536, useAsync: true);
            await file.CopyToAsync(fs, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "HTTM image save failed");
            return (string.Empty, "Không lưu được file.");
        }

        var url = "/uploads/httm/" + name;
        return (url, null);
    }
}
