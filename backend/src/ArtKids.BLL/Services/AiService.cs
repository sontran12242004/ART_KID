using System.Net.Http.Json;
using System.Text.Json;
using ArtKids.BLL.Common;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ArtKids.BLL.Services;

public sealed record CreatureAnalysis(
    string AnimalType,
    string DisplayName,
    string CheeringMessage,
    string? SuggestedAnimationId
);

public interface IAiProvider
{
    Task<CreatureAnalysis> Analyze(byte[] image, string contentType, CancellationToken ct);
}

public sealed class ConfiguredAiProvider(HttpClient http, IConfiguration config) : IAiProvider
{
    public async Task<CreatureAnalysis> Analyze(
        byte[] image,
        string contentType,
        CancellationToken ct
    )
    {
        if (config["AI:Mode"] == "Demo")
            return new("cat", "Mèo sáng tạo (demo)", "Bức vẽ của bé rất đáng yêu!", null);
        if (config["AI:Mode"] != "Gemini" || string.IsNullOrWhiteSpace(config["AI:ApiKey"]))
            throw new InvalidOperationException("AI provider is not configured.");
        var model = config["AI:Model"] ?? "gemini-2.5-flash";
        using var req = new HttpRequestMessage(
            HttpMethod.Post,
            $"https://generativelanguage.googleapis.com/v1beta/models/{Uri.EscapeDataString(model)}:generateContent"
        );
        req.Headers.Add("x-goog-api-key", config["AI:ApiKey"]);
        req.Content = JsonContent.Create(
            new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new object[]
                        {
                            new
                            {
                                text = "Describe this child's drawing kindly in Vietnamese. Return JSON only: animalType, displayName, cheeringMessage. Do not identify people or infer personal information.",
                            },
                            new
                            {
                                inline_data = new
                                {
                                    mime_type = contentType,
                                    data = Convert.ToBase64String(image),
                                },
                            },
                        },
                    },
                },
                generationConfig = new { responseMimeType = "application/json" },
            }
        );
        using var response = await http.SendAsync(req, ct);
        response.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        var text = doc
            .RootElement.GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString()!;
        using var result = JsonDocument.Parse(text);
        var root = result.RootElement;
        return new(
            root.GetProperty("animalType").GetString()!,
            root.GetProperty("displayName").GetString()!,
            root.GetProperty("cheeringMessage").GetString()!,
            null
        );
    }
}

public sealed class AiService(
    IUnitOfWork store,
    ICurrentUser actor,
    IConfiguration config,
    IFileStorage files,
    IAiProvider provider
) : ServiceBase(store, actor)
{
    public Task<AiGenerationJob> Create(string submissionId)
    {
        return Store.TransactionAsync(async () =>
        {
            Require(
                config["AI:Mode"] is "Demo" or "Gemini",
                "AI is disabled. Configure AI:Mode and provider credentials.",
                503
            );
            var s = await Get<DrawingSubmission>(submissionId);
            await OwnChild(s.ChildId);
            var consent =
                await Q<ParentalConsent>()
                    .FirstOrDefaultAsync(x =>
                        x.ChildId == s.ChildId
                        && x.Purpose == "ai_generation"
                        && x.RevokedAt == null
                    )
                ?? throw new BusinessException(403, "AI parental consent is required.");
            var old = await Q<AiGenerationJob>()
                .Where(x => x.SubmissionId == s.Id && x.Status != "failed")
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();
            if (old is not null)
                return old;
            var job = new AiGenerationJob
            {
                SubmissionId = s.Id,
                ChildId = s.ChildId,
                ConsentId = consent.Id,
                DrawingImageUrl = s.ImagePath,
            };
            Add(job);
            return job;
        });
    }

    public async Task<object> Job(string id)
    {
        var j = await Get<AiGenerationJob>(id);
        await OwnChild(j.ChildId);
        return new
        {
            job = j,
            result = await Q<AiCreature>().SingleOrDefaultAsync(x => x.JobId == id),
        };
    }

    public async Task<object> Creatures(string childId, int page, int size)
    {
        await OwnChild(childId);
        var ids = Q<DrawingSubmission>().Where(x => x.ChildId == childId).Select(x => x.Id);
        return await Q<AiCreature>()
            .Where(x => ids.Contains(x.SubmissionId))
            .OrderByDescending(x => x.CreatedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task<bool> ProcessOne(CancellationToken ct)
    {
        var job = await Store.TransactionAsync(async () =>
        {
            var j = await Q<AiGenerationJob>()
                .Where(x => x.Status == "queued")
                .OrderBy(x => x.CreatedAt)
                .FirstOrDefaultAsync();
            if (j is null)
                return null;
            j.Status = "processing";
            j.Attempts++;
            j.LeaseExpiresAt = DateTime.UtcNow.AddMinutes(3);
            return j;
        });
        if (job is null)
            return false;
        try
        {
            Require(
                await Q<ParentalConsent>()
                    .AnyAsync(x => x.Id == job.ConsentId && x.RevokedAt == null),
                "Consent revoked."
            );
            var s = await Get<DrawingSubmission>(job.SubmissionId);
            var asset = await Get<MediaAsset>(s.ImageAssetId);
            await using var stream = files.Read(asset.StorageKey);
            using var data = new MemoryStream();
            await stream.CopyToAsync(data, ct);
            var result = await provider.Analyze(data.ToArray(), asset.ContentType, ct);
            await Store.TransactionAsync(async () =>
            {
                Require(
                    await Q<ParentalConsent>()
                        .AnyAsync(x => x.Id == job.ConsentId && x.RevokedAt == null),
                    "Consent revoked during analysis."
                );
                if (!await Q<AiCreature>().AnyAsync(x => x.JobId == job.Id))
                    Add(
                        new AiCreature
                        {
                            JobId = job.Id,
                            SubmissionId = s.Id,
                            AnimalType = result.AnimalType,
                            DisplayName = result.DisplayName,
                            CheeringMessage = result.CheeringMessage,
                            SuggestedAnimationId = result.SuggestedAnimationId,
                            ThumbnailUrl = s.ImagePath,
                        }
                    );
                job.Status = "completed";
                job.CompletedAt = DateTime.UtcNow;
                job.LeaseExpiresAt = null;
                var child = await Get<ChildProfile>(s.ChildId);
                Notify(child.ParentId, "AI đã xử lý xong", result.DisplayName, job.Id);
                return true;
            });
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            job.Status = "failed";
            job.CompletedAt = DateTime.UtcNow;
            job.LeaseExpiresAt = null;
            job.ErrorMessage =
                ex is BusinessException ? ex.Message : "AI provider failed. Please retry later.";
            await Store.SaveAsync();
        }

        return true;
    }

    public async Task RecoverInterruptedJobs()
    {
        // Leases are bounded: recover only jobs older than the HTTP timeout, not other active workers.
        foreach (
            var j in await Q<AiGenerationJob>()
                .Where(x => x.Status == "processing" && x.LeaseExpiresAt < DateTime.UtcNow)
                .ToListAsync()
        )
        {
            j.Status = "failed";
            j.LeaseExpiresAt = null;
            j.ErrorMessage = "Worker was interrupted; submit a retry.";
        }

        await Store.SaveAsync();
    }
}
