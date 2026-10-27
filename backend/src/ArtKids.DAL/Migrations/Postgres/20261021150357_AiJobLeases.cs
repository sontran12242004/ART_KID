using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable
namespace ArtKids.DAL.Migrations.Postgres
{
    /// <inheritdoc/>
    public partial class AiJobLeases : Migration
    {
        /// <inheritdoc/>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "lease_expires_at",
                table: "ai_generation_jobs",
                type: "timestamp with time zone",
                nullable: true
            );
        }

        /// <inheritdoc/>
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "lease_expires_at", table: "ai_generation_jobs");
        }
    }
}
