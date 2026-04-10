PKG = scripts/BuddyPatcher

.PHONY: build test test-security test-all clean help

build: ## Build the Swift patcher (release mode)
	swift build -c release --package-path $(PKG)

test: ## Run unit tests (94 tests across 8 suites)
	swift test --package-path $(PKG)

test-security: ## Run security validation tests
	bash scripts/test-security.sh

test-all: test test-security ## Run all tests

clean: ## Remove build artifacts
	rm -rf $(PKG)/.build

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
