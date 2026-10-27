using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable
namespace ArtKids.DAL.Migrations.Sqlite
{
    /// <inheritdoc/>
    public partial class SqliteNumericScores : Migration
    {
        /// <inheritdoc/>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<double>(
                name: "score",
                table: "submission_reviews",
                type: "REAL",
                precision: 4,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "TEXT",
                oldPrecision: 4,
                oldScale: 2
            );
            migrationBuilder.AlterColumn<double>(
                name: "rating",
                table: "products",
                type: "REAL",
                precision: 18,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "TEXT",
                oldPrecision: 18,
                oldScale: 2
            );
        }

        /// <inheritdoc/>
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<decimal>(
                name: "score",
                table: "submission_reviews",
                type: "TEXT",
                precision: 4,
                scale: 2,
                nullable: false,
                oldClrType: typeof(double),
                oldType: "REAL",
                oldPrecision: 4,
                oldScale: 2
            );
            migrationBuilder.AlterColumn<decimal>(
                name: "rating",
                table: "products",
                type: "TEXT",
                precision: 18,
                scale: 2,
                nullable: false,
                oldClrType: typeof(double),
                oldType: "REAL",
                oldPrecision: 18,
                oldScale: 2
            );
        }
    }
}
