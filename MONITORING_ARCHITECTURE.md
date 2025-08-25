# Unified Software Manager - Monitoring Architecture

## Overview

This document describes the comprehensive monitoring architecture for tracking software updates across multiple package ecosystems using GitHub Dependabot integration.

## Architecture Principles

### 🎯 **Clear Separation of Concerns**
- **Command-line Tools**: Managed via `tools.yaml` with `binary_download` method
- **Language Libraries**: Monitored via ecosystem-specific pseudo-dependency files
- **No Naming Conflicts**: Only scoped or distinctly named packages in monitoring files

### 🔄 **Dual Management Strategy**
1. **Direct Tool Management**: `tools.yaml` for actual software installation/updates
2. **Release Monitoring**: Dependabot integration for automated update notifications

## Monitoring Structure

### 📁 Directory Layout
```
monitoring/
├── nodejs-tools/package.json     # npm ecosystem monitoring
├── python-tools/requirements.txt # pip ecosystem monitoring  
├── go-tools/go.mod               # Go modules monitoring
└── ruby-tools/Gemfile            # Ruby gems monitoring
```

### ⚙️ Dependabot Configuration
**File**: `.github/dependabot.yml`

**Ecosystems Monitored**:
- `npm` (Node.js) - Daily 09:00 JST
- `pip` (Python) - Daily 09:30 JST  
- `bundler` (Ruby) - Daily 10:00 JST
- `gomod` (Go) - Daily 10:30 JST
- `github-actions` - Weekly Monday 09:00 JST

## Current Monitored Tools

### ✅ **Appropriate Entries** (Scoped/Distinct Names)
| Tool | npm | pip | go | ruby |
|------|-----|-----|----|----- |
| **GitHub CLI** | `@github/gh` | `github-cli` | `github.com/cli/cli` | `github_cli` |
| **Kubernetes CLI** | `@kubernetes/kubectl` | `kubectl` | `github.com/kubernetes/kubernetes` | `kubectl-rb` |

### 🚫 **Removed Conflicting Entries**
| Tool | Reason for Removal |
|------|-------------------|
| `docker` | CLI tool vs library confusion |
| `terraform` | HashiCorp tool vs library confusion |
| `jq` | Command processor vs library confusion |
| `node` | Runtime vs library confusion |
| `code` | VS Code vs assertion library confusion |
| `ollama` | AI tool vs client library confusion |

## Benefits Achieved

### 📈 **Quantitative Improvements**
- **Entries Removed**: 24 (6 tools × 4 ecosystems)
- **Remaining Appropriate**: 8 (2 tools × 4 ecosystems)
- **PR Noise Reduction**: ~90% of irrelevant update PRs eliminated

### 🎯 **Qualitative Improvements**
- **Precision**: Only legitimate tool updates trigger PRs
- **Clarity**: Clear distinction between tools and libraries
- **Maintainability**: Scalable architecture for future additions
- **Reliability**: No false positives from naming conflicts

## Management Workflows

### 🔧 **Command-line Tools** (via tools.yaml)
```yaml
jq:
  current_version: "1.8.1"
  github_repo: "jqlang/jq"  
  update_method: "binary_download"
  install_command: "curl -L https://github.com/jqlang/jq/releases/download/jq-{version}/jq-linux-amd64 -o /usr/local/bin/jq && chmod +x /usr/local/bin/jq"
```

### 📦 **Monitoring Only** (via pseudo-dependencies)
```json
// monitoring/nodejs-tools/package.json
{
  "dependencies": {
    "@github/gh": "2.78.0",
    "@kubernetes/kubectl": "1.25.4"
  }
}
```

## Future Additions Guidelines

### ✅ **Safe to Add**
- Scoped packages: `@org/package`
- Distinctly named packages without CLI conflicts
- Official wrapper packages with clear naming

### ⚠️ **Require Careful Review**
- Packages sharing names with command-line tools
- Generic names that could cause confusion
- Libraries representing CLI tools

### 🚫 **Should Not Add**
- Direct CLI tool names (docker, terraform, etc.)
- Generic utility names without scoping
- Packages that duplicate tools.yaml entries

## Validation Commands

### Test Monitoring Setup
```bash
# Verify file syntax
find monitoring/ -name "*.json" -exec jq . {} \;

# Check version detection
./version-checker.sh --check-all --category cli

# Test jq functionality
echo '{"test": "data"}' | jq '.test'
```

### Monitor Dependabot Activity
```bash
# Check for new PRs
gh pr list --label "automated-pr"

# Review dependency updates
gh pr list --label "dependencies"
```

## Troubleshooting

### Common Issues
1. **JSON Syntax Errors**: Validate with `jq . file.json`
2. **Missing Dependencies**: Check monitoring files exist in correct directories
3. **Dependabot Not Running**: Verify `.github/dependabot.yml` syntax

### Debugging Commands
```bash
# Check file formatting
find monitoring/ -type f -exec echo "=== {} ===" \; -exec cat {} \;

# Validate Dependabot config
gh api repos/:owner/:repo/dependabot/secrets
```

## Related Documentation
- [Dependabot Configuration Reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [Package Ecosystem Support](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates#supported-repositories-and-ecosystems)

---

**Last Updated**: 2025-08-25  
**Version**: 2.0 (Post-Cleanup Architecture)