using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ArtKids.DAL.Migrations.Postgres
{
    /// <inheritdoc />
    public partial class VnpaySandboxPayments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "vnpay_payments",
                columns: table => new
                {
                    id = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "character varying(64)", nullable: false),
                    amount_vnd = table.Column<long>(type: "bigint", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    expires_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    transaction_no = table.Column<string>(type: "text", nullable: true),
                    response_code = table.Column<string>(type: "text", nullable: true),
                    paid_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vnpay_payments", x => x.id);
                    table.ForeignKey(
                        name: "FK_vnpay_payments_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_vnpay_payments_order_id",
                table: "vnpay_payments",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "IX_vnpay_payments_transaction_no",
                table: "vnpay_payments",
                column: "transaction_no",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "vnpay_payments");
        }
    }
}
