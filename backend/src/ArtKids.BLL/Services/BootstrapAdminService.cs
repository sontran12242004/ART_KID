using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ArtKids.BLL.Services;

/// <summary>Explicit first-administrator bootstrap; never enables the demo accounts in Production.</summary>
public sealed class BootstrapAdminService(
    IUnitOfWork store,
    IPasswordHasher<User> hasher,
    IConfiguration config
)
{
    public async Task Initialize()
    {
        var email = config["Bootstrap:AdminEmail"];
        var password = config["Bootstrap:AdminPassword"];
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            return;
        if (
            !new System.ComponentModel.DataAnnotations.EmailAddressAttribute().IsValid(email)
            || password.Length < 12
        )
            throw new InvalidOperationException(
                "Bootstrap admin needs a valid email and a password of at least 12 characters."
            );
        if (await store.Repository<User>().Query.AnyAsync(x => x.Role == "admin"))
            return;
        email = email.Trim().ToLowerInvariant();
        if (await store.Repository<User>().Query.AnyAsync(x => x.Email == email))
            throw new InvalidOperationException(
                "Bootstrap email already belongs to another account."
            );
        var u = new User
        {
            Email = email,
            FullName = "Administrator",
            Role = "admin",
        };
        u.PasswordHash = hasher.HashPassword(u, password);
        store.Repository<User>().Add(u);
        await store.SaveAsync();
    }
}
