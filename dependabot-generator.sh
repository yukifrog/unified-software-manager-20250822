#!/bin/bash

# Unified Software Manager Manager - GitHub Dependabot監視ファイル生成
# 疑似依存関係ファイルを生成してDependabotにリリース監視させる

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.unified-software-manager-manager"
DATA_FILE="$CONFIG_DIR/programs.yaml"
MONITORING_DIR="$SCRIPT_DIR/monitoring"

# 色付きメッセージ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

highlight() {
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1"
}

# GitHubリポジトリマッピング（拡張版）
get_github_repo_for_dependabot() {
    local program_name="$1"
    
    case "$program_name" in
        # Node.js ecosystem
        "gh") echo "cli/cli" ;;
        "node"|"nodejs") echo "nodejs/node" ;;
        
        # DevOps tools  
        "kubectl") echo "kubernetes/kubernetes" ;;
        "helm") echo "helm/helm" ;;
        "terraform") echo "hashicorp/terraform" ;;
        "vault") echo "hashicorp/vault" ;;
        "consul") echo "hashicorp/consul" ;;
        "nomad") echo "hashicorp/nomad" ;;
        
        # Container tools
        "docker"|"docker.io") echo "docker/cli" ;;
        "kind") echo "kubernetes-sigs/kind" ;;
        "k9s") echo "derailed/k9s" ;;
        "dive") echo "wagoodman/dive" ;;
        "ctop") echo "bcicen/ctop" ;;
        
        # CLI utilities
        "jq") echo "jqlang/jq" ;;
        "yq") echo "mikefarah/yq" ;;
        "fzf") echo "junegunn/fzf" ;;
        "bat") echo "sharkdp/bat" ;;
        "fd") echo "sharkdp/fd" ;;
        "ripgrep"|"rg") echo "BurntSushi/ripgrep" ;;
        "exa") echo "ogham/exa" ;;
        "delta") echo "dandavison/delta" ;;
        
        # Development tools
        "lazygit") echo "jesseduffield/lazygit" ;;
        "hugo") echo "gohugoio/hugo" ;;
        "httpie") echo "httpie/httpie" ;;
        "code"|"vscode") echo "microsoft/vscode" ;;
        
        # Language runtimes
        "golang"|"go") echo "golang/go" ;;
        "rust"|"rustc") echo "rust-lang/rust" ;;
        "python"|"python3") echo "python/cpython" ;;
        
        # AI/ML tools
        "ollama") echo "ollama/ollama" ;;
        
        *) echo "" ;;
    esac
}

# パッケージ名をnpm互換形式に変換
convert_to_npm_package() {
    local program_name="$1"
    local version="$2"
    
    case "$program_name" in
        "kubectl") echo "    \"@kubernetes/kubectl\": \"$version\",";;
        "terraform") echo "    \"terraform\": \"$version\",";;
        "vault") echo "    \"@hashicorp/vault\": \"$version\",";;
        "helm") echo "    \"@helm/helm\": \"$version\",";;
        "docker") echo "    \"docker\": \"$version\",";;
        "gh") echo "    \"@github/gh\": \"$version\",";;
        *) echo "    \"$program_name\": \"$version\",";;
    esac
}

# パッケージ名をPython互換形式に変換
convert_to_python_package() {
    local program_name="$1"
    local version="$2"
    
    case "$program_name" in
        "kubectl") echo "kubectl==$version";;
        "terraform") echo "terraform==$version";;
        "vault") echo "hvac==$version  # HashiCorp Vault client";;
        "docker") echo "docker==$version";;
        "gh") echo "github-cli==$version";;
        *) echo "$program_name==$version";;
    esac
}

# パッケージ名をRuby/Gem互換形式に変換
convert_to_ruby_gem() {
    local program_name="$1"
    local version="$2"
    
    case "$program_name" in
        "kubectl") echo "gem 'kubectl-rb', '$version'";;
        "terraform") echo "gem 'terraform', '$version'";;
        "gh") echo "gem 'github_cli', '$version'";;
        "jq") echo "gem 'jq', '$version'";;
        *) echo "gem '$program_name', '$version'";;
    esac
}

# Go mod形式に変換
convert_to_go_mod() {
    local program_name="$1"
    local version="$2"
    local github_repo="$3"
    
    if [[ -n "$github_repo" ]]; then
        echo "    github.com/$github_repo v$version"
    else
        echo "    // $program_name v$version (repository unknown)"
    fi
}

# プログラム情報を取得
get_program_info() {
    if [[ ! -f "$DATA_FILE" ]]; then
        warn "データファイルが見つかりません: $DATA_FILE"
        warn "先に ./unified-software-manager-manager.sh --full-scan を実行してください"
        return 1
    fi
    
    # プログラム一覧と情報を取得
    awk '/^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$/ && !/^[[:space:]]*programs:[[:space:]]*$/ {
        # プログラム名を取得
        gsub(/^[[:space:]]*/, ""); 
        gsub(/:.*$/, ""); 
        prog_name = $0;
        
        # バージョンとカテゴリを探す
        while ((getline) > 0) {
            if (/^[[:space:]]*version:[[:space:]]/) {
                gsub(/^[[:space:]]*version:[[:space:]]*"?/, "");
                gsub(/".*$/, "");
                version = $0;
            }
            if (/^[[:space:]]*category:[[:space:]]/) {
                gsub(/^[[:space:]]*category:[[:space:]]*"?/, "");
                gsub(/".*$/, "");
                category = $0;
            }
            # 次のプログラムまたはセクション開始で終了
            if (/^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$/ && !/^[[:space:]]{4}/) {
                print prog_name "|" (version ? version : "unknown") "|" (category ? category : "unknown");
                # 戻る
                prog_name = "";
                gsub(/^[[:space:]]*/, "");
                gsub(/:.*$/, "");
                prog_name = $0;
                version = "";
                category = "";
            }
        }
        # 最後のプログラム
        if (prog_name) {
            print prog_name "|" (version ? version : "unknown") "|" (category ? category : "unknown");
        }
    }' "$DATA_FILE"
}

# Node.js/npm形式のファイル生成
generate_nodejs_package() {
    local output_file="$1"
    local programs_info="$2"
    
    cat > "$output_file" << 'EOF'
{
  "name": "monitoring-nodejs-tools",
  "version": "1.0.0",
  "description": "Monitoring file for tracking DevOps tools releases via Dependabot",
  "private": true,
  "dependencies": {
EOF

    # プログラム情報を処理してpackage.jsonに追加
    echo "$programs_info" | while IFS='|' read -r name version category; do
        if [[ -n "$name" && "$version" != "unknown" ]]; then
            local github_repo
            github_repo=$(get_github_repo_for_dependabot "$name")
            if [[ -n "$github_repo" ]]; then
                convert_to_npm_package "$name" "$version" >> "$output_file"
            fi
        fi
    done
    
    # 最後のカンマを削除して閉じる
    sed -i '$ s/,$//' "$output_file"
    
    cat >> "$output_file" << 'EOF'
  },
  "devDependencies": {},
  "scripts": {
    "note": "This is a monitoring file for Dependabot - not for actual installation"
  },
  "keywords": ["monitoring", "dependabot", "devops-tools"],
  "repository": "https://github.com/yukifrog/unified-software-manager-20250822"
}
EOF
}

# Python/pip形式のファイル生成
generate_python_requirements() {
    local output_file="$1"
    local programs_info="$2"
    
    cat > "$output_file" << 'EOF'
# Requirements file for monitoring DevOps tools via Dependabot
# This is a monitoring file - not for actual installation

EOF

    echo "$programs_info" | while IFS='|' read -r name version category; do
        if [[ -n "$name" && "$version" != "unknown" ]]; then
            local github_repo
            github_repo=$(get_github_repo_for_dependabot "$name")
            if [[ -n "$github_repo" ]]; then
                echo "# $name - https://github.com/$github_repo" >> "$output_file"
                convert_to_python_package "$name" "$version" >> "$output_file"
                echo >> "$output_file"
            fi
        fi
    done
}

# Ruby/Gem形式のファイル生成
generate_ruby_gemfile() {
    local output_file="$1"
    local programs_info="$2"
    
    cat > "$output_file" << 'EOF'
# Gemfile for monitoring DevOps tools via Dependabot
# This is a monitoring file - not for actual installation

source 'https://rubygems.org'

ruby '3.0.0'

EOF

    echo "$programs_info" | while IFS='|' read -r name version category; do
        if [[ -n "$name" && "$version" != "unknown" ]]; then
            local github_repo
            github_repo=$(get_github_repo_for_dependabot "$name")
            if [[ -n "$github_repo" ]]; then
                echo "# $name - https://github.com/$github_repo" >> "$output_file"
                convert_to_ruby_gem "$name" "$version" >> "$output_file"
                echo >> "$output_file"
            fi
        fi
    done
}

# Go modules形式のファイル生成
generate_go_mod() {
    local output_file="$1"
    local programs_info="$2"
    
    cat > "$output_file" << 'EOF'
// Go module file for monitoring DevOps tools via Dependabot
// This is a monitoring file - not for actual compilation

module github.com/yukifrog/unified-software-manager-20250822/monitoring/go-tools

go 1.21

require (
EOF

    echo "$programs_info" | while IFS='|' read -r name version category; do
        if [[ -n "$name" && "$version" != "unknown" ]]; then
            local github_repo
            github_repo=$(get_github_repo_for_dependabot "$name")
            if [[ -n "$github_repo" ]]; then
                convert_to_go_mod "$name" "$version" "$github_repo" >> "$output_file"
            fi
        fi
    done
    
    echo ")" >> "$output_file"
}

# Dependabot設定ファイル生成
generate_dependabot_config() {
    local config_file="$1"
    
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << 'EOF'
# GitHub Dependabot configuration for monitoring tool releases
# This automatically creates PRs when new versions are released

version: 2

updates:
  # Monitor Node.js/npm dependencies
  - package-ecosystem: "npm"
    directory: "/monitoring/nodejs-tools"
    schedule:
      interval: "daily"
      time: "09:00"
      timezone: "Asia/Tokyo"
    open-pull-requests-limit: 10
    commit-message:
      prefix: "deps(nodejs-tools)"
      include: "scope"
    labels:
      - "dependencies"
      - "nodejs-tools"
      - "automated-pr"

  # Monitor Python/pip dependencies  
  - package-ecosystem: "pip"
    directory: "/monitoring/python-tools"
    schedule:
      interval: "daily" 
      time: "09:30"
      timezone: "Asia/Tokyo"
    open-pull-requests-limit: 10
    commit-message:
      prefix: "deps(python-tools)"
      include: "scope"
    labels:
      - "dependencies"
      - "python-tools"
      - "automated-pr"

  # Monitor Ruby/gem dependencies
  - package-ecosystem: "bundler"
    directory: "/monitoring/ruby-tools"
    schedule:
      interval: "daily"
      time: "10:00" 
      timezone: "Asia/Tokyo"
    open-pull-requests-limit: 10
    commit-message:
      prefix: "deps(ruby-tools)"
      include: "scope"
    labels:
      - "dependencies"
      - "ruby-tools"
      - "automated-pr"

  # Monitor Go modules
  - package-ecosystem: "gomod"
    directory: "/monitoring/go-tools"
    schedule:
      interval: "daily"
      time: "10:30"
      timezone: "Asia/Tokyo" 
    open-pull-requests-limit: 10
    commit-message:
      prefix: "deps(go-tools)"
      include: "scope"
    labels:
      - "dependencies"
      - "go-tools"
      - "automated-pr"

  # Monitor GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Asia/Tokyo"
    commit-message:
      prefix: "deps(actions)"
      include: "scope"
    labels:
      - "dependencies"
      - "github-actions"
      - "automated-pr"
EOF
}

# メイン実行関数
main() {
    case "${1:-}" in
        --generate|-g)
            generate_all_files
            ;;
        --setup-dirs)
            setup_directories
            ;;
        --help|-h)
            show_help
            ;;
        "")
            generate_all_files
            ;;
        *)
            warn "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
}

# ディレクトリ構造セットアップ
setup_directories() {
    info "監視用ディレクトリ構造を作成中..."
    
    mkdir -p "$MONITORING_DIR/nodejs-tools"
    mkdir -p "$MONITORING_DIR/python-tools"  
    mkdir -p "$MONITORING_DIR/ruby-tools"
    mkdir -p "$MONITORING_DIR/go-tools"
    mkdir -p "$SCRIPT_DIR/.github"
    
    success "ディレクトリ構造を作成しました"
}

# 全ファイル生成
generate_all_files() {
    info "GitHub Dependabot監視ファイルを生成中..."
    
    # ディレクトリ作成
    setup_directories
    
    # プログラム情報取得
    local programs_info
    programs_info=$(get_program_info)
    
    if [[ -z "$programs_info" ]]; then
        warn "監視対象のプログラムが見つかりません"
        return 1
    fi
    
    # 各種依存関係ファイル生成
    info "Node.js package.json を生成中..."
    generate_nodejs_package "$MONITORING_DIR/nodejs-tools/package.json" "$programs_info"
    
    info "Python requirements.txt を生成中..."
    generate_python_requirements "$MONITORING_DIR/python-tools/requirements.txt" "$programs_info"
    
    info "Ruby Gemfile を生成中..."
    generate_ruby_gemfile "$MONITORING_DIR/ruby-tools/Gemfile" "$programs_info"
    
    info "Go go.mod を生成中..."
    generate_go_mod "$MONITORING_DIR/go-tools/go.mod" "$programs_info"
    
    info "Dependabot設定ファイルを生成中..."
    generate_dependabot_config "$SCRIPT_DIR/.github/dependabot.yml"
    
    success "すべてのDependabot監視ファイルを生成しました！"
    echo
    highlight "作成されたファイル:"
    echo "  📁 monitoring/nodejs-tools/package.json"
    echo "  📁 monitoring/python-tools/requirements.txt"  
    echo "  📁 monitoring/ruby-tools/Gemfile"
    echo "  📁 monitoring/go-tools/go.mod"
    echo "  ⚙️  .github/dependabot.yml"
    echo
    info "GitHubにプッシュ後、Dependabotが自動でリリース監視を開始します"
    info "新しいバージョンがリリースされると自動でPRが作成されます"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Unified Software Manager Manager - GitHub Dependabot監視ファイル生成

使用法:
    ./dependabot-generator.sh [オプション]

オプション:
    --generate, -g    監視ファイルを生成（デフォルト）
    --setup-dirs      ディレクトリ構造のみ作成
    --help, -h        このヘルプを表示

説明:
    GitHub Dependabotを使用してツールのリリースを自動監視するため、
    疑似的な依存関係ファイルを生成します。
    
    生成されるファイル:
    • package.json (Node.js形式)
    • requirements.txt (Python形式)  
    • Gemfile (Ruby形式)
    • go.mod (Go形式)
    • .github/dependabot.yml (Dependabot設定)

例:
    ./dependabot-generator.sh          # 全ファイル生成
    ./dependabot-generator.sh -g       # 同上
    ./dependabot-generator.sh --help   # ヘルプ表示

EOF
}

main "$@"