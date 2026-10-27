using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ArtKids.DAL.Migrations.Postgres
{
    /// <inheritdoc />
    public partial class CourseSoftDeletion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_deleted",
                table: "courses",
                type: "boolean",
                nullable: false,
                defaultValue: false
            );
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "is_deleted", table: "courses");
        }
    }
}
