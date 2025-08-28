#!/bin/bash
set -euo pipefail

# Unified Software Manager Manager セットアップスクリプト
# 初期設定と依存関係のインストールを行う

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.unified-software-manager-manager"

# 色付きメッセージ
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# 依存関係チェック
check_dependencies() {
    info "依存関係をチェック中..."
    
    local missing_deps=()
    
    # 必須依存関係
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    # yqは将来のYAML改善に備えて追加（現在は必須ではない）
    if ! command -v yq >/dev/null 2>&1; then
        warn "yq がインストールされていません (将来的な機能で必要になる可能性があります)"
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # 推奨依存関係
    local recommended_deps=()
    
    if ! command -v sha256sum >/dev/null 2>&1; then
        recommended_deps+=("coreutils")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "必須依存関係が不足しています: ${missing_deps[*]}"
        info "以下のコマンドでインストールしてください:"
        echo "  sudo apt update && sudo apt install ${missing_deps[*]}"
        return 1
    fi
    
    if [[ ${#recommended_deps[@]} -gt 0 ]]; then
        warn "推奨パッケージが不足しています: ${recommended_deps[*]}"
        info "以下のコマンドでインストールできます:"
        echo "  sudo apt install ${recommended_deps[*]}"
    fi
    
    success "依存関係チェック完了"
}

# 設定ディレクトリ作成
setup_directories() {
    info "設定ディレクトリを作成中..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/backups"
    mkdir -p "$CONFIG_DIR/logs"
    
    success "ディレクトリ作成完了: $CONFIG_DIR"
}

# スクリプトを実行可能にする
make_executable() {
    info "スクリプトを実行可能にしています..."
    
    local scripts=(
        "unified-software-manager-manager.sh"
        "detect-all-programs.sh"
        "git-updater.sh"
        "manual-tracker.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            chmod +x "$SCRIPT_DIR/$script"
            success "  $script を実行可能にしました"
        else
            warn "  $script が見つかりません"
        fi
    done
}

# 初期データファイル作成
create_initial_data() {
    info "初期データファイルを作成中..."
    
    local data_file="$CONFIG_DIR/programs.yaml"
    
    if [[ ! -f "$data_file" ]]; then
        cat > "$data_file" << EOF
# プログラム管理データベース
# 最終更新: $(date -Iseconds)

metadata:
  last_scan: "$(date -Iseconds)"
  total_programs: 0
  created_at: "$(date -Iseconds)"

statistics:
  apt: 0
  snap: 0
  npm: 0
  pip: 0
  git: 0
  manual: 0
  appimage: 0
  unknown: 0

programs: {}
EOF
        success "初期YAMLデータファイルを作成: $data_file"
    else
        info "YAMLデータファイルは既に存在します: $data_file"
    fi
}

# シンボリックリンク作成（オプション）
create_symlinks() {
    local create_links="$1"
    
    if [[ "$create_links" == "yes" ]]; then
        info "シンボリックリンクを作成中..."
        
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        
        # PATHに含まれているかチェック
        if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
            warn "$bin_dir がPATHに含まれていません"
            info "$HOME/.bashrc または $HOME/.zshrc に以下を追加してください:"
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
        
        # メインスクリプトのリンク作成
        if [[ -f "$SCRIPT_DIR/unified-software-manager-manager.sh" ]]; then
            ln -sf "$SCRIPT_DIR/unified-software-manager-manager.sh" "$bin_dir/unified-software-manager-manager"
            success "シンボリックリンクを作成: unified-software-manager-manager → $SCRIPT_DIR/unified-software-manager-manager.sh"
        fi
        
        # サブスクリプトのリンク作成
        local scripts=(
            "git-updater.sh:git-updater"
            "manual-tracker.sh:manual-tracker"
        )
        
        for script_info in "${scripts[@]}"; do
            IFS=':' read -r script_file link_name <<< "$script_info"
            if [[ -f "$SCRIPT_DIR/$script_file" ]]; then
                ln -sf "$SCRIPT_DIR/$script_file" "$bin_dir/$link_name"
                success "シンボリックリンクを作成: $link_name → $SCRIPT_DIR/$script_file"
            fi
        done
    fi
}

# セットアップ情報表示
show_setup_info() {
    success "Unified Software Manager Manager セットアップ完了!"
    echo
    info "使用開始手順:"
    echo "  1. 初回スキャン実行:"
    echo "     ./unified-software-manager-manager.sh --full-scan"
    echo
    echo "  2. プログラム一覧確認:"
    echo "     ./unified-software-manager-manager.sh --list"
    echo
    echo "  3. 更新チェック:"
    echo "     ./unified-software-manager-manager.sh --check-updates"
    echo
    echo "  4. 統計情報確認:"
    echo "     ./unified-software-manager-manager.sh --stats"
    echo
    info "詳細な使用方法は README.md をご確認ください。"
}

# 使用方法表示
show_help() {
    cat << EOF
Unified Software Manager Manager セットアップスクリプト

使用法:
    $0 [オプション]

オプション:
    --symlinks      シンボリックリンクを ~/.local/bin に作成
    --check-only    依存関係チェックのみ実行
    --help          このヘルプを表示

例:
    $0                  # 標準セットアップ
    $0 --symlinks       # シンボリックリンクも作成
    $0 --check-only     # 依存関係チェックのみ

EOF
}

# メイン処理
main() {
    echo "=========================================="
    echo "Unified Software Manager Manager セットアップ"
    echo "=========================================="
    echo
    
    case "${1:-}" in
        --help)
            show_help
            exit 0
            ;;
        --check-only)
            check_dependencies
            exit $?
            ;;
        --symlinks)
            check_dependencies || exit 1
            setup_directories
            make_executable
            create_initial_data
            create_symlinks "yes"
            show_setup_info
            ;;
        "")
            check_dependencies || exit 1
            setup_directories
            make_executable
            create_initial_data
            create_symlinks "no"
            show_setup_info
            ;;
        *)
            error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"