PKG = scripts/BuddyPatcher

.PHONY: build lint test-smoke test test-security \
        test-integration test-functional test-ui test-e2e \
        test-snapshots test-docs test-compat test-perf \
        test-all test-full coverage clean help

# ── Build ─────────────────────────────────────────────────────────
build: ## Build the Swift patcher (release mode)
	swift build -c release --package-path $(PKG)

# ── Stage 1: Static ───────────────────────────────────────────────
lint: ## Run shellcheck + JSON + frontmatter + hygiene checks
	@bash scripts/lint.sh

# ── Stage 2: Smoke ────────────────────────────────────────────────
test-smoke: build ## Fast build + CLI contract sanity checks (~30s)
	@bash scripts/test-smoke.sh

# ── Stage 3: Core ─────────────────────────────────────────────────
test: ## Run unit tests (178 tests across 12 files, incl. 3 regression)
	swift test --package-path $(PKG)

test-security: ## Run security validation tests (27 tests)
	@bash scripts/test-security.sh

# ── Stage 4: Real-world ───────────────────────────────────────────
test-integration: ## End-to-end patch/restore/metadata flows (23 tests)
	@bash scripts/test-integration.sh

test-functional: ## Byte-level patch correctness + Mach-O validity (19 tests)
	@bash scripts/test-functional.sh

test-ui: ## Buddy card rendering against fixtures (23 tests)
	@bash scripts/test-ui.sh

test-e2e: build ## Real-binary reset→evolve→verify→reset flow (23 tests)
	@bash scripts/test-e2e.sh

# ── Stage 5: Full system ──────────────────────────────────────────
test-snapshots: build ## Golden file comparison for CLI output (6 tests)
	@bash scripts/test-snapshots.sh

# ── Stage 6: Peripheral ───────────────────────────────────────────
test-docs: ## Verify doc paths, links, test count consistency (14 tests)
	@bash scripts/test-docs.sh

# ── Separate schedules ────────────────────────────────────────────
test-compat: build ## Compatibility against knownVarMaps (~27 tests, on-demand)
	@bash scripts/test-compatibility.sh

test-perf: build ## Performance benchmarks (7 benchmarks, on-demand)
	@bash scripts/test-perf.sh

# ── Aggregates ────────────────────────────────────────────────────
test-all: ## Run the full test-all.sh pipeline (all tiers)
	@bash scripts/test-all.sh

test-full: lint test-all test-docs ## Full pipeline + lint + doc validation
	@echo "  Full test run complete"

coverage: ## Generate local HTML coverage report
	@bash scripts/coverage.sh

# ── Utilities ─────────────────────────────────────────────────────
clean: ## Remove build artifacts and coverage output
	rm -rf $(PKG)/.build test-results/coverage

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
