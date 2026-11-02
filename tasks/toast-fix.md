# Toast message bug fix

## Branch audit (2026-11-02)

GitHub has three branches after fetching origin. `main` is 19 commits behind `Live_Steam-for-Teacher`; `codex/teacher-marketplace-approval` is 9 commits behind it, with no unique commits on either older branch. `Live_Steam-for-Teacher` therefore contains the most functionality by ancestry: existing marketplace plus live classroom, startup/login and staff workspace changes. This is a source comparison, not a claim that every feature has been manually verified.

Fix branch: `codex/fix-toast-messages`, based on `origin/Live_Steam-for-Teacher` at `1a594bf`. Do not merge or rewrite the other branches.

## Findings and implementation slices

1. Reproduce the persistent add-to-cart notification. Its `SnackBarAction` implicitly enables `persist`, so its two-second duration is ignored. Set an explicit transient policy, preserve the View Cart action and confirmed cart results, and test automatic dismissal/action navigation.
2. Reproduce notification backlog in the shared connected-screen `toast` helper. Add a core presenter that removes queued/current notifications before displaying the latest one, with safe handling of disposed contexts. Route existing direct presenters through it while preserving their content, duration, style and actions. Cover rapid messages, duplicate calls, existing queues and lifecycle behavior.
3. Audit cart failure ownership, async success messages and error formatting. Fix confirmed notification bugs only; keep commerce, payments, live classroom/media, authentication and authorization behavior intact.
4. Run targeted then full Flutter tests/analyzer, web build and real Edge/API smoke. Record evidence and limitations, commit the focused changes and publish a separate draft fix PR.

No backend schema, payment, shipping provider or application dependency changes are planned.

## Implemented behavior

- All 46 direct notification calls across 15 presentation files now use `core/widgets/app_snack_bar.dart`. The connected-screen `toast` helper delegates to the same presenter. It clears old queued/current snackbars before showing the latest result; it safely ignores unmounted contexts or missing messengers. Existing messages, colors, icons, durations and actions are retained.
- Add-to-cart explicitly sets `persist: false`, so its View Cart action no longer makes it remain forever. The action still opens the existing cart route. No custom timer, overlay, global event bus or new dependency is introduced.
- Product detail snapshots the submitted quantity before awaiting the cart API. Changing the selection during the request cannot change the success message for the completed operation.
- Login, checkout/voucher and PIN error messages reuse the existing `apiError` formatter instead of interpolating a verbose Dio exception. The interceptor, token refresh and authorization rules are unchanged.
- Long order-copy/review and profile notifications wrap in their available width instead of overflowing a Row.
- The real Edge smoke additionally checks timeout, rapid add results, cart navigation/quantity and a genuine API rejection when an approved item becomes unavailable while a parent is still viewing it.

The change fixes transient notification delivery/presentation. It does not implement missing legacy features such as password-reset email or order-review persistence, translate every server business error, or redesign unrelated mobile screen layouts. Existing placeholders and non-notification layout issues need separate feature work; no success or payment verification is newly fabricated here.

## Verification

| Check | Result |
| --- | --- |
| Red tests before fixes | Reproduced persistent cart action toast, stale queue replay, deactivated-context exception, quantity-message race, verbose login error and narrow toast overflow. |
| Targeted Flutter notification regressions | 9 tests passed: queue replacement, duplicate replay, unmounted context, cart timeout/action, quantity race, failed cart, login error and narrow order-copy toast. |
| Full `flutter test --no-pub` | 81 passed, including the existing marketplace, parent tracking, checkout and live classroom tests. |
| `flutter analyze --no-pub` | No issues found. |
| `.NET` backend build on the selected base | Passed, 0 warnings/errors. No backend source was changed. |
| `flutter build web --no-pub` with isolated API URL | JavaScript build passed; pre-existing flutter_tts Wasm dry-run warnings remain. |
| Real Edge + migrated SQLite API smoke | Passed: transient and rapid cart notifications, View Cart navigation, exact persisted quantity, genuine unavailable-item rejection, teacher listing/admin approval, COD checkout, seller fulfillment, parent tracking and 390×844 staff form. Reviewed success/error screenshots. The initial smoke selector matched both Flutter's accessibility announcement and visible text; scoping it to the visible span fixed the test harness. |
| `python -m unittest discover -s backend/tests -p marketplace_tracking_test.py -k MarketplaceTrackingTests -v` | All 29 real HTTP/SQLite tests passed: legacy auth/learning/commerce, listing approval, COD/transfers, vouchers/cancellation, mixed seller/platform isolation, subscriptions and parent tracking/idempotency. |

Tests use local fixtures or isolated development databases, not production data. Screenshots are ignored under `backend/tests/artifacts/`. No Android/iOS device build or live carrier/payment integration is claimed.

Framework references: [SnackBar.persist](https://api.flutter.dev/flutter/material/SnackBar/persist.html), [clearSnackBars](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/clearSnackBars.html), [removeCurrentSnackBar](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/removeCurrentSnackBar.html).

## Delivery

Committed and pushed on `codex/fix-toast-messages`. [Draft PR #3](https://github.com/sontran12242004/ART_KID/pull/3) targets `Live_Steam-for-Teacher` to show only the toast fix. Verified open/draft; no merge was performed. Feature commits: `27413a1` (transient presenter/cart timeout) and `eb3b33a` (accurate/readable feedback and regressions).
