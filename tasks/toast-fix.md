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

## Verification

Pending implementation.
