#!/bin/bash

# PR作成スクリプト
# バージョンチェッカーの結果を受け取り、自動でPull Requestを作成

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/monitoring-configs/tools.yaml"

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

highlight() {
    echo -e "${CYAN}[PR]${NC} $1"
}

# 必要なツールチェック
check_requirements() {
    if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) がインストールされていません"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        error "jq がインストールされていません"
        exit 1
    fi
    
    # GitHub CLI の認証確認
    if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI が認証されていません: gh auth login を実行してください"
        exit 1
    fi
}

# YAML値更新
update_yaml_version() {
    local tool_name="$1"
    local new_version="$2"
    
    # 一時ファイルで更新
    local temp_file
    temp_file=$(mktemp)
    
    awk -v tool="$tool_name" -v new_ver="$new_version" '
    /^[[:space:]]*'"$tool_name"':[[:space:]]*$/ { in_tool=1; print; next }
    in_tool && /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$/ { 
        if (!/^[[:space:]]{4}/) in_tool=0 
    }
    in_tool && /^[[:space:]]{4}current_version:[[:space:]]/ {
        gsub(/current_version:[[:space:]]*"?[^"]*"?/, "current_version: \"" new_ver "\"")
    }
    { print }
    ' "$CONFIG_FILE" > "$temp_file"
    
    mv "$temp_file" "$CONFIG_FILE"
}

# ブランチ名生成
generate_branch_name() {
    local tool_name="$1"
    local new_version="$2"
    
    echo "deps/update-${tool_name}-${new_version}"
}

# PR本文生成
generate_pr_body() {
    local tool_name="$1"
    local old_version="$2"
    local new_version="$3"
    local github_repo="$4"
    local category="$5"
    local priority="$6"
    
    cat << EOF
## 📦 Dependency Update

**Tool:** $tool_name  
**Category:** $category  
**Priority:** $priority

**Version Change:**
- **From:** \`v$old_version\`
- **To:** \`v$new_version\`

## 🔗 Links

- [GitHub Repository](https://github.com/$github_repo)
- [Latest Release](https://github.com/$github_repo/releases/tag/v$new_version)
- [Release Notes](https://github.com/$github_repo/releases/tag/v$new_version)
- [All Releases](https://github.com/$github_repo/releases)

## 🤖 Automated Update

This PR was automatically created by the Unified Software Manager system.

### Next Steps:
1. Review the release notes above
2. Test the update if necessary
3. Approve and merge when ready

---

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
}

# 単一ツールのPR作成
create_single_pr() {
    local update_json="$1"
    
    local tool_name
    local current_version
    local latest_version
    local github_repo
    local category
    local priority
    
    tool_name=$(echo "$update_json" | jq -r '.tool')
    current_version=$(echo "$update_json" | jq -r '.current_version')
    latest_version=$(echo "$update_json" | jq -r '.latest_version')
    github_repo=$(echo "$update_json" | jq -r '.github_repo')
    category=$(echo "$update_json" | jq -r '.category')
    priority=$(echo "$update_json" | jq -r '.priority')
    
    info "PR作成中: $tool_name ($current_version → $latest_version)"
    
    # ブランチ名生成
    local branch_name
    branch_name=$(generate_branch_name "$tool_name" "$latest_version")
    
    # 既存ブランチチェック
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        warn "ブランチ '$branch_name' は既に存在します - スキップ"
        return 0
    fi
    
    # 新しいブランチを作成
    git checkout -b "$branch_name" > /dev/null 2>&1
    
    # YAML ファイルを更新
    update_yaml_version "$tool_name" "$latest_version"
    
    # 変更をコミット
    git add "$CONFIG_FILE"
    git commit -m "deps: update $tool_name from v$current_version to v$latest_version

Automated update for $tool_name dependency

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # PRタイトル生成
    local pr_title="deps: update $tool_name from v$current_version to v$latest_version"
    
    # PR本文生成
    local pr_body
    pr_body=$(generate_pr_body "$tool_name" "$current_version" "$latest_version" "$github_repo" "$category" "$priority")
    
    # PRを作成 (Draft PR)
    local pr_url
    pr_url=$(gh pr create \
        --title "$pr_title" \
        --body "$pr_body" \
        --label "dependencies" \
        --label "automated-pr" \
        --label "$category" \
        --draft 2>/dev/null || echo "")
    
    if [[ -n "$pr_url" ]]; then
        success "PR作成成功: $pr_url"
        highlight "$tool_name: $current_version → $latest_version"
    else
        error "PR作成に失敗: $tool_name"
    fi
    
    # メインブランチに戻る
    git checkout - > /dev/null 2>&1
}

# 複数ツールのPR一括作成
create_multiple_prs() {
    local input_file="$1"
    
    if [[ ! -f "$input_file" ]]; then
        error "入力ファイルが見つかりません: $input_file"
        exit 1
    fi
    
    local updates
    updates=$(cat "$input_file")
    
    if [[ -z "$updates" || "$updates" == "[]" ]]; then
        info "更新対象のツールがありません"
        return 0
    fi
    
    local update_count
    update_count=$(echo "$updates" | jq length 2>/dev/null || echo "0")
    
    info "$update_count 個のツールでPRを作成します"
    echo
    
    # 各更新についてPRを作成
    echo "$updates" | jq -c '.[]' | while IFS= read -r update; do
        create_single_pr "$update"
        echo
    done
    
    success "すべてのPR作成処理が完了しました"
}

# 手動PR作成（特定ツール）
create_manual_pr() {
    local tool_name="$1"
    local new_version="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "設定ファイルが見つかりません: $CONFIG_FILE"
        exit 1
    fi
    
    # 設定から情報取得
    local current_version
    local github_repo
    local category
    local priority
    
    current_version=$(awk -v tool="$tool_name" '/^[[:space:]]*'"$tool_name"':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*current_version:[[:space:]]/ {gsub(/^[[:space:]]*current_version:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$CONFIG_FILE")
    github_repo=$(awk -v tool="$tool_name" '/^[[:space:]]*'"$tool_name"':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*github_repo:[[:space:]]/ {gsub(/^[[:space:]]*github_repo:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$CONFIG_FILE")
    category=$(awk -v tool="$tool_name" '/^[[:space:]]*'"$tool_name"':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*category:[[:space:]]/ {gsub(/^[[:space:]]*category:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$CONFIG_FILE")
    priority=$(awk -v tool="$tool_name" '/^[[:space:]]*'"$tool_name"':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*priority:[[:space:]]/ {gsub(/^[[:space:]]*priority:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$CONFIG_FILE")
    
    if [[ -z "$current_version" || -z "$github_repo" ]]; then
        error "ツール '$tool_name' の設定が見つかりません"
        exit 1
    fi
    
    # JSONを作成して単一PR作成関数を呼び出し
    local update_json="{\"tool\":\"$tool_name\",\"current_version\":\"$current_version\",\"latest_version\":\"$new_version\",\"github_repo\":\"$github_repo\",\"category\":\"$category\",\"priority\":\"$priority\"}"
    
    create_single_pr "$update_json"
}

# ヘルプ表示
show_help() {
    cat << EOF
PR作成スクリプト - 自動Pull Request生成

使用法:
    $0 [オプション]

オプション:
    --input-file <file>          更新情報JSONファイルから一括PR作成
    --tool <name> <version>      特定ツールの手動PR作成
    --help                       このヘルプを表示

例:
    $0 --input-file updates.json
    $0 --tool kubectl 1.26.0

前提条件:
    - GitHub CLI (gh) がインストール・認証済み
    - jq がインストール済み
    - Gitリポジトリ内で実行

EOF
}

# メイン処理
main() {
    check_requirements
    
    case "${1:-}" in
        --input-file)
            if [[ -z "${2:-}" ]]; then
                error "入力ファイルを指定してください"
                exit 1
            fi
            create_multiple_prs "$2"
            ;;
        --tool)
            if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                error "ツール名とバージョンを指定してください"
                exit 1
            fi
            create_manual_pr "$2" "$3"
            ;;
        --help|"")
            show_help
            ;;
        *)
            error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"