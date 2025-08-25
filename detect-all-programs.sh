#!/bin/bash

# Unified Software Manager Manager - 全実行ファイル検出スクリプト
# 統合ソフトウェア管理ツール管理ツール - システム内のすべての実行可能プログラムをYAMLで管理

set -euo pipefail

CONFIG_DIR="$HOME/.unified-software-manager-manager"
DATA_FILE="$CONFIG_DIR/programs.yaml"

# 色付きメッセージ
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# YAML初期構造作成
init_yaml() {
    cat > "$DATA_FILE" << EOF
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

programs:
EOF
}

# PATH内の実行ファイルをスキャン
scan_path_executables() {
    info "PATH内の実行ファイルをスキャン中..."
    local count=0
    local temp_results
    temp_results=$(mktemp)
    
    # エラー時の一時ファイル削除を保証
    trap 'rm -f "$temp_results"' EXIT ERR
    
    # PATH を分割してスキャン
    while IFS= read -r dir; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            info "  スキャン中: $dir"
            
            while IFS= read -r file; do
                local name
                name=$(basename "$file")
                
                # ファイル存在・権限チェック
                [[ ! -f "$file" || ! -r "$file" ]] && continue
                
                local category="unknown"
                local package_name="none"
                local version="unknown"
                
                # パッケージマネージャー判定  
                if [[ -f "$file" && -x "$file" ]] && dpkg -S "$file" >/dev/null 2>&1; then
                    category="apt"
                    package_name=$(dpkg -S "$file" 2>/dev/null | cut -d: -f1)
                    [[ -z "$package_name" ]] && package_name="unknown"
                elif [[ "$file" =~ /snap/ ]]; then
                    category="snap"
                elif [[ "$file" =~ /usr/local/ ]]; then
                    category="manual"
                elif [[ "$file" =~ /.local/bin/ ]]; then
                    # pip/npm/gem などの可能性
                    if command -v pip >/dev/null 2>&1 && pip show "$name" >/dev/null 2>&1; then
                        category="pip"
                        package_name="$name"
                    elif command -v npm >/dev/null 2>&1 && npm list -g "$name" >/dev/null 2>&1; then
                        category="npm"
                        package_name="$name"
                    else
                        category="user"
                    fi
                elif [[ "$file" =~ /.nvm/ ]]; then
                    category="nvm"
                elif [[ "$file" =~ /.asdf/ ]]; then
                    category="asdf"
                fi
                
                # バージョン取得試行（セキュリティ向上）
                if [[ -f "$file" && -x "$file" ]]; then
                    version=$("$file" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 2>/dev/null || echo "unknown")
                fi
                
                echo "$name|$file|$category|$package_name|$version" >> "$temp_results"
                count=$((count + 1))
            done < <(find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | head -30)
        fi
    done < <(echo "$PATH" | tr ':' '\n')
    
    # 結果をYAMLに追加
    add_programs_to_yaml "$temp_results" "$count"
    rm -f "$temp_results"
    trap - EXIT ERR
    
    success "PATH内のスキャン完了: $count 個検出"
}

# 手動インストールディレクトリスキャン
scan_manual_installs() {
    info "手動インストールプログラムをスキャン中..."
    
    local manual_dirs=(
        "/usr/local/bin"
        "/opt"
        "$HOME/.local/bin"
        "$HOME/bin"
    )
    
    local temp_results
    temp_results=$(mktemp)
    local count=0
    
    for dir in "${manual_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            info "  手動インストールディレクトリをスキャン: $dir"
            
            while IFS= read -r file; do
                local name
                name=$(basename "$file")
                
                # 重複チェック
                if ! grep -q "^$name|" "$temp_results" 2>/dev/null; then
                    local version
                    version=$("$file" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 2>/dev/null || echo "unknown")
                    echo "$name|$file|manual|none|$version" >> "$temp_results"
                    count=$((count + 1))
                fi
            done < <(find "$dir" -type f -executable 2>/dev/null)
        fi
    done
    
    # 手動プログラムをYAMLに追加
    add_manual_programs_to_yaml "$temp_results"
    rm -f "$temp_results"
    
    success "手動インストールプログラムのスキャン完了: $count 個検出"
}

# AppImageファイルを検出
scan_appimages() {
    info "AppImageファイルをスキャン中..."
    
    local appimage_paths=(
        "$HOME/Applications"
        "$HOME/Downloads"
        "$HOME/.local/bin"
        "/opt"
    )
    
    local count=0
    
    for path in "${appimage_paths[@]}"; do
        if [[ -d "$path" ]]; then
            while IFS= read -r appimage; do
                local name
                name=$(basename "$appimage" .AppImage)
                add_appimage_to_yaml "$name" "$appimage"
                count=$((count + 1))
            done < <(find "$path" -name "*.AppImage" -type f 2>/dev/null)
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        success "AppImageファイルのスキャン完了: $count 個検出"
    else
        info "AppImageファイルは見つかりませんでした"
    fi
}

# プログラムをYAMLに追加
add_programs_to_yaml() {
    local results_file="$1"
    local total_count="$2"
    
    while IFS='|' read -r name path category package version; do
        if [[ -n "$name" ]]; then
            add_program_to_yaml "$name" "$path" "$category" "$package" "$version"
        fi
    done < "$results_file"
}

# 手動プログラムをYAMLに追加
add_manual_programs_to_yaml() {
    local results_file="$1"
    
    while IFS='|' read -r name path category package version; do
        if [[ -n "$name" ]]; then
            add_program_to_yaml "$name" "$path" "manual" "none" "$version"
        fi
    done < "$results_file"
}

# 単一プログラムをYAMLに追加
add_program_to_yaml() {
    local name="$1"
    local path="$2"
    local category="$3"
    local package="$4"
    local version="$5"
    
    local update_method
    update_method=$(get_update_method "$category" "$name")
    
    cat >> "$DATA_FILE" << EOF
  $name:
    path: "$path"
    category: "$category"
    package: "$package"
    version: "$version"
    last_checked: "$(date -Iseconds)"
    update_method: "$update_method"
    size: $(stat -c%s "$path" 2>/dev/null || echo 0)
    modified: "$(date -r "$path" -Iseconds 2>/dev/null || echo "unknown")"
EOF
}

# AppImageをYAMLに追加
add_appimage_to_yaml() {
    local name="$1"
    local path="$2"
    
    cat >> "$DATA_FILE" << EOF
  $name:
    path: "$path"
    category: "appimage"
    package: "none"
    version: "unknown"
    last_checked: "$(date -Iseconds)"
    update_method: "manual download and replace"
    size: $(stat -c%s "$path" 2>/dev/null || echo 0)
    modified: "$(date -r "$path" -Iseconds 2>/dev/null || echo "unknown")"
    type: "AppImage"
EOF
}

# 更新方法を決定
get_update_method() {
    local category="$1"
    local name="$2"
    
    case "$category" in
        "apt") echo "apt upgrade $name" ;;
        "snap") echo "snap refresh $name" ;;
        "npm") echo "npm update -g $name" ;;
        "pip") echo "pip install --upgrade $name" ;;
        "manual") echo "manual update required" ;;
        "appimage") echo "download latest AppImage" ;;
        *) echo "unknown update method" ;;
    esac
}

# 統計情報を更新
update_statistics() {
    info "統計情報を更新中..."
    
    # 各カテゴリの数をカウント
    local apt_count
    apt_count=$(grep -c "category: \"apt\"" "$DATA_FILE" 2>/dev/null || echo 0)
    local snap_count
    snap_count=$(grep -c "category: \"snap\"" "$DATA_FILE" 2>/dev/null || echo 0)
    local manual_count
    manual_count=$(grep -c "category: \"manual\"" "$DATA_FILE" 2>/dev/null || echo 0)
    local appimage_count
    appimage_count=$(grep -c "category: \"appimage\"" "$DATA_FILE" 2>/dev/null || echo 0)
    local unknown_count
    unknown_count=$(grep -c "category: \"unknown\"" "$DATA_FILE" 2>/dev/null || echo 0)
    local total_count=$((${apt_count:-0} + ${snap_count:-0} + ${manual_count:-0} + ${appimage_count:-0} + ${unknown_count:-0}))
    
    # 統計情報を更新
    sed -i "s/apt: .*/apt: $apt_count/" "$DATA_FILE"
    sed -i "s/snap: .*/snap: $snap_count/" "$DATA_FILE"
    sed -i "s/manual: .*/manual: $manual_count/" "$DATA_FILE"
    sed -i "s/appimage: .*/appimage: $appimage_count/" "$DATA_FILE"
    sed -i "s/unknown: .*/unknown: $unknown_count/" "$DATA_FILE"
    sed -i "s/total_programs: .*/total_programs: $total_count/" "$DATA_FILE"
    
    success "統計情報更新完了: 合計 $total_count 個のプログラム"
}

# メイン実行関数
main() {
    info "Unified Software Manager Manager 全実行ファイル検出を開始..."
    
    # 設定ディレクトリ作成
    mkdir -p "$CONFIG_DIR"
    
    # 初期YAML構造作成
    init_yaml
    
    # 各種スキャン実行
    scan_path_executables
    scan_manual_installs
    scan_appimages
    
    # 統計情報更新
    update_statistics
    
    success "全実行ファイル検出完了: $DATA_FILE"
    info "GitHubで美しく表示される人間に読みやすいYAML形式で保存されました"
}

main "$@"