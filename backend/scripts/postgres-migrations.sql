CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;
CREATE TABLE avatar_presets (
    id character varying(64) NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    is_for_child boolean NOT NULL,
    type text NOT NULL,
    asset_path text,
    icon_name text,
    primary_color text NOT NULL,
    secondary_color text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_avatar_presets" PRIMARY KEY (id)
);

CREATE TABLE badges (
    id character varying(64) NOT NULL,
    display_order integer NOT NULL,
    title text NOT NULL,
    emoji text NOT NULL,
    icon_name text NOT NULL,
    condition text NOT NULL,
    meaning text NOT NULL,
    category text NOT NULL,
    primary_color text NOT NULL,
    secondary_color text NOT NULL,
    max_progress integer NOT NULL,
    metric text NOT NULL,
    model_glb_path text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_badges" PRIMARY KEY (id)
);

CREATE TABLE picture_sets (
    id character varying(64) NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    thumbnail_asset text NOT NULL,
    background_asset text NOT NULL,
    bg_aspect_ratio double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_picture_sets" PRIMARY KEY (id)
);

CREATE TABLE subscription_plans (
    id character varying(64) NOT NULL,
    name text NOT NULL,
    description text,
    price_monthly bigint NOT NULL,
    price_vnd bigint NOT NULL,
    duration_months integer NOT NULL,
    features text NOT NULL,
    includes_kit boolean NOT NULL,
    kit_delivery_included boolean NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_subscription_plans" PRIMARY KEY (id)
);

CREATE TABLE vouchers (
    id character varying(64) NOT NULL,
    code text NOT NULL,
    title text NOT NULL,
    discount_type text NOT NULL,
    discount_value bigint NOT NULL,
    min_order_amount bigint NOT NULL,
    max_discount_amount bigint,
    expiry_date timestamp with time zone NOT NULL,
    is_usable boolean NOT NULL,
    usage_limit integer NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_vouchers" PRIMARY KEY (id)
);

CREATE TABLE users (
    id character varying(64) NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    phone_number text,
    avatar_url text,
    avatar_preset_id character varying(64),
    role text NOT NULL,
    password_hash text NOT NULL,
    parent_pin_hash text,
    has_completed_coppa_consent boolean NOT NULL,
    parental_consent_at timestamp with time zone,
    notifications_enabled boolean NOT NULL,
    daily_drawing_reminder boolean NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_users" PRIMARY KEY (id),
    CONSTRAINT "FK_users_avatar_presets_avatar_preset_id" FOREIGN KEY (avatar_preset_id) REFERENCES avatar_presets (id) ON DELETE RESTRICT
);

CREATE TABLE picture_slots (
    id character varying(64) NOT NULL,
    picture_set_id character varying(64) NOT NULL,
    animal text NOT NULL,
    sequence_index integer NOT NULL,
    left_percent double precision NOT NULL,
    top_percent double precision NOT NULL,
    width_percent double precision NOT NULL,
    height_percent double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_picture_slots" PRIMARY KEY (id),
    CONSTRAINT "FK_picture_slots_picture_sets_picture_set_id" FOREIGN KEY (picture_set_id) REFERENCES picture_sets (id) ON DELETE RESTRICT
);

CREATE TABLE carts (
    id character varying(64) NOT NULL,
    parent_id character varying(64) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_carts" PRIMARY KEY (id),
    CONSTRAINT "FK_carts_users_parent_id" FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE child_profiles (
    id character varying(64) NOT NULL,
    parent_id character varying(64) NOT NULL,
    nickname text NOT NULL,
    birth_year integer NOT NULL,
    avatar_url text,
    avatar_preset_id character varying(64),
    interests text,
    kid_pin_hash text,
    total_points integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_child_profiles" PRIMARY KEY (id),
    CONSTRAINT "FK_child_profiles_avatar_presets_avatar_preset_id" FOREIGN KEY (avatar_preset_id) REFERENCES avatar_presets (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_child_profiles_users_parent_id" FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE courses (
    id character varying(64) NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    thumbnail_url text,
    age_range text NOT NULL,
    price_vnd bigint NOT NULL,
    includes_physical_kit boolean NOT NULL,
    instructor_id character varying(64) NOT NULL,
    is_published boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_courses" PRIMARY KEY (id),
    CONSTRAINT "FK_courses_users_instructor_id" FOREIGN KEY (instructor_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE notifications (
    id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    reference_id text,
    read_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_notifications" PRIMARY KEY (id),
    CONSTRAINT "FK_notifications_users_user_id" FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE refresh_tokens (
    id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_refresh_tokens" PRIMARY KEY (id),
    CONSTRAINT "FK_refresh_tokens_users_user_id" FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE child_badges (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    badge_id character varying(64) NOT NULL,
    current_progress integer NOT NULL,
    unlocked_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_child_badges" PRIMARY KEY (id),
    CONSTRAINT "FK_child_badges_badges_badge_id" FOREIGN KEY (badge_id) REFERENCES badges (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_child_badges_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT
);

CREATE TABLE completed_pictures (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    picture_set_id character varying(64) NOT NULL,
    picture_title text NOT NULL,
    thumbnail_asset text NOT NULL,
    completed_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_completed_pictures" PRIMARY KEY (id),
    CONSTRAINT "FK_completed_pictures_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_completed_pictures_picture_sets_picture_set_id" FOREIGN KEY (picture_set_id) REFERENCES picture_sets (id) ON DELETE RESTRICT
);

CREATE TABLE kid_rewards (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    title text NOT NULL,
    icon_name text NOT NULL,
    description text NOT NULL,
    unlocked_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_kid_rewards" PRIMARY KEY (id),
    CONSTRAINT "FK_kid_rewards_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT
);

CREATE TABLE matching_game_progress (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    picture_set_id character varying(64) NOT NULL,
    current_step text NOT NULL,
    current_animal_index integer NOT NULL,
    unlocked_stickers text NOT NULL,
    matched_animals text NOT NULL,
    last_updated_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_matching_game_progress" PRIMARY KEY (id),
    CONSTRAINT "FK_matching_game_progress_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_matching_game_progress_picture_sets_picture_set_id" FOREIGN KEY (picture_set_id) REFERENCES picture_sets (id) ON DELETE RESTRICT
);

CREATE TABLE media_assets (
    id character varying(64) NOT NULL,
    owner_id character varying(64) NOT NULL,
    child_id character varying(64),
    kind text NOT NULL,
    storage_key text NOT NULL,
    original_name text NOT NULL,
    content_type text NOT NULL,
    size_bytes bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_media_assets" PRIMARY KEY (id),
    CONSTRAINT "FK_media_assets_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_media_assets_users_owner_id" FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    id character varying(64) NOT NULL,
    order_code text NOT NULL,
    parent_id character varying(64) NOT NULL,
    child_id character varying(64),
    paid_at timestamp with time zone,
    status text NOT NULL,
    order_type text NOT NULL,
    payment_status text NOT NULL,
    payment_method_name text NOT NULL,
    subtotal_vnd bigint NOT NULL,
    shipping_fee_vnd bigint NOT NULL,
    discount_vnd bigint NOT NULL,
    voucher_id character varying(64),
    voucher_code text,
    total_amount_vnd bigint NOT NULL,
    cancel_reason text,
    idempotency_key text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_orders" PRIMARY KEY (id),
    CONSTRAINT ck_order_total CHECK (subtotal_vnd >= 0 AND shipping_fee_vnd >= 0 AND discount_vnd >= 0 AND total_amount_vnd = subtotal_vnd + shipping_fee_vnd - discount_vnd AND total_amount_vnd >= 0),
    CONSTRAINT "FK_orders_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_orders_users_parent_id" FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_orders_vouchers_voucher_id" FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE RESTRICT
);

CREATE TABLE parental_consents (
    id character varying(64) NOT NULL,
    parent_id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    purpose text NOT NULL,
    policy_version text NOT NULL,
    granted_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_parental_consents" PRIMARY KEY (id),
    CONSTRAINT "FK_parental_consents_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_parental_consents_users_parent_id" FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE live_classs (
    id character varying(64) NOT NULL,
    course_id character varying(64) NOT NULL,
    instructor_id character varying(64) NOT NULL,
    name text NOT NULL,
    capacity integer NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_live_classs" PRIMARY KEY (id),
    CONSTRAINT ck_capacity CHECK (capacity BETWEEN 1 AND 30),
    CONSTRAINT "FK_live_classs_courses_course_id" FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_live_classs_users_instructor_id" FOREIGN KEY (instructor_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE products (
    id character varying(64) NOT NULL,
    name text NOT NULL,
    price_vnd bigint NOT NULL,
    original_price_vnd bigint,
    thumbnail_url text NOT NULL,
    images text NOT NULL,
    description text NOT NULL,
    category text NOT NULL,
    course_id character varying(64),
    recommended_subscription_plan_id character varying(64),
    kit_items text NOT NULL,
    rating numeric(18,2) NOT NULL,
    sold_count integer NOT NULL,
    created_by character varying(64) NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_products" PRIMARY KEY (id),
    CONSTRAINT "FK_products_courses_course_id" FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_products_subscription_plans_recommended_subscription_plan_id" FOREIGN KEY (recommended_subscription_plan_id) REFERENCES subscription_plans (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_products_users_created_by" FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE lessons (
    id character varying(64) NOT NULL,
    course_id character varying(64) NOT NULL,
    title text NOT NULL,
    order_index integer NOT NULL,
    video_url text,
    video_asset_id character varying(64),
    practice_instructions text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_lessons" PRIMARY KEY (id),
    CONSTRAINT "FK_lessons_courses_course_id" FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_lessons_media_assets_video_asset_id" FOREIGN KEY (video_asset_id) REFERENCES media_assets (id) ON DELETE RESTRICT
);

CREATE TABLE order_shipping_info (
    id character varying(64) NOT NULL,
    order_id character varying(64) NOT NULL,
    recipient_name text NOT NULL,
    phone_number text NOT NULL,
    full_address text NOT NULL,
    carrier_name text,
    tracking_number text,
    tracking_url text,
    estimated_delivery_date timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_order_shipping_info" PRIMARY KEY (id),
    CONSTRAINT "FK_order_shipping_info_orders_order_id" FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT
);

CREATE TABLE order_tracking_events (
    id character varying(64) NOT NULL,
    order_id character varying(64) NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    timestamp timestamp with time zone NOT NULL,
    is_passed boolean NOT NULL,
    is_current boolean NOT NULL,
    cancel_reason text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_order_tracking_events" PRIMARY KEY (id),
    CONSTRAINT "FK_order_tracking_events_orders_order_id" FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT
);

CREATE TABLE live_class_enrollments (
    id character varying(64) NOT NULL,
    class_id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    status text NOT NULL,
    enrolled_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_live_class_enrollments" PRIMARY KEY (id),
    CONSTRAINT "FK_live_class_enrollments_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_live_class_enrollments_live_classs_class_id" FOREIGN KEY (class_id) REFERENCES live_classs (id) ON DELETE RESTRICT
);

CREATE TABLE cart_items (
    id character varying(64) NOT NULL,
    cart_id character varying(64) NOT NULL,
    product_id character varying(64) NOT NULL,
    quantity integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_cart_items" PRIMARY KEY (id),
    CONSTRAINT ck_cart_quantity CHECK (quantity > 0),
    CONSTRAINT "FK_cart_items_carts_cart_id" FOREIGN KEY (cart_id) REFERENCES carts (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_cart_items_products_product_id" FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

CREATE TABLE inventory_skus (
    id character varying(64) NOT NULL,
    sku text NOT NULL,
    product_id character varying(64) NOT NULL,
    kit_name text NOT NULL,
    quantity_available integer NOT NULL,
    quantity_reserved integer NOT NULL,
    reorder_threshold integer NOT NULL,
    unit_cost_vnd bigint NOT NULL,
    warehouse_location text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_inventory_skus" PRIMARY KEY (id),
    CONSTRAINT ck_stock CHECK (quantity_available >= 0 AND quantity_reserved >= 0),
    CONSTRAINT "FK_inventory_skus_products_product_id" FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

CREATE TABLE order_items (
    id character varying(64) NOT NULL,
    order_id character varying(64) NOT NULL,
    item_type text NOT NULL,
    product_id character varying(64),
    course_id character varying(64),
    plan_id character varying(64),
    title text NOT NULL,
    thumbnail_url text,
    quantity integer NOT NULL,
    unit_price_vnd bigint NOT NULL,
    kit_items text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_order_items" PRIMARY KEY (id),
    CONSTRAINT ck_item CHECK (quantity > 0 AND unit_price_vnd >= 0),
    CONSTRAINT "FK_order_items_courses_course_id" FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_order_items_orders_order_id" FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_order_items_products_product_id" FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_order_items_subscription_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES subscription_plans (id) ON DELETE RESTRICT
);

CREATE TABLE live_sessions (
    id character varying(64) NOT NULL,
    class_id character varying(64) NOT NULL,
    lesson_id character varying(64),
    title text NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    provider text NOT NULL,
    room_url text,
    status text NOT NULL,
    recording_url text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_live_sessions" PRIMARY KEY (id),
    CONSTRAINT ck_session_time CHECK (ends_at > starts_at),
    CONSTRAINT "FK_live_sessions_lessons_lesson_id" FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_live_sessions_live_classs_class_id" FOREIGN KEY (class_id) REFERENCES live_classs (id) ON DELETE RESTRICT
);

CREATE TABLE fulfillment_orders (
    id character varying(64) NOT NULL,
    order_id character varying(64) NOT NULL,
    inventory_sku_id character varying(64) NOT NULL,
    kit_name text NOT NULL,
    quantity integer NOT NULL,
    carrier text NOT NULL,
    tracking_number text NOT NULL,
    status text NOT NULL,
    shipping_address text NOT NULL,
    recipient_name text NOT NULL,
    recipient_phone text NOT NULL,
    estimated_delivery_date timestamp with time zone,
    shipped_at timestamp with time zone,
    delivered_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_fulfillment_orders" PRIMARY KEY (id),
    CONSTRAINT "FK_fulfillment_orders_inventory_skus_inventory_sku_id" FOREIGN KEY (inventory_sku_id) REFERENCES inventory_skus (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_fulfillment_orders_orders_order_id" FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT
);

CREATE TABLE enrollments (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    course_id character varying(64) NOT NULL,
    order_item_id character varying(64),
    enrolled_at timestamp with time zone NOT NULL,
    last_learned_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_enrollments" PRIMARY KEY (id),
    CONSTRAINT "FK_enrollments_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_enrollments_courses_course_id" FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_enrollments_order_items_order_item_id" FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE RESTRICT
);

CREATE TABLE inventory_reservations (
    id character varying(64) NOT NULL,
    order_item_id character varying(64) NOT NULL,
    inventory_sku_id character varying(64) NOT NULL,
    quantity integer NOT NULL,
    status text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_inventory_reservations" PRIMARY KEY (id),
    CONSTRAINT "FK_inventory_reservations_inventory_skus_inventory_sku_id" FOREIGN KEY (inventory_sku_id) REFERENCES inventory_skus (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_inventory_reservations_order_items_order_item_id" FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE RESTRICT
);

CREATE TABLE subscriptions (
    id character varying(64) NOT NULL,
    parent_id character varying(64) NOT NULL,
    child_id character varying(64),
    plan_id character varying(64) NOT NULL,
    order_item_id character varying(64) NOT NULL,
    status text NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_subscriptions" PRIMARY KEY (id),
    CONSTRAINT "FK_subscriptions_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_subscriptions_order_items_order_item_id" FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_subscriptions_subscription_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES subscription_plans (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_subscriptions_users_parent_id" FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE drawing_submissions (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    lesson_id character varying(64),
    live_session_id character varying(64),
    image_asset_id character varying(64) NOT NULL,
    image_path text NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_drawing_submissions" PRIMARY KEY (id),
    CONSTRAINT "FK_drawing_submissions_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_drawing_submissions_lessons_lesson_id" FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_drawing_submissions_live_sessions_live_session_id" FOREIGN KEY (live_session_id) REFERENCES live_sessions (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_drawing_submissions_media_assets_image_asset_id" FOREIGN KEY (image_asset_id) REFERENCES media_assets (id) ON DELETE RESTRICT
);

CREATE TABLE live_session_attendance (
    id character varying(64) NOT NULL,
    session_id character varying(64) NOT NULL,
    class_enrollment_id character varying(64) NOT NULL,
    first_joined_at timestamp with time zone,
    last_joined_at timestamp with time zone,
    last_left_at timestamp with time zone,
    total_duration_seconds integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_live_session_attendance" PRIMARY KEY (id),
    CONSTRAINT "FK_live_session_attendance_live_class_enrollments_class_enroll~" FOREIGN KEY (class_enrollment_id) REFERENCES live_class_enrollments (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_live_session_attendance_live_sessions_session_id" FOREIGN KEY (session_id) REFERENCES live_sessions (id) ON DELETE RESTRICT
);

CREATE TABLE lesson_progress (
    id character varying(64) NOT NULL,
    enrollment_id character varying(64) NOT NULL,
    lesson_id character varying(64) NOT NULL,
    status text NOT NULL,
    learning_seconds integer NOT NULL,
    last_learned_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_lesson_progress" PRIMARY KEY (id),
    CONSTRAINT "FK_lesson_progress_enrollments_enrollment_id" FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_lesson_progress_lessons_lesson_id" FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE RESTRICT
);

CREATE TABLE ai_generation_jobs (
    id character varying(64) NOT NULL,
    child_id character varying(64) NOT NULL,
    submission_id character varying(64) NOT NULL,
    consent_id character varying(64) NOT NULL,
    drawing_image_url text NOT NULL,
    status text NOT NULL,
    error_message text,
    completed_at timestamp with time zone,
    attempts integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_ai_generation_jobs" PRIMARY KEY (id),
    CONSTRAINT "FK_ai_generation_jobs_child_profiles_child_id" FOREIGN KEY (child_id) REFERENCES child_profiles (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_ai_generation_jobs_drawing_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES drawing_submissions (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_ai_generation_jobs_parental_consents_consent_id" FOREIGN KEY (consent_id) REFERENCES parental_consents (id) ON DELETE RESTRICT
);

CREATE TABLE submission_reviews (
    id character varying(64) NOT NULL,
    submission_id character varying(64) NOT NULL,
    instructor_id character varying(64) NOT NULL,
    score numeric(4,2) NOT NULL,
    feedback text NOT NULL,
    reviewed_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_submission_reviews" PRIMARY KEY (id),
    CONSTRAINT ck_score CHECK (score BETWEEN 0 AND 10),
    CONSTRAINT "FK_submission_reviews_drawing_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES drawing_submissions (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_submission_reviews_users_instructor_id" FOREIGN KEY (instructor_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE ai_creatures (
    id character varying(64) NOT NULL,
    submission_id character varying(64) NOT NULL,
    job_id character varying(64) NOT NULL,
    animal_type text NOT NULL,
    display_name text NOT NULL,
    model2d_url text,
    model3d_url text,
    animation_url text,
    audio_url text,
    thumbnail_url text,
    cheering_message text NOT NULL,
    suggested_animation_id text,
    status text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_ai_creatures" PRIMARY KEY (id),
    CONSTRAINT "FK_ai_creatures_ai_generation_jobs_job_id" FOREIGN KEY (job_id) REFERENCES ai_generation_jobs (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_ai_creatures_drawing_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES drawing_submissions (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX "IX_ai_creatures_job_id" ON ai_creatures (job_id);

CREATE INDEX "IX_ai_creatures_submission_id" ON ai_creatures (submission_id);

CREATE INDEX "IX_ai_generation_jobs_child_id" ON ai_generation_jobs (child_id);

CREATE INDEX "IX_ai_generation_jobs_consent_id" ON ai_generation_jobs (consent_id);

CREATE INDEX "IX_ai_generation_jobs_submission_id" ON ai_generation_jobs (submission_id);

CREATE UNIQUE INDEX "IX_cart_items_cart_id_product_id" ON cart_items (cart_id, product_id);

CREATE INDEX "IX_cart_items_product_id" ON cart_items (product_id);

CREATE UNIQUE INDEX "IX_carts_parent_id" ON carts (parent_id);

CREATE INDEX "IX_child_badges_badge_id" ON child_badges (badge_id);

CREATE UNIQUE INDEX "IX_child_badges_child_id_badge_id" ON child_badges (child_id, badge_id);

CREATE INDEX "IX_child_profiles_avatar_preset_id" ON child_profiles (avatar_preset_id);

CREATE INDEX "IX_child_profiles_parent_id" ON child_profiles (parent_id);

CREATE INDEX "IX_completed_pictures_child_id" ON completed_pictures (child_id);

CREATE INDEX "IX_completed_pictures_picture_set_id" ON completed_pictures (picture_set_id);

CREATE INDEX "IX_courses_instructor_id" ON courses (instructor_id);

CREATE INDEX "IX_drawing_submissions_child_id" ON drawing_submissions (child_id);

CREATE INDEX "IX_drawing_submissions_image_asset_id" ON drawing_submissions (image_asset_id);

CREATE INDEX "IX_drawing_submissions_lesson_id" ON drawing_submissions (lesson_id);

CREATE INDEX "IX_drawing_submissions_live_session_id" ON drawing_submissions (live_session_id);

CREATE UNIQUE INDEX "IX_enrollments_child_id_course_id" ON enrollments (child_id, course_id);

CREATE INDEX "IX_enrollments_course_id" ON enrollments (course_id);

CREATE INDEX "IX_enrollments_order_item_id" ON enrollments (order_item_id);

CREATE UNIQUE INDEX "IX_fulfillment_orders_carrier_tracking_number" ON fulfillment_orders (carrier, tracking_number);

CREATE INDEX "IX_fulfillment_orders_inventory_sku_id" ON fulfillment_orders (inventory_sku_id);

CREATE UNIQUE INDEX "IX_fulfillment_orders_order_id_inventory_sku_id" ON fulfillment_orders (order_id, inventory_sku_id);

CREATE INDEX "IX_inventory_reservations_inventory_sku_id" ON inventory_reservations (inventory_sku_id);

CREATE INDEX "IX_inventory_reservations_order_item_id" ON inventory_reservations (order_item_id);

CREATE UNIQUE INDEX "IX_inventory_skus_product_id" ON inventory_skus (product_id);

CREATE UNIQUE INDEX "IX_inventory_skus_sku" ON inventory_skus (sku);

CREATE INDEX "IX_kid_rewards_child_id" ON kid_rewards (child_id);

CREATE UNIQUE INDEX "IX_lesson_progress_enrollment_id_lesson_id" ON lesson_progress (enrollment_id, lesson_id);

CREATE INDEX "IX_lesson_progress_lesson_id" ON lesson_progress (lesson_id);

CREATE UNIQUE INDEX "IX_lessons_course_id_order_index" ON lessons (course_id, order_index);

CREATE INDEX "IX_lessons_video_asset_id" ON lessons (video_asset_id);

CREATE INDEX "IX_live_class_enrollments_child_id" ON live_class_enrollments (child_id);

CREATE UNIQUE INDEX "IX_live_class_enrollments_class_id_child_id" ON live_class_enrollments (class_id, child_id);

CREATE INDEX "IX_live_classs_course_id" ON live_classs (course_id);

CREATE INDEX "IX_live_classs_instructor_id" ON live_classs (instructor_id);

CREATE INDEX "IX_live_session_attendance_class_enrollment_id" ON live_session_attendance (class_enrollment_id);

CREATE UNIQUE INDEX "IX_live_session_attendance_session_id_class_enrollment_id" ON live_session_attendance (session_id, class_enrollment_id);

CREATE INDEX "IX_live_sessions_class_id" ON live_sessions (class_id);

CREATE INDEX "IX_live_sessions_lesson_id" ON live_sessions (lesson_id);

CREATE UNIQUE INDEX "IX_matching_game_progress_child_id_picture_set_id" ON matching_game_progress (child_id, picture_set_id);

CREATE INDEX "IX_matching_game_progress_picture_set_id" ON matching_game_progress (picture_set_id);

CREATE INDEX "IX_media_assets_child_id" ON media_assets (child_id);

CREATE INDEX "IX_media_assets_owner_id" ON media_assets (owner_id);

CREATE INDEX "IX_notifications_user_id" ON notifications (user_id);

CREATE INDEX "IX_order_items_course_id" ON order_items (course_id);

CREATE INDEX "IX_order_items_order_id" ON order_items (order_id);

CREATE INDEX "IX_order_items_plan_id" ON order_items (plan_id);

CREATE INDEX "IX_order_items_product_id" ON order_items (product_id);

CREATE UNIQUE INDEX "IX_order_shipping_info_order_id" ON order_shipping_info (order_id);

CREATE INDEX "IX_order_tracking_events_order_id" ON order_tracking_events (order_id);

CREATE INDEX "IX_orders_child_id" ON orders (child_id);

CREATE UNIQUE INDEX "IX_orders_order_code" ON orders (order_code);

CREATE UNIQUE INDEX "IX_orders_parent_id_idempotency_key" ON orders (parent_id, idempotency_key);

CREATE INDEX "IX_orders_voucher_id" ON orders (voucher_id);

CREATE INDEX "IX_parental_consents_child_id" ON parental_consents (child_id);

CREATE INDEX "IX_parental_consents_parent_id" ON parental_consents (parent_id);

CREATE UNIQUE INDEX "IX_picture_slots_picture_set_id_animal" ON picture_slots (picture_set_id, animal);

CREATE INDEX "IX_products_course_id" ON products (course_id);

CREATE INDEX "IX_products_created_by" ON products (created_by);

CREATE INDEX "IX_products_recommended_subscription_plan_id" ON products (recommended_subscription_plan_id);

CREATE UNIQUE INDEX "IX_refresh_tokens_token_hash" ON refresh_tokens (token_hash);

CREATE INDEX "IX_refresh_tokens_user_id" ON refresh_tokens (user_id);

CREATE INDEX "IX_submission_reviews_instructor_id" ON submission_reviews (instructor_id);

CREATE INDEX "IX_submission_reviews_submission_id" ON submission_reviews (submission_id);

CREATE INDEX "IX_subscriptions_child_id" ON subscriptions (child_id);

CREATE UNIQUE INDEX "IX_subscriptions_order_item_id" ON subscriptions (order_item_id);

CREATE INDEX "IX_subscriptions_parent_id" ON subscriptions (parent_id);

CREATE INDEX "IX_subscriptions_plan_id" ON subscriptions (plan_id);

CREATE INDEX "IX_users_avatar_preset_id" ON users (avatar_preset_id);

CREATE UNIQUE INDEX "IX_users_email" ON users (email);

CREATE UNIQUE INDEX "IX_vouchers_code" ON vouchers (code);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261021145551_InitialCreate', '10.0.9');

COMMIT;

START TRANSACTION;
ALTER TABLE ai_generation_jobs ADD lease_expires_at timestamp with time zone;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261021150357_AiJobLeases', '10.0.9');

COMMIT;

START TRANSACTION;
DROP INDEX "IX_fulfillment_orders_order_id_inventory_sku_id";

ALTER TABLE subscription_plans ADD kit_inventory_sku_id character varying(64);

ALTER TABLE subscription_plans ADD kit_quantity integer NOT NULL DEFAULT 0;

ALTER TABLE order_items ADD duration_months integer;

ALTER TABLE order_items ADD kit_inventory_sku_id character varying(64);

ALTER TABLE order_items ADD kit_quantity integer NOT NULL DEFAULT 0;

ALTER TABLE fulfillment_orders ADD subscription_kit_delivery_id character varying(64);

CREATE TABLE subscription_kit_deliverys (
    id character varying(64) NOT NULL,
    subscription_id character varying(64) NOT NULL,
    inventory_sku_id character varying(64) NOT NULL,
    delivery_index integer NOT NULL,
    scheduled_for timestamp with time zone NOT NULL,
    quantity integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT "PK_subscription_kit_deliverys" PRIMARY KEY (id),
    CONSTRAINT "FK_subscription_kit_deliverys_inventory_skus_inventory_sku_id" FOREIGN KEY (inventory_sku_id) REFERENCES inventory_skus (id) ON DELETE RESTRICT,
    CONSTRAINT "FK_subscription_kit_deliverys_subscriptions_subscription_id" FOREIGN KEY (subscription_id) REFERENCES subscriptions (id) ON DELETE RESTRICT
);

CREATE INDEX "IX_subscription_plans_kit_inventory_sku_id" ON subscription_plans (kit_inventory_sku_id);

CREATE INDEX "IX_order_items_kit_inventory_sku_id" ON order_items (kit_inventory_sku_id);

CREATE INDEX "IX_fulfillment_orders_order_id" ON fulfillment_orders (order_id);

CREATE UNIQUE INDEX "IX_fulfillment_orders_subscription_kit_delivery_id" ON fulfillment_orders (subscription_kit_delivery_id);

CREATE INDEX "IX_subscription_kit_deliverys_inventory_sku_id" ON subscription_kit_deliverys (inventory_sku_id);

CREATE UNIQUE INDEX "IX_subscription_kit_deliverys_subscription_id_delivery_index" ON subscription_kit_deliverys (subscription_id, delivery_index);

ALTER TABLE fulfillment_orders ADD CONSTRAINT "FK_fulfillment_orders_subscription_kit_deliverys_subscription_~" FOREIGN KEY (subscription_kit_delivery_id) REFERENCES subscription_kit_deliverys (id) ON DELETE RESTRICT;

ALTER TABLE order_items ADD CONSTRAINT "FK_order_items_inventory_skus_kit_inventory_sku_id" FOREIGN KEY (kit_inventory_sku_id) REFERENCES inventory_skus (id) ON DELETE RESTRICT;

ALTER TABLE subscription_plans ADD CONSTRAINT "FK_subscription_plans_inventory_skus_kit_inventory_sku_id" FOREIGN KEY (kit_inventory_sku_id) REFERENCES inventory_skus (id) ON DELETE RESTRICT;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261021150639_SubscriptionKitSchedules', '10.0.9');

COMMIT;

START TRANSACTION;
ALTER TABLE courses ADD is_deleted boolean NOT NULL DEFAULT FALSE;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261022144108_CourseSoftDeletion', '10.0.9');

COMMIT;
