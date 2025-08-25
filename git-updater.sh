#!/bin/bash

# Unified Software Manager Manager - Git リポジトリ更新スクリプト
# 統合ソフトウェア管理ツール管理ツール - Gitで管理されたプログラムの更新を自動化

set -euo pipefail

CONFIG_DIR="$HOME/.unified-software-manager-manager"
DATA_FILE="$CONFIG_DIR/programs.yaml"
GIT_LOG_FILE="$CONFIG_DIR/git-updates.log"

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "WARN: $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    log "ERROR: $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$GIT_LOG_FILE"
}

# Gitリポジトリの状態チェック
check_repo_status() {
    local repo_path="$1"
    
    if [[ ! -d "$repo_path/.git" ]]; then
        echo "NOT_GIT"
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    # 作業ディレクトリの状態確認
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo "DIRTY"
        return 1
    fi
    
    # ブランチ確認
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    
    if [[ -z "$current_branch" || "$current_branch" == "HEAD" ]]; then
        echo "DETACHED"
        return 1
    fi
    
    echo "CLEAN"
    return 0
}

# リモートの更新確認
check_remote_updates() {
    local repo_path="$1"
    
    cd "$repo_path" || return 1
    
    # リモートから最新情報を取得
    if ! git fetch --quiet 2>/dev/null; then
        echo "FETCH_FAILED"
        return 1
    fi
    
    # ローカルとリモートの差分確認
    local local_commit
    local_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    
    local remote_commit
    remote_commit=$(git rev-parse '@{u}' 2>/dev/null || echo "")
    
    if [[ -z "$local_commit" || -z "$remote_commit" ]]; then
        echo "UNKNOWN"
        return 1
    fi
    
    if [[ "$local_commit" == "$remote_commit" ]]; then
        echo "UP_TO_DATE"
        return 0
    fi
    
    # 先祖確認
    if git merge-base --is-ancestor "$local_commit" "$remote_commit" 2>/dev/null; then
        echo "BEHIND"
        return 0
    elif git merge-base --is-ancestor "$remote_commit" "$local_commit" 2>/dev/null; then
        echo "AHEAD"
        return 0
    else
        echo "DIVERGED"
        return 1
    fi
}

# Git リポジトリ更新実行
update_git_repo() {
    local repo_path="$1"
    local repo_name
    repo_name=$(basename "$repo_path")
    
    info "Git更新開始: $repo_name ($repo_path)"
    
    # リポジトリ状態確認
    local repo_status
    repo_status=$(check_repo_status "$repo_path")
    
    if [[ "$repo_status" != "CLEAN" ]]; then
        error "リポジトリが更新可能な状態ではありません: $repo_status"
        return 1
    fi
    
    # リモート更新確認
    local remote_status
    remote_status=$(check_remote_updates "$repo_path")
    
    case "$remote_status" in
        "UP_TO_DATE")
            success "最新版です: $repo_name"
            return 0
            ;;
        "BEHIND")
            info "更新が利用可能です: $repo_name"
            ;;
        "AHEAD")
            warn "ローカルがリモートより進んでいます: $repo_name"
            return 0
            ;;
        "DIVERGED")
            error "ブランチが分岐しています。手動マージが必要: $repo_name"
            return 1
            ;;
        "FETCH_FAILED"|"UNKNOWN")
            error "リモート情報取得に失敗: $repo_name"
            return 1
            ;;
    esac
    
    # バックアップ作成（現在のコミット保存）
    cd "$repo_path" || return 1
    local current_commit
    current_commit=$(git rev-parse HEAD)
    
    # 更新実行
    info "  git pull 実行中..."
    if git pull --ff-only 2>&1 | tee -a "$GIT_LOG_FILE"; then
        local new_commit
        new_commit=$(git rev-parse HEAD)
        
        if [[ "$current_commit" != "$new_commit" ]]; then
            success "更新完了: $repo_name ($current_commit -> $new_commit)"
            
            # 変更ログ表示
            info "  変更内容:"
            git log --oneline "$current_commit..$new_commit" | head -10 | while IFS= read -r line; do
                echo "    $line"
            done
        else
            success "既に最新版でした: $repo_name"
        fi
        
        return 0
    else
        error "git pull に失敗: $repo_name"
        return 1
    fi
}

# ビルドが必要かチェックし実行
check_and_build() {
    local repo_path="$1"
    local repo_name
    repo_name=$(basename "$repo_path")
    
    cd "$repo_path" || return 1
    
    # ビルドファイルの存在確認
    if [[ -f "Makefile" || -f "makefile" ]]; then
        info "Makefile発見、ビルド実行: $repo_name"
        if make 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "ビルド完了: $repo_name"
        else
            error "ビルド失敗: $repo_name"
            return 1
        fi
    elif [[ -f "CMakeLists.txt" ]]; then
        info "CMake設定発見、ビルド実行: $repo_name"
        mkdir -p build && cd build
        if cmake .. && make 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "CMakeビルド完了: $repo_name"
        else
            error "CMakeビルド失敗: $repo_name"
            return 1
        fi
    elif [[ -f "configure" ]]; then
        info "autotools設定発見、ビルド実行: $repo_name"
        if ./configure && make 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "autotools ビルド完了: $repo_name"
        else
            error "autotools ビルド失敗: $repo_name"
            return 1
        fi
    elif [[ -f "package.json" ]]; then
        info "Node.js プロジェクト発見、依存関係更新: $repo_name"
        if npm install 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "npm install 完了: $repo_name"
        else
            error "npm install 失敗: $repo_name"
            return 1
        fi
    elif [[ -f "Cargo.toml" ]]; then
        info "Rust プロジェクト発見、ビルド実行: $repo_name"
        if cargo build --release 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "Cargo ビルド完了: $repo_name"
        else
            error "Cargo ビルド失敗: $repo_name"
            return 1
        fi
    elif [[ -f "setup.py" ]]; then
        info "Python プロジェクト発見、インストール実行: $repo_name"
        if python3 setup.py install --user 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "Python セットアップ完了: $repo_name"
        else
            error "Python セットアップ失敗: $repo_name"
            return 1
        fi
    elif [[ -f "go.mod" ]]; then
        info "Go プロジェクト発見、ビルド実行: $repo_name"
        if go build 2>&1 | tee -a "$GIT_LOG_FILE"; then
            success "Go ビルド完了: $repo_name"
        else
            error "Go ビルド失敗: $repo_name"
            return 1
        fi
    else
        info "ビルド設定ファイルが見つかりません: $repo_name"
    fi
    
    return 0
}

# 更新可能性チェック
check_updates_only() {
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません: $DATA_FILE"
        return 1
    fi
    
    info "Git リポジトリの更新確認中..."
    
    local git_repos
    git_repos=$(jq -r '.programs[] | select(.category == "git") | .metadata.repo_path' "$DATA_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$git_repos" ]]; then
        warn "Git管理のプログラムが見つかりません"
        return 0
    fi
    
    echo "$git_repos" | sort | uniq | while IFS= read -r repo_path; do
        if [[ -n "$repo_path" && -d "$repo_path" ]]; then
            local repo_name
            repo_name=$(basename "$repo_path")
            
            local remote_status
            remote_status=$(check_remote_updates "$repo_path")
            
            case "$remote_status" in
                "UP_TO_DATE")
                    echo "  ✓ $repo_name: 最新版"
                    ;;
                "BEHIND")
                    echo "  ⬇ $repo_name: 更新可能"
                    ;;
                "AHEAD")
                    echo "  ⬆ $repo_name: ローカルが進行"
                    ;;
                "DIVERGED")
                    echo "  ⚠ $repo_name: ブランチが分岐"
                    ;;
                *)
                    echo "  ? $repo_name: 状態不明"
                    ;;
            esac
        fi
    done
}

# 特定リポジトリ更新
update_specific_repo() {
    local target_name="$1"
    
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません: $DATA_FILE"
        return 1
    fi
    
    local repo_info
    repo_info=$(jq -r --arg name "$target_name" '.programs[] | select(.category == "git" and .name == $name) | .metadata' "$DATA_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$repo_info" || "$repo_info" == "null" ]]; then
        error "Gitプログラム '$target_name' が見つかりません"
        return 1
    fi
    
    local repo_path
    repo_path=$(echo "$repo_info" | jq -r '.repo_path')
    
    if [[ -z "$repo_path" || ! -d "$repo_path" ]]; then
        error "リポジトリパスが無効です: $repo_path"
        return 1
    fi
    
    update_git_repo "$repo_path"
    check_and_build "$repo_path"
}

# 全Git リポジトリ更新
update_all_repos() {
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません: $DATA_FILE"
        return 1
    fi
    
    info "全Git リポジトリの更新を開始..."
    
    local git_repos
    git_repos=$(jq -r '.programs[] | select(.category == "git") | .metadata.repo_path' "$DATA_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$git_repos" ]]; then
        warn "Git管理のプログラムが見つかりません"
        return 0
    fi
    
    local success_count=0
    local error_count=0
    
    while IFS= read -r repo_path; do
        if [[ -n "$repo_path" && -d "$repo_path" ]]; then
            if update_git_repo "$repo_path"; then
                check_and_build "$repo_path"
                success_count=$((success_count + 1))
            else
                error_count=$((error_count + 1))
            fi
        fi
    done < <(echo "$git_repos" | sort | uniq)
    
    success "Git更新完了: 成功 $success_count 件、エラー $error_count 件"
}

# ヘルプ表示
show_help() {
    cat << EOF
Unified Software Manager Manager - Git リポジトリ更新管理ツール

使用法:
    $0 [オプション] [引数]

オプション:
    --check-only        更新可能性のみチェック
    --update <name>     特定のプログラムを更新
    --update-all        全Git リポジトリを更新
    --help              このヘルプを表示

例:
    $0 --check-only
    $0 --update myapp
    $0 --update-all

EOF
}

# メイン処理
main() {
    # ログディレクトリ作成
    mkdir -p "$CONFIG_DIR"
    
    case "${1:-}" in
        --check-only)
            check_updates_only
            ;;
        --update)
            if [[ -z "${2:-}" ]]; then
                error "更新するプログラム名を指定してください"
                exit 1
            fi
            update_specific_repo "$2"
            ;;
        --update-all)
            update_all_repos
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

# Git の存在チェック
if ! command -v git >/dev/null 2>&1; then
    error "git が必要です。インストールしてください: sudo apt install git"
    exit 1
fi

# YAML版では jq は不要
# if ! command -v jq >/dev/null 2>&1; then
#     error "jq が必要です。インストールしてください: sudo apt install jq"
#     exit 1
# fi

main "$@"