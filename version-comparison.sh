#!/bin/bash

# Unified Software Manager Manager - バージョン比較スクリプト
# GitHubリリース vs パッケージマネージャーのバージョン差を検出

set -euo pipefail

CONFIG_DIR="$HOME/.unified-software-manager-manager"
DATA_FILE="$CONFIG_DIR/programs.yaml"
VERSION_CACHE="$CONFIG_DIR/version-cache.txt"

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
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1"
}

# GitHub API レート制限対策のためのキャッシュ
get_cached_version() {
    local repo="$1"
    local cache_time=3600  # 1時間キャッシュ
    
    if [[ -f "$VERSION_CACHE" ]]; then
        local cached_line
        cached_line=$(grep "^$repo:" "$VERSION_CACHE" 2>/dev/null || echo "")
        
        if [[ -n "$cached_line" ]]; then
            local cached_time
            cached_time=$(echo "$cached_line" | cut -d: -f3)
            local current_time
            current_time=$(date +%s)
            
            if [[ $((current_time - cached_time)) -lt $cache_time ]]; then
                echo "$cached_line" | cut -d: -f2
                return 0
            fi
        fi
    fi
    
    return 1
}

# GitHub APIでリリース情報取得
get_github_latest_version() {
    local repo="$1"
    
    # キャッシュチェック
    local cached_version
    if cached_version=$(get_cached_version "$repo"); then
        echo "$cached_version"
        return 0
    fi
    
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s "$api_url" 2>/dev/null || echo "")
        
        if [[ -n "$response" && "$response" != *"rate limit"* && "$response" != *"Not Found"* ]]; then
            # tag_nameからバージョン取得
            local version
            version=$(echo "$response" | grep '"tag_name":' | head -1 | sed 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/')
            
            if [[ -n "$version" && "$version" != "null" ]]; then
                # vプレフィックスを除去
                version=$(echo "$version" | sed 's/^v//')
                
                # キャッシュに保存
                local current_time
                current_time=$(date +%s)
                grep -v "^$repo:" "$VERSION_CACHE" > "$VERSION_CACHE.tmp" 2>/dev/null || touch "$VERSION_CACHE.tmp"
                echo "$repo:$version:$current_time" >> "$VERSION_CACHE.tmp"
                mv "$VERSION_CACHE.tmp" "$VERSION_CACHE"
                
                echo "$version"
                return 0
            fi
        fi
    fi
    
    echo "unknown"
    return 1
}

# 既知のGitHubリポジトリマッピング
get_github_repo() {
    local program_name="$1"
    
    case "$program_name" in
        "gh") echo "cli/cli" ;;
        "docker"|"docker.io") echo "docker/cli" ;;
        "kubectl") echo "kubernetes/kubernetes" ;;
        "helm") echo "helm/helm" ;;
        "terraform") echo "hashicorp/terraform" ;;
        "vault") echo "hashicorp/vault" ;;
        "consul") echo "hashicorp/consul" ;;
        "nomad") echo "hashicorp/nomad" ;;
        "jq") echo "jqlang/jq" ;;
        "yq") echo "mikefarah/yq" ;;
        "fzf") echo "junegunn/fzf" ;;
        "bat") echo "sharkdp/bat" ;;
        "fd") echo "sharkdp/fd" ;;
        "ripgrep"|"rg") echo "BurntSushi/ripgrep" ;;
        "exa") echo "ogham/exa" ;;
        "lazygit") echo "jesseduffield/lazygit" ;;
        "delta") echo "dandavison/delta" ;;
        "hugo") echo "gohugoio/hugo" ;;
        "kind") echo "kubernetes-sigs/kind" ;;
        "k9s") echo "derailed/k9s" ;;
        "stern") echo "stern/stern" ;;
        "dive") echo "wagoodman/dive" ;;
        "ctop") echo "bcicen/ctop" ;;
        "httpie") echo "httpie/httpie" ;;
        "node"|"nodejs") echo "nodejs/node" ;;
        "golang"|"go") echo "golang/go" ;;
        "rust") echo "rust-lang/rust" ;;
        "python"|"python3") echo "python/cpython" ;;
        "ollama") echo "ollama/ollama" ;;
        "code"|"vscode") echo "microsoft/vscode" ;;
        *) echo "" ;;
    esac
}

# バージョン比較（簡易版）
version_compare() {
    local ver1="$1"
    local ver2="$2"
    
    # 両方ともunknownの場合
    if [[ "$ver1" == "unknown" && "$ver2" == "unknown" ]]; then
        echo "equal"
        return 0
    fi
    
    # どちらかがunknownの場合
    if [[ "$ver1" == "unknown" || "$ver2" == "unknown" ]]; then
        echo "unknown"
        return 0
    fi
    
    # 数値部分を抽出して比較
    local ver1_nums
    local ver2_nums
    ver1_nums=$(echo "$ver1" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0")
    ver2_nums=$(echo "$ver2" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0")
    
    if [[ "$ver1_nums" == "$ver2_nums" ]]; then
        echo "equal"
    else
        # 簡易的な比較（完全ではないが実用的）
        if [[ $(echo -e "$ver1_nums\n$ver2_nums" | sort -V | tail -1) == "$ver2_nums" ]]; then
            echo "github_newer"
        else
            echo "package_newer"
        fi
    fi
}

# インストール済みプログラムの比較
compare_versions() {
    local category_filter="${1:-all}"
    
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません: $DATA_FILE"
        error "まず unified-software-manager-manager.sh --full-scan を実行してください"
        return 1
    fi
    
    info "バージョン比較を開始..."
    info "GitHubから最新リリース情報を取得中（時間がかかる場合があります）"
    echo
    
    # プログラム一覧を取得
    local programs
    programs=$(awk '/^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$/ && !/^[[:space:]]*programs:[[:space:]]*$/ {gsub(/^[[:space:]]*/, ""); gsub(/:.*$/, ""); print}' "$DATA_FILE")
    
    local outdated_count=0
    local checked_count=0
    
    echo "プログラム名 | ローカル版 | GitHub最新版 | 状態"
    echo "------|------|------|------"
    
    while IFS= read -r prog_name; do
        if [[ -z "$prog_name" ]]; then continue; fi
        
        # プログラム情報を取得
        local prog_category
        prog_category=$(awk -v prog="$prog_name" '/^[[:space:]]*'$prog_name':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*category:[[:space:]]/ {gsub(/^[[:space:]]*category:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$DATA_FILE")
        
        # カテゴリフィルター
        if [[ "$category_filter" != "all" && "$prog_category" != "$category_filter" ]]; then
            continue
        fi
        
        # apt/snap管理のもののみ対象
        if [[ "$prog_category" != "apt" && "$prog_category" != "snap" ]]; then
            continue
        fi
        
        local prog_version
        prog_version=$(awk -v prog="$prog_name" '/^[[:space:]]*'$prog_name':[[:space:]]*$/ {found=1; next} found && /^[[:space:]]*version:[[:space:]]/ {gsub(/^[[:space:]]*version:[[:space:]]*"?/, ""); gsub(/".*$/, ""); print; exit}' "$DATA_FILE")
        
        # GitHubリポジトリ取得
        local github_repo
        github_repo=$(get_github_repo "$prog_name")
        
        if [[ -n "$github_repo" ]]; then
            checked_count=$((checked_count + 1))
            
            # GitHub最新バージョン取得
            local github_version
            github_version=$(get_github_latest_version "$github_repo")
            
            # バージョン比較
            local comparison
            comparison=$(version_compare "$prog_version" "$github_version")
            
            case "$comparison" in
                "github_newer")
                    highlight "$prog_name | $prog_version | $github_version | 🔄 GitHubの方が新しい"
                    outdated_count=$((outdated_count + 1))
                    ;;
                "package_newer")
                    echo "$prog_name | $prog_version | $github_version | ✅ パッケージが新しい"
                    ;;
                "equal")
                    echo "$prog_name | $prog_version | $github_version | ✅ 同じ"
                    ;;
                "unknown")
                    echo "$prog_name | $prog_version | $github_version | ❓ 比較不可"
                    ;;
            esac
            
            # API制限対策で少し待機
            sleep 0.5
        fi
    done <<< "$programs"
    
    echo
    success "バージョン比較完了"
    info "チェック対象: $checked_count 個のプログラム"
    if [[ $outdated_count -gt 0 ]]; then
        warn "更新が遅れている可能性: $outdated_count 個"
        echo
        info "GitHubから直接インストールを検討してみてください："
        echo "- 公式リリースページから最新版をダウンロード"
        echo "- パッケージマネージャーの更新を待つ"
        echo "- 別のパッケージソース（PPA等）を使用"
    else
        success "すべてのプログラムが最新または新しいバージョンです"
    fi
}

# 特定プログラムの詳細比較
detailed_comparison() {
    local program_name="$1"
    
    local github_repo
    github_repo=$(get_github_repo "$program_name")
    
    if [[ -z "$github_repo" ]]; then
        error "プログラム '$program_name' のGitHubリポジトリが不明です"
        return 1
    fi
    
    info "詳細バージョン比較: $program_name"
    echo "  GitHubリポジトリ: https://github.com/$github_repo"
    
    # ローカルバージョン取得
    if command -v "$program_name" >/dev/null 2>&1; then
        local local_version
        local_version=$("$program_name" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown")
        echo "  ローカル版: $local_version"
    else
        echo "  ローカル版: インストールされていません"
    fi
    
    # GitHub最新版取得
    local github_version
    github_version=$(get_github_latest_version "$github_repo")
    echo "  GitHub最新版: $github_version"
    echo "  リリースページ: https://github.com/$github_repo/releases"
}

# ヘルプ表示
show_help() {
    cat << EOF
Unified Software Manager Manager - バージョン比較ツール

使用法:
    $0 [オプション] [引数]

オプション:
    --compare [category]    バージョン比較実行 (category: all, apt, snap)
    --check <program>       特定プログラムの詳細比較
    --clear-cache           バージョンキャッシュをクリア
    --help                  このヘルプを表示

例:
    $0 --compare            # 全プログラム比較
    $0 --compare apt        # APTパッケージのみ比較
    $0 --check gh           # ghコマンドの詳細比較
    $0 --clear-cache        # キャッシュクリア

EOF
}

# メイン処理
main() {
    mkdir -p "$CONFIG_DIR"
    
    case "${1:-}" in
        --compare)
            compare_versions "${2:-all}"
            ;;
        --check)
            if [[ -z "${2:-}" ]]; then
                error "プログラム名を指定してください"
                exit 1
            fi
            detailed_comparison "$2"
            ;;
        --clear-cache)
            rm -f "$VERSION_CACHE"
            success "バージョンキャッシュをクリアしました"
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