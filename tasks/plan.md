# Teacher marketplace listing and approval implementation plan

## Parent tracking polish (2026-10-29)

- Inspect: seller fulfillment currently emits no tracking events; the parent model discards seller fulfillment progress, and event flags can show several current milestones.
- Add `SellerOrderTracking.cs` for Vietnamese seller milestones and deterministic per-order/seller/state event IDs. Call within existing checkout/fulfillment transactions; retries and carrier metadata edits must not duplicate milestones. Do not alter order/payment transitions or add migrations.
- `CommerceService.cs`: add parent/admin-only seller progress projection (names, own order item titles, status, manually supplied carrier/tracking, actual timestamps); retain existing response fields. Normalize marketplace timeline flags and translate known historical system text on response without rewriting history.
- Flutter: add a small seller progress entity/widget and decode it in the existing OrderModel; display each seller independently with an explicit seller-reported/unverified-carrier notice. Reuse the timeline, render local timestamps, and add refresh. Correct marketplace tracking-button fallback so an order code/default GHN is never presented as a verified shipment.
- Add backend tracking/idempotency/multi-seller/privacy/payment regressions and Flutter parsing/rendering/refresh/fallback tests. Run relevant existing suites, build and browser smoke, then commit/push this branch and update Draft PR #1. Preserve legacy platform shipping and all approval, payment, inventory and authorization logic.

## PR #1 correction: order processing (2026-10-29)

- Keep listing moderation unchanged. No new persisted fields or migrations: use existing payment method/status, seller snapshots and fulfillment records, with additive response action flags.
- `CommerceService.cs`: seller-only COD starts preparing; expose order actions without changing existing fields; allow cancellation before seller dispatch; preserve legacy platform confirmation/reservations. Reject unverified marketplace transfers through the legacy confirm route. Protect dispatched mixed orders from whole-order reservation expiry/cancellation.
- `MarketplaceService.cs`, `OrderFulfillment.cs`: COD sellers may fulfill immediately regardless of the platform portion's confirmation. Transfer sellers wait for verified paid state. Prevent premature completion while platform reservations are still reserved, and never infer marketplace COD collection from delivery. Count seller sales once on delivery.
- Flutter seller/admin screens: show seller readiness and pending payment; remove seller-only order approval buttons and keep platform-only/mixed platform actions. Carry server cancellation permission into the parent order action button.
- Tests: reproduce COD/transfer/admin-bypass/cancellation/mixed-stock failures before fixes; rerun legacy integration, Flutter tests/analyze and real browser smoke without marketplace order confirmation. Update this plan, technical payment-policy documentation and existing Draft PR #1; push this branch only.
- Open policy: marketplace bank-account recipient and authorized verifier are unspecified. Do not add a payment-verification endpoint or mark marketplace transfers/COD paid based on seller claims. Unverified marketplace transfers stay blocked; verified payment integration is a future explicit policy decision.

Source: ART_KID_CODEX_TASK.md supplied in Downloads, plus current main. Work only on `codex/teacher-marketplace-approval`.

## Decisions and compatibility boundaries

- Reuse Product, CreatedBy, course ownership, media upload, UnitOfWork, cart, checkout and payment confirmation. New seller products start pending; every content edit or availability change requires review. Approved edits immediately disappear from the public shop. Deletion is a soft withdrawal.
- Existing products remain approved platform products with existing inventory/reservations. Do not convert existing stock or outstanding orders. New seller products never create warehouse records.
- Use a seller ID snapshot on order items, and a separate per-order/per-seller fulfillment record. Seller responses project only their items, their subtotal and necessary recipient information. Admin still confirms payment.
- Legacy course mutations delegate to MarketplaceService; admin catalog edits cannot mutate seller listings. Public catalog/detail/media require active and approved. Private image previews use authenticated media downloads.
- No carrier network calls. Carrier/tracking records describe teacher-arranged shipping only. Order completion must account for both platform and seller fulfillment.

## Phases and exact file map

1. **Persistence and contracts** (no dependencies): extend `backend/src/ArtKids.DAL/Entities/Entities.cs`, `Persistence/AppDbContext.cs`; add generated SQLite and Postgres migrations and snapshots. Add `backend/src/ArtKids.BLL/Contracts/MarketplaceRequests.cs`. Verify migration generation, fresh database startup and existing defaults.
2. **Seller submission and moderation** (depends on 1): add `backend/src/ArtKids.BLL/Services/MarketplaceService.cs`, `backend/src/ArtKids.API/Controllers/MarketplaceController.cs`; register in `Program.cs`. Adapt `CommerceController.cs` / `CommerceService.cs` legacy routes, catalog, cart; adapt `MediaService.cs` / `MediaController.cs` visibility and private preview caching. Verify roles, image/course/product ownership, required rejection reason, pending/rejected visibility, resubmission, stale-review protection.
3. **Checkout and seller fulfillment** (depends on 2): change only kit branches and physical completion logic in `CommerceService.cs`; add seller order projection and manual fulfillment in MarketplaceService/controller; prevent warehouse SKU creation for seller products and coordinate mixed fulfillment completion in `InventoryService.cs`. Preserve vouchers, digital course/subscription logic, idempotency and payment privileges. Verify mixed sellers, stock exclusion, cancellation, confirmation, shipping transitions.
4. **Flutter submission and management** (depends on 2): adapt existing `apps/artkids_app/lib/features/connected/presentation/course_product_screens.dart` form/manager to binary availability and marketplace endpoint; add `marketplace_screens.dart` and `seller_order_screens.dart` in the same directory. Wire guarded routes in `core/routing/app_router.dart`, workspace links in `workspace_screens.dart`. Disable unavailable cart action in `features/shop/presentation/screens/product_detail_screen.dart`; keep existing product `inStock` decoding. Verify loading/error/empty states, Vietnamese labels, ownership/role routing, private image previews.
5. **QA and handoff** (depends on 1–4): add `backend/tests/marketplace_test.py`, update affected cases in `integration_test.py` and `course_products_smoke.py`; add Flutter widget tests under `apps/artkids_app/test/features/connected/`. Add `docs/teacher-marketplace.md` with API contracts, migration notes, integration seam and actual test results; minimal README link. Run backend build, real HTTP integration tests, migration checks, Flutter analyze/tests. Review diff, commit logical slices, push and create draft PR against main.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Older documentation describes NestJS | Follow verified ASP.NET Core implementation; avoid unrelated documentation rewrite. |
| SDK 10 missing locally | Install isolated SDK, record any execution constraints, continue independent work. |
| Admin/legacy routes bypass approval | Centralize seller mutations, reject seller writes through platform catalog API. |
| Admin reviewing outdated content | Optimistic product review revision and serializable transactions. |
| Mixed orders expose other seller/payment details | Explicit response projection; snapshot seller ownership; no generic OrderDetail for seller. |
| Platform shipment marks mixed order delivered early | Check seller completion before aggregate delivery; retain existing platform quantity checks. |
| Unavailable items remain in cart | Allow removing stale items, validate availability again at checkout. |
| Private image URLs leak through cache | Authenticated byte previews and private/no-store headers on media responses. |

Each phase has a build/test checkpoint. User explicitly authorized immediate implementation and draft PR; no separate plan approval is needed.

## Verification-driven adjustment

Browser smoke testing exposed relative uploaded-image URLs in order history, which resolved against the Flutter web host instead of the API. Add an optional base URL to the existing `apps/artkids_app/lib/core/network/api_json.dart` order mapper and pass it from `features/orders/data/datasources/order_remote_datasource.dart`. Cover this with a failing regression test before the fix. No order/payment fields or checkout behavior change.
