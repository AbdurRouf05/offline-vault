# Code Quality

## Writing rules

1. **Match the codebase.** Same naming, structure, error handling, and libraries as the surrounding code. Consistency > your preference.
2. **Names say intent.** `calculateInvoiceTotal`, `isEligibleForRefund`, `pendingOrders`. Avoid `data`, `info`, `temp`, `handle`, `doStuff`, `x2`.
   Booleans read as questions (`isActive`, `hasAccess`). Functions are verbs, values are nouns.
3. **Small functions, one job.** If you need "and" to describe it, split it.
4. **Early returns over deep nesting.**
5. **No magic values.** Named constants for numbers/strings with meaning (`MAX_UPLOAD_MB = 10`).
6. **Explicit types at boundaries** (function signatures, API inputs/outputs). Strict mode on. No `any` / untyped dicts
   for structured data — define a type/schema.
7. **Handle errors deliberately.** Every external call (DB, network, file, parse) can fail — decide what happens.
   Never `catch {}` and ignore.
8. **Comments explain WHY, not WHAT.** Don't narrate code. Do explain non-obvious decisions, workarounds, and constraints.
9. **No dead code.** Delete commented-out code and unused functions/imports — git remembers.
10. **No premature abstraction.** Duplicate twice; abstract on the third time, when the pattern is clear.
11. **Dependencies are a cost.** Before adding one: is it in the standard library or already installed? Is it maintained? How big?
12. **Immutability by default** where the language makes it easy (`const`, `final`, frozen dataclasses).

## Good vs bad

**Nesting**
```ts
// BAD
function ship(order) {
  if (order) {
    if (order.paid) {
      if (order.items.length > 0) {
        return createShipment(order);
      }
    }
  }
  return null;
}

// GOOD
function ship(order: Order): Shipment | null {
  if (!order.paid) return null;
  if (order.items.length === 0) return null;
  return createShipment(order);
}
```

**Error handling**
```python
# BAD — hides the failure, caller thinks it worked
try:
    send_invoice(user)
except Exception:
    pass

# GOOD — expected failure handled, unexpected one surfaces with context
try:
    send_invoice(user)
except EmailProviderUnavailable as e:
    logger.warning("invoice email deferred", extra={"user_id": user.id, "error": str(e)})
    enqueue_retry(user.id)
```

**Business logic location**
```php
// BAD — logic in controller, untestable, duplicated elsewhere
public function store(Request $r) {
    $total = 0;
    foreach ($r->items as $i) { $total += $i['price'] * $i['qty']; }
    if ($r->user()->is_member) { $total *= 0.9; }
    // ...
}

// GOOD — controller is thin; rule lives in one tested place
public function store(StoreOrderRequest $request, CreateOrder $createOrder) {
    $order = $createOrder->handle($request->user(), $request->validated());
    return new OrderResource($order);
}
```

## Modularity

1. **Feature modules.** Code lives in `features/<name>/` (or the framework's equivalent), grouped by what it does for the user.
2. **Public entry point.** Other modules import only from `features/<name>/index.*` (or the module's public API),
   never from its internal files.
3. **No circular dependencies** between modules. If A needs B and B needs A, extract the shared part or invert with an interface.
4. **Shared code is earned.** Move code to `shared/`/`lib/` only when ≥ 2 features use it. No dumping-ground `utils` file —
   name helpers by topic (`lib/money.ts`, `lib/dates.ts`).
5. **Pure core, I/O at the edges.** Business rules are pure functions; DB, network, files, clock are passed in or
   called from a thin outer layer. Pure logic is easy to test and reuse.
6. **One file, one job.** A component file holds one main component; a service file holds one use-case group.
7. **Consistent naming.** Files and folders follow one convention per project (written in `docs/PROJECT.md` → Conventions).
8. **Enforce it with a tool** for tier M/L (`quality-gates.md` → Boundaries).

## Self-review checklist (run on your own diff before saying "done")

**Correctness**
- [ ] Each acceptance criterion is actually implemented (re-read them).
- [ ] Edge cases: empty, null/undefined, zero, negative, very long input, duplicates, unicode, timezone, double-click/double-submit.
- [ ] Every external call has error handling that does something sensible.
- [ ] Async code: awaited properly, no race conditions on shared state, no unhandled promise rejections.

**Safety**
- [ ] No secrets, tokens, or personal data hard-coded or logged.
- [ ] Input validated server-side; queries parameterized; output escaped.
- [ ] Permission checked for the specific resource (not only "is logged in").

**Clarity**
- [ ] Names are clear without needing the comment.
- [ ] No function does more than one job; no file has grown past ~300 lines without reason.
- [ ] Follows the existing patterns of the project.
- [ ] Module boundaries respected: imports go through public entry points, no new cycles.

**Hygiene**
- [ ] No debug prints, commented-out code, unused imports/variables, leftover TODOs.
- [ ] No unrelated changes in the diff (formatting churn, drive-by renames).
- [ ] Tests added/updated, and they would fail if the feature broke.
- [ ] Verify command passes.
