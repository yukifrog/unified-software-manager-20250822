#!/bin/bash

# 手動インストール追跡スクリプト
# 手動でインストールされたプログラムの更新情報を追跡・管理

set -euo pipefail

CONFIG_DIR="$HOME/.update-manager"
DATA_FILE="$CONFIG_DIR/programs.json"
MANUAL_CONFIG="$CONFIG_DIR/manual-config.json"
CHECKSUM_FILE="$CONFIG_DIR/checksums.txt"

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 手動管理設定ファイル初期化
init_manual_config() {
    if [[ ! -f "$MANUAL_CONFIG" ]]; then
        cat > "$MANUAL_CONFIG" << 'EOF'
{
  "update_sources": {
    "github_releases": [
      {
        "name": "docker",
        "repo": "docker/docker-ce",
        "binary_pattern": "docker-.*-linux.*\\.tgz"
      },
      {
        "name": "kubectl",
        "repo": "kubernetes/kubernetes",
        "binary_pattern": "kubectl"
      },
      {
        "name": "helm",
        "repo": "helm/helm",
        "binary_pattern": "helm-.*-linux.*\\.tar\\.gz"
      },
      {
        "name": "terraform",
        "repo": "hashicorp/terraform",
        "binary_pattern": "terraform_.*_linux.*\\.zip"
      }
    ],
    "direct_download": [
      {
        "name": "ollama",
        "url": "https://ollama.ai/install.sh",
        "install_method": "curl -fsSL https://ollama.ai/install.sh | sh"
      }
    ],
    "custom_update_commands": []
  },
  "tracking": {
    "check_interval_days": 7,
    "auto_backup": true,
    "notify_updates": true
  }
}
EOF
        info "手動管理設定ファイルを初期化: $MANUAL_CONFIG"
    fi
}

# ファイルのチェックサム計算
calculate_checksum() {
    local file_path="$1"
    
    if [[ -f "$file_path" ]]; then
        sha256sum "$file_path" 2>/dev/null | cut -d' ' -f1
    else
        echo "FILE_NOT_FOUND"
    fi
}

# チェックサム記録
record_checksum() {
    local program_name="$1"
    local file_path="$2"
    local checksum="$3"
    
    # 既存レコード削除
    if [[ -f "$CHECKSUM_FILE" ]]; then
        grep -v "^$program_name:" "$CHECKSUM_FILE" > "$CHECKSUM_FILE.tmp" 2>/dev/null || touch "$CHECKSUM_FILE.tmp"
        mv "$CHECKSUM_FILE.tmp" "$CHECKSUM_FILE"
    fi
    
    # 新しいチェックサム追加
    echo "$program_name:$file_path:$checksum:$(date -Iseconds)" >> "$CHECKSUM_FILE"
}

# チェックサム変更チェック
check_checksum_changed() {
    local program_name="$1"
    local file_path="$2"
    
    if [[ ! -f "$CHECKSUM_FILE" ]]; then
        echo "NEW"
        return 0
    fi
    
    local stored_info
    stored_info=$(grep "^$program_name:" "$CHECKSUM_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$stored_info" ]]; then
        echo "NEW"
        return 0
    fi
    
    local stored_checksum
    stored_checksum=$(echo "$stored_info" | cut -d':' -f3)
    
    local current_checksum
    current_checksum=$(calculate_checksum "$file_path")
    
    if [[ "$stored_checksum" != "$current_checksum" ]]; then
        echo "CHANGED"
    else
        echo "UNCHANGED"
    fi
}

# GitHub API経由でリリース情報取得
get_github_release_info() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    # レート制限対策のためにcurlを使用
    if command -v curl >/dev/null 2>&1; then
        curl -s "$api_url" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# 手動インストールプログラムの更新チェック
check_manual_program_updates() {
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません: $DATA_FILE"
        return 1
    fi
    
    info "手動インストールプログラムの更新をチェック中..."
    
    # 手動カテゴリのプログラムを取得
    local manual_programs
    manual_programs=$(jq -r '.programs[] | select(.category == "manual") | "\(.name):\(.path)"' "$DATA_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$manual_programs" ]]; then
        warn "手動インストールプログラムが見つかりません"
        return 0
    fi
    
    echo "$manual_programs" | while IFS=':' read -r name path; do
        info "  チェック中: $name"
        
        # ファイル変更チェック
        local checksum_status
        checksum_status=$(check_checksum_changed "$name" "$path")
        
        case "$checksum_status" in
            "NEW")
                info "    新規追跡開始"
                local current_checksum
                current_checksum=$(calculate_checksum "$path")
                record_checksum "$name" "$path" "$current_checksum"
                ;;
            "CHANGED")
                warn "    ファイルが変更されています（更新済み可能性あり）"
                local current_checksum
                current_checksum=$(calculate_checksum "$path")
                record_checksum "$name" "$path" "$current_checksum"
                ;;
            "UNCHANGED")
                info "    変更なし"
                ;;
        esac
        
        # 設定ファイルに基づく更新チェック
        check_configured_updates "$name" "$path"
    done
}

# 設定された更新ソースをチェック
check_configured_updates() {
    local program_name="$1"
    local program_path="$2"
    
    # GitHub releases チェック
    local github_config
    github_config=$(jq -r --arg name "$program_name" '.update_sources.github_releases[] | select(.name == $name)' "$MANUAL_CONFIG" 2>/dev/null || echo "")
    
    if [[ -n "$github_config" && "$github_config" != "null" ]]; then
        local repo
        repo=$(echo "$github_config" | jq -r '.repo')
        
        info "    GitHub更新チェック: $repo"
        
        local release_info
        release_info=$(get_github_release_info "$repo")
        
        if [[ -n "$release_info" && "$release_info" != "{}" ]]; then
            local latest_version
            latest_version=$(echo "$release_info" | jq -r '.tag_name // .name // "unknown"')
            
            if [[ "$latest_version" != "unknown" ]]; then
                # 現在のバージョン取得試行
                local current_version
                current_version=$("$program_path" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 2>/dev/null || echo "unknown")
                
                info "    現在版: $current_version, 最新版: $latest_version"
                
                if [[ "$current_version" != "unknown" && "$current_version" != "$latest_version" ]]; then
                    warn "    ★ 更新可能: $current_version → $latest_version"
                    
                    # ダウンロードURL情報表示
                    local download_url
                    download_url=$(echo "$release_info" | jq -r '.assets[0].browser_download_url // .tarball_url // "manual_download_required"')
                    info "    ダウンロードURL: $download_url"
                fi
            fi
        fi
    fi
    
    # 直接ダウンロード設定チェック
    local direct_config
    direct_config=$(jq -r --arg name "$program_name" '.update_sources.direct_download[] | select(.name == $name)' "$MANUAL_CONFIG" 2>/dev/null || echo "")
    
    if [[ -n "$direct_config" && "$direct_config" != "null" ]]; then
        local update_url
        update_url=$(echo "$direct_config" | jq -r '.url')
        
        local install_method
        install_method=$(echo "$direct_config" | jq -r '.install_method')
        
        info "    直接更新可能"
        info "    更新コマンド: $install_method"
    fi
}

# 手動プログラム追加
add_manual_program() {
    local program_path="$1"
    local update_source="${2:-}"
    
    if [[ ! -f "$program_path" || ! -x "$program_path" ]]; then
        error "実行可能ファイルが見つかりません: $program_path"
        return 1
    fi
    
    local program_name
    program_name=$(basename "$program_path")
    
    info "手動プログラムを追加: $program_name"
    
    # チェックサム記録
    local checksum
    checksum=$(calculate_checksum "$program_path")
    record_checksum "$program_name" "$program_path" "$checksum"
    
    # 更新ソース設定
    if [[ -n "$update_source" ]]; then
        case "$update_source" in
            github:*)
                local repo
                repo=${update_source#github:}
                add_github_source "$program_name" "$repo"
                ;;
            url:*)
                local url
                url=${update_source#url:}
                add_direct_source "$program_name" "$url"
                ;;
        esac
    fi
    
    success "手動プログラム追加完了: $program_name"
}

# GitHub更新ソース追加
add_github_source() {
    local program_name="$1"
    local repo="$2"
    
    local new_source
    new_source=$(jq -n \
        --arg name "$program_name" \
        --arg repo "$repo" \
        '{name: $name, repo: $repo, binary_pattern: ($name + ".*")}'
    )
    
    jq --argjson source "$new_source" \
       '.update_sources.github_releases += [$source]' \
       "$MANUAL_CONFIG" > "$MANUAL_CONFIG.tmp" && mv "$MANUAL_CONFIG.tmp" "$MANUAL_CONFIG"
    
    success "GitHub更新ソースを追加: $program_name ($repo)"
}

# 直接ダウンロード更新ソース追加
add_direct_source() {
    local program_name="$1"
    local url="$2"
    
    local new_source
    new_source=$(jq -n \
        --arg name "$program_name" \
        --arg url "$url" \
        '{name: $name, url: $url, install_method: ("curl -L " + $url + " | bash")}'
    )
    
    jq --argjson source "$new_source" \
       '.update_sources.direct_download += [$source]' \
       "$MANUAL_CONFIG" > "$MANUAL_CONFIG.tmp" && mv "$MANUAL_CONFIG.tmp" "$MANUAL_CONFIG"
    
    success "直接ダウンロード更新ソースを追加: $program_name ($url)"
}

# バックアップ作成
backup_program() {
    local program_path="$1"
    local program_name
    program_name=$(basename "$program_path")
    
    local backup_dir="$CONFIG_DIR/backups"
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/${program_name}.$(date +%Y%m%d_%H%M%S).backup"
    
    if cp "$program_path" "$backup_file" 2>/dev/null; then
        success "バックアップ作成: $backup_file"
        
        # 古いバックアップを削除（5個以上保持しない）
        ls -1t "$backup_dir/${program_name}".*.backup 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    else
        error "バックアップ作成失敗: $program_path"
        return 1
    fi
}

# 追跡情報表示
show_tracking_info() {
    if [[ ! -f "$CHECKSUM_FILE" ]]; then
        warn "追跡情報がありません"
        return 0
    fi
    
    info "手動プログラム追跡情報:"
    echo "----------------------------------------"
    
    while IFS=':' read -r name path checksum timestamp; do
        if [[ -n "$name" ]]; then
            echo "プログラム: $name"
            echo "  パス: $path"
            echo "  チェックサム: ${checksum:0:16}..."
            echo "  記録日時: $timestamp"
            
            # 現在の状態確認
            local current_checksum
            current_checksum=$(calculate_checksum "$path")
            
            if [[ "$current_checksum" == "$checksum" ]]; then
                echo "  状態: 変更なし ✓"
            else
                echo "  状態: 変更あり ⚠"
            fi
            
            echo ""
        fi
    done < "$CHECKSUM_FILE"
}

# ヘルプ表示
show_help() {
    cat << EOF
Manual Tracker - 手動インストールプログラム追跡ツール

使用法:
    $0 [オプション] [引数]

オプション:
    --check-updates     手動プログラムの更新をチェック
    --add <path> [source]  手動プログラムを追跡対象に追加
    --backup <path>     プログラムのバックアップ作成
    --show-tracking     追跡情報を表示
    --init-config       設定ファイルを初期化
    --help              このヘルプを表示

更新ソースの指定方法:
    github:owner/repo   GitHub リリースから更新
    url:https://...     指定URLから更新

例:
    $0 --check-updates
    $0 --add /usr/local/bin/myapp
    $0 --add /usr/local/bin/kubectl github:kubernetes/kubernetes
    $0 --backup /usr/local/bin/myapp
    $0 --show-tracking

EOF
}

# メイン処理
main() {
    # 設定ディレクトリ作成
    mkdir -p "$CONFIG_DIR"
    
    # 設定ファイル初期化
    init_manual_config
    
    case "${1:-}" in
        --check-updates)
            check_manual_program_updates
            ;;
        --add)
            if [[ -z "${2:-}" ]]; then
                error "プログラムパスを指定してください"
                exit 1
            fi
            add_manual_program "$2" "${3:-}"
            ;;
        --backup)
            if [[ -z "${2:-}" ]]; then
                error "バックアップするプログラムパスを指定してください"
                exit 1
            fi
            backup_program "$2"
            ;;
        --show-tracking)
            show_tracking_info
            ;;
        --init-config)
            rm -f "$MANUAL_CONFIG"
            init_manual_config
            success "設定ファイルを再初期化しました"
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