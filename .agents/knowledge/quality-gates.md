# Quality Gates

Gates are automatic checks that reject bad code **no matter which AI (or human) wrote it**.
They are the strongest part of this workflow: instructions can be ignored, gates cannot.

## Required in every project

1. **Formatter** — consistent style, zero debate.
2. **Linter** — catches bugs and bad patterns.
3. **Type checker** (if the language has one) — strict mode.
4. **Tests** — at least one real test from day 1.
5. **One `verify` command** running 1–4 in sequence, failing on the first error. Written in `docs/PROJECT.md` → Commands.
6. **Pre-commit hook** — runs format + lint (+ secret scan) on staged files.
7. **CI** — runs `verify` on every push/PR (GitHub Actions or the host's equivalent).
8. **Secret scan** — `gitleaks` in pre-commit or CI.

Rule for the agent: **run `verify` before every "done"**. If it fails, the task is not done.
Never disable a rule, add ignore comments, or lower strictness to make it pass — fix the code.
If a rule is genuinely wrong for this project, propose changing the config and explain why (ADR if significant).

## Tools by stack

| Stack | Format | Lint | Types | Tests | Audit |
|---|---|---|---|---|---|
| JS/TS | Biome *or* Prettier | Biome *or* ESLint | `tsc --noEmit` (strict) | Vitest | `pnpm audit` / `npm audit` |
| Python | Ruff format | Ruff | Pyright (or mypy) | pytest | pip-audit |
| PHP/Laravel | Laravel Pint | Larastan (PHPStan) | (Larastan) | Pest / PHPUnit | `composer audit` |
| Flutter/Dart | `dart format` | `flutter analyze` (+ very_good_analysis or flutter_lints) | (analyzer) | `flutter test` | `flutter pub outdated` |
| React Native | Prettier/Biome | ESLint | `tsc --noEmit` | Jest | `pnpm audit` |
| Go | `gofmt` / `goimports` | golangci-lint | (compiler) + `go vet` | `go test ./...` | govulncheck |
| Rust | `cargo fmt` | `cargo clippy -- -D warnings` | (compiler) | `cargo test` | cargo audit |
| Kotlin/Android | ktlint | detekt / Android lint | (compiler) | `./gradlew test` | — |
| Swift/iOS | swift-format | SwiftLint | (compiler) | `xcodebuild test` | — |
| C#/.NET | `dotnet format` | analyzers + `-warnaserror` | (compiler) | `dotnet test` | `dotnet list package --vulnerable` |
| Shell / PowerShell | shfmt | shellcheck / PSScriptAnalyzer | — | bats / Pester | — |

## `verify` command examples

**JS/TS (`package.json`)**
```json
"scripts": {
  "format": "biome format --write .",
  "lint": "biome check .",
  "typecheck": "tsc --noEmit",
  "test": "vitest run",
  "verify": "biome check . && tsc --noEmit && vitest run"
}
```

**Python (`pyproject.toml` + uv)** — run as `uv run poe verify` with poethepoet, or a script:
```toml
[tool.poe.tasks]
verify = ["fmt-check", "lint", "types", "test"]
fmt-check = "ruff format --check ."
lint = "ruff check ."
types = "pyright"
test = "pytest -q"
```

**Laravel (`composer.json`)**
```json
"scripts": {
  "verify": ["pint --test", "phpstan analyse --memory-limit=1G", "pest"]
}
```

**Flutter** — `scripts/verify.sh` / `scripts/verify.ps1`:
```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**Go (`Makefile` or `justfile`)**
```
verify:
	gofmt -l . | (! grep .)
	go vet ./...
	golangci-lint run
	go test ./...
```

**Windows note:** prefer the stack's own script runner (pnpm/composer/poe scripts) so the same command works on Windows,
macOS, Linux, and CI. If you need a shell script, provide both `scripts/verify.ps1` and `scripts/verify.sh`.

## Pre-commit hooks

- Any stack: **lefthook** (single binary, fast, works on Windows). Example `lefthook.yml`:
  ```yaml
  pre-commit:
    parallel: true
    commands:
      format:
        run: <format-check command for staged files>
      lint:
        run: <lint command>
      kit:
        run: sh .agents/hooks/pre-commit.sh   # anti-slop UI check + gitleaks if installed
  commit-msg:
    commands:
      kit:
        run: sh .agents/hooks/commit-msg.sh {1}   # conventional format + PROGRESS.md reminder
  ```
- No hook manager? `sh .agents/hooks/install-hooks.sh` installs the kit hooks directly (never overwrites foreign hooks).

## Boundaries & dead code (tier M/L)

Modular code stays modular only if a tool checks it:

| Stack | Module boundaries / cycles | Dead code / unused deps |
|---|---|---|
| JS/TS | `dependency-cruiser` or `eslint-plugin-boundaries` | `knip` |
| Python | `import-linter` | `vulture` |
| PHP | `deptrac` | — |
| Go / Rust | compiler + package visibility | `staticcheck` / `cargo udeps` |

Add them to `verify`. Verify the exact config keys against the tool's docs — don't write them from memory.
- JS-only alternative: husky + lint-staged. Python-only alternative: `pre-commit` framework.

## CI (GitHub Actions skeleton)

```yaml
name: CI
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # - setup step for the language (actions/setup-node, astral-sh/setup-uv, shivammathur/setup-php, subosito/flutter-action, ...)
      # - install dependencies (with cache)
      - run: <verify command>
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
```
Look up the current major versions of each action before writing them; don't trust the versions above blindly.

## Strictness defaults

- TypeScript: `"strict": true`, `"noUncheckedIndexedAccess": true`.
- Python: Pyright `standard` at minimum (`strict` for new projects), Ruff with `E,F,I,B,UP,S` rule sets.
- PHPStan/Larastan: level 6+ for new projects.
- Dart: `strict-casts`, `strict-raw-types`, `strict-inference`.
- Warnings are treated as errors in CI.
