#!/bin/bash

# バージョンチェッカースクリプト
# GitHub APIを使用してツールの最新バージョンを取得し、現在のバージョンと比較

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/monitoring-configs/tools.yaml"
CACHE_DIR="$HOME/.unified-software-manager-manager/cache"
CACHE_FILE="$CACHE_DIR/version-cache.json"

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

highlight() {
    echo -e "${CYAN}[UPDATE]${NC} $1" >&2
}

# 初期化
init() {
    mkdir -p "$CACHE_DIR"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "設定ファイルが見つかりません: $CONFIG_FILE"
        exit 1
    fi
    
    # キャッシュファイル初期化
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo '{}' > "$CACHE_FILE"
    fi
}

# YAML値取得 (簡易版)
get_yaml_value() {
    local yaml_file="$1"
    local tool_name="$2"
    local field="$3"
    
    awk -v tool="$tool_name" -v field="$field" '
    /^[[:space:]]*'$tool_name':[[:space:]]*$/ { in_tool=1; next }
    in_tool && /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$/ { 
        if (!/^[[:space:]]{4}/) in_tool=0 
    }
    in_tool && /^[[:space:]]{4}'$field':[[:space:]]/ {
        gsub(/^[[:space:]]*'$field':[[:space:]]*"?/, "")
        gsub(/".*$/, "")
        print
        exit
    }
    ' "$yaml_file"
}

# ツール一覧取得
get_tools_list() {
    awk '/^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$/ && !/^[[:space:]]*(metadata|github_api|pr_settings|notifications):[[:space:]]*$/ {
        gsub(/^[[:space:]]*/, ""); 
        gsub(/:.*$/, ""); 
        print
    }' "$CONFIG_FILE"
}

# キャッシュから取得
get_cached_version() {
    local repo="$1"
    local cache_hours="6"
    
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo ""
        return 1
    fi
    
    local cached_entry
    if command -v jq >/dev/null 2>&1; then
        cached_entry=$(jq -r --arg repo "$repo" '.[$repo] // empty' "$CACHE_FILE" 2>/dev/null || echo "")
    else
        # jq がない場合はキャッシュ無効
        cached_entry=""
    fi
    
    if [[ -n "$cached_entry" && "$cached_entry" != "null" ]]; then
        if command -v jq >/dev/null 2>&1; then
            local cached_time
            cached_time=$(echo "$cached_entry" | jq -r '.timestamp // 0' 2>/dev/null || echo "0")
            local current_time
            current_time=$(date +%s)
            local cache_duration=$((cache_hours * 3600))
            
            if [[ $((current_time - cached_time)) -lt $cache_duration ]]; then
                echo "$cached_entry" | jq -r '.version // ""' 2>/dev/null || echo ""
                return 0
            fi
        fi
    fi
    
    return 1
}

# キャッシュに保存
save_to_cache() {
    local repo="$1"
    local version="$2"
    local timestamp
    timestamp=$(date +%s)
    
    local temp_cache
    temp_cache=$(mktemp)
    
    if [[ -f "$CACHE_FILE" ]]; then
        cp "$CACHE_FILE" "$temp_cache"
    else
        echo '{}' > "$temp_cache"
    fi
    
    if command -v jq >/dev/null 2>&1; then
        jq --arg repo "$repo" --arg version "$version" --argjson timestamp "$timestamp" \
           '.[$repo] = {"version": $version, "timestamp": $timestamp}' \
           "$temp_cache" > "$CACHE_FILE"
    else
        # jq がない場合はキャッシュ保存しない
        warn "jq がないためキャッシュ機能が無効です"
    fi
    
    rm -f "$temp_cache"
}

# GitHub APIでバージョン取得
get_github_latest_version() {
    local repo="$1"
    
    # キャッシュチェック
    local cached_version
    if cached_version=$(get_cached_version "$repo"); then
        if [[ -n "$cached_version" ]]; then
            echo "$cached_version"
            return 0
        fi
    fi
    
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    # GitHub Token があれば使用
    local auth_header=""
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_header="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    local response
    response=$(timeout 10 curl -s $auth_header "$api_url" 2>/dev/null || echo "")
    
    if [[ -n "$response" && "$response" != *"rate limit"* && "$response" != *"Not Found"* ]]; then
        local version
        if command -v jq >/dev/null 2>&1; then
            version=$(echo "$response" | jq -r '.tag_name // ""' 2>/dev/null || echo "")
        else
            # jq がない場合の代替処理
            version=$(echo "$response" | grep '"tag_name":' | head -1 | sed 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        fi
        
        if [[ -n "$version" && "$version" != "null" && "$version" != "" ]]; then
            # vプレフィックスを除去
            version=$(echo "$version" | sed 's/^v//')
            
            # キャッシュに保存
            save_to_cache "$repo" "$version"
            
            echo "$version"
            return 0
        fi
    fi
    
    # API制限またはエラーの場合
    if [[ "$response" == *"rate limit"* ]]; then
        warn "GitHub API制限に達しました: $repo"
    fi
    
    echo "unknown"
    return 1
}

# バージョン比較 (簡易版)
version_compare() {
    local ver1="$1"
    local ver2="$2"
    
    if [[ "$ver1" == "unknown" || "$ver2" == "unknown" ]]; then
        echo "unknown"
        return 0
    fi
    
    if [[ "$ver1" == "$ver2" ]]; then
        echo "equal"
        return 0
    fi
    
    # セマンティックバージョニング対応の比較
    local ver1_nums
    local ver2_nums
    ver1_nums=$(echo "$ver1" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0.0.0")
    ver2_nums=$(echo "$ver2" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0.0.0")
    
    # sort -V で比較
    if [[ $(printf '%s\n%s' "$ver1_nums" "$ver2_nums" | sort -V | tail -1) == "$ver2_nums" ]]; then
        echo "github_newer"
    else
        echo "package_newer"
    fi
}

# 更新チェック実行
check_updates() {
    local output_format="${1:-table}"
    local category_filter="${2:-all}"
    
    info "バージョン更新チェック開始..."
    
    local tools
    tools=$(get_tools_list)
    
    local updates=()
    local checked_count=0
    local error_count=0
    
    while IFS= read -r tool_name; do
        if [[ -z "$tool_name" ]]; then continue; fi
        
        # カテゴリフィルター
        if [[ "$category_filter" != "all" ]]; then
            local tool_category
            tool_category=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "category")
            if [[ "$tool_category" != "$category_filter" ]]; then
                continue
            fi
        fi
        
        local current_version
        local github_repo
        local priority
        local category
        
        current_version=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "current_version")
        github_repo=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "github_repo")
        priority=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "priority")
        category=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "category")
        
        if [[ -z "$github_repo" ]]; then
            warn "GitHubリポジトリが設定されていません: $tool_name"
            continue
        fi
        
        info "チェック中: $tool_name ($current_version)"
        
        local latest_version
        latest_version=$(get_github_latest_version "$github_repo")
        checked_count=$((checked_count + 1))
        
        if [[ "$latest_version" == "unknown" ]]; then
            error_count=$((error_count + 1))
            continue
        fi
        
        local comparison
        comparison=$(version_compare "$current_version" "$latest_version")
        
        if [[ "$comparison" == "github_newer" ]]; then
            highlight "更新あり: $tool_name $current_version → $latest_version"
            
            # 更新情報を配列に追加
            local update_info="{\"tool\":\"$tool_name\",\"current_version\":\"$current_version\",\"latest_version\":\"$latest_version\",\"github_repo\":\"$github_repo\",\"category\":\"$category\",\"priority\":\"$priority\"}"
            updates+=("$update_info")
        fi
        
        # API制限対策
        sleep 0.3
        
    done <<< "$tools"
    
    # 結果出力
    case "$output_format" in
        "json")
            if [[ ${#updates[@]} -gt 0 ]]; then
                printf "[\n"
                for i in "${!updates[@]}"; do
                    printf "  %s" "${updates[$i]}"
                    if [[ $i -lt $((${#updates[@]} - 1)) ]]; then
                        printf ","
                    fi
                    printf "\n"
                done
                printf "]\n"
            else
                printf "[]\n"
            fi
            ;;
        "table"|*)
            echo
            success "バージョンチェック完了"
            info "チェック対象: $checked_count ツール"
            info "エラー: $error_count ツール"
            
            if [[ ${#updates[@]} -gt 0 ]]; then
                highlight "${#updates[@]} 個のツールに更新があります"
            else
                success "すべてのツールが最新版です"
            fi
            ;;
    esac
    
    return 0
}

# 特定ツールの詳細チェック
check_single_tool() {
    local tool_name="$1"
    
    local current_version
    local github_repo
    
    current_version=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "current_version")
    github_repo=$(get_yaml_value "$CONFIG_FILE" "$tool_name" "github_repo")
    
    if [[ -z "$github_repo" ]]; then
        error "ツール '$tool_name' が設定に見つかりません"
        return 1
    fi
    
    info "詳細チェック: $tool_name"
    echo "  現在のバージョン: $current_version"
    echo "  GitHubリポジトリ: $github_repo"
    
    local latest_version
    latest_version=$(get_github_latest_version "$github_repo")
    echo "  最新バージョン: $latest_version"
    
    local comparison
    comparison=$(version_compare "$current_version" "$latest_version")
    
    case "$comparison" in
        "github_newer")
            highlight "  ステータス: 更新が利用可能"
            echo "  リリースページ: https://github.com/$github_repo/releases"
            ;;
        "equal")
            success "  ステータス: 最新版です"
            ;;
        "package_newer")
            info "  ステータス: ローカル版の方が新しい"
            ;;
        "unknown")
            warn "  ステータス: 比較できませんでした"
            ;;
    esac
}

# ヘルプ表示
show_help() {
    cat << EOF
バージョンチェッカー - GitHub API監視ツール

使用法:
    $0 [オプション]

オプション:
    --check-all                  すべてのツールをチェック
    --check <tool>               特定のツールをチェック
    --category <category>        特定カテゴリのみチェック
    --output-format <format>     出力形式 (table, json)
    --clear-cache                キャッシュをクリア
    --help                       このヘルプを表示

例:
    $0 --check-all
    $0 --check-all --output-format=json
    $0 --check kubectl
    $0 --category kubernetes
    $0 --clear-cache

カテゴリ:
    kubernetes, infrastructure, cli, development, containers, runtime, ai

EOF
}

# メイン処理
main() {
    init
    
    case "${1:-}" in
        --check-all)
            check_updates "${2:-table}" "${3:-all}"
            ;;
        --check)
            if [[ -z "${2:-}" ]]; then
                error "ツール名を指定してください"
                exit 1
            fi
            check_single_tool "$2"
            ;;
        --category)
            if [[ -z "${2:-}" ]]; then
                error "カテゴリを指定してください"
                exit 1
            fi
            check_updates "table" "$2"
            ;;
        --output-format)
            error "--output-format は --check-all と組み合わせて使用してください"
            exit 1
            ;;
        --clear-cache)
            rm -f "$CACHE_FILE"
            success "キャッシュをクリアしました"
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