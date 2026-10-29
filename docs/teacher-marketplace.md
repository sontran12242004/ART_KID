# Teacher marketplace and moderation

The current implementation uses the ASP.NET Core 10 backend in `backend/` and the Flutter app in `apps/artkids_app/`. Older NestJS architecture descriptions do not describe this workflow.

## Behavior and ownership

- Only instructors create seller listings. A listing can link to a course currently taught by that instructor, or be an independent art tool. The category is assigned by the server.
- New submissions, edits, resubmissions and availability changes become `pending`. Editing an approved listing immediately removes it from public catalog/detail/media until approval. Rejections require a nonblank reason. Only the owning instructor can edit or withdraw a listing; admins review it through the review API.
- `Revision` is an application-managed EF concurrency token. Updates and reviews compare the revision the user saw; stale or already-reviewed submissions return 409. Server transactions are serializable.
- Approval and withdrawal are separate from binary availability. Approved out-of-stock products may be browsed, but cannot be added to cart or checked out. Existing stale cart items can be removed. Pending/withdrawn product content is excluded from cart responses.
- Seller inventory does not create or consume SKUs or reservations. Platform inventory, vouchers, checkout shipping fees, manual transfer/COD restrictions and subscription allocation remain on their existing paths. Legacy platform confirmation remains privileged. Seller-only COD starts `preparing` immediately after checkout and never needs admin order confirmation. Marketplace transfers stay pending until a trusted funds-verification mechanism exists; the legacy confirm endpoint cannot verify them.
- Seller order lines snapshot `SellerId` when purchased. Product edits/deletion cannot transfer order access. Seller responses contain only their own items and subtotal, necessary recipient fields and their own fulfillment record. They exclude other sellers' items, whole-order amounts, vouchers, bank/payment reference metadata, tracking events and parent/child IDs. Additive coarse readiness flags explain whether this seller may ship, without exposing unrelated lines or amounts. Generic commerce order endpoints remain restricted to the buyer/admin.

## API contracts

All paths below are relative to `/api/v1`. Authentication uses the existing bearer-token system. Lists return `{ total, page, pageSize, items }`; page size is clamped to 1–100.

| Method/path | Role | Contract |
| --- | --- | --- |
| `GET marketplace/listings` | instructor | Own active listings, optional `courseId`, `page`, `pageSize`. Includes pending/rejected. |
| `GET marketplace/listings/{id}` | owner instructor | Product and moderation metadata. |
| `POST marketplace/listings` | instructor | `name`, `priceVnd` (1–100000000), `description`, owned uploaded `imageAssetId`, optional `courseId`, `isAvailable` (default true). Returns pending Product. |
| `PUT marketplace/listings/{id}` | owner instructor | Same full listing fields; image can be omitted to retain it; `expectedRevision` required. Returns pending Product. |
| `PUT marketplace/listings/{id}/availability` | owner instructor | `isAvailable`, `expectedRevision`; returns pending Product. |
| `DELETE marketplace/listings/{id}` | owner instructor | Soft withdrawal; 204. Historical orders remain. |
| `GET marketplace/reviews` | admin | Active pending submissions, paginated. |
| `GET marketplace/reviews/{id}` | admin | Listing detail and revision for review. |
| `POST marketplace/reviews/{id}` | admin | `status` (`approved` or `rejected`), `expectedRevision`, `reason` required for rejection (max 1000). Returns reviewed Product. |
| `GET marketplace/orders` | instructor | Own order summaries and seller subtotal only, paginated. |
| `GET marketplace/orders/{id}` | involved instructor | Own items, recipient information and own fulfillment. No unrelated seller data. |
| `PUT marketplace/orders/{id}/fulfillment` | involved instructor | `carrier` (`GHN`, `VNPost`, `GHTK`), `status` (`preparing`, `shipping`, `delivered`), optional `trackingNumber` (max 100). COD sellers can prepare/ship immediately; manual transfer requires an already verified `paid` state. Seller dispatch never approves the platform portion. |

Wrong roles return 403; cross-owner resources return 404; invalid request data returns 400; stale revisions/state conflicts return 409. Existing ProblemDetails responses are reused.

The legacy course-product POST/PUT/DELETE routes now require instructors and delegate seller writes to moderation. Numeric legacy quantity is interpreted as binary availability; it never updates warehouse stock. `ExpectedQuantityAvailable` is obsolete for seller products; new clients use marketplace revisions. Course-product GET remains staff-only and enforces course/creator access. The admin platform catalog PUT rejects seller products with 409, preventing approval bypass. Admin platform catalog creation remains available for existing platform commerce.

Public `shop/products` and product detail require active+approved, including when called by admins. `inStock` comes from teacher availability for seller products and existing warehouse stock for platform products. Private image previews reuse authenticated `GET media/{assetId}`. Both product-image and authenticated media responses use `private, no-store`; pending/rejected images are accessible only to their owner/admin. Previously downloaded images cannot be revoked from a user's device.

## Order processing and unresolved payment policy

Listing moderation is not order approval. Sellers see their own lines immediately after checkout, including unpaid transfer orders.

| Order/payment | Seller readiness | Platform behavior | Payment meaning |
| --- | --- | --- | --- |
| Seller-only COD | `preparing` at checkout; no admin action required | No warehouse allocation | `cod`, `paidAt=null`, including after seller-reported delivery |
| Mixed seller/platform COD | Each seller can prepare/ship immediately; own `sellerStatus` is independent | Whole-order status stays `pending_confirmation` while platform reservations await the existing legacy action | Seller or platform delivery must not mark this marketplace order paid |
| Any marketplace manual transfer | Visible as `sellerStatus=pending_payment`; preparation/dispatch blocked until trusted `PaymentStatus=paid` | Legacy `/confirm` returns 409 for unverified funds, even on mixed orders | No inferred receipt or invented gateway; money remains pending |
| Platform-only orders, courses, subscriptions | No seller access | Existing confirmation, stock, entitlements and payment behavior retained | Existing legacy verification/collection behavior unchanged |

Marketplace bank-transfer **recipient/account** (ART_KID or each teacher), verification authority, acceptable evidence, reconciliation and split settlement have not been decided. No seller/admin marketplace transfer-verification endpoint or money-collection assertion is added. Do not instruct parents to transfer to an assumed account. A future trusted payment adapter or explicitly authorized verifier must establish `paid` and its audit evidence before dispatch. The regression test simulates that trusted persisted state only; it does not prove a real payment integration exists. Pre-existing marketplace records marked paid by an earlier prototype require reconciliation against actual receipts before production use; this correction does not bulk-reset historical payments or assume those receipts exist. COD collection verification is also unresolved: delivery alone, including all deliveries in a mixed order, leaves marketplace payment `cod` until a genuine collection signal is designed.

The existing admin `/commerce/orders/{id}/confirm` is retained for legacy platform work. For seller-only COD it is a harmless idempotent no-op (and can advance old pending COD records), not a required workflow step. For mixed COD it commits platform reservations and handles legacy entitlements only; it does not authorize seller fulfillment. The admin UI hides this action for seller-only orders and unverified marketplace transfers. Mixed COD shows **Xác nhận phần hàng nền tảng**; platform-only orders retain their existing action.

Additive order response fields (computed, not database columns): `hasMarketplaceItems`, `requiresLegacyConfirmation`, `awaitingMarketplacePayment`, `canCancel`. Seller list/detail adds `sellerStatus`, `canFulfill`, `awaitingPayment`, `collectionUnverified`; `status` remains the existing whole-order status for compatibility. Transfer whole-order status continues to use `pending_confirmation` with the explicit awaiting-payment flag. New clients use these flags instead of guessing permissions from whole-order status.

Cancellation uses the existing buyer/admin endpoint. Seller-only COD may be cancelled while preparing and before any seller dispatch; unverified transfers may be cancelled. Once any seller dispatches, whole-order cancellation is rejected, even if a platform portion is pending. Voucher restoration stays atomic/idempotent. Before dispatch, expired platform reservations retain their existing automatic cancellation. After dispatch, those mixed-order reservations remain held; the background job cannot cancel shipped seller lines. The legacy platform action can commit the held allocation after its original timeout. No partial cancellation/refund/stock-release policy is invented; staff must resolve the platform portion. Seller sales are counted once on first delivery, not through admin order confirmation.

## Shipping handoff

Marketplace COD delivery never marks funds collected. `SellerFulfillment` is unique per order/seller. Allowed progression is `preparing → shipping → delivered`; repeating the same final state with the same carrier/tracking is idempotent. Carrier/tracking cannot change after dispatch. Every seller can update only their own fulfillment. No warehouse IDs are needed.

This endpoint records teacher-arranged shipping. It does **not** call GHN, purchase labels, register carrier shipments, calculate carrier rates, or claim carrier acceptance. A teammate can integrate carrier registration around this record later with separate provider IDs/verification and webhook handling. No GHN/provider integration is changed. The existing platform fulfillment webhook/API retains its responsibility; marketplace payment cannot be inferred from its delivery signal. Order completion now checks all platform allocations and all seller deliveries, so neither side can complete a mixed order early.

MVP limits: no seller payout/commission accounting, automatic carrier verification, returns/refunds workflow, partial shipments within one seller's order, or content revision archive. Existing order-detail JSON exposes `sellerFulfillments` to buyer/admin; the seller UI displays its own carrier/tracking. Historical platform products remain administered through the existing platform paths.

The order-processing correction adds no migration: the response flags are `[NotMapped]`; existing pending seller COD records become fulfillable without data rewriting.

## Parent tracking and seller-reported milestones

Seller COD checkout records a preparing milestone for each seller. Successful seller fulfillment updates record preparing, shipping or delivered milestones inside the existing serializable transaction. A deterministic event ID derived from order ID, seller ID and status prevents duplicate milestones on idempotent checkout, repeated fulfillment requests and metadata-only preparation updates. Concurrent conflicting writes retain the existing retry/409 behavior. Payment status and aggregate order completion rules are unchanged.

Buyer/admin `GET commerce/orders/{id}` retains `sellerFulfillments` and adds `sellerProgress`: one entry for every seller snapshot in the purchased items, including sellers without a fulfillment record yet. Each entry contains `sellerId`, `sellerName`, `itemTitles`, computed `status`, optional `carrier`, `trackingNumber`, `shippedAt` and `deliveredAt`. Only supplied carrier/reference values are returned; this projection creates no tracking URL. Seller endpoints continue to expose only the requesting seller's lines and fulfillment.

The parent detail screen displays each seller independently, so one seller's reported delivery cannot make another seller appear delivered. Its refresh button reloads the existing detail endpoint; there is no new background polling. Order creation, timeline and seller timestamps use the device's local time. Marketplace timeline responses identify only the latest milestone as current and previous milestones as passed. Known English system messages in historical marketplace events are translated into Vietnamese in response copies; persisted historical text and user-entered cancellation reasons are not rewritten, and historical dispatch/delivery dates are not invented.

Vietnamese shipping/delivery titles and the per-seller card explicitly attribute updates to the instructor. **Teacher-reported delivery is neither verified carrier delivery nor proof of COD collection.** Marketplace COD remains `cod` with `paidAt=null`; transfer receipt and verification policy remain unresolved as described above. For marketplace orders without a real tracking URL, the tracking action refers parents to seller progress instead of substituting the order code or a default GHN reference. No carrier acceptance, shipping registration or payment verification is introduced.

This polish requires no schema migration. Existing orders gain the computed per-seller projection immediately; only subsequent checkout/fulfillment actions create new milestones.

## Migrations and deployment

Generated migrations:

- SQLite: `20261029034849_TeacherMarketplace`
- Postgres: `20261029035241_TeacherMarketplace`

Both add moderation/availability fields to Product, nullable seller snapshots to OrderItem, and the seller fulfillment table/foreign keys/indexes. Existing products receive `approved`, `platform`, `is_available=true`, `revision=1`. Existing order items retain `seller_id=NULL`. Existing stock, reservations and payment snapshots are not converted. Apply the matching provider migration before deploying the backend. Production migrations use the existing deployment configuration; no production database was modified during this task.

From `backend/`, with .NET SDK 10 and repository tools restored:

```powershell
dotnet tool restore --tool-manifest dotnet-tools.json
dotnet build ArtKids.slnx
dotnet ef database update --context SqliteAppDbContext --project src/ArtKids.DAL --startup-project src/ArtKids.API
# For Postgres deployments select PostgresAppDbContext and configure the Postgres connection.
```

Rollback drops seller/moderation data and seller order ownership. Use it only before marketplace orders are accepted, or after backing up and reconciling those records. The automated SQLite test verifies old platform data survives upgrade, rollback and re-upgrade.

## Verification

Commands run from the repository root unless stated otherwise:

| Check | Result |
| --- | --- |
| `dotnet build backend/ArtKids.slnx --no-restore` with local SDK 10.0.403 | Passed; 0 warnings/errors. |
| Existing HTTP integration scenarios inherited by `MarketplaceTests` | All 15 passed in the combined 29-case tracking run: auth, ownership, course access, submissions/AI, checkout atomicity/idempotency/cancel, vouchers, payment confirmation, platform shipment, subscriptions/monthly kits, live classes, grading and family browser. |
| `python -m unittest discover -s backend/tests -p marketplace_test.py -k test_marketplace -v` | All 4 passed within the combined 25-case run against real HTTP and fresh migrated SQLite. Covers linked/standalone submission, approval/rejection/resubmission, private media, edit visibility, stale revisions, roles/ownership, legacy bypass, availability/cart/checkout, stock preservation, mixed-seller isolation and manual shipping. |
| `python -m unittest discover -s backend/tests -p marketplace_order_workflow_test.py -k OrderWorkflowTests -v` | All 25 passed: 15 legacy + 4 marketplace + 6 order workflow regressions (COD, transfers, trusted paid state, ownership, cancellation/vouchers, mixed fulfillment and reservation expiry). |
| `python -m unittest discover -s backend/tests -p marketplace_tracking_test.py -k MarketplaceTrackingTests -v` | All 29 passed: the previous 25 scenarios plus four parent-tracking regressions for per-state milestones, checkout/fulfillment idempotency and concurrent retries, independent sellers/privacy, Vietnamese historical response translation and unchanged COD payment. |
| `python -m unittest discover -s backend/tests -p marketplace_migration_test.py -v` | Passed: legacy product, stock and order data preserved through upgrade/rollback/re-upgrade, correct defaults and foreign keys. |
| `dotnet ef migrations has-pending-model-changes` for both contexts | No pending changes. |
| Postgres migration SQL generation from `CourseSoftDeletion` | Passed. Live Postgres execution remains unverified in this environment. |
| `flutter test --no-pub` from `apps/artkids_app` | All 64 tests passed: the previous 60 plus four parent-tracking regressions for model compatibility, independent seller progress/attribution, refresh and avoiding fabricated carrier tracking. |
| `flutter analyze --no-pub` | Passed: no issues found. |
| `flutter build web --no-pub --dart-define=API_BASE_URL=http://localhost:5081/api/v1 --output=<absolute path to .tools/qa-web>` | JavaScript build passed. Existing flutter_tts Wasm dry-run warnings remain; no Wasm build is claimed. |
| `node backend/tests/marketplace_ui_smoke.cjs` in Edge against real Flutter web + isolated SQLite API | Teacher submission/private pending image, admin approval, existing cart/COD checkout, no admin order confirmation, seller shipping/delivery with COD still unverified, parent refresh/Vietnamese timeline and 390×844 mobile form passed. QA used isolated API/web ports 5081/8081 without stopping existing servers; screenshots saved under ignored `backend/tests/artifacts/`, including `marketplace-parent-tracking.png`. |

Initial failures were corrected: a new fixture accidentally used a course owned by the same instructor; the migration test needed explicit SQLite connection disposal on Windows; the widget test needed the current TestFlutterView property and existing dialog button label. A further failing regression test reproduced the relative order-thumbnail URL issue found in browser testing; the existing order mapper now resolves uploaded images against the API origin. The browser smoke requires Playwright, Edge, a seeded local API and a served Flutter web build (see its header); Python `course_products_smoke.py` was adapted but the executed browser test was the Node script. Browser QA used an ignored local dev.env containing only local URLs/mock flags, as required by the existing bootstrap setup.

QA used .NET SDK 10.0.403 and Flutter 3.47.3 / Dart 3.13.3. The .NET SDK and temporary QA files are isolated under ignored `.tools/`; the browser test used the available bundled Playwright runtime. No application dependency upgrade is committed. Flutter's automatic lockfile/config edits are excluded from the feature commits.

## Changed-file map

- `backend/src/ArtKids.DAL/Entities/Entities.cs`, `Persistence/AppDbContext.cs`: moderation, concurrency, seller ownership/fulfillment and EF mapping.
- `backend/src/ArtKids.DAL/Migrations/{Sqlite,Postgres}/*TeacherMarketplace*` and both model snapshots: generated provider schema changes.
- `backend/src/ArtKids.BLL/Contracts/MarketplaceRequests.cs`: validated seller, review, availability and shipping contracts.
- `backend/src/ArtKids.BLL/Services/MarketplaceService.cs`: seller listing/review/order operations and authorization.
- `backend/src/ArtKids.BLL/Services/OrderFulfillment.cs`: shared aggregate delivery completion for mixed orders.
- `backend/src/ArtKids.BLL/Services/SellerOrderTracking.cs`: idempotent Vietnamese seller milestones and historical marketplace timeline response localization.
- `backend/src/ArtKids.BLL/Services/CommerceService.cs`: legacy route delegation, public/cart visibility, seller checkout and physical confirmation compatibility.
- `backend/src/ArtKids.BLL/Services/InventoryService.cs`: block seller SKU creation and wait for seller completion.
- `backend/src/ArtKids.BLL/Services/MediaService.cs`: moderation-aware image access.
- `backend/src/ArtKids.API/Controllers/MarketplaceController.cs`: new role-guarded endpoints.
- `backend/src/ArtKids.API/Controllers/CommerceController.cs`, `MediaController.cs`, `Program.cs`: legacy roles, private caching and service registration.
- `apps/artkids_app/lib/features/connected/presentation/course_product_screens.dart`: reuse existing form/image upload, course-or-independent selection, binary availability, moderation status/rejection/resubmission.
- `apps/artkids_app/lib/features/connected/presentation/marketplace_screens.dart`: paginated seller management, detail/withdrawal, admin queue/review detail.
- `apps/artkids_app/lib/features/connected/presentation/seller_order_screens.dart`: paginated own orders and carrier/tracking transitions.
- `apps/artkids_app/lib/features/connected/presentation/workspace_screens.dart`, `lib/core/routing/app_router.dart`: staff navigation and role-specific route guards.
- `apps/artkids_app/lib/features/shop/presentation/screens/product_detail_screen.dart`: disable add-to-cart for out-of-stock products; existing Product model already decodes binary `inStock`.
- `apps/artkids_app/lib/core/network/api_json.dart`, `lib/features/orders/data/datasources/order_remote_datasource.dart`: resolve order-image URLs against the API origin, preserving order/payment data.
- `apps/artkids_app/test/features/connected/marketplace_test.dart`: form resubmission, required rejection reason, manual shipping payload, stock parser and order-thumbnail regression tests.
- `backend/tests/marketplace_test.py`, `marketplace_migration_test.py`, `integration_test.py`, `course_products_smoke.py`, `marketplace_ui_smoke.cjs`, `marketplace_order_workflow_test.py`: new coverage and adapt existing immediate-publish expectations.
- Order correction additionally touches `apps/artkids_app/lib/features/connected/presentation/commerce_screens.dart` and `widgets.dart` for payment wording/readiness labels; `features/orders/domain/entities/order_entity.dart`, `data/models/order.dart`, `presentation/widgets/order_action_buttons.dart`, `presentation/screens/order_detail_screen.dart` for server cancellation permission and pending-payment information; `test/features/connected/order_workflow_test.dart` for UI regressions.
- Parent tracking adds `features/orders/domain/entities/seller_delivery_progress.dart`, `presentation/widgets/seller_delivery_progress_card.dart`, and updates the order mapper, detail/actions and timeline widgets. `backend/tests/marketplace_tracking_test.py`, `apps/artkids_app/test/features/connected/parent_tracking_test.dart` and the browser smoke cover the tracking correction.
- `.gitignore`, `tasks/plan.md`, `tasks/todo.md`, this document and README: local-tool exclusion, implementation plan/checklist and handoff.

## Framework references

- [EF Core migration management](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/managing): generated migration, designer and snapshot files.
- [EF Core concurrency tokens](https://learn.microsoft.com/en-us/ef/core/saving/concurrency): application-managed revision with optimistic concurrency.
- [ASP.NET Core role authorization](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/roles?view=aspnetcore-10.0): controller role restrictions plus service ownership checks.
- [Flutter SwitchListTile](https://api.flutter.dev/flutter/material/SwitchListTile-class.html): labeled binary availability using the established Material form style.
