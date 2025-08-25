# Claude Code Development Tools

## Overview

This document lists recommended tools that significantly enhance development efficiency when used with Claude Code. These tools are optimized for command-line development workflows and integrate seamlessly with Claude Code's capabilities.

## 🚀 **Recommended Tools by Category**

### **📝 Editor & IDE Integration**

#### Neovim/Vim Ecosystem
```bash
# Plugin Managers
lazy.nvim          # Fast and flexible plugin manager with lazy loading
                   # Improves Neovim startup time significantly
packer.nvim        # Alternative plugin manager with declarative configuration

# Essential Plugins  
telescope.nvim     # Fuzzy finder for files, buffers, git commits, LSP symbols
                   # Replaces multiple tools with unified interface
nvim-lspconfig     # Easy LSP setup for code completion, diagnostics, formatting
                   # Brings IDE-like features to Neovim
nvim-treesitter    # Better syntax highlighting using tree-sitter parsers
                   # Provides semantic understanding of code structure
```

#### VS Code Extensions (Claude Code Compatible)
```bash
# Development Enhancement
GitLens            # Comprehensive Git integration showing blame, history, branches
                   # Visualizes code evolution and collaboration patterns
Thunder Client     # Built-in REST API testing without leaving editor
                   # Alternative to Postman for simple API development
Error Lens         # Shows errors and warnings directly in editor lines
                   # Reduces need to check Problems panel constantly
Bracket Pair       # Color-codes matching brackets and parentheses
                   # Essential for nested code structure visualization
```

### **🔍 Search & File Operations**

#### Already Configured ✅
```bash
ripgrep (rg)       # Ultra-fast text search with regex and Unicode support
                   # 10-100x faster than grep, ignores binary files and .gitignore
fd                 # Intuitive find replacement with sensible defaults
                   # Faster than find, respects .gitignore, colored output
fzf                # Interactive fuzzy finder for files, history, processes
                   # Integrates with shell history, git, and many tools
bat                # Cat clone with syntax highlighting and Git integration
                   # Shows line numbers, file changes, and supports themes
```

#### Recommended Additions
```bash
eza                # Modern ls replacement with Git status, icons, and colors
                   # Shows file metadata, permissions, and directory trees beautifully
zoxide             # Intelligent cd replacement that learns frequently used paths
                   # Jump to directories using partial names and usage frequency
broot              # Interactive tree navigator with fuzzy search and preview
                   # Navigate large directory structures with vim-like commands
```

### **🐛 Debugging & System Analysis**

#### System Monitoring
```bash
htop               # Interactive process viewer with CPU, memory, and process management
                   # Color-coded, sortable interface for system monitoring
iotop              # Real-time I/O statistics showing disk read/write per process
                   # Essential for identifying I/O bottlenecks in development
ncdu               # Interactive disk usage analyzer with drill-down navigation
                   # Find large files and directories consuming disk space
btop               # Modern htop alternative with better graphics and mouse support
                   # GPU monitoring, network stats, and beautiful terminal UI
```

#### Network & API Tools
```bash
httpie             # Intuitive HTTP client with JSON support and syntax highlighting
                   # Perfect for API testing with readable request/response format
curlie             # Curl wrapper with httpie-style syntax but curl power
                   # Combines curl's features with httpie's user-friendliness
dog                # DNS lookup tool with colorized output and multiple record types
                   # Modern dig replacement with better formatting
bandwhich          # Real-time network utilization monitoring by process
                   # Shows which processes are using bandwidth
```

### **⚡ Development Efficiency**

#### Git & Version Control ✅
```bash
lazygit            # Full-featured TUI for Git with branch visualization
                   # Interactive staging, commit, push, merge with mouse support
delta              # Syntax-highlighted diff viewer with line numbers and themes
                   # Makes code changes much easier to review and understand
gh                 # Official GitHub CLI for issues, PRs, releases, and workflows
                   # Manage GitHub repositories without leaving terminal
```

#### Data Processing ✅
```bash
jq                 # Powerful JSON processor with filtering, mapping, and formatting
                   # Essential for API development and data manipulation
yq                 # YAML/XML processor with jq-compatible syntax
                   # Perfect for configuration file manipulation and CI/CD
```

#### File Operations
```bash
rsync              # Robust file synchronization with incremental transfers
                   # Efficient backups and deployment with network support
meld               # Visual diff and merge tool with 3-way comparison
                   # GUI tool for resolving merge conflicts and comparing files
rclone             # Universal cloud storage CLI supporting 70+ providers
                   # Sync files with Google Drive, AWS S3, Dropbox, etc.
```

### **🛠️ Build & Development Tools**

#### Language-Specific Tools
```bash
# Node.js Ecosystem (via nvm) ✅
node               # JavaScript/TypeScript runtime environment
                   # Latest v24.6.0 with modern ES features and performance improvements
npm                # Default Node.js package manager with workspaces support
                   # Built-in security auditing and dependency management
yarn               # Alternative package manager with deterministic installs
                   # Faster installs, better monorepo support, plug'n'play mode
pnpm               # Fast, disk space efficient package manager with hard links
                   # Saves gigabytes of disk space, faster CI builds

# Python Tools
pyenv              # Python version management with seamless switching
                   # Install multiple Python versions, per-project configuration
pipx               # Install Python CLI applications in isolated environments
                   # Prevents dependency conflicts between tools
poetry             # Modern dependency management with lock files
                   # Virtual environment management and package publishing

# Go Tools
gvm                # Go version manager for multiple Go installations
                   # Switch between Go versions per project
air                # Live reload for Go applications during development
                   # Watches files and rebuilds automatically on changes
```

#### Universal Development
```bash
direnv             # Automatic environment variable loading per directory
                   # Load project-specific env vars when entering directories
just               # Command runner with simple syntax (better than Make)
                   # Project-specific commands with parameter support
watchexec          # File watcher that executes commands on changes
                   # Cross-platform, supports glob patterns and ignore files
entr               # Run commands when files change (Unix-focused)
                   # Simple, reliable file watching for build automation
```

### **📊 Code Quality & Analysis**

```bash
# Universal Linters
prettier           # Opinionated code formatter supporting 20+ languages
                   # Consistent formatting for JS, TS, JSON, CSS, HTML, Markdown
eslint             # Pluggable JavaScript/TypeScript linter with auto-fixing
                   # Catches bugs, enforces style, supports modern frameworks
shellcheck         # Static analysis tool for shell scripts with helpful suggestions
                   # Finds bugs, suggests improvements, supports all shell types
hadolint           # Dockerfile linter following best practices
                   # Security, optimization, and maintainability checks

# Security Tools
gitleaks           # Fast secret detection in git repositories
                   # Scans commits, branches, and files for API keys, passwords
truffleHog         # Advanced secret scanner with entropy analysis
                   # Finds high-entropy strings and known secret patterns
```

### **🔧 System Utilities**

```bash
# Terminal Enhancements
starship           # Fast, customizable shell prompt with Git, language info
                   # Shows project context, Git status, execution time
tmux               # Terminal multiplexer for persistent sessions and window management
                   # Essential for remote development and session persistence
zellij             # Modern tmux alternative with layouts, plugins, and floating panes
                   # User-friendly terminal workspace manager with sensible defaults

# File Management
duf                # User-friendly disk usage display with colors and graphs
                   # Shows available space, mount points, and file system types
dust               # Interactive directory size analyzer with visual tree
                   # Quickly identify large directories and files
procs              # Modern process viewer with tree view and search
                   # Colored output, shows process relationships and resource usage
```

## 🎯 **Priority Installation Recommendations**

### **Immediate Impact (Install First)**
1. **eza** - Enhanced file listing with colors and icons
2. **zoxide** - Intelligent directory navigation
3. **httpie** - API testing and HTTP requests
4. **starship** - Beautiful, informative shell prompt

### **Development Workflow Enhancement**
1. **direnv** - Project-specific environment management
2. **watchexec** - Automatic command execution on file changes
3. **just** - Simplified command running
4. **btop** - System monitoring

### **Code Quality & Security**
1. **prettier** - Universal code formatting
2. **shellcheck** - Shell script validation
3. **gitleaks** - Security scanning

## 🔄 **Integration with Unified Software Manager**

### Adding Tools to Management
```bash
# Edit tools.yaml to add new tools
vim monitoring-configs/tools.yaml

# Example entry for a new tool:
eza:
  current_version: "0.15.0"
  github_repo: "eza-community/eza"
  update_method: "binary_download"
  category: "cli"
  priority: "medium"
```

### Monitoring Strategy
- **Command-line tools**: Managed via `tools.yaml` with binary_download
- **Language-specific tools**: Managed via version managers (nvm, pyenv, etc.)
- **Editor plugins**: Managed within respective editors

## 🚀 **Quick Start Commands**

### Essential Setup
```bash
# Install the unified software manager first
./unified-software-manager-manager.sh

# Then add priority tools to tools.yaml and run updates
./version-checker.sh --check-all

# Install version managers for language-specific tools
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
curl https://pyenv.run | bash
```

### Verification
```bash
# Test the tools
eza -la --icons
zoxide query --list
httpie --version
starship --version
```

## 📚 **Documentation & Resources**

### Tool Documentation
- [ripgrep User Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [fzf Advanced Usage](https://github.com/junegunn/fzf#usage)
- [Neovim LSP Configuration](https://github.com/neovim/nvim-lspconfig)
- [Starship Configuration](https://starship.rs/config/)

### Integration Guides
- [Zoxide Setup Guide](https://github.com/ajeetdsouza/zoxide#installation)
- [Direnv Hook Installation](https://direnv.net/docs/hook.html)
- [GitHub CLI Authentication](https://cli.github.com/manual/gh_auth_login)

---

**Last Updated**: 2025-08-25  
**Compatible with**: Unified Software Manager v2.0+  
**Maintenance**: Use `./version-checker.sh --check-all` for updates