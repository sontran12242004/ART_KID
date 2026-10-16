# ArtKids System Workflow

This document is the end-to-end test workflow for the ArtKids platform. It covers
the Flutter application, the parent and kid journeys, commerce, fulfillment,
inventory, hand-drawn lesson submissions, and the matching game.

The fixture values below are synthetic and must only be used in local or test
environments. They are not production credentials or real customer data.

## 1. Test profile and environment

### Synthetic parent profile

| Field | Value |
|---|---|
| Display name | Nguyen Test Parent |
| Email | `parent.test@example.invalid` |
| Password | `ArtKids-Test-2026!` |
| Parent ID | `parent_test_01` |
| Kid PIN | `2468` |
| Child 1 | Bo Test (`child-1`, birth year `2018`) |
| Child 2 | Mi Test (`child-2`, birth year `2021`) |
| Empty-progress child | New Test Child (`child-empty`, birth year `2022`) |
| Address | `1 Test Street, District 1, Ho Chi Minh City` |
| Phone | `0900000000` |

Do not place this profile in a production database. If authentication is backed
by a real API, seed an equivalent test account there rather than changing the
Flutter source.

### Local environment

Run the app from `apps/artkids_app` with the dev flavor:

```bash
flutter pub get
flutter run --flavor dev --dart-define=FLAVOR=dev -t lib/main.dart
```

The expected local flags in `env/dev.env` are:

```dotenv
API_BASE_URL=http://10.0.2.2:3000/api
ENABLE_MOCK_ORDERS=true
ENABLE_MOCK_SHOP=true
ENABLE_MOCK_COURSES_PROGRESS=true
ENABLE_FIREBASE=false
```

`10.0.2.2` is the Android emulator alias for the host machine. Use the host
machine's reachable address for a physical device.

## 2. Application entry and mode selection

1. Launch the app at `/`.
2. The splash screen navigates to `/mode-selector`.
3. Choose **Parent Mode** to open `/parent/login`.
4. Choose **Kid Mode** to open `/kid/pin`.
5. The parent can return to kid mode from `/parent`; the kid must pass the PIN
   gate to return to parent mode.

### Parent authentication workflow

1. Enter the synthetic email and password.
2. Submit the login form.
3. On success, open `/parent`.
4. Verify the selected child is `Bo Test`.
5. Open registration from the login page, submit the form, and verify the
   navigation back to parent login.
6. Verify logout from parent settings returns to `/parent/login`.

### Kid authentication workflow

1. Open `/kid/pin`.
2. Enter `2468`.
3. On success, open `/kid`.
4. Enter an incorrect PIN such as `0000` and verify that the child is not
   granted parent access.

**Implementation note:** the current `AuthRepositoryImpl` delegates login and PIN
verification to the API, but does not implement registration, child retrieval,
or parental-consent persistence. The PIN screen also contains a TODO for the
production PIN-pad behavior. The synthetic profile is therefore a test contract
for an auth fixture; it is not currently an automatic in-app mock account.

## 3. Parent workflows

From `/parent`, verify each of the following:

### Child and settings management

1. Open parent settings at `/parent/settings`.
2. Open kid PIN setup at `/parent/kid-pin`.
3. Select a child if multiple children are available.
4. Return to the dashboard and confirm the selected child's summary is shown.

### Course catalogue and progress

1. Open `/parent/courses`.
2. Browse the course list.
3. Open a course and inspect its lesson list.
4. Open `/parent/progress?childId=child-1`.
5. Open `/parent/child-progress/child-1/courses`.
6. Repeat with `child-2` and verify that progress differs.
7. Repeat with `child-empty` and verify the empty-progress state.

Mock progress expectations:

- `child-1`: four courses, including one completed course (`10/10`) and
  in-progress courses (`8/12` and `3/14`).
- `child-2`: two in-progress courses (`4/10` and `1/6`).
- `child-empty` or `new-child`: no course progress.

### Subscription workflow

1. Open `/parent/subscriptions`.
2. Inspect available plans.
3. Select a plan and continue to checkout.
4. Confirm the selected plan, price, duration, kit inclusion, and delivery
   information.
5. Complete or cancel checkout and verify the resulting screen.

### Shop and cart workflow

1. Open `/parent/shop`.
2. Search or filter products.
3. Open a product at `/parent/shop/product/<productId>`.
4. Add a product to the cart at `/parent/shop/cart`.
5. Change quantity and remove an item.
6. Verify free shipping at a cart subtotal of at least `300000` VND.
7. Apply each voucher:
   - `ARTKIDS10`: valid for orders from `200000` VND, 10% off, capped at
     `50000` VND.
   - `KID30K`: valid for orders from `150000` VND, 30000 VND off.
   - `VIP500K`: valid only from `500000` VND.
   - `EXPIRED20`: expected expired-voucher error.
8. Continue to `/parent/shop/checkout`.
9. Verify totals, shipping address, payment selection, and order confirmation.
10. Open the created order detail page.

Useful product IDs:

- `prod_kit_animal`
- `prod_kit_acrylic`
- `prod_kit_fairytale`
- `prod_kit_clay`
- `prod_tool_brushes`
- `prod_tool_kuretake`

### Orders and fulfillment tracking

1. Open `/parent/orders`.
2. Filter or inspect orders in each available status.
3. Open `/parent/orders/<orderId>`.
4. Verify item details, payment summary, shipping address, carrier, tracking
   number, timeline, and cancellation rules.
5. Cancel `ord_mock_1`, which is pending confirmation, and verify the cancelled
   state and reason.
6. Attempt to cancel a later-stage order and verify that cancellation is
   rejected or unavailable.

The mock repository initializes orders covering pending confirmation, preparing,
shipping, delivered, and cancelled states. The fulfillment service also exposes
the synthetic shipment `del_001` for parent `parent_1`, with tracking number
`VNPOST-884920194`.

## 4. Kid workflows

### Kid home and rewards

1. Pass the kid PIN and open `/kid`.
2. Open the lesson catalogue.
3. Open `/kid/badges`.
4. Inspect locked and unlocked badges and the badge detail view.
5. Return to kid home without exposing parent-only commerce or settings actions.

### Hand-drawn lesson submission workflow

1. Open a course lesson at `/kid/course/<courseId>/lessons`.
2. Open a lesson submission screen at `/kid/lesson/<lessonId>/submit`.
3. Draw the assignment on paper, outside the app.
4. Capture the finished picture with the camera.
5. Review the photo, retake it if needed, and confirm the submission.
6. Complete the parental consent check when prompted.
7. Verify the local pending-review confirmation for the teacher.
8. Cancel from the camera or consent flow and verify that no submission
   confirmation is shown.

### Matching game workflow

1. Open `/matching-game`.
2. Select the `living_room` picture set.
3. Draw each animal in the configured sequence at
   `/matching-game/draw/living_room`.
4. Verify that completing a drawing unlocks its sticker.
5. Match stickers to drop targets at `/matching-game/match/living_room`.
6. Verify success audio, celebration overlay, and completion persistence.
7. Leave and re-enter the game to verify Hive resume behavior.
8. Open `/matching-game/gallery` and verify the completed picture.

The matching game persists progress in the `matchingProgress` Hive box and
completed pictures in `completedPictures`.

## 5. Service workflows

These flows describe the service-side contracts used by the app and by
integration tests.

### Auth

1. `POST /api/v1/auth/register` creates a parent.
2. `POST /api/v1/auth/login` authenticates a parent.
3. `GET /api/v1/auth/me` returns the current parent.
4. `POST /api/v1/auth/kid-pin/verify` validates the kid PIN.
5. `POST /api/v1/auth/kid-pin/update` changes the PIN.

### Courses

1. `GET /api/v1/courses` lists courses.
2. `GET /api/v1/courses/:courseId` returns course detail.
3. `GET /api/v1/courses/:courseId/lessons` returns lessons.
4. `POST /api/v1/courses/progress` records child lesson progress.

### Commerce and orders

1. `GET /api/v1/commerce/plans` lists subscription plans.
2. `POST /api/v1/commerce/checkout` creates a checkout/order.
3. `GET /api/v1/commerce/orders` lists parent orders.

### Inventory

1. `GET /api/v1/inventory/stock` lists stock.
2. `GET /api/v1/inventory/stock/:sku` reads one SKU.
3. `POST /api/v1/inventory/reserve` reserves stock.

Known inventory fixtures:

- `KIT-BASIC-01`: 450 available, 35 reserved, reorder threshold 50.
- `KIT-CLAY-02`: 320 available, 20 reserved, reorder threshold 40.

Test both successful reservations and an over-quantity reservation that must
return an insufficient-stock error.

### Fulfillment

1. `POST /api/v1/fulfillment/shipments` creates a shipment.
2. `GET /api/v1/fulfillment/tracking/:trackingNumber` reads tracking status.
3. `POST /api/v1/fulfillment/webhook` updates status from a carrier webhook.
4. Verify the status progression:
   `ordered` -> `packed` -> `shipping` -> `delivered`.
5. Verify an unknown tracking number returns not found.

### Future AI generation

1. `POST /api/v1/ai/generate` creates a job with `queued` status.
2. `GET /api/v1/ai/jobs/:jobId` reads the job.
3. The worker or test harness updates the result to `completed`.
4. The app polls until `completed` or `failed`.
5. Verify invalid job IDs return not found and failed jobs expose an error.

The orchestrator currently creates an in-memory job and leaves the Redis/BullMQ
enqueue as a future integration point. Tests must not assume a persistent queue.

## 6. End-to-end acceptance sequence

Run this shortest complete happy path:

1. Launch the dev app and select Parent Mode.
2. Log in with the synthetic parent fixture.
3. Inspect child progress for `child-1`.
4. Open the shop, add `prod_kit_animal`, apply `ARTKIDS10`, and complete checkout.
5. Open the created order and verify its status and shipping summary.
6. Switch to Kid Mode and enter PIN `2468`.
7. Open a lesson and verify that teacher-reviewed hand-drawn submissions are
   handled separately from the future AI pipeline.
8. Play one `living_room` matching round.
9. Open the completion gallery.
10. Return through the PIN gate and verify parent settings remain protected.

## 7. Reset and test isolation

- Restart the Flutter process between tests that depend on initial mock order
  state; mock orders are held in memory.
- Clear the Hive boxes `matchingProgress` and `completedPictures` when testing
  first-run matching behavior.
- Use a fresh synthetic parent for API-backed auth tests.
- Keep `ENABLE_MOCK_*` flags enabled for deterministic UI tests and disable only
  the specific mock path being integration-tested.
- Never use the synthetic profile, test PIN, or fixture addresses in production.

## 8. Known implementation gaps

The following items should be treated as explicit failing integration checks
until implemented:

1. Auth registration, child retrieval, child creation, and parental consent are
   currently unimplemented in the Flutter auth repository.
2. The kid PIN screen still contains a TODO for the production PIN pad and
   verification flow.
3. The app router currently has no authentication redirect guard.
4. Fulfillment and inventory services expose providers but do not yet show
   controller wiring in the service entry point.
5. AI orchestration is in-memory; Redis/BullMQ enqueueing is commented out.
6. The order datasource contains TODOs for final backend response and
   cancellation contracts.

These gaps do not invalidate the UI workflow, but they must be resolved before
claiming the full production workflow is operational.
