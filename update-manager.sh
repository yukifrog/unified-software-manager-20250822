#!/bin/bash

# Update Manager - 包括的プログラム更新管理ツール
# 全てのパッケージマネージャー、手動インストール、Gitリポジトリ等を統合管理

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.update-manager"
DATA_FILE="$CONFIG_DIR/programs.json"
LOG_FILE="$CONFIG_DIR/update.log"

# 色付きメッセージ用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ出力関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "WARN: $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    log "ERROR: $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

# 初期化
init() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        info "設定ディレクトリを作成: $CONFIG_DIR"
    fi
    
    if [[ ! -f "$DATA_FILE" ]]; then
        echo '{"programs": [], "last_scan": "", "categories": {}}' > "$DATA_FILE"
        info "データファイルを初期化: $DATA_FILE"
    fi
}

# 全プログラムスキャン
scan_all() {
    info "全プログラムのスキャンを開始..."
    
    # サブスクリプト実行
    if [[ -f "$SCRIPT_DIR/detect-all-programs.sh" ]]; then
        bash "$SCRIPT_DIR/detect-all-programs.sh"
    else
        warn "detect-all-programs.sh が見つかりません"
    fi
    
    if [[ -f "$SCRIPT_DIR/classify-update-method.sh" ]]; then
        bash "$SCRIPT_DIR/classify-update-method.sh"
    else
        warn "classify-update-method.sh が見つかりません"
    fi
    
    # 最終スキャン時刻を記録
    jq --arg date "$(date -Iseconds)" '.last_scan = $date' "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    success "スキャン完了"
}

# プログラム一覧表示
list_programs() {
    local category="${1:-all}"
    
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません。まず --scan を実行してください"
        return 1
    fi
    
    info "プログラム一覧 (カテゴリ: $category)"
    echo "----------------------------------------"
    
    if [[ "$category" == "all" ]]; then
        jq -r '.programs[] | "\(.name) [\(.category)] - \(.path)"' "$DATA_FILE"
    else
        jq -r --arg cat "$category" '.programs[] | select(.category == $cat) | "\(.name) [\(.category)] - \(.path)"' "$DATA_FILE"
    fi
}

# カテゴリ一覧表示
list_categories() {
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません。まず --scan を実行してください"
        return 1
    fi
    
    info "利用可能なカテゴリ:"
    jq -r '.programs[].category' "$DATA_FILE" | sort | uniq -c | sort -nr
}

# 更新チェック
check_updates() {
    info "更新可能なプログラムをチェック中..."
    
    # パッケージマネージャー系
    check_apt_updates
    check_snap_updates
    check_npm_updates
    
    # Git リポジトリ
    if [[ -f "$SCRIPT_DIR/git-updater.sh" ]]; then
        bash "$SCRIPT_DIR/git-updater.sh" --check-only
    fi
}

# APT更新チェック
check_apt_updates() {
    if command -v apt >/dev/null 2>&1; then
        info "APTパッケージの更新をチェック中..."
        apt list --upgradable 2>/dev/null | grep -v "Listing..." | head -10
    fi
}

# Snap更新チェック
check_snap_updates() {
    if command -v snap >/dev/null 2>&1; then
        info "Snapパッケージの更新をチェック中..."
        snap refresh --list 2>/dev/null || true
    fi
}

# NPM更新チェック
check_npm_updates() {
    if command -v npm >/dev/null 2>&1; then
        info "NPMグローバルパッケージの更新をチェック中..."
        npm outdated -g --depth=0 2>/dev/null || true
    fi
}

# プログラム更新実行
update_program() {
    local target="$1"
    
    if [[ "$target" == "all" ]]; then
        update_all
    else
        # 特定プログラムの更新
        local program_info
        program_info=$(jq -r --arg name "$target" '.programs[] | select(.name == $name)' "$DATA_FILE")
        
        if [[ -z "$program_info" ]]; then
            error "プログラム '$target' が見つかりません"
            return 1
        fi
        
        local category
        category=$(echo "$program_info" | jq -r '.category')
        
        case "$category" in
            "apt")
                sudo apt update && sudo apt upgrade "$target" -y
                ;;
            "snap")
                sudo snap refresh "$target"
                ;;
            "npm")
                npm update -g "$target"
                ;;
            "git")
                if [[ -f "$SCRIPT_DIR/git-updater.sh" ]]; then
                    bash "$SCRIPT_DIR/git-updater.sh" --update "$target"
                fi
                ;;
            "manual")
                warn "手動インストールプログラム '$target' は手動で更新する必要があります"
                ;;
            *)
                warn "未知のカテゴリ '$category' です"
                ;;
        esac
    fi
}

# 全プログラム更新
update_all() {
    info "全プログラムの更新を開始..."
    
    # APT
    if command -v apt >/dev/null 2>&1; then
        info "APTパッケージを更新中..."
        sudo apt update && sudo apt upgrade -y
    fi
    
    # Snap
    if command -v snap >/dev/null 2>&1; then
        info "Snapパッケージを更新中..."
        sudo snap refresh
    fi
    
    # NPM
    if command -v npm >/dev/null 2>&1; then
        info "NPMグローバルパッケージを更新中..."
        npm update -g
    fi
    
    # Git repositories
    if [[ -f "$SCRIPT_DIR/git-updater.sh" ]]; then
        bash "$SCRIPT_DIR/git-updater.sh" --update-all
    fi
    
    success "全プログラムの更新完了"
}

# 手動プログラム追加
add_manual() {
    local path="$1"
    local name
    name=$(basename "$path")
    
    if [[ ! -f "$path" || ! -x "$path" ]]; then
        error "実行可能ファイルが見つかりません: $path"
        return 1
    fi
    
    # データファイルに追加
    jq --arg name "$name" --arg path "$path" --arg category "manual" \
       '.programs += [{"name": $name, "path": $path, "category": $category, "added": now|todate}]' \
       "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    
    success "手動プログラムを追加: $name ($path)"
}

# ヘルプ表示
show_help() {
    cat << EOF
Update Manager - 包括的プログラム更新管理ツール

使用法:
    $0 [オプション]

オプション:
    --scan              全プログラムをスキャン
    --list [category]   プログラム一覧表示 (category: all, apt, snap, npm, git, manual)
    --categories        利用可能なカテゴリ一覧
    --check-updates     更新可能なプログラムをチェック
    --update <target>   プログラム更新 (target: all または プログラム名)
    --add-manual <path> 手動インストールプログラムを追加
    --help              このヘルプを表示

例:
    $0 --scan
    $0 --list apt
    $0 --check-updates
    $0 --update all
    $0 --add-manual /usr/local/bin/myapp

EOF
}

# メイン処理
main() {
    init
    
    case "${1:-}" in
        --scan)
            scan_all
            ;;
        --list)
            list_programs "${2:-all}"
            ;;
        --categories)
            list_categories
            ;;
        --check-updates)
            check_updates
            ;;
        --update)
            if [[ -z "${2:-}" ]]; then
                error "更新対象を指定してください"
                exit 1
            fi
            update_program "$2"
            ;;
        --add-manual)
            if [[ -z "${2:-}" ]]; then
                error "プログラムパスを指定してください"
                exit 1
            fi
            add_manual "$2"
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

# jqの存在チェック
if ! command -v jq >/dev/null 2>&1; then
    error "jq が必要です。インストールしてください: sudo apt install jq"
    exit 1
fi

main "$@"