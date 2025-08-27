# Unified Software Manager - Development Makefile

.PHONY: help test test-unit test-integration lint format clean install-deps

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Test targets
test: test-unit test-integration ## Run all tests

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	bats tests/version-checker.bats

test-integration: ## Run integration tests only
	@echo "Running integration tests..."
	bats tests/version-checker-integration.bats

test-verbose: ## Run tests with verbose output
	bats --verbose-run tests/

test-coverage: ## Generate test coverage report
	@echo "## Test Coverage Report"
	@echo "### Function Coverage"
	@total_funcs=$$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*() {" lib/version-functions.sh); \
	normalize_tests=$$(grep -c "@test.*normalize_version" tests/version-checker.bats); \
	compare_tests=$$(grep -c "@test.*version_compare" tests/version-checker.bats); \
	tested_funcs=2; \
	coverage=$$((tested_funcs * 100 / total_funcs)); \
	echo "- Total functions: $$total_funcs"; \
	echo "- Functions with tests: $$tested_funcs"; \
	echo "- normalize_version tests: $$normalize_tests"; \
	echo "- version_compare tests: $$compare_tests"; \
	echo "- Coverage: $${coverage}%"
	@echo ""
	@echo "### Test Statistics" 
	@echo "- Total tests: $$(bats tests/ --count)"

# Linting and formatting
lint: ## Run shell script linting
	@echo "Running shellcheck..."
	shellcheck version-checker.sh
	shellcheck lib/version-functions.sh
	shellcheck *.sh
	@echo "Running yamllint..."
	yamllint monitoring-configs/tools.yaml
	yamllint .github/workflows/

format: ## Format shell scripts
	@echo "Formatting shell scripts..."
	shfmt -w -i 4 version-checker.sh
	shfmt -w -i 4 lib/version-functions.sh
	shfmt -w -i 4 *.sh

# Development setup
install-deps: ## Install development dependencies
	@echo "Installing development dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update; \
		sudo apt-get install -y bats jq yq curl shellcheck yamllint; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install bats-core jq yq curl shellcheck yamllint; \
	else \
		echo "Package manager not supported. Please install manually:"; \
		echo "- bats-core"; \
		echo "- jq"; \
		echo "- yq"; \
		echo "- curl"; \
		echo "- shellcheck"; \
		echo "- yamllint"; \
	fi

setup: install-deps ## Setup development environment
	@echo "Setting up development environment..."
	mkdir -p ~/.unified-software-manager-manager/cache
	mkdir -p ~/.local/bin
	@echo "Development environment ready!"

# Version management
check-versions: ## Check tool versions for updates
	@echo "Checking for tool updates..."
	./version-checker.sh --check-all

check-version: ## Check specific tool version (usage: make check-version TOOL=gh)
	@if [ -z "$(TOOL)" ]; then \
		echo "Usage: make check-version TOOL=<tool-name>"; \
		echo "Example: make check-version TOOL=gh"; \
	else \
		./version-checker.sh --check $(TOOL); \
	fi

update-tools: ## Interactive tool update session
	@echo "Starting interactive tool update..."
	@echo "Current status:"
	./version-checker.sh --check-all --output-format=json 2>/dev/null | jq '.' || ./version-checker.sh --check-all

# Cleanup
clean: ## Clean cache and temporary files
	@echo "Cleaning up..."
	rm -rf ~/.unified-software-manager-manager/cache/*
	./version-checker.sh --clear-cache
	find . -name "*.tmp" -delete
	find . -name "*.log" -delete

clean-all: clean ## Deep clean including test artifacts
	rm -rf test-results/
	rm -f updates.json

# CI/CD simulation
ci: lint test ## Simulate CI pipeline locally
	@echo "✅ CI pipeline completed successfully!"

ci-quick: ## Quick CI check (lint + unit tests only)
	@echo "Running quick CI check..."
	$(MAKE) lint
	$(MAKE) test-unit
	@echo "✅ Quick CI check completed!"

# Documentation
docs-check: ## Check documentation completeness
	@echo "Checking documentation..."
	@if ! grep -q "bats tests/" CLAUDE.md; then \
		echo "⚠️  Test execution command not documented in CLAUDE.md"; \
	fi
	@if [ -f README.md ] && ! grep -q -i "test" README.md; then \
		echo "💡 Consider adding test information to README.md"; \
	fi
	@echo "Documentation check complete!"

# Performance testing
perf-test: ## Run performance tests
	@echo "Running performance tests..."
	@echo "Single tool check:"
	time timeout 30 ./version-checker.sh --check gh
	@echo ""
	@echo "Cache performance test:"
	./version-checker.sh --clear-cache
	@echo "First run (no cache):"
	time timeout 30 ./version-checker.sh --check gh
	@echo "Second run (cached):"  
	time timeout 30 ./version-checker.sh --check gh

# Security
security-scan: ## Basic security scan
	@echo "Running basic security scan..."
	@if grep -r -i -E "(password|passwd|pwd|api_key|secret|token)" --include="*.sh" --include="*.yaml" --include="*.json" . | grep -v "example" | grep -v "template" | grep -v "test" | grep -v "Makefile"; then \
		echo "⚠️  Potential credentials found in code!"; \
	else \
		echo "✅ No obvious credentials found"; \
	fi

# GitHub Actions
gh-act: ## Run GitHub Actions locally (requires act)
	@if command -v act >/dev/null 2>&1; then \
		act -j test; \
	else \
		echo "act not installed. Install with: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"; \
	fi