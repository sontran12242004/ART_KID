using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace ArtKids.BLL.Services;

public sealed class AuthService(
    IUnitOfWork store,
    ICurrentUser actor,
    IConfiguration config,
    IPasswordHasher<User> hasher
) : ServiceBase(store, actor)
{
    public async Task<object> Register(RegisterRequest r)
    {
        var email = r.Email.Trim().ToLowerInvariant();
        Require(
            !await Q<User>().AnyAsync(x => x.Email == email),
            "This email is already registered.",
            409
        );
        var u = new User { Email = email, FullName = r.FullName.Trim() };
        u.PasswordHash = hasher.HashPassword(u, r.Password);
        Add(u);
        await Store.SaveAsync();
        return View(u);
    }

    public async Task<object> Login(LoginRequest r)
    {
        var email = r.Email.Trim().ToLowerInvariant();
        var u = await Q<User>().SingleOrDefaultAsync(x => x.Email == email);
        Require(
            u is { IsActive: true }
                && hasher.VerifyHashedPassword(u, u.PasswordHash, r.Password)
                    != PasswordVerificationResult.Failed,
            "Invalid email or password.",
            401
        );
        return await Issue(u!);
    }

    public Task<object> Refresh(RefreshRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var hash = Hash(r.RefreshToken);
            var old = await Q<RefreshToken>().SingleOrDefaultAsync(x => x.TokenHash == hash);
            Require(
                old is not null && old.RevokedAt == null && old.ExpiresAt > DateTime.UtcNow,
                "Refresh token is invalid or expired.",
                401
            );
            var u = await Get<User>(old!.UserId);
            Require(u.IsActive, "Account disabled.", 401);
            old.RevokedAt = DateTime.UtcNow;
            return await Issue(u);
        });
    }

    public async Task Logout(RefreshRequest r)
    {
        var hash = Hash(r.RefreshToken);
        var row = await Q<RefreshToken>()
            .SingleOrDefaultAsync(x => x.TokenHash == hash && x.UserId == Actor.Id);
        if (row is not null)
        {
            row.RevokedAt = DateTime.UtcNow;
            await Store.SaveAsync();
        }
    }

    public async Task<object> Me()
    {
        return View(await Get<User>(Actor.Id));
    }

    public async Task<object> UpdateProfile(UserProfileRequest r)
    {
        var u = await Get<User>(Actor.Id);
        if (r.AvatarPresetId is not null)
            await Get<AvatarPreset>(r.AvatarPresetId);
        u.FullName = r.FullName.Trim();
        u.PhoneNumber = r.PhoneNumber;
        u.AvatarPresetId = r.AvatarPresetId;
        u.NotificationsEnabled = r.NotificationsEnabled;
        u.DailyDrawingReminder = r.DailyDrawingReminder;
        await Store.SaveAsync();
        return View(u);
    }

    public async Task SetPin(SetPinRequest r)
    {
        Roles("parent");
        var u = await Get<User>(Actor.Id);
        Require(
            hasher.VerifyHashedPassword(u, u.PasswordHash, r.Password)
                != PasswordVerificationResult.Failed,
            "Current password is incorrect.",
            403
        );
        u.ParentPinHash = hasher.HashPassword(u, r.Pin);
        await Store.SaveAsync();
    }

    public async Task<object> VerifyPin(PinRequest r)
    {
        var u = await Get<User>(Actor.Id);
        return new
        {
            valid = u.ParentPinHash is not null
                && hasher.VerifyHashedPassword(u, u.ParentPinHash, r.Pin)
                    != PasswordVerificationResult.Failed,
        };
    }

    public async Task<object> CreateStaff(StaffRequest r)
    {
        Roles("admin");
        var email = r.Email.Trim().ToLowerInvariant();
        Require(!await Q<User>().AnyAsync(x => x.Email == email), "Email already registered.", 409);
        var u = new User
        {
            Email = email,
            FullName = r.FullName,
            Role = r.Role,
        };
        u.PasswordHash = hasher.HashPassword(u, r.Password);
        Add(u);
        await Store.SaveAsync();
        return View(u);
    }

    public async Task<object> Staff(int page, int size)
    {
        Roles("admin");
        return await Q<User>()
            .Where(x => x.Role != "parent")
            .OrderBy(x => x.Email)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .Select(x => new
            {
                x.Id,
                x.Email,
                x.FullName,
                x.Role,
                x.IsActive,
            })
            .ToListAsync();
    }

    private async Task<object> Issue(User u)
    {
        var key = config["Jwt:Key"]!;
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(30);
        var jwt = new JwtSecurityToken(
            config["Jwt:Issuer"],
            config["Jwt:Audience"],
            [
                new Claim(JwtRegisteredClaimNames.Sub, u.Id),
                new Claim(ClaimTypes.Role, u.Role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            ],
            now,
            expires,
            new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
                SecurityAlgorithms.HmacSha256
            )
        );
        var refresh = Convert.ToHexString(RandomNumberGenerator.GetBytes(48));
        Add(
            new RefreshToken
            {
                UserId = u.Id,
                TokenHash = Hash(refresh),
                ExpiresAt = now.AddDays(7),
            }
        );
        await Store.SaveAsync();
        return new
        {
            accessToken = new JwtSecurityTokenHandler().WriteToken(jwt),
            refreshToken = refresh,
            expiresAt = expires,
            user = View(u),
        };
    }

    public static object View(User u)
    {
        return new
        {
            u.Id,
            u.Email,
            u.FullName,
            displayName = u.FullName,
            u.Role,
            u.PhoneNumber,
            u.AvatarUrl,
            u.AvatarPresetId,
            u.NotificationsEnabled,
            u.DailyDrawingReminder,
            u.HasCompletedCoppaConsent,
            u.ParentalConsentAt,
            u.CreatedAt,
        };
    }

    private static string Hash(string value)
    {
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
    }
}
