using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable
namespace ArtKids.DAL.Migrations.Sqlite
{
    /// <inheritdoc/>
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc/>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "avatar_presets",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    is_for_child = table.Column<bool>(type: "INTEGER", nullable: false),
                    type = table.Column<string>(type: "TEXT", nullable: false),
                    asset_path = table.Column<string>(type: "TEXT", nullable: true),
                    icon_name = table.Column<string>(type: "TEXT", nullable: true),
                    primary_color = table.Column<string>(type: "TEXT", nullable: false),
                    secondary_color = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_avatar_presets", x => x.id);
                }
            );
            migrationBuilder.CreateTable(
                name: "badges",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    display_order = table.Column<int>(type: "INTEGER", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    emoji = table.Column<string>(type: "TEXT", nullable: false),
                    icon_name = table.Column<string>(type: "TEXT", nullable: false),
                    condition = table.Column<string>(type: "TEXT", nullable: false),
                    meaning = table.Column<string>(type: "TEXT", nullable: false),
                    category = table.Column<string>(type: "TEXT", nullable: false),
                    primary_color = table.Column<string>(type: "TEXT", nullable: false),
                    secondary_color = table.Column<string>(type: "TEXT", nullable: false),
                    max_progress = table.Column<int>(type: "INTEGER", nullable: false),
                    metric = table.Column<string>(type: "TEXT", nullable: false),
                    model_glb_path = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_badges", x => x.id);
                }
            );
            migrationBuilder.CreateTable(
                name: "picture_sets",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    thumbnail_asset = table.Column<string>(type: "TEXT", nullable: false),
                    background_asset = table.Column<string>(type: "TEXT", nullable: false),
                    bg_aspect_ratio = table.Column<double>(type: "REAL", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_picture_sets", x => x.id);
                }
            );
            migrationBuilder.CreateTable(
                name: "subscription_plans",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: true),
                    price_monthly = table.Column<long>(type: "INTEGER", nullable: false),
                    price_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    duration_months = table.Column<int>(type: "INTEGER", nullable: false),
                    features = table.Column<string>(type: "TEXT", nullable: false),
                    includes_kit = table.Column<bool>(type: "INTEGER", nullable: false),
                    kit_delivery_included = table.Column<bool>(type: "INTEGER", nullable: false),
                    is_active = table.Column<bool>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscription_plans", x => x.id);
                }
            );
            migrationBuilder.CreateTable(
                name: "vouchers",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    code = table.Column<string>(type: "TEXT", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    discount_type = table.Column<string>(type: "TEXT", nullable: false),
                    discount_value = table.Column<long>(type: "INTEGER", nullable: false),
                    min_order_amount = table.Column<long>(type: "INTEGER", nullable: false),
                    max_discount_amount = table.Column<long>(type: "INTEGER", nullable: true),
                    expiry_date = table.Column<DateTime>(type: "TEXT", nullable: false),
                    is_usable = table.Column<bool>(type: "INTEGER", nullable: false),
                    usage_limit = table.Column<int>(type: "INTEGER", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vouchers", x => x.id);
                }
            );
            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    email = table.Column<string>(type: "TEXT", nullable: false),
                    full_name = table.Column<string>(type: "TEXT", nullable: false),
                    phone_number = table.Column<string>(type: "TEXT", nullable: true),
                    avatar_url = table.Column<string>(type: "TEXT", nullable: true),
                    avatar_preset_id = table.Column<string>(type: "TEXT", nullable: true),
                    role = table.Column<string>(type: "TEXT", nullable: false),
                    password_hash = table.Column<string>(type: "TEXT", nullable: false),
                    parent_pin_hash = table.Column<string>(type: "TEXT", nullable: true),
                    has_completed_coppa_consent = table.Column<bool>(
                        type: "INTEGER",
                        nullable: false
                    ),
                    parental_consent_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    notifications_enabled = table.Column<bool>(type: "INTEGER", nullable: false),
                    daily_drawing_reminder = table.Column<bool>(type: "INTEGER", nullable: false),
                    is_active = table.Column<bool>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.id);
                    table.ForeignKey(
                        name: "FK_users_avatar_presets_avatar_preset_id",
                        column: x => x.avatar_preset_id,
                        principalTable: "avatar_presets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "picture_slots",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    picture_set_id = table.Column<string>(type: "TEXT", nullable: false),
                    animal = table.Column<string>(type: "TEXT", nullable: false),
                    sequence_index = table.Column<int>(type: "INTEGER", nullable: false),
                    left_percent = table.Column<double>(type: "REAL", nullable: false),
                    top_percent = table.Column<double>(type: "REAL", nullable: false),
                    width_percent = table.Column<double>(type: "REAL", nullable: false),
                    height_percent = table.Column<double>(type: "REAL", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_picture_slots", x => x.id);
                    table.ForeignKey(
                        name: "FK_picture_slots_picture_sets_picture_set_id",
                        column: x => x.picture_set_id,
                        principalTable: "picture_sets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "carts",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    parent_id = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_carts", x => x.id);
                    table.ForeignKey(
                        name: "FK_carts_users_parent_id",
                        column: x => x.parent_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "child_profiles",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    parent_id = table.Column<string>(type: "TEXT", nullable: false),
                    nickname = table.Column<string>(type: "TEXT", nullable: false),
                    birth_year = table.Column<int>(type: "INTEGER", nullable: false),
                    avatar_url = table.Column<string>(type: "TEXT", nullable: true),
                    avatar_preset_id = table.Column<string>(type: "TEXT", nullable: true),
                    interests = table.Column<string>(type: "TEXT", nullable: true),
                    kid_pin_hash = table.Column<string>(type: "TEXT", nullable: true),
                    total_points = table.Column<int>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_child_profiles", x => x.id);
                    table.ForeignKey(
                        name: "FK_child_profiles_avatar_presets_avatar_preset_id",
                        column: x => x.avatar_preset_id,
                        principalTable: "avatar_presets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_child_profiles_users_parent_id",
                        column: x => x.parent_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "courses",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    thumbnail_url = table.Column<string>(type: "TEXT", nullable: true),
                    age_range = table.Column<string>(type: "TEXT", nullable: false),
                    price_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    includes_physical_kit = table.Column<bool>(type: "INTEGER", nullable: false),
                    instructor_id = table.Column<string>(type: "TEXT", nullable: false),
                    is_published = table.Column<bool>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_courses", x => x.id);
                    table.ForeignKey(
                        name: "FK_courses_users_instructor_id",
                        column: x => x.instructor_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "notifications",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    user_id = table.Column<string>(type: "TEXT", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    message = table.Column<string>(type: "TEXT", nullable: false),
                    reference_id = table.Column<string>(type: "TEXT", nullable: true),
                    read_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notifications", x => x.id);
                    table.ForeignKey(
                        name: "FK_notifications_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    user_id = table.Column<string>(type: "TEXT", nullable: false),
                    token_hash = table.Column<string>(type: "TEXT", nullable: false),
                    expires_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    revoked_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_refresh_tokens", x => x.id);
                    table.ForeignKey(
                        name: "FK_refresh_tokens_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "child_badges",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    badge_id = table.Column<string>(type: "TEXT", nullable: false),
                    current_progress = table.Column<int>(type: "INTEGER", nullable: false),
                    unlocked_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_child_badges", x => x.id);
                    table.ForeignKey(
                        name: "FK_child_badges_badges_badge_id",
                        column: x => x.badge_id,
                        principalTable: "badges",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_child_badges_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "completed_pictures",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    picture_set_id = table.Column<string>(type: "TEXT", nullable: false),
                    picture_title = table.Column<string>(type: "TEXT", nullable: false),
                    thumbnail_asset = table.Column<string>(type: "TEXT", nullable: false),
                    completed_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_completed_pictures", x => x.id);
                    table.ForeignKey(
                        name: "FK_completed_pictures_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_completed_pictures_picture_sets_picture_set_id",
                        column: x => x.picture_set_id,
                        principalTable: "picture_sets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "kid_rewards",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    icon_name = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    unlocked_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_kid_rewards", x => x.id);
                    table.ForeignKey(
                        name: "FK_kid_rewards_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "matching_game_progress",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    picture_set_id = table.Column<string>(type: "TEXT", nullable: false),
                    current_step = table.Column<string>(type: "TEXT", nullable: false),
                    current_animal_index = table.Column<int>(type: "INTEGER", nullable: false),
                    unlocked_stickers = table.Column<string>(type: "TEXT", nullable: false),
                    matched_animals = table.Column<string>(type: "TEXT", nullable: false),
                    last_updated_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_matching_game_progress", x => x.id);
                    table.ForeignKey(
                        name: "FK_matching_game_progress_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_matching_game_progress_picture_sets_picture_set_id",
                        column: x => x.picture_set_id,
                        principalTable: "picture_sets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "media_assets",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    owner_id = table.Column<string>(type: "TEXT", nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: true),
                    kind = table.Column<string>(type: "TEXT", nullable: false),
                    storage_key = table.Column<string>(type: "TEXT", nullable: false),
                    original_name = table.Column<string>(type: "TEXT", nullable: false),
                    content_type = table.Column<string>(type: "TEXT", nullable: false),
                    size_bytes = table.Column<long>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_media_assets", x => x.id);
                    table.ForeignKey(
                        name: "FK_media_assets_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_media_assets_users_owner_id",
                        column: x => x.owner_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "orders",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_code = table.Column<string>(type: "TEXT", nullable: false),
                    parent_id = table.Column<string>(type: "TEXT", nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: true),
                    paid_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    order_type = table.Column<string>(type: "TEXT", nullable: false),
                    payment_status = table.Column<string>(type: "TEXT", nullable: false),
                    payment_method_name = table.Column<string>(type: "TEXT", nullable: false),
                    subtotal_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    shipping_fee_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    discount_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    voucher_id = table.Column<string>(type: "TEXT", nullable: true),
                    voucher_code = table.Column<string>(type: "TEXT", nullable: true),
                    total_amount_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    cancel_reason = table.Column<string>(type: "TEXT", nullable: true),
                    idempotency_key = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_orders", x => x.id);
                    table.CheckConstraint(
                        "ck_order_total",
                        "subtotal_vnd >= 0 AND shipping_fee_vnd >= 0 AND discount_vnd >= 0 AND total_amount_vnd = subtotal_vnd + shipping_fee_vnd - discount_vnd AND total_amount_vnd >= 0"
                    );
                    table.ForeignKey(
                        name: "FK_orders_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_orders_users_parent_id",
                        column: x => x.parent_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_orders_vouchers_voucher_id",
                        column: x => x.voucher_id,
                        principalTable: "vouchers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "parental_consents",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    parent_id = table.Column<string>(type: "TEXT", nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    purpose = table.Column<string>(type: "TEXT", nullable: false),
                    policy_version = table.Column<string>(type: "TEXT", nullable: false),
                    granted_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    revoked_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_parental_consents", x => x.id);
                    table.ForeignKey(
                        name: "FK_parental_consents_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_parental_consents_users_parent_id",
                        column: x => x.parent_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "live_classs",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    course_id = table.Column<string>(type: "TEXT", nullable: false),
                    instructor_id = table.Column<string>(type: "TEXT", nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    capacity = table.Column<int>(type: "INTEGER", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_live_classs", x => x.id);
                    table.CheckConstraint("ck_capacity", "capacity BETWEEN 1 AND 30");
                    table.ForeignKey(
                        name: "FK_live_classs_courses_course_id",
                        column: x => x.course_id,
                        principalTable: "courses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_live_classs_users_instructor_id",
                        column: x => x.instructor_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "products",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    price_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    original_price_vnd = table.Column<long>(type: "INTEGER", nullable: true),
                    thumbnail_url = table.Column<string>(type: "TEXT", nullable: false),
                    images = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    category = table.Column<string>(type: "TEXT", nullable: false),
                    course_id = table.Column<string>(type: "TEXT", nullable: true),
                    recommended_subscription_plan_id = table.Column<string>(
                        type: "TEXT",
                        nullable: true
                    ),
                    kit_items = table.Column<string>(type: "TEXT", nullable: false),
                    rating = table.Column<decimal>(
                        type: "TEXT",
                        precision: 18,
                        scale: 2,
                        nullable: false
                    ),
                    sold_count = table.Column<int>(type: "INTEGER", nullable: false),
                    created_by = table.Column<string>(type: "TEXT", nullable: false),
                    is_active = table.Column<bool>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_products", x => x.id);
                    table.ForeignKey(
                        name: "FK_products_courses_course_id",
                        column: x => x.course_id,
                        principalTable: "courses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_products_subscription_plans_recommended_subscription_plan_id",
                        column: x => x.recommended_subscription_plan_id,
                        principalTable: "subscription_plans",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_products_users_created_by",
                        column: x => x.created_by,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "lessons",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    course_id = table.Column<string>(type: "TEXT", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    order_index = table.Column<int>(type: "INTEGER", nullable: false),
                    video_url = table.Column<string>(type: "TEXT", nullable: true),
                    video_asset_id = table.Column<string>(type: "TEXT", nullable: true),
                    practice_instructions = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lessons", x => x.id);
                    table.ForeignKey(
                        name: "FK_lessons_courses_course_id",
                        column: x => x.course_id,
                        principalTable: "courses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_lessons_media_assets_video_asset_id",
                        column: x => x.video_asset_id,
                        principalTable: "media_assets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "order_shipping_info",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "TEXT", nullable: false),
                    recipient_name = table.Column<string>(type: "TEXT", nullable: false),
                    phone_number = table.Column<string>(type: "TEXT", nullable: false),
                    full_address = table.Column<string>(type: "TEXT", nullable: false),
                    carrier_name = table.Column<string>(type: "TEXT", nullable: true),
                    tracking_number = table.Column<string>(type: "TEXT", nullable: true),
                    tracking_url = table.Column<string>(type: "TEXT", nullable: true),
                    estimated_delivery_date = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_order_shipping_info", x => x.id);
                    table.ForeignKey(
                        name: "FK_order_shipping_info_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "order_tracking_events",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "TEXT", nullable: false),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    description = table.Column<string>(type: "TEXT", nullable: false),
                    timestamp = table.Column<DateTime>(type: "TEXT", nullable: false),
                    is_passed = table.Column<bool>(type: "INTEGER", nullable: false),
                    is_current = table.Column<bool>(type: "INTEGER", nullable: false),
                    cancel_reason = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_order_tracking_events", x => x.id);
                    table.ForeignKey(
                        name: "FK_order_tracking_events_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "live_class_enrollments",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    class_id = table.Column<string>(type: "TEXT", nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    enrolled_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_live_class_enrollments", x => x.id);
                    table.ForeignKey(
                        name: "FK_live_class_enrollments_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_live_class_enrollments_live_classs_class_id",
                        column: x => x.class_id,
                        principalTable: "live_classs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "cart_items",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    cart_id = table.Column<string>(type: "TEXT", nullable: false),
                    product_id = table.Column<string>(type: "TEXT", nullable: false),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cart_items", x => x.id);
                    table.CheckConstraint("ck_cart_quantity", "quantity > 0");
                    table.ForeignKey(
                        name: "FK_cart_items_carts_cart_id",
                        column: x => x.cart_id,
                        principalTable: "carts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_cart_items_products_product_id",
                        column: x => x.product_id,
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "inventory_skus",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    sku = table.Column<string>(type: "TEXT", nullable: false),
                    product_id = table.Column<string>(type: "TEXT", nullable: false),
                    kit_name = table.Column<string>(type: "TEXT", nullable: false),
                    quantity_available = table.Column<int>(type: "INTEGER", nullable: false),
                    quantity_reserved = table.Column<int>(type: "INTEGER", nullable: false),
                    reorder_threshold = table.Column<int>(type: "INTEGER", nullable: false),
                    unit_cost_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    warehouse_location = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_skus", x => x.id);
                    table.CheckConstraint(
                        "ck_stock",
                        "quantity_available >= 0 AND quantity_reserved >= 0"
                    );
                    table.ForeignKey(
                        name: "FK_inventory_skus_products_product_id",
                        column: x => x.product_id,
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "order_items",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "TEXT", nullable: false),
                    item_type = table.Column<string>(type: "TEXT", nullable: false),
                    product_id = table.Column<string>(type: "TEXT", nullable: true),
                    course_id = table.Column<string>(type: "TEXT", nullable: true),
                    plan_id = table.Column<string>(type: "TEXT", nullable: true),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    thumbnail_url = table.Column<string>(type: "TEXT", nullable: true),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    unit_price_vnd = table.Column<long>(type: "INTEGER", nullable: false),
                    kit_items = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_order_items", x => x.id);
                    table.CheckConstraint("ck_item", "quantity > 0 AND unit_price_vnd >= 0");
                    table.ForeignKey(
                        name: "FK_order_items_courses_course_id",
                        column: x => x.course_id,
                        principalTable: "courses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_order_items_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_order_items_products_product_id",
                        column: x => x.product_id,
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_order_items_subscription_plans_plan_id",
                        column: x => x.plan_id,
                        principalTable: "subscription_plans",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "live_sessions",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    class_id = table.Column<string>(type: "TEXT", nullable: false),
                    lesson_id = table.Column<string>(type: "TEXT", nullable: true),
                    title = table.Column<string>(type: "TEXT", nullable: false),
                    starts_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ends_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    provider = table.Column<string>(type: "TEXT", nullable: false),
                    room_url = table.Column<string>(type: "TEXT", nullable: true),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    recording_url = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_live_sessions", x => x.id);
                    table.CheckConstraint("ck_session_time", "ends_at > starts_at");
                    table.ForeignKey(
                        name: "FK_live_sessions_lessons_lesson_id",
                        column: x => x.lesson_id,
                        principalTable: "lessons",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_live_sessions_live_classs_class_id",
                        column: x => x.class_id,
                        principalTable: "live_classs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "fulfillment_orders",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_id = table.Column<string>(type: "TEXT", nullable: false),
                    inventory_sku_id = table.Column<string>(type: "TEXT", nullable: false),
                    kit_name = table.Column<string>(type: "TEXT", nullable: false),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    carrier = table.Column<string>(type: "TEXT", nullable: false),
                    tracking_number = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    shipping_address = table.Column<string>(type: "TEXT", nullable: false),
                    recipient_name = table.Column<string>(type: "TEXT", nullable: false),
                    recipient_phone = table.Column<string>(type: "TEXT", nullable: false),
                    estimated_delivery_date = table.Column<DateTime>(type: "TEXT", nullable: true),
                    shipped_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    delivered_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_fulfillment_orders", x => x.id);
                    table.ForeignKey(
                        name: "FK_fulfillment_orders_inventory_skus_inventory_sku_id",
                        column: x => x.inventory_sku_id,
                        principalTable: "inventory_skus",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_fulfillment_orders_orders_order_id",
                        column: x => x.order_id,
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "enrollments",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    course_id = table.Column<string>(type: "TEXT", nullable: false),
                    order_item_id = table.Column<string>(type: "TEXT", nullable: true),
                    enrolled_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    last_learned_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_enrollments", x => x.id);
                    table.ForeignKey(
                        name: "FK_enrollments_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_enrollments_courses_course_id",
                        column: x => x.course_id,
                        principalTable: "courses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_enrollments_order_items_order_item_id",
                        column: x => x.order_item_id,
                        principalTable: "order_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "inventory_reservations",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    order_item_id = table.Column<string>(type: "TEXT", nullable: false),
                    inventory_sku_id = table.Column<string>(type: "TEXT", nullable: false),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    expires_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_reservations", x => x.id);
                    table.ForeignKey(
                        name: "FK_inventory_reservations_inventory_skus_inventory_sku_id",
                        column: x => x.inventory_sku_id,
                        principalTable: "inventory_skus",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_inventory_reservations_order_items_order_item_id",
                        column: x => x.order_item_id,
                        principalTable: "order_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "subscriptions",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    parent_id = table.Column<string>(type: "TEXT", nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: true),
                    plan_id = table.Column<string>(type: "TEXT", nullable: false),
                    order_item_id = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    starts_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ends_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscriptions", x => x.id);
                    table.ForeignKey(
                        name: "FK_subscriptions_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_subscriptions_order_items_order_item_id",
                        column: x => x.order_item_id,
                        principalTable: "order_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_subscriptions_subscription_plans_plan_id",
                        column: x => x.plan_id,
                        principalTable: "subscription_plans",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_subscriptions_users_parent_id",
                        column: x => x.parent_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "drawing_submissions",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    lesson_id = table.Column<string>(type: "TEXT", nullable: true),
                    live_session_id = table.Column<string>(type: "TEXT", nullable: true),
                    image_asset_id = table.Column<string>(type: "TEXT", nullable: false),
                    image_path = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_drawing_submissions", x => x.id);
                    table.ForeignKey(
                        name: "FK_drawing_submissions_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_drawing_submissions_lessons_lesson_id",
                        column: x => x.lesson_id,
                        principalTable: "lessons",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_drawing_submissions_live_sessions_live_session_id",
                        column: x => x.live_session_id,
                        principalTable: "live_sessions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_drawing_submissions_media_assets_image_asset_id",
                        column: x => x.image_asset_id,
                        principalTable: "media_assets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "live_session_attendance",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    session_id = table.Column<string>(type: "TEXT", nullable: false),
                    class_enrollment_id = table.Column<string>(type: "TEXT", nullable: false),
                    first_joined_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    last_joined_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    last_left_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    total_duration_seconds = table.Column<int>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_live_session_attendance", x => x.id);
                    table.ForeignKey(
                        name: "FK_live_session_attendance_live_class_enrollments_class_enrollment_id",
                        column: x => x.class_enrollment_id,
                        principalTable: "live_class_enrollments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_live_session_attendance_live_sessions_session_id",
                        column: x => x.session_id,
                        principalTable: "live_sessions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "lesson_progress",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    enrollment_id = table.Column<string>(type: "TEXT", nullable: false),
                    lesson_id = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    learning_seconds = table.Column<int>(type: "INTEGER", nullable: false),
                    last_learned_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    completed_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lesson_progress", x => x.id);
                    table.ForeignKey(
                        name: "FK_lesson_progress_enrollments_enrollment_id",
                        column: x => x.enrollment_id,
                        principalTable: "enrollments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_lesson_progress_lessons_lesson_id",
                        column: x => x.lesson_id,
                        principalTable: "lessons",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "ai_generation_jobs",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    child_id = table.Column<string>(type: "TEXT", nullable: false),
                    submission_id = table.Column<string>(type: "TEXT", nullable: false),
                    consent_id = table.Column<string>(type: "TEXT", nullable: false),
                    drawing_image_url = table.Column<string>(type: "TEXT", nullable: false),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    error_message = table.Column<string>(type: "TEXT", nullable: true),
                    completed_at = table.Column<DateTime>(type: "TEXT", nullable: true),
                    attempts = table.Column<int>(type: "INTEGER", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_generation_jobs", x => x.id);
                    table.ForeignKey(
                        name: "FK_ai_generation_jobs_child_profiles_child_id",
                        column: x => x.child_id,
                        principalTable: "child_profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_ai_generation_jobs_drawing_submissions_submission_id",
                        column: x => x.submission_id,
                        principalTable: "drawing_submissions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_ai_generation_jobs_parental_consents_consent_id",
                        column: x => x.consent_id,
                        principalTable: "parental_consents",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "submission_reviews",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    submission_id = table.Column<string>(type: "TEXT", nullable: false),
                    instructor_id = table.Column<string>(type: "TEXT", nullable: false),
                    score = table.Column<decimal>(
                        type: "TEXT",
                        precision: 4,
                        scale: 2,
                        nullable: false
                    ),
                    feedback = table.Column<string>(type: "TEXT", nullable: false),
                    reviewed_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_submission_reviews", x => x.id);
                    table.CheckConstraint("ck_score", "score BETWEEN 0 AND 10");
                    table.ForeignKey(
                        name: "FK_submission_reviews_drawing_submissions_submission_id",
                        column: x => x.submission_id,
                        principalTable: "drawing_submissions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_submission_reviews_users_instructor_id",
                        column: x => x.instructor_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateTable(
                name: "ai_creatures",
                columns: table => new
                {
                    id = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    submission_id = table.Column<string>(type: "TEXT", nullable: false),
                    job_id = table.Column<string>(type: "TEXT", nullable: false),
                    animal_type = table.Column<string>(type: "TEXT", nullable: false),
                    display_name = table.Column<string>(type: "TEXT", nullable: false),
                    model2d_url = table.Column<string>(type: "TEXT", nullable: true),
                    model3d_url = table.Column<string>(type: "TEXT", nullable: true),
                    animation_url = table.Column<string>(type: "TEXT", nullable: true),
                    audio_url = table.Column<string>(type: "TEXT", nullable: true),
                    thumbnail_url = table.Column<string>(type: "TEXT", nullable: true),
                    cheering_message = table.Column<string>(type: "TEXT", nullable: false),
                    suggested_animation_id = table.Column<string>(type: "TEXT", nullable: true),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    created_at = table.Column<DateTime>(type: "TEXT", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_creatures", x => x.id);
                    table.ForeignKey(
                        name: "FK_ai_creatures_ai_generation_jobs_job_id",
                        column: x => x.job_id,
                        principalTable: "ai_generation_jobs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_ai_creatures_drawing_submissions_submission_id",
                        column: x => x.submission_id,
                        principalTable: "drawing_submissions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );
            migrationBuilder.CreateIndex(
                name: "IX_ai_creatures_job_id",
                table: "ai_creatures",
                column: "job_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_ai_creatures_submission_id",
                table: "ai_creatures",
                column: "submission_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_ai_generation_jobs_child_id",
                table: "ai_generation_jobs",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_ai_generation_jobs_consent_id",
                table: "ai_generation_jobs",
                column: "consent_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_ai_generation_jobs_submission_id",
                table: "ai_generation_jobs",
                column: "submission_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_cart_items_cart_id_product_id",
                table: "cart_items",
                columns: new[] { "cart_id", "product_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_cart_items_product_id",
                table: "cart_items",
                column: "product_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_carts_parent_id",
                table: "carts",
                column: "parent_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_child_badges_badge_id",
                table: "child_badges",
                column: "badge_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_child_badges_child_id_badge_id",
                table: "child_badges",
                columns: new[] { "child_id", "badge_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_child_profiles_avatar_preset_id",
                table: "child_profiles",
                column: "avatar_preset_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_child_profiles_parent_id",
                table: "child_profiles",
                column: "parent_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_completed_pictures_child_id",
                table: "completed_pictures",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_completed_pictures_picture_set_id",
                table: "completed_pictures",
                column: "picture_set_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_courses_instructor_id",
                table: "courses",
                column: "instructor_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_drawing_submissions_child_id",
                table: "drawing_submissions",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_drawing_submissions_image_asset_id",
                table: "drawing_submissions",
                column: "image_asset_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_drawing_submissions_lesson_id",
                table: "drawing_submissions",
                column: "lesson_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_drawing_submissions_live_session_id",
                table: "drawing_submissions",
                column: "live_session_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_enrollments_child_id_course_id",
                table: "enrollments",
                columns: new[] { "child_id", "course_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_enrollments_course_id",
                table: "enrollments",
                column: "course_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_enrollments_order_item_id",
                table: "enrollments",
                column: "order_item_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_carrier_tracking_number",
                table: "fulfillment_orders",
                columns: new[] { "carrier", "tracking_number" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_inventory_sku_id",
                table: "fulfillment_orders",
                column: "inventory_sku_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_fulfillment_orders_order_id_inventory_sku_id",
                table: "fulfillment_orders",
                columns: new[] { "order_id", "inventory_sku_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_inventory_reservations_inventory_sku_id",
                table: "inventory_reservations",
                column: "inventory_sku_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_inventory_reservations_order_item_id",
                table: "inventory_reservations",
                column: "order_item_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_inventory_skus_product_id",
                table: "inventory_skus",
                column: "product_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_inventory_skus_sku",
                table: "inventory_skus",
                column: "sku",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_kid_rewards_child_id",
                table: "kid_rewards",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_lesson_progress_enrollment_id_lesson_id",
                table: "lesson_progress",
                columns: new[] { "enrollment_id", "lesson_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_lesson_progress_lesson_id",
                table: "lesson_progress",
                column: "lesson_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_lessons_course_id_order_index",
                table: "lessons",
                columns: new[] { "course_id", "order_index" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_lessons_video_asset_id",
                table: "lessons",
                column: "video_asset_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_class_enrollments_child_id",
                table: "live_class_enrollments",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_class_enrollments_class_id_child_id",
                table: "live_class_enrollments",
                columns: new[] { "class_id", "child_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_classs_course_id",
                table: "live_classs",
                column: "course_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_classs_instructor_id",
                table: "live_classs",
                column: "instructor_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_session_attendance_class_enrollment_id",
                table: "live_session_attendance",
                column: "class_enrollment_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_session_attendance_session_id_class_enrollment_id",
                table: "live_session_attendance",
                columns: new[] { "session_id", "class_enrollment_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_sessions_class_id",
                table: "live_sessions",
                column: "class_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_live_sessions_lesson_id",
                table: "live_sessions",
                column: "lesson_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_matching_game_progress_child_id_picture_set_id",
                table: "matching_game_progress",
                columns: new[] { "child_id", "picture_set_id" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_matching_game_progress_picture_set_id",
                table: "matching_game_progress",
                column: "picture_set_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_media_assets_child_id",
                table: "media_assets",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_media_assets_owner_id",
                table: "media_assets",
                column: "owner_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_notifications_user_id",
                table: "notifications",
                column: "user_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_items_course_id",
                table: "order_items",
                column: "course_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_items_order_id",
                table: "order_items",
                column: "order_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_items_plan_id",
                table: "order_items",
                column: "plan_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_items_product_id",
                table: "order_items",
                column: "product_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_shipping_info_order_id",
                table: "order_shipping_info",
                column: "order_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_order_tracking_events_order_id",
                table: "order_tracking_events",
                column: "order_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_orders_child_id",
                table: "orders",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_orders_order_code",
                table: "orders",
                column: "order_code",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_orders_parent_id_idempotency_key",
                table: "orders",
                columns: new[] { "parent_id", "idempotency_key" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_orders_voucher_id",
                table: "orders",
                column: "voucher_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_parental_consents_child_id",
                table: "parental_consents",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_parental_consents_parent_id",
                table: "parental_consents",
                column: "parent_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_picture_slots_picture_set_id_animal",
                table: "picture_slots",
                columns: new[] { "picture_set_id", "animal" },
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_products_course_id",
                table: "products",
                column: "course_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_products_created_by",
                table: "products",
                column: "created_by"
            );
            migrationBuilder.CreateIndex(
                name: "IX_products_recommended_subscription_plan_id",
                table: "products",
                column: "recommended_subscription_plan_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_token_hash",
                table: "refresh_tokens",
                column: "token_hash",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_user_id",
                table: "refresh_tokens",
                column: "user_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_submission_reviews_instructor_id",
                table: "submission_reviews",
                column: "instructor_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_submission_reviews_submission_id",
                table: "submission_reviews",
                column: "submission_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscriptions_child_id",
                table: "subscriptions",
                column: "child_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscriptions_order_item_id",
                table: "subscriptions",
                column: "order_item_id",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscriptions_parent_id",
                table: "subscriptions",
                column: "parent_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_subscriptions_plan_id",
                table: "subscriptions",
                column: "plan_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_users_avatar_preset_id",
                table: "users",
                column: "avatar_preset_id"
            );
            migrationBuilder.CreateIndex(
                name: "IX_users_email",
                table: "users",
                column: "email",
                unique: true
            );
            migrationBuilder.CreateIndex(
                name: "IX_vouchers_code",
                table: "vouchers",
                column: "code",
                unique: true
            );
        }

        /// <inheritdoc/>
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "ai_creatures");
            migrationBuilder.DropTable(name: "cart_items");
            migrationBuilder.DropTable(name: "child_badges");
            migrationBuilder.DropTable(name: "completed_pictures");
            migrationBuilder.DropTable(name: "fulfillment_orders");
            migrationBuilder.DropTable(name: "inventory_reservations");
            migrationBuilder.DropTable(name: "kid_rewards");
            migrationBuilder.DropTable(name: "lesson_progress");
            migrationBuilder.DropTable(name: "live_session_attendance");
            migrationBuilder.DropTable(name: "matching_game_progress");
            migrationBuilder.DropTable(name: "notifications");
            migrationBuilder.DropTable(name: "order_shipping_info");
            migrationBuilder.DropTable(name: "order_tracking_events");
            migrationBuilder.DropTable(name: "picture_slots");
            migrationBuilder.DropTable(name: "refresh_tokens");
            migrationBuilder.DropTable(name: "submission_reviews");
            migrationBuilder.DropTable(name: "subscriptions");
            migrationBuilder.DropTable(name: "ai_generation_jobs");
            migrationBuilder.DropTable(name: "carts");
            migrationBuilder.DropTable(name: "badges");
            migrationBuilder.DropTable(name: "inventory_skus");
            migrationBuilder.DropTable(name: "enrollments");
            migrationBuilder.DropTable(name: "live_class_enrollments");
            migrationBuilder.DropTable(name: "picture_sets");
            migrationBuilder.DropTable(name: "drawing_submissions");
            migrationBuilder.DropTable(name: "parental_consents");
            migrationBuilder.DropTable(name: "order_items");
            migrationBuilder.DropTable(name: "live_sessions");
            migrationBuilder.DropTable(name: "orders");
            migrationBuilder.DropTable(name: "products");
            migrationBuilder.DropTable(name: "lessons");
            migrationBuilder.DropTable(name: "live_classs");
            migrationBuilder.DropTable(name: "vouchers");
            migrationBuilder.DropTable(name: "subscription_plans");
            migrationBuilder.DropTable(name: "media_assets");
            migrationBuilder.DropTable(name: "courses");
            migrationBuilder.DropTable(name: "child_profiles");
            migrationBuilder.DropTable(name: "users");
            migrationBuilder.DropTable(name: "avatar_presets");
        }
    }
}
