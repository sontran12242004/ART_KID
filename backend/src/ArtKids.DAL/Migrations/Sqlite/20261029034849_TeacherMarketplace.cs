using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ArtKids.DAL.Migrations.Sqlite
{
    /// <inheritdoc />
    public partial class TeacherMarketplace : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "approval_status",
                table: "products",
                type: "TEXT",
                nullable: false,
                defaultValue: "approved"
            );

            migrationBuilder.AddColumn<string>(
                name: "fulfillment_mode",
                table: "products",
                type: "TEXT",
                nullable: false,
                defaultValue: "platform"
            );

            migrationBuilder.AddColumn<bool>(
                name: "is_available",
                table: "products",
                type: "INTEGER",
                nullable: false,
                defaultValue: true
            );

            migrationBuilder.AddColumn<string>(
                name: "rejection_reason",
                table: "products",
                type: "TEXT",
                nullable: true
            );

            migrationBuilder.AddColumn<DateTime>(
                name: "reviewed_at",
                table: "products",
                type: "TEXT",
                nullable: true
            );

            migrationBuilder.AddColumn<string>(
                name: "reviewed_by",
                table: "products",
                type: "TEXT",
                nullable: true
            );

            migrationBuilder.AddColumn<int>(
                name: "revision",
                table: "products",
                type: "INTEGER",
                nullable: false,
                defaultValue: 1
            );

            migrationBuilder.AddColumn<string>(
                name: "seller_id",
                table: "order_items",
                type: "TEXT",
                nullable: true
            );

            migrationBuilder.CreateTable(
                name: "seller_fulfillments",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "TEXT", nullable: false),
                    seller_id = table.Column<string>(type: "TEXT", nullable: false),
                    carrier = table.Column<string>(type: "TEXT", nullable: false),
                    tracking_number = table.Column<string>(type: "TEXT", nullable: true),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    shipped_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    delivered_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_seller_fulfillments", x => x.id);
                    table.ForeignKey(
                        name: "FK_seller_fulfillments_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_seller_fulfillments_users_seller_id",
                        column: x => x.seller_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );

            migrationBuilder.CreateIndex(
                name: "IX_products_fulfillment_mode_approval_status",
                table: "products",
                columns: new[] { "fulfillment_mode", "approval_status" }
            );

            migrationBuilder.CreateIndex(
                name: "IX_products_reviewed_by",
                table: "products",
                column: "reviewed_by"
            );

            migrationBuilder.CreateIndex(
                name: "IX_order_items_seller_id_order_id",
                table: "order_items",
                columns: new[] { "seller_id", "order_id" }
            );

            migrationBuilder.CreateIndex(
                name: "IX_seller_fulfillments_order_id_seller_id",
                table: "seller_fulfillments",
                columns: new[] { "order_id", "seller_id" },
                unique: true
            );

            migrationBuilder.CreateIndex(
                name: "IX_seller_fulfillments_seller_id",
                table: "seller_fulfillments",
                column: "seller_id"
            );

            migrationBuilder.AddForeignKey(
                name: "FK_order_items_users_seller_id",
                table: "order_items",
                column: "seller_id",
                principalTable: "users",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict
            );

            migrationBuilder.AddForeignKey(
                name: "FK_products_users_reviewed_by",
                table: "products",
                column: "reviewed_by",
                principalTable: "users",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict
            );
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_order_items_users_seller_id",
                table: "order_items"
            );

            migrationBuilder.DropForeignKey(
                name: "FK_products_users_reviewed_by",
                table: "products"
            );

            migrationBuilder.DropTable(name: "seller_fulfillments");

            migrationBuilder.DropIndex(
                name: "IX_products_fulfillment_mode_approval_status",
                table: "products"
            );

            migrationBuilder.DropIndex(name: "IX_products_reviewed_by", table: "products");

            migrationBuilder.DropIndex(
                name: "IX_order_items_seller_id_order_id",
                table: "order_items"
            );

            migrationBuilder.DropColumn(name: "approval_status", table: "products");

            migrationBuilder.DropColumn(name: "fulfillment_mode", table: "products");

            migrationBuilder.DropColumn(name: "is_available", table: "products");

            migrationBuilder.DropColumn(name: "rejection_reason", table: "products");

            migrationBuilder.DropColumn(name: "reviewed_at", table: "products");

            migrationBuilder.DropColumn(name: "reviewed_by", table: "products");

            migrationBuilder.DropColumn(name: "revision", table: "products");

            migrationBuilder.DropColumn(name: "seller_id", table: "order_items");
        }
    }
}
