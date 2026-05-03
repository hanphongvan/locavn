using System.Buffers.Binary;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.BadReports.Services;

public sealed class BadReportImageUploadService(
    IWebHostEnvironment env,
    IConfiguration configuration) : IBadReportImageUploadService
{
    public const long MaxBytes = 5 * 1024 * 1024;

    public async Task<(string? AbsoluteUrl, string? Error)> SaveAsync(
        IFormFile file,
        HttpRequest request,
        CancellationToken cancellationToken = default)
    {
        if (file.Length == 0)
            return (null, "file is empty.");

        if (file.Length > MaxBytes)
            return (null, $"Image must be at most {MaxBytes / (1024 * 1024)} MB.");

        await using var input = file.OpenReadStream();
        var header = new byte[64];
        var read = await input.ReadAsync(header.AsMemory(0, header.Length), cancellationToken)
            .ConfigureAwait(false);
        if (read < 12)
            return (null, "Could not read image header.");

        if (!TryDetectImageFormat(header.AsSpan(0, read), out var ext))
            return (null, "Only JPEG, PNG, or WebP images are allowed.");

        var webRoot = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        var dir = Path.Combine(webRoot, "uploads", "bad-reports");
        Directory.CreateDirectory(dir);

        var name = $"{Guid.NewGuid():N}{ext}";
        var physicalPath = Path.Combine(dir, name);

        await using (var fs = new FileStream(
                         physicalPath,
                         FileMode.CreateNew,
                         FileAccess.Write,
                         FileShare.None,
                         bufferSize: 64 * 1024,
                         options: FileOptions.Asynchronous))
        {
            await fs.WriteAsync(header.AsMemory(0, read), cancellationToken).ConfigureAwait(false);
            await input.CopyToAsync(fs, cancellationToken).ConfigureAwait(false);
        }

        var relativeUrl = $"/uploads/bad-reports/{name}";
        var absolute = BuildPublicUrl(request, relativeUrl);
        return (absolute, null);
    }

    private string BuildPublicUrl(HttpRequest request, string relativeUrl)
    {
        var configured = configuration["BadReports:UploadedImagePublicBaseUrl"]?.Trim();
        if (!string.IsNullOrEmpty(configured))
            return configured.TrimEnd('/') + relativeUrl;

        return $"{request.Scheme}://{request.Host.Value}{request.PathBase}{relativeUrl}";
    }

    private static bool TryDetectImageFormat(ReadOnlySpan<byte> header, out string extension)
    {
        extension = "";
        if (header.Length >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            extension = ".jpg";
            return true;
        }

        if (header.Length >= 8
            && header[0] == 0x89
            && header[1] == (byte)'P'
            && header[2] == (byte)'N'
            && header[3] == (byte)'G'
            && header[4] == 0x0D
            && header[5] == 0x0A
            && header[6] == 0x1A
            && header[7] == 0x0A)
        {
            extension = ".png";
            return true;
        }

        if (header.Length >= 12
            && BinaryPrimitives.ReadUInt32LittleEndian(header) == 0x46464952 // "RIFF"
            && header[8] == (byte)'W'
            && header[9] == (byte)'E'
            && header[10] == (byte)'B'
            && header[11] == (byte)'P')
        {
            extension = ".webp";
            return true;
        }

        return false;
    }
}
