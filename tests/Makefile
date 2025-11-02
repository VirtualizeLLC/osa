#!/usr/bin/env make
# Tests Makefile - Convenient test running

.PHONY: test test-verbose test-all test-args test-clean test-watch install-deps help

help:
	@echo "OSA Test Commands"
	@echo "================="
	@echo ""
	@echo "make install-deps    Install test dependencies (bats-core)"
	@echo "make test            Run all tests"
	@echo "make test-verbose    Run tests with verbose output"
	@echo "make test-args       Run only CLI argument tests"
	@echo "make test-clean      Run only clean function tests"
	@echo "make test-watch      Re-run tests on file changes (requires entr)"
	@echo "make lint            Check shell script syntax"
	@echo ""

# Test runner commands
test:
	@command -v bats >/dev/null || (echo "Error: bats not installed. Run: make install-deps"; exit 1)
	bats tests/test_*.bats

test-verbose:
	@command -v bats >/dev/null || (echo "Error: bats not installed. Run: make install-deps"; exit 1)
	bats --verbose tests/test_*.bats

test-args:
	@command -v bats >/dev/null || (echo "Error: bats not installed. Run: make install-deps"; exit 1)
	bats --verbose tests/test_cli_args.bats

test-clean:
	@command -v bats >/dev/null || (echo "Error: bats not installed. Run: make install-deps"; exit 1)
	bats --verbose tests/test_clean_function.bats

test-watch:
	@command -v entr >/dev/null || (echo "Error: entr not installed. Run: brew install entr"; exit 1)
	@command -v bats >/dev/null || (echo "Error: bats not installed. Run: make install-deps"; exit 1)
	@echo "Watching tests/ and src/ for changes..."
	@ls tests/*.bats src/**/*.zsh osa-cli.zsh 2>/dev/null | entr -c make test

# Installation
install-deps:
	@echo "Installing test dependencies..."
	@if command -v brew &>/dev/null; then \
		brew install bats-core || true; \
		echo "✓ bats-core installed (or already present)"; \
	elif command -v apt-get &>/dev/null; then \
		sudo apt-get update && sudo apt-get install -y bats || true; \
		echo "✓ bats installed (or already present)"; \
	else \
		echo "Error: Neither brew nor apt-get found. Please install bats manually."; \
		exit 1; \
	fi

# Linting
lint:
	@echo "Checking shell script syntax..."
	@bash -n osa-cli.zsh
	@bash -n cleanup-symlinks.zsh
	@bash -n src/setup/*.zsh
	@echo "✓ All scripts are syntactically valid"

# CI/CD commands
ci: install-deps lint test
	@echo "✓ CI checks passed"

# View test file
view-test-args:
	less tests/test_cli_args.bats

view-test-clean:
	less tests/test_clean_function.bats

view-helpers:
	less tests/helpers.zsh
