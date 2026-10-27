using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable
namespace ArtKids.DAL.Migrations.Sqlite
{
    /// <inheritdoc/>
    public partial class SubscriptionKitSchedules : Migration
    {
        /// <inheritdoc/>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_fulfillment_orders_order_id_inventory_sku_id",
                table: "fulfillment_orders"
            );
            migrationBuilder.AddColumn<string>(
                name: "kit_inventory_sku_id",
                table: "subscription_plans",
                type: "TEXT",
                nullable: true
            );
            migrationBuilder.AddColumn<int>(
                name: "kit_quantity",
                table: "subscription_plans",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0
            );
            migrationBuilder.AddColumn<int>(
                name: "duration_months",
                table: "order_items",
                type: "INTEGER",
                nullable: true
            );
            migrationBuilder.AddColumn<string>(
                name: "kit_inventory_sku_id",
                table: "order_items",
                type: "TEXT",
                nullable: true
            );
            migrationBuilder.AddColumn<int>(
                name: "kit_quantity",
                table: "order_items",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0
            );
            migrationBuilder.AddColumn<string>(
                name: "subscription_kit_delivery_id",
                table: "fulfillment_orders",
                type: "TEXT",
                nullable: true
            );
            migrationBuilder.CreateTable(
                name: "subscription_kit_deliverys",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    subscription_id = table.Column<string>(type: "TEXT", nullable: false),
                    inventory_sku_id = table.Column<string>(type: "TEXT", nullable: false),
                    delivery_index = table.Column<int>(type: "INTEGER", nullable: false),
                    scheduled_for = table.Column<DateTime>(type: "TEXT", nullable: false),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscription_kit_deliverys", x => x.id);
                    table.ForeignKey(
                        name: "FK_subscription_kit_deliverys_inventory_skus_inventory_sku_id",
                        column: x => x.inventory_sku_id,
                        principalTable: "inventory_skus",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_subscription_kit_deliverys_subscriptions_subscription_id",
                        column: x => x.subscription_id,
                        principalTable: "subscriptions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscription_plans_kit_inventory_sku_id",
                table: "subscription_plans",
                column: "kit_inventory_sku_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_items_kit_inventory_sku_id",
                table: "order_items",
                column: "kit_inventory_sku_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_order_id",
                table: "fulfillment_orders",
                column: "order_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_subscription_kit_delivery_id",
                table: "fulfillment_orders",
                column: "subscription_kit_delivery_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscription_kit_deliverys_inventory_sku_id",
                table: "subscription_kit_deliverys",
                column: "inventory_sku_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscription_kit_deliverys_subscription_id_delivery_index",
                table: "subscription_kit_deliverys",
                columns: new[] { "subscription_id", "delivery_index" },
                unique: true
            );
            migrationBuilder.AddForeignKey(
                name: "FK_fulfillment_orders_subscription_kit_deliverys_subscription_kit_delivery_id",
                table: "fulfillment_orders",
                column: "subscription_kit_delivery_id",
                principalTable: "subscription_kit_deliverys",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict
            );
            migrationBuilder.AddForeignKey(
                name: "FK_order_items_inventory_skus_kit_inventory_sku_id",
                table: "order_items",
                column: "kit_inventory_sku_id",
                principalTable: "inventory_skus",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict
            );
            migrationBuilder.AddForeignKey(
                name: "FK_subscription_plans_inventory_skus_kit_inventory_sku_id",
                table: "subscription_plans",
                column: "kit_inventory_sku_id",
                principalTable: "inventory_skus",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict
            );
        }

        /// <inheritdoc/>
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_fulfillment_orders_subscription_kit_deliverys_subscription_kit_delivery_id",
                table: "fulfillment_orders"
            );
            migrationBuilder.DropForeignKey(
                name: "FK_order_items_inventory_skus_kit_inventory_sku_id",
                table: "order_items"
            );
            migrationBuilder.DropForeignKey(
                name: "FK_subscription_plans_inventory_skus_kit_inventory_sku_id",
                table: "subscription_plans"
            );
            migrationBuilder.DropTable(name: "subscription_kit_deliverys");
            migrationBuilder.DropIndex(
                name: "IX_subscription_plans_kit_inventory_sku_id",
                table: "subscription_plans"
            );
            migrationBuilder.DropIndex(
                name: "IX_order_items_kit_inventory_sku_id",
                table: "order_items"
            );
            migrationBuilder.DropIndex(
                name: "IX_fulfillment_orders_order_id",
                table: "fulfillment_orders"
            );
            migrationBuilder.DropIndex(
                name: "IX_fulfillment_orders_subscription_kit_delivery_id",
                table: "fulfillment_orders"
            );
            migrationBuilder.DropColumn(name: "kit_inventory_sku_id", table: "subscription_plans");
            migrationBuilder.DropColumn(name: "kit_quantity", table: "subscription_plans");
            migrationBuilder.DropColumn(name: "duration_months", table: "order_items");
            migrationBuilder.DropColumn(name: "kit_inventory_sku_id", table: "order_items");
            migrationBuilder.DropColumn(name: "kit_quantity", table: "order_items");
            migrationBuilder.DropColumn(
                name: "subscription_kit_delivery_id",
                table: "fulfillment_orders"
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_order_id_inventory_sku_id",
                table: "fulfillment_orders",
                columns: new[] { "order_id", "inventory_sku_id" },
                unique: true
            );
        }
    }
}
