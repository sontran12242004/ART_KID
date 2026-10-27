using System.Data;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.DAL.Repositories;

public interface IRepository<T>
    where T : Entity
{
    IQueryable<T> Query { get; }

    Task<T?> FindAsync(string id);
    void Add(T entity);
    void Remove(T entity);
}

public sealed class EfRepository<T>(AppDbContext db) : IRepository<T>
    where T : Entity
{
    public IQueryable<T> Query => db.Set<T>();

    public async Task<T?> FindAsync(string id)
    {
        return await db.Set<T>().FindAsync(id);
    }

    public void Add(T entity)
    {
        db.Add(entity);
    }

    public void Remove(T entity)
    {
        db.Remove(entity);
    }
}

public interface IUnitOfWork
{
    IRepository<T> Repository<T>()
        where T : Entity;
    Task<int> SaveAsync();
    Task<T> TransactionAsync<T>(Func<Task<T>> operation);
}

public sealed class UnitOfWork(AppDbContext db) : IUnitOfWork
{
    public IRepository<T> Repository<T>()
        where T : Entity
    {
        return new EfRepository<T>(db);
    }

    public Task<int> SaveAsync()
    {
        return db.SaveChangesAsync();
    }

    public async Task<T> TransactionAsync<T>(Func<Task<T>> operation)
    {
        if (db.Database.CurrentTransaction is not null)
            return await operation();
        await using var transaction = await db.Database.BeginTransactionAsync(
            IsolationLevel.Serializable
        );
        var result = await operation();
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return result;
    }
}
