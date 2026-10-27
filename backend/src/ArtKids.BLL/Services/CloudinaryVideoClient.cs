using System.Globalization;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using ArtKids.BLL.Common;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace ArtKids.BLL.Services;

public sealed partial class CloudinaryVideoClient(
    HttpClient http,
    IConfiguration config,
    IHostEnvironment environment
)
{
    public const long DefaultMaxBytes = 100_000_000;
    public long MaxBytes =>
        Math.Clamp(
            config.GetValue<long?>("Cloudinary:MaxVideoBytes") ?? DefaultMaxBytes,
            1,
            300_000_000
        );
    private string Cloud => config["Cloudinary:CloudName"] ?? "";
    private string Key => config["Cloudinary:ApiKey"] ?? "";
    private string Secret => config["Cloudinary:ApiSecret"] ?? "";
    public bool IsConfigured =>
        Regex.IsMatch(Cloud, "^[a-zA-Z0-9_-]+$")
        && !string.IsNullOrWhiteSpace(Key)
        && !string.IsNullOrWhiteSpace(Secret);

    private string ApiRoot
    {
        get
        {
            var value = config["Cloudinary:ApiBaseUrl"] ?? "https://api.cloudinary.com";
            if (
                value != "https://api.cloudinary.com"
                && !(
                    environment.IsDevelopment()
                    && Uri.TryCreate(value, UriKind.Absolute, out var uri)
                    && uri.IsLoopback
                )
            )
                throw new InvalidOperationException(
                    "Cloudinary API override is only allowed for local development tests."
                );
            return value.TrimEnd('/') + "/v1_1/" + Cloud;
        }
    }

    public void EnsureConfigured()
    {
        if (!IsConfigured)
            throw new BusinessException(
                503,
                "Chưa thiết lập nơi lưu video. Vui lòng liên hệ quản trị viên."
            );
    }

    private string Sign(SortedDictionary<string, string> fields)
    {
        var input = string.Join("&", fields.Select(pair => pair.Key + "=" + pair.Value)) + Secret;
        return Convert
            .ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(input)))
            .ToLowerInvariant();
    }

    public object UploadParameters(string publicId)
    {
        EnsureConfigured();
        var fields = new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["allowed_formats"] = "mp4",
            ["overwrite"] = "false",
            ["public_id"] = publicId,
            ["timestamp"] = DateTimeOffset
                .UtcNow.ToUnixTimeSeconds()
                .ToString(CultureInfo.InvariantCulture),
            ["type"] = "authenticated",
        };
        var signature = Sign(fields);
        fields["api_key"] = Key;
        fields["signature"] = signature;
        return new { uploadUrl = ApiRoot + "/video/upload", fields };
    }

    public async Task<string> VerifyUpload(
        string publicId,
        long expectedBytes,
        CancellationToken ct
    )
    {
        EnsureConfigured();
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            ApiRoot
                + "/resources/video/authenticated/"
                + Uri.EscapeDataString(publicId)
                + "?media_metadata=true"
        );
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Basic",
            Convert.ToBase64String(Encoding.UTF8.GetBytes(Key + ":" + Secret))
        );
        HttpResponseMessage response;
        try
        {
            response = await http.SendAsync(request, ct);
        }
        catch (Exception error)
            when (error is HttpRequestException
                || error is TaskCanceledException && !ct.IsCancellationRequested
            )
        {
            throw new BusinessException(
                502,
                "Không thể kết nối nơi lưu video. Hãy thử lưu lại bài giảng."
            );
        }
        using (response)
        {
            if (!response.IsSuccessStatusCode)
                throw new BusinessException(
                    502,
                    "Chưa xác minh được video đã tải lên. Hãy kiểm tra cấu hình và thử lại."
                );
            using var document = await JsonDocument.ParseAsync(
                await response.Content.ReadAsStreamAsync(ct),
                cancellationToken: ct
            );
            var asset = document.RootElement;
            if (
                ReadText(asset, "public_id") != publicId
                || ReadText(asset, "resource_type") != "video"
                || ReadText(asset, "type") != "authenticated"
                || ReadText(asset, "format") != "mp4"
                || ReadInteger(asset, "bytes") != expectedBytes
                || ReadInteger(asset, "width") is not > 0
                || ReadInteger(asset, "height") is not > 0
            )
                throw new BusinessException(
                    400,
                    "Video tải lên không khớp hoặc không phải video MP4 hợp lệ."
                );
            if (
                !asset.TryGetProperty("duration", out var duration)
                || duration.ValueKind != JsonValueKind.Number
                || !duration.TryGetDouble(out var seconds)
            )
                throw new BusinessException(
                    502,
                    "Chưa nhận được metadata thời lượng video. Hãy thử lưu lại bài giảng."
                );
            if (seconds <= 0 || !double.IsFinite(seconds))
                throw new BusinessException(400, "Thời lượng video không hợp lệ.");
            var version = ReadInteger(asset, "version");
            if (version is not > 0)
                throw new BusinessException(
                    502,
                    "Chưa nhận được phiên bản video. Hãy thử lưu lại bài giảng."
                );
            return $"https://res.cloudinary.com/{Cloud}/video/authenticated/v{version}/{publicId}.mp4";
        }
    }

    public static bool IsManagedUrl(string? url) => url is not null && ManagedUrl().IsMatch(url);

    private static string? ReadText(JsonElement asset, string name) =>
        asset.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static long? ReadInteger(JsonElement asset, string name) =>
        asset.TryGetProperty(name, out var value)
        && value.ValueKind == JsonValueKind.Number
        && value.TryGetInt64(out var number)
            ? number
            : null;

    public string? PlaybackUrl(string? storedUrl)
    {
        if (storedUrl is null)
            return null;
        var match = ManagedUrl().Match(storedUrl);
        if (!match.Success)
            return storedUrl;
        EnsureConfigured();
        if (match.Groups["cloud"].Value != Cloud)
            throw new BusinessException(503, "Cấu hình nơi lưu video không khớp với bài giảng.");
        var ttl = Math.Clamp(
            config.GetValue<int?>("Cloudinary:PlaybackSeconds") ?? 7200,
            300,
            86400
        );
        var fields = new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["attachment"] = "false",
            ["expires_at"] = DateTimeOffset
                .UtcNow.AddSeconds(ttl)
                .ToUnixTimeSeconds()
                .ToString(CultureInfo.InvariantCulture),
            ["format"] = "mp4",
            ["public_id"] = match.Groups["public"].Value,
            ["timestamp"] = DateTimeOffset
                .UtcNow.ToUnixTimeSeconds()
                .ToString(CultureInfo.InvariantCulture),
            ["type"] = "authenticated",
        };
        var signature = Sign(fields);
        fields["api_key"] = Key;
        fields["signature"] = signature;
        return ApiRoot
            + "/video/download?"
            + string.Join(
                "&",
                fields.Select(pair =>
                    Uri.EscapeDataString(pair.Key) + "=" + Uri.EscapeDataString(pair.Value)
                )
            );
    }

    [GeneratedRegex(
        @"^https://res\.cloudinary\.com/(?<cloud>[a-zA-Z0-9_-]+)/video/authenticated/v[0-9]+/(?<public>artkid/lectures/[a-f0-9]{32})\.mp4$"
    )]
    private static partial Regex ManagedUrl();
}
