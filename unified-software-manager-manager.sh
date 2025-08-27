#!/bin/bash

# Unified Software Manager Manager
# 統合ソフトウェア管理ツール管理ツール - YAMLファイルでプログラム情報を管理

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.unified-software-manager-manager"
DATA_FILE="$CONFIG_DIR/programs.yaml"
LOG_FILE="$CONFIG_DIR/update.log"

# YAML処理関数（内蔵）
yaml_list_section() {
    local yaml_file="$1"
    local section="$2"
    
    awk -v section="$section" '
    BEGIN { in_section = 0; section_indent = -1 }
    /^[[:space:]]*[^#[:space:]]/ {
        match($0, /^[[:space:]]*/); 
        indent = RLENGTH
        
        gsub(/^[[:space:]]*/, "")
        gsub(/:.*$/, "")
        
        if (indent == 0 && $0 == section) {
            in_section = 1
            section_indent = 0
        } else if (in_section) {
            if (indent <= section_indent && section_indent >= 0) {
                in_section = 0
            } else if (indent == 2) {
                print $0
            }
        }
    }' "$yaml_file"
}

# YAML値取得（簡易版）
get_program_value() {
    local prog_name="$1"
    local field="$2"
    local yaml_file="$DATA_FILE"
    
    # プログラム名の後の該当フィールドを探す
    awk -v prog="$prog_name" -v field="$field" '
    /^[[:space:]]*'"$prog_name"':[[:space:]]*$/ { in_prog=1; next }
    in_prog && /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$/ { 
        if (!/^[[:space:]]{4}/) in_prog=0 
    }
    in_prog && /^[[:space:]]{4}'"$field"':[[:space:]]/ {
        sub(/^[[:space:]]*'"$field"':[[:space:]]*/, "")
        gsub(/^"/, ""); gsub(/"$/, "")
        print
        exit
    }
    ' "$yaml_file"
}

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 初期化
init() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        info "設定ディレクトリを作成: $CONFIG_DIR"
    fi
    
    if [[ ! -f "$DATA_FILE" ]]; then
        cat > "$DATA_FILE" << 'EOF'
# プログラム管理データベース
# 最終更新: 自動生成

metadata:
  last_scan: ""
  total_programs: 0
  created_at: ""

statistics:
  apt: 0
  snap: 0
  npm: 0
  git: 0
  manual: 0
  unknown: 0

programs: {}
EOF
        info "YAMLデータファイルを初期化: $DATA_FILE"
    fi
}

# プログラムスキャン（シンプル版）
scan_programs() {
    info "プログラムスキャンを開始..."
    
    # 一時的なスキャン結果
    local temp_file
    temp_file=$(mktemp)
    
    # PATH内の主要ディレクトリをスキャン
    local scan_dirs=("/usr/bin" "/usr/local/bin" "/bin")
    local count=0
    
    for dir in "${scan_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            info "  スキャン中: $dir"
            
            # 実行ファイルを検出（最初の50個まで）
            find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | head -50 | while IFS= read -r file; do
                local name
                name=$(basename "$file")
                local category="unknown"
                local package_name="none"
                local version="unknown"
                
                # パッケージマネージャー判定
                if dpkg -S "$file" >/dev/null 2>&1; then
                    category="apt"
                    package_name=$(dpkg -S "$file" 2>/dev/null | cut -d: -f1)
                elif [[ "$file" =~ /snap/ ]]; then
                    category="snap"
                elif [[ "$file" =~ /usr/local/ ]]; then
                    category="manual"
                fi
                
                # バージョン取得試行
                if command -v "$name" >/dev/null 2>&1; then
                    version=$("$name" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown")
                fi
                
                echo "$name|$file|$category|$package_name|$version" >> "$temp_file"
                count=$((count + 1))
            done
        fi
    done
    
    # YAMLファイルを更新
    update_yaml_from_scan "$temp_file" "$count"
    rm -f "$temp_file"
    
    success "スキャン完了: $count 個のプログラムを検出"
}

# スキャン結果をYAMLに反映
update_yaml_from_scan() {
    local scan_file="$1"
    local total_count="$2"
    
    # YAMLファイルを再構築
    cat > "$DATA_FILE" << EOF
# プログラム管理データベース
# 最終更新: $(date -Iseconds)

metadata:
  last_scan: "$(date -Iseconds)"
  total_programs: $total_count
  created_at: "$(date -Iseconds)"

statistics:
EOF

    # 統計情報を追加
    local apt_count
    apt_count=$(grep -c "|apt|" "$scan_file" 2>/dev/null || echo 0)
    local snap_count
    snap_count=$(grep -c "|snap|" "$scan_file" 2>/dev/null || echo 0)
    local manual_count
    manual_count=$(grep -c "|manual|" "$scan_file" 2>/dev/null || echo 0)
    local unknown_count
    unknown_count=$(grep -c "|unknown|" "$scan_file" 2>/dev/null || echo 0)
    
    cat >> "$DATA_FILE" << EOF
  apt: $apt_count
  snap: $snap_count
  manual: $manual_count
  unknown: $unknown_count

programs:
EOF

    # プログラム情報を追加
    while IFS='|' read -r name path category package version; do
        if [[ -n "$name" ]]; then
            cat >> "$DATA_FILE" << EOF
  $name:
    path: "$path"
    category: "$category"
    package: "$package"
    version: "$version"
    last_checked: "$(date -Iseconds)"
    update_method: "$(get_update_method "$category" "$name")"
EOF
        fi
    done < "$scan_file"
}

# 更新方法を決定
get_update_method() {
    local category="$1"
    local name="$2"
    
    case "$category" in
        "apt") echo "apt upgrade $name" ;;
        "snap") echo "snap refresh $name" ;;
        "manual") echo "manual update required" ;;
        *) echo "unknown" ;;
    esac
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
    
    # プログラム名の一覧を取得
    local programs
    programs=$(yaml_list_section "$DATA_FILE" "programs")
    
    if [[ -z "$programs" ]]; then
        warn "プログラムが登録されていません"
        return 0
    fi
    
    echo "$programs" | sort | uniq | while IFS= read -r prog_name; do
        if [[ -n "$prog_name" ]]; then
            local prog_category
            prog_category=$(get_program_value "$prog_name" "category")
            local prog_path
            prog_path=$(get_program_value "$prog_name" "path")
            local prog_version
            prog_version=$(get_program_value "$prog_name" "version")
            
            if [[ "$category" == "all" || "$prog_category" == "$category" ]]; then
                echo "$prog_name [$prog_category] $prog_version - $prog_path"
            fi
        fi
    done
}

# 統計情報表示
show_statistics() {
    if [[ ! -f "$DATA_FILE" ]]; then
        error "データファイルが見つかりません"
        return 1
    fi
    
    info "プログラム管理統計:"
    echo "  APT管理: $(grep "^[[:space:]]*apt:" "$DATA_FILE" | sed 's/.*: //' | head -1)"
    echo "  Snap管理: $(grep "^[[:space:]]*snap:" "$DATA_FILE" | sed 's/.*: //' | head -1)"
    echo "  手動インストール: $(grep "^[[:space:]]*manual:" "$DATA_FILE" | sed 's/.*: //' | head -1)"
    echo "  不明: $(grep "^[[:space:]]*unknown:" "$DATA_FILE" | sed 's/.*: //' | head -1)"
    echo "  合計: $(grep "^[[:space:]]*total_programs:" "$DATA_FILE" | sed 's/.*: //')"
    echo "  最終スキャン: $(grep "^[[:space:]]*last_scan:" "$DATA_FILE" | sed 's/.*: //' | sed 's/"//g')"
}

# 更新チェック
check_updates() {
    info "更新チェックを実行中..."
    
    if command -v apt >/dev/null 2>&1; then
        info "APTパッケージの更新をチェック..."
        apt list --upgradable 2>/dev/null | grep -v "Listing..." | head -10
    fi
    
    if command -v snap >/dev/null 2>&1; then
        info "Snapパッケージの更新をチェック..."
        snap refresh --list 2>/dev/null || true
    fi
}

# ヘルプ表示
show_help() {
    cat << EOF
Unified Software Manager Manager - 統合ソフトウェア管理ツール管理ツール

使用法:
    $0 [オプション]

オプション:
    --scan              プログラムをスキャンしてYAMLに保存
    --full-scan         詳細スキャン（YAML版検出スクリプト使用）
    --list [category]   プログラム一覧表示
    --stats             統計情報表示
    --check-updates     更新可能プログラムをチェック
    --help              このヘルプを表示
    --generate-monitoring  GitHub Dependabot監視ファイルを生成
    --auto-update          自動更新PR作成システムの実行
    --check-versions       バージョンチェッカーを実行

例:
    $0 --scan
    $0 --list apt
    $0 --stats
    $0 --check-updates
    $0 --generate-monitoring
    $0 --auto-update
    $0 --check-versions

データファイル: $DATA_FILE

EOF
}

# メイン処理
main() {
    init
    
    case "${1:-}" in
        --scan)
            scan_programs
            ;;
        --full-scan)
            if [[ -f "$SCRIPT_DIR/detect-all-programs.sh" ]]; then
                bash "$SCRIPT_DIR/detect-all-programs.sh"
            else
                error "詳細スキャンスクリプトが見つかりません"
            fi
            ;;
        --list)
            list_programs "${2:-all}"
            ;;
        --stats)
            show_statistics
            ;;
        --check-updates)
            check_updates
            ;;
        --generate-monitoring)
            if [[ -f "$SCRIPT_DIR/dependabot-generator.sh" ]]; then
                bash "$SCRIPT_DIR/dependabot-generator.sh" --generate
            else
                error "dependabot-generator.sh が見つかりません"
            fi
            ;;
        --auto-update)
            info "自動更新PR作成システムを実行中..."
            if [[ -f "$SCRIPT_DIR/version-checker.sh" ]]; then
                # バージョンチェック実行
                bash "$SCRIPT_DIR/version-checker.sh" --check-all --output-format=json > /tmp/update-results.json
                
                if [[ -s /tmp/update-results.json ]]; then
                    info "更新が必要なツールを検出 - PR作成中..."
                    if [[ -f "$SCRIPT_DIR/pr-creator.sh" ]]; then
                        bash "$SCRIPT_DIR/pr-creator.sh" --input-file=/tmp/update-results.json
                    else
                        error "pr-creator.sh が見つかりません"
                    fi
                else
                    success "すべてのツールが最新版です"
                fi
                
                rm -f /tmp/update-results.json
            else
                error "version-checker.sh が見つかりません"
            fi
            ;;
        --check-versions)
            if [[ -f "$SCRIPT_DIR/version-checker.sh" ]]; then
                bash "$SCRIPT_DIR/version-checker.sh" --check-all "${2:-}"
            else
                error "version-checker.sh が見つかりません"
            fi
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