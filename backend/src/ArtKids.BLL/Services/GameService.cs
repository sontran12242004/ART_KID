using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class GameService(IUnitOfWork store, ICurrentUser actor) : ServiceBase(store, actor)
{
    public async Task<object> PictureSets()
    {
        return await Q<PictureSet>().OrderBy(x => x.Title).ToListAsync();
    }

    public async Task<object> PictureSet(string id)
    {
        return new
        {
            pictureSet = await Get<PictureSet>(id),
            slots = await Q<PictureSlot>()
                .Where(x => x.PictureSetId == id)
                .OrderBy(x => x.SequenceIndex)
                .ToListAsync(),
        };
    }

    public Task<PictureSet> CreatePictureSet(PictureSetRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            Roles("admin");
            Require(
                r.BgAspectRatio > 0 && r.Slots.Count is > 0 and <= 20,
                "A picture set needs 1–20 slots and a positive aspect ratio."
            );
            Require(
                r.Slots.Select(x => x.Animal).Distinct().Count() == r.Slots.Count
                    && r.Slots.Select(x => x.SequenceIndex).Distinct().Count() == r.Slots.Count,
                "Duplicate animals or slot sequence."
            );
            var s = new PictureSet
            {
                Title = r.Title,
                Description = r.Description,
                ThumbnailAsset = r.ThumbnailAsset,
                BackgroundAsset = r.BackgroundAsset,
                BgAspectRatio = r.BgAspectRatio,
            };
            Add(s);
            foreach (var x in r.Slots)
            {
                Require(
                    x.SequenceIndex >= 0
                        && x.WidthPercent > 0
                        && x.HeightPercent > 0
                        && x.LeftPercent + x.WidthPercent <= 1
                        && x.TopPercent + x.HeightPercent <= 1,
                    "Invalid slot bounds."
                );
                Add(
                    new PictureSlot
                    {
                        PictureSetId = s.Id,
                        Animal = x.Animal,
                        SequenceIndex = x.SequenceIndex,
                        LeftPercent = x.LeftPercent,
                        TopPercent = x.TopPercent,
                        WidthPercent = x.WidthPercent,
                        HeightPercent = x.HeightPercent,
                    }
                );
            }

            return s;
        });
    }

    public async Task<object?> Progress(string childId, string setId)
    {
        await OwnChild(childId);
        return await Q<MatchingGameProgress>()
            .SingleOrDefaultAsync(x => x.ChildId == childId && x.PictureSetId == setId);
    }

    public Task<MatchingGameProgress> SaveProgress(
        string childId,
        string setId,
        GameProgressRequest r
    )
    {
        return Store.TransactionAsync(async () =>
        {
            await OwnChild(childId);
            await Get<PictureSet>(setId);
            var animals = await Q<PictureSlot>()
                .Where(x => x.PictureSetId == setId)
                .Select(x => x.Animal)
                .ToListAsync();
            Require(
                r.CurrentAnimalIndex <= animals.Count
                    && r.UnlockedStickers.Distinct().Count() == r.UnlockedStickers.Count
                    && r.MatchedAnimals.Distinct().Count() == r.MatchedAnimals.Count
                    && r.UnlockedStickers.All(animals.Contains)
                    && r.MatchedAnimals.All(r.UnlockedStickers.Contains),
                "Invalid matching-game progress."
            );
            var p = await Q<MatchingGameProgress>()
                .SingleOrDefaultAsync(x => x.ChildId == childId && x.PictureSetId == setId);
            if (p is null)
            {
                p = new MatchingGameProgress { ChildId = childId, PictureSetId = setId };
                Add(p);
            }

            p.CurrentStep = r.CurrentStep;
            p.CurrentAnimalIndex = r.CurrentAnimalIndex;
            p.UnlockedStickers = r.UnlockedStickers;
            p.MatchedAnimals = r.MatchedAnimals;
            p.LastUpdatedAt = DateTime.UtcNow;
            return p;
        });
    }

    public Task<CompletedPicture> Complete(string childId, string setId)
    {
        return Store.TransactionAsync(async () =>
        {
            await OwnChild(childId);
            var set = await Get<PictureSet>(setId);
            var p =
                await Q<MatchingGameProgress>()
                    .SingleOrDefaultAsync(x => x.ChildId == childId && x.PictureSetId == setId)
                ?? throw new BusinessException(409, "No game progress found.");
            var count = await Q<PictureSlot>().CountAsync(x => x.PictureSetId == setId);
            Require(
                count > 0 && p.MatchedAnimals.Count == count,
                "Finish matching every animal first.",
                409
            );
            var id = "done_" + p.Id;
            var old = await Store.Repository<CompletedPicture>().FindAsync(id);
            if (old is not null)
                return old;
            var picture = new CompletedPicture
            {
                Id = id,
                ChildId = childId,
                PictureSetId = setId,
                PictureTitle = set.Title,
                ThumbnailAsset = set.ThumbnailAsset,
            };
            Add(picture);
            return picture;
        });
    }

    public async Task<object> Gallery(string childId, int page, int size)
    {
        await OwnChild(childId);
        return await Q<CompletedPicture>()
            .Where(x => x.ChildId == childId)
            .OrderByDescending(x => x.CompletedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task<object> Rewards(string childId)
    {
        await OwnChild(childId);
        return await Q<KidReward>()
            .Where(x => x.ChildId == childId)
            .OrderByDescending(x => x.UnlockedAt)
            .ToListAsync();
    }
}
