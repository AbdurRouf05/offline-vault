# Testing

## What to test (priority order)

1. **Business rules / pure logic** — calculations, validation, state transitions, permissions. Unit tests. Cheap, fast, high value.
2. **Integration points** — API endpoints / route handlers with a real (test) database, repositories, queue jobs.
   Feature/integration tests. Catch most real bugs.
3. **Critical user flows** — sign up, login, checkout, the core action of the app. A few end-to-end tests (Playwright,
   integration_test for Flutter, Detox/Maestro for RN). Keep these few; they're slow and brittle.
4. **Bugs** — every fixed bug gets a regression test.

Don't spend effort testing framework internals, trivial getters, or third-party libraries.

## Rules

- A test must **fail if the behavior breaks**. Assert outcomes (returned value, DB state, response body/status), not just "no crash".
- Test the **unhappy paths**: invalid input, unauthorized user, not found, conflict, external service failure.
- Tests are independent: no order dependency, no shared mutable state. Each sets up what it needs.
- Deterministic: control time (fake clock), randomness (seed), and network (mock external HTTP at the integration-module boundary).
- Use a separate test database / in-memory DB. Never run tests against real or production data.
- Test names describe behavior: `rejects_order_when_stock_is_insufficient`, `it('returns 403 when user is not the owner')`.
- Arrange → Act → Assert structure, one behavior per test.
- Mock only at boundaries you own (your `integrations/` wrappers), not deep internals. Over-mocking makes tests pass while the app breaks.
- Never weaken or delete a test to make it pass. If the test is wrong, explain why before changing it.

## Minimum per change

| Change | Minimum tests |
|---|---|
| New business rule | Unit tests: happy path + each rule branch + one invalid input |
| New endpoint / action | Integration test: success, validation error, unauthorized/forbidden |
| UI component with logic | Component test of the logic/states, or covered by an E2E of the flow |
| Bug fix | Regression test that failed before the fix |
| Refactor | Existing tests unchanged and passing (add characterization tests first if missing) |
| Script / CLI | Test core functions with sample inputs; one run on a small real fixture |

## Tools by stack (defaults)

| Stack | Unit / integration | E2E |
|---|---|---|
| JS/TS | Vitest (+ Testing Library for components) | Playwright |
| Python | pytest (+ httpx/TestClient for APIs) | Playwright |
| PHP/Laravel | Pest (or PHPUnit), `RefreshDatabase` | Laravel Dusk or Playwright |
| Flutter | `flutter_test`, mocktail | `integration_test`, Patrol |
| React Native | Jest + React Native Testing Library | Maestro or Detox |
| Go | `testing` + testify, `httptest` | Playwright (web) |
| Rust | `cargo test` | — |
| .NET | xUnit | Playwright |

## Coverage

Coverage is a hint, not a goal. Aim for strong coverage on business logic and critical flows; don't chase 100%.
A missing test on a payment rule matters more than 20 tests on getters.

## E2E with Playwright (web and Electron/Tauri webviews)

Setup: `pnpm create playwright` (choose TypeScript, `e2e/` folder). Add `"e2e": "playwright test"` to scripts and the
E2E row in `docs/PROJECT.md` → Commands. Check options with `pnpm exec playwright --help`, not from memory.

Rules:
- Cover **critical flows only**: login, the core create/edit action, checkout/payment, anything that loses money or data if broken.
- Locate like a user: `getByRole('button', { name: 'Simpan produk' })`, `getByLabel('Email')`, `getByText(...)`.
  Use `data-testid` only when nothing accessible exists. No CSS/XPath chains.
- **Never `waitForTimeout`.** Use web-first assertions that auto-wait: `await expect(locator).toBeVisible()`,
  `toHaveText`, `toHaveURL`.
- Each test creates its own data (API call or seed helper) and does not depend on other tests. Separate test database.
- Start the app via `webServer` in `playwright.config.ts` so `pnpm e2e` works from a clean checkout.
- `trace: 'on-first-retry'` and screenshots on failure; read the trace before guessing at a fix.
- Run in CI on every PR (install browsers with `pnpm exec playwright install --with-deps`).

Writing one test:
1. Write the flow as user steps (Given/When/Then from the PRD story).
2. Translate each step to a locator + action; assert the visible outcome, not internals.
3. Run it, make it fail once on purpose (break the feature) to prove it tests something, then restore.

Mobile: Flutter `integration_test`, React Native Maestro or Detox — same rules (user-level steps, no fixed sleeps).
