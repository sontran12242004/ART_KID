using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.RateLimiting;
using ArtKids.API.Infrastructure;
using ArtKids.BLL.Common;
using ArtKids.BLL.Services;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Persistence;
using ArtKids.DAL.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);
builder
    .Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables();
var development = builder.Environment.IsDevelopment();
var dataRoot = Path.Combine(builder.Environment.ContentRootPath, "App_Data");
Directory.CreateDirectory(dataRoot);
if (string.IsNullOrWhiteSpace(builder.Configuration["Jwt:Key"]) && development)
{
    var path = Path.Combine(dataRoot, "jwt.key");
    if (!File.Exists(path))
        File.WriteAllText(path, Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)));
    builder.Configuration["Jwt:Key"] = File.ReadAllText(path).Trim();
}

var key = builder.Configuration["Jwt:Key"] ?? "";
if (Encoding.UTF8.GetByteCount(key) < 32)
    throw new InvalidOperationException(
        "Configure Jwt:Key with at least 32 random bytes (use environment variables or user secrets)."
    );
var provider = builder.Configuration["Database:Provider"] ?? "Sqlite";
if (provider == "Postgres")
{
    builder.Services.AddDbContext<PostgresAppDbContext>(o =>
        o.UseNpgsql(builder.Configuration.GetConnectionString("Postgres"))
    );
    builder.Services.AddScoped<AppDbContext>(s => s.GetRequiredService<PostgresAppDbContext>());
}
else if (provider == "Sqlite")
{
    var connection =
        builder.Configuration.GetConnectionString("Sqlite")
        ?? $"Data Source={Path.Combine(dataRoot, "artkids.db")};Default Timeout=10";
    builder.Services.AddDbContext<SqliteAppDbContext>(o => o.UseSqlite(connection));
    builder.Services.AddScoped<AppDbContext>(s => s.GetRequiredService<SqliteAppDbContext>());
}
else
    throw new InvalidOperationException("Database:Provider must be Sqlite or Postgres.");
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();
builder.Services.Configure<PasswordHasherOptions>(o => o.IterationCount = 210000);
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<FamilyService>();
builder.Services.AddScoped<LearningService>();
builder.Services.AddScoped<CloudinaryVideoService>();
builder.Services.AddHttpClient<CloudinaryVideoClient>(client =>
    client.Timeout = TimeSpan.FromSeconds(60)
);
builder
    .Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(dataRoot, "DataProtectionKeys")));
builder.Services.AddScoped<LiveService>();
builder.Services.AddScoped<CommerceService>();
builder.Services.AddScoped<InventoryService>();
builder.Services.AddScoped<MediaService>();
builder.Services.AddScoped<AiService>();
builder.Services.AddScoped<GameService>();
builder.Services.AddScoped<DevelopmentSeeder>();
builder.Services.AddScoped<BootstrapAdminService>();
builder.Configuration["Storage:Root"] ??= Path.Combine(dataRoot, "uploads");
builder.Services.AddSingleton<IFileStorage, LocalFileStorage>();
builder.Services.AddHttpClient<IAiProvider, ConfiguredAiProvider>(c =>
    c.Timeout = TimeSpan.FromSeconds(90)
);
builder.Services.AddHostedService<BackgroundJobs>();
builder
    .Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false;
        o.TokenValidationParameters = new()
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            ClockSkew = TimeSpan.FromSeconds(30),
            NameClaimType = "sub",
            RoleClaimType = ClaimTypes.Role,
        };
        o.Events = new JwtBearerEvents
        {
            OnTokenValidated = async ctx =>
            {
                var id = ctx.Principal?.FindFirstValue("sub");
                var role = ctx.Principal?.FindFirstValue(ClaimTypes.Role);
                var repo = ctx
                    .HttpContext.RequestServices.GetRequiredService<IUnitOfWork>()
                    .Repository<User>();
                if (!await repo.Query.AnyAsync(x => x.Id == id && x.IsActive && x.Role == role))
                    ctx.Fail("Account is disabled or token role no longer matches.");
            },
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddCors(o =>
    o.AddDefaultPolicy(p =>
        p.WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [])
            .AllowAnyHeader()
            .AllowAnyMethod()
    )
);
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = 429;
    o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            ctx.User.FindFirstValue("sub") ?? ctx.Connection.RemoteIpAddress?.ToString() ?? "local",
            _ =>
                new()
                {
                    PermitLimit = 1000,
                    Window = TimeSpan.FromMinutes(1),
                    QueueLimit = 0,
                }
        )
    );
    o.AddPolicy(
        "auth",
        ctx =>
            RateLimitPartition.GetFixedWindowLimiter(
                ctx.Connection.RemoteIpAddress?.ToString() ?? "local",
                _ =>
                    new()
                    {
                        PermitLimit = 20,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                    }
            )
    );
});
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(o =>
    o.MultipartBodyLengthLimit = 315_000_000
);
builder
    .Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new UtcDateTimeConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o =>
{
    o.SwaggerDoc(
        "v1",
        new()
        {
            Title = "ART_KID API",
            Version = "v1",
            Description =
                "DAL → BLL → API. JWT authentication. Demo data is Development-only; external integrations require configuration.",
        }
    );
    o.AddSecurityDefinition(
        "Bearer",
        new()
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "Paste the accessToken returned by POST /api/v1/auth/login.",
        }
    );
    o.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            [
                new OpenApiSecurityScheme
                {
                    Reference = new() { Type = ReferenceType.SecurityScheme, Id = "Bearer" },
                }
            ] = Array.Empty<string>(),
        }
    );
});
var app = builder.Build();
if (development || builder.Configuration.GetValue<bool>("Database:MigrateOnStartup"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
    if (development && builder.Configuration.GetValue<bool>("Seed:Enabled"))
        await scope.ServiceProvider.GetRequiredService<DevelopmentSeeder>().Seed();
}

if (!string.IsNullOrWhiteSpace(builder.Configuration["Bootstrap:AdminEmail"]))
{
    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<BootstrapAdminService>().Initialize();
}

app.UseMiddleware<ErrorMiddleware>();
app.Use(
    async (ctx, next) =>
    {
        ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
        ctx.Response.Headers["Cache-Control"] = "no-store";
        await next();
    }
);
if (!development)
    app.UseHttpsRedirection();
app.UseCors();
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();
if (development)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet(
        "/health",
        async (IUnitOfWork store) =>
        {
            try
            {
                await store.Repository<User>().Query.AnyAsync();
                return Results.Ok(new { status = "healthy", database = provider });
            }
            catch
            {
                return Results.StatusCode(503);
            }
        }
    )
    .AllowAnonymous();
app.MapControllers();
app.Run();

public partial class Program;
