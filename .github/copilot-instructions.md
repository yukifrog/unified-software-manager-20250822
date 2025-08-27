# Unified Software Manager - Bash-based Software Version Management Tool

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup
- Install development dependencies:
  - `make install-deps` -- installs bats, jq, curl, shellcheck, yamllint via apt/brew. Takes ~30 seconds. NEVER CANCEL.
  - `make setup` -- creates directories and sets up development environment. Takes <5 seconds.
- Initialize the system:
  - `./setup.sh` -- sets up configuration directories and makes scripts executable. Takes <1 second.
  - `chmod +x *.sh` -- ensure all scripts are executable if needed.

### Testing
- Run unit tests: `make test-unit` or `bats tests/version-checker.bats` -- 18 tests, takes ~1 second. NEVER CANCEL.
- Run integration tests: `make test-integration` or `bats tests/version-checker-integration.bats` -- 11 tests, some currently fail due to YAML parsing issues, takes ~1 second.
- Run all tests: `make test` or `bats tests/` -- combines both test suites, takes ~2 seconds. NEVER CANCEL.
- Generate test coverage: `make test-coverage` -- shows function coverage statistics, takes <1 second.

### Linting and Code Quality
- Run shell linting: `make lint` -- runs shellcheck and yamllint, takes ~2 seconds but currently fails with style issues.
- Basic shellcheck: `shellcheck *.sh` -- check individual scripts for bash issues.
- YAML validation: `yamllint monitoring-configs/tools.yaml` and `yamllint .github/workflows/` -- validate configuration files.
- Security scan: `make security-scan` -- basic credential pattern detection, takes <1 second.

### Main Application Usage
- Show help: `./unified-software-manager-manager.sh --help` -- displays all available options.
- Quick stats: `./unified-software-manager-manager.sh --stats` -- shows program management statistics, takes <1 second.
- Regular scan: `./unified-software-manager-manager.sh --scan` -- scans /usr/bin directory, takes ~10-15 seconds. NEVER CANCEL. Set timeout to 30+ seconds.
- Full scan: `./unified-software-manager-manager.sh --full-scan` -- comprehensive system scan, takes 5+ minutes. NEVER CANCEL. Set timeout to 10+ minutes.
- List programs: `./unified-software-manager-manager.sh --list [category]` -- show discovered programs.
- Check updates: `./unified-software-manager-manager.sh --check-updates` -- check for available updates.

### Version Checker Tool
- Show help: `./version-checker.sh --help` -- displays version checker options.
- Check all tools: `./version-checker.sh --check-all` -- attempts to check all configured tools, takes ~1 second but currently fails due to YAML parsing issues.
- Clear cache: `./version-checker.sh --clear-cache` -- clears GitHub API response cache, takes <1 second.
- JSON output: `./version-checker.sh --check-all --output-format=json` -- outputs results in JSON format.

## Known Issues and Limitations
- **YAML Parsing Bug**: The version-checker tool currently has YAML parsing issues where it cannot read tool configurations properly. Commands like `./version-checker.sh --check gh` fail with "tool not found" errors.
- **Shellcheck Failures**: Multiple shell scripts have style issues detected by shellcheck, causing `make lint` to fail.
- **Missing shfmt**: The formatting command `make format` fails because shfmt is not installed.
- **Integration Test Failures**: Several integration tests fail due to the YAML parsing bug.
- **Long Scan Times**: Full system scans can take 5+ minutes depending on the number of installed programs.

## Validation Scenarios
After making changes, always test these scenarios:
1. **Basic functionality**: Run `./unified-software-manager-manager.sh --help` and verify help text displays correctly.
2. **Setup workflow**: Run `./setup.sh` and verify it completes without errors in <5 seconds.
3. **Unit tests**: Run `make test-unit` and verify all 18 tests pass in ~1 second.
4. **Stats command**: Run `./unified-software-manager-manager.sh --stats` and verify it returns statistics in <1 second.
5. **Configuration validation**: Run `yamllint monitoring-configs/tools.yaml` and verify YAML is valid.

## Development Workflow
- Quick development check: `make ci-quick` -- runs linting and unit tests only, currently fails due to lint issues.
- Full CI simulation: `make ci` -- runs all linting and tests, currently fails.
- Performance testing: `make perf-test` -- measures command execution times, currently fails due to YAML parsing.
- Documentation check: `make docs-check` -- validates documentation completeness.

## Configuration Files
- Main tool configuration: `monitoring-configs/tools.yaml` -- defines tools to monitor for updates.
- User data: `~/.unified-software-manager-manager/programs.yaml` -- stores discovered program information.
- Cache directory: `~/.unified-software-manager-manager/cache/` -- GitHub API response cache.
- GitHub workflows: `.github/workflows/test.yml` -- CI/CD pipeline configuration.

## Common Development Tasks
- To add a new tool to monitor: Edit `monitoring-configs/tools.yaml` and add tool configuration under the `tools:` section.
- To fix YAML parsing: The `get_yaml_value()` and `get_tools_list()` functions in `version-checker.sh` need to handle the nested YAML structure properly.
- To add tests: Create new `@test` functions in `tests/version-checker.bats` or `tests/version-checker-integration.bats`.
- To check specific commands: Use `timeout 30 <command>` for commands that may hang, and `timeout 300 <command>` for scans.

## Performance Expectations
- Unit tests: ~1 second. NEVER CANCEL. Set timeout to 30+ seconds.
- Integration tests: ~1 second. NEVER CANCEL. Set timeout to 30+ seconds.
- Linting: ~2 seconds. NEVER CANCEL. Set timeout to 30+ seconds.
- Regular scan: ~10-15 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- Full scan: 5+ minutes. NEVER CANCEL. Set timeout to 10+ minutes.
- Setup operations: <5 seconds. NEVER CANCEL. Set timeout to 30+ seconds.
- Help commands: <1 second.
- Stats/status commands: <1 second.

## Repository Structure
```
├── .github/
│   ├── workflows/          # CI/CD pipelines
│   └── dependabot.yml      # Dependency monitoring
├── tests/                  # Bats test suite
├── lib/                    # Shared library functions
├── monitoring-configs/     # Tool configuration
├── monitoring/             # Dependabot monitoring files
├── version-checker.sh      # Main version checking tool
├── unified-software-manager-manager.sh  # Main management script
├── setup.sh               # Initial setup script
├── Makefile               # Development commands
└── README.md              # User documentation
```

This is a bash-based tool suite for managing software versions and dependencies across different package managers and installation methods. The codebase does not require compilation but has comprehensive testing and linting infrastructure.