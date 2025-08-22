#!/bin/bash

# 全実行ファイル検出スクリプト
# システム内のすべての実行可能プログラムを検出し、分類する

set -euo pipefail

CONFIG_DIR="$HOME/.update-manager"
DATA_FILE="$CONFIG_DIR/programs.json"
TEMP_FILE="$CONFIG_DIR/programs_temp.json"

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

# 初期データ構造を作成
init_data() {
    echo '{
        "programs": [],
        "last_scan": "",
        "categories": {
            "apt": [],
            "snap": [],
            "npm": [],
            "pip": [],
            "gem": [],
            "git": [],
            "manual": [],
            "unknown": []
        },
        "scan_info": {
            "scanned_paths": [],
            "total_executables": 0
        }
    }' > "$TEMP_FILE"
}

# PATH内の実行ファイルを検出
scan_path_executables() {
    info "PATH内の実行ファイルをスキャン中..."
    local count=0
    
    # PATH を分割してスキャン
    echo "$PATH" | tr ':' '\n' | while IFS= read -r dir; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            info "  スキャン中: $dir"
            find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | while IFS= read -r file; do
                local name
                name=$(basename "$file")
                
                # 基本情報を収集
                local size
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                
                local modified
                modified=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null || echo "0")
                modified=$(date -d "@$modified" -Iseconds 2>/dev/null || date -r "$modified" -Iseconds 2>/dev/null || echo "unknown")
                
                # JSONエントリを作成
                local entry
                entry=$(jq -n \
                    --arg name "$name" \
                    --arg path "$file" \
                    --arg size "$size" \
                    --arg modified "$modified" \
                    --arg directory "$dir" \
                    '{
                        name: $name,
                        path: $path,
                        size: $size|tonumber,
                        modified: $modified,
                        directory: $directory,
                        category: "unknown",
                        package_manager: null,
                        version: null,
                        update_method: null,
                        metadata: {}
                    }'
                )
                
                # 一時ファイルに追加
                jq --argjson entry "$entry" '.programs += [$entry]' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
                count=$((count + 1))
            done
            
            # スキャンしたパスを記録
            jq --arg dir "$dir" '.scan_info.scanned_paths += [$dir]' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
        fi
    done
    
    success "PATH内のスキャン完了"
}

# 特定ディレクトリの手動インストールプログラムを検出
scan_manual_installs() {
    info "手動インストールプログラムをスキャン中..."
    
    local manual_dirs=(
        "/usr/local/bin"
        "/opt"
        "$HOME/.local/bin"
        "$HOME/bin"
        "/usr/local/opt"
    )
    
    for dir in "${manual_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            info "  手動インストールディレクトリをスキャン: $dir"
            
            find "$dir" -type f -executable 2>/dev/null | while IFS= read -r file; do
                local name
                name=$(basename "$file")
                
                # 既に登録済みかチェック
                if jq -e --arg path "$file" '.programs[] | select(.path == $path)' "$TEMP_FILE" >/dev/null 2>&1; then
                    # 既存エントリをmanualカテゴリに更新
                    jq --arg path "$file" \
                       '(.programs[] | select(.path == $path) | .category) = "manual"' \
                       "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
                else
                    # 新しいエントリを追加
                    local size
                    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                    
                    local modified
                    modified=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null || echo "0")
                    modified=$(date -d "@$modified" -Iseconds 2>/dev/null || date -r "$modified" -Iseconds 2>/dev/null || echo "unknown")
                    
                    local entry
                    entry=$(jq -n \
                        --arg name "$name" \
                        --arg path "$file" \
                        --arg size "$size" \
                        --arg modified "$modified" \
                        --arg directory "$dir" \
                        '{
                            name: $name,
                            path: $path,
                            size: $size|tonumber,
                            modified: $modified,
                            directory: $directory,
                            category: "manual",
                            package_manager: null,
                            version: null,
                            update_method: "manual",
                            metadata: {}
                        }'
                    )
                    
                    jq --argjson entry "$entry" '.programs += [$entry]' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
                fi
            done
        fi
    done
    
    success "手動インストールプログラムのスキャン完了"
}

# Gitリポジトリを検出
scan_git_repositories() {
    info "Gitリポジトリをスキャン中..."
    
    # よくあるGitリポジトリのパス
    local git_search_paths=(
        "$HOME/src"
        "$HOME/projects"
        "$HOME/dev"
        "$HOME/workspace"
        "$HOME/git"
        "$HOME/github"
        "/usr/local/src"
        "/opt"
    )
    
    for search_path in "${git_search_paths[@]}"; do
        if [[ -d "$search_path" ]]; then
            info "  Gitリポジトリを検索: $search_path"
            
            find "$search_path" -name ".git" -type d 2>/dev/null | while IFS= read -r git_dir; do
                local repo_dir
                repo_dir=$(dirname "$git_dir")
                local repo_name
                repo_name=$(basename "$repo_dir")
                
                # 実行可能ファイルがあるかチェック
                local executables
                executables=$(find "$repo_dir" -type f -executable ! -path "*/.git/*" 2>/dev/null || true)
                
                if [[ -n "$executables" ]]; then
                    # Gitリポジトリ情報を取得
                    local remote_url=""
                    local branch=""
                    
                    if cd "$repo_dir" 2>/dev/null; then
                        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
                        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
                    fi
                    
                    # 実行ファイルごとにエントリを作成
                    echo "$executables" | while IFS= read -r executable; do
                        local name
                        name=$(basename "$executable")
                        
                        local entry
                        entry=$(jq -n \
                            --arg name "$name" \
                            --arg path "$executable" \
                            --arg repo_path "$repo_dir" \
                            --arg remote_url "$remote_url" \
                            --arg branch "$branch" \
                            '{
                                name: $name,
                                path: $path,
                                size: 0,
                                modified: "unknown",
                                directory: ($path | split("/")[:-1] | join("/")),
                                category: "git",
                                package_manager: "git",
                                version: null,
                                update_method: "git_pull",
                                metadata: {
                                    repo_path: $repo_path,
                                    remote_url: $remote_url,
                                    branch: $branch
                                }
                            }'
                        )
                        
                        jq --argjson entry "$entry" '.programs += [$entry]' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
                    done
                fi
            done
        fi
    done
    
    success "Gitリポジトリのスキャン完了"
}

# AppImageファイルを検出
scan_appimages() {
    info "AppImageファイルをスキャン中..."
    
    local appimage_paths=(
        "$HOME/Applications"
        "$HOME/Downloads"
        "$HOME/.local/bin"
        "/opt"
        "$HOME/AppImages"
    )
    
    for path in "${appimage_paths[@]}"; do
        if [[ -d "$path" ]]; then
            find "$path" -name "*.AppImage" -type f 2>/dev/null | while IFS= read -r appimage; do
                local name
                name=$(basename "$appimage" .AppImage)
                
                local size
                size=$(stat -f%z "$appimage" 2>/dev/null || stat -c%s "$appimage" 2>/dev/null || echo "0")
                
                local entry
                entry=$(jq -n \
                    --arg name "$name" \
                    --arg path "$appimage" \
                    --arg size "$size" \
                    '{
                        name: $name,
                        path: $path,
                        size: $size|tonumber,
                        modified: "unknown",
                        directory: ($path | split("/")[:-1] | join("/")),
                        category: "appimage",
                        package_manager: null,
                        version: null,
                        update_method: "manual",
                        metadata: {
                            type: "AppImage"
                        }
                    }'
                )
                
                jq --argjson entry "$entry" '.programs += [$entry]' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
            done
        fi
    done
    
    success "AppImageファイルのスキャン完了"
}

# 統計情報を更新
update_statistics() {
    info "統計情報を更新中..."
    
    local total_count
    total_count=$(jq '.programs | length' "$TEMP_FILE")
    
    # カテゴリ別にプログラムを分類
    jq '.programs | group_by(.category) | map({key: .[0].category, value: map(.name)}) | from_entries' "$TEMP_FILE" > "$TEMP_FILE.categories"
    
    # 統計情報を更新
    jq --argjson total "$total_count" \
       --slurpfile categories "$TEMP_FILE.categories" \
       '.scan_info.total_executables = $total | .categories = $categories[0] | .last_scan = now|todate' \
       "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
    
    rm -f "$TEMP_FILE.categories"
    success "統計情報更新完了: 合計 $total_count 個のプログラムを検出"
}

# メイン実行関数
main() {
    info "全実行ファイルの検出を開始..."
    
    # 設定ディレクトリ作成
    mkdir -p "$CONFIG_DIR"
    
    # 初期データ構造作成
    init_data
    
    # 各種スキャン実行
    scan_path_executables
    scan_manual_installs
    scan_git_repositories
    scan_appimages
    
    # 統計情報更新
    update_statistics
    
    # データファイルに保存
    mv "$TEMP_FILE" "$DATA_FILE"
    
    success "全実行ファイルの検出完了: $DATA_FILE"
}

# jqの存在チェック
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq が必要です。インストールしてください: sudo apt install jq" >&2
    exit 1
fi

main "$@"