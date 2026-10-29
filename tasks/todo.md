# Marketplace implementation checklist

- [x] Read supplied task and audit current source, routes, schema and tests.
- [x] Create dedicated feature branch and file-by-file plan.
- [x] Add compatible model/contracts and both provider migrations.
- [x] Implement seller ownership and admin review with legacy bypass protection.
- [x] Enforce catalog/media/cart/checkout visibility and availability.
- [x] Implement seller-only order projection and manual carrier fulfillment.
- [x] Reuse publishing form and add guarded management/review/order screens.
- [x] Run integration, migration and Flutter validation; fix introduced regressions.
- [x] Document APIs, limitations, tests and GHN integration boundary.
- [x] Review, commit, push, create and attach Draft PR; never merge.

Draft PR: https://github.com/sontran12242004/ART_KID/pull/1
Target: main. Branch: codex/teacher-marketplace-approval. Created as an open draft; no merge performed.

## Order confirmation correction

- [x] Reproduce and remove mandatory admin confirmation for seller COD.
- [x] Keep marketplace transfers pending; document missing recipient and verification policy.
- [x] Preserve mixed platform allocations, expiry safety, cancellation/vouchers and seller isolation.
- [x] Update seller/admin/parent UI permissions and payment wording.
- [x] Run 25 HTTP tests, 60 Flutter tests, analyzer and both EF model checks.
- [x] Run final web browser smoke without any marketplace order confirmation requests.
- [ ] Push the committed correction and update Draft PR #1.
