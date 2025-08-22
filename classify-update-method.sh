#!/bin/bash

# 更新方法分類スクリプト
# 検出されたプログラムの更新方法を分析・分類する

set -euo pipefail

CONFIG_DIR="$HOME/.update-manager"
DATA_FILE="$CONFIG_DIR/programs.json"

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

# パッケージマネージャー管理かチェック
check_package_manager() {
    local program_name="$1"
    local program_path="$2"
    
    # APT/dpkg管理かチェック
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -S "$program_path" >/dev/null 2>&1; then
            echo "apt"
            return 0
        fi
    fi
    
    # Snap管理かチェック
    if command -v snap >/dev/null 2>&1; then
        if snap list | grep -q "^$program_name "; then
            echo "snap"
            return 0
        fi
    fi
    
    # NPM グローバル管理かチェック
    if command -v npm >/dev/null 2>&1; then
        if [[ "$program_path" =~ /npm/ ]] || npm list -g --depth=0 2>/dev/null | grep -q "$program_name"; then
            echo "npm"
            return 0
        fi
    fi
    
    # pip管理かチェック（Pythonスクリプトの場合）
    if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
        if [[ "$program_path" =~ \.py$ ]] || [[ "$program_path" =~ /python/ ]]; then
            local pip_cmd="pip3"
            if ! command -v pip3 >/dev/null 2>&1; then
                pip_cmd="pip"
            fi
            
            if $pip_cmd list 2>/dev/null | grep -i "$program_name" >/dev/null; then
                echo "pip"
                return 0
            fi
        fi
    fi
    
    # gem管理かチェック（Rubyスクリプトの場合）
    if command -v gem >/dev/null 2>&1; then
        if [[ "$program_path" =~ \.rb$ ]] || [[ "$program_path" =~ /ruby/ ]] || [[ "$program_path" =~ /gem/ ]]; then
            if gem list | grep -i "$program_name" >/dev/null 2>&1; then
                echo "gem"
                return 0
            fi
        fi
    fi
    
    # Flatpak管理かチェック
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak list 2>/dev/null | grep -q "$program_name"; then
            echo "flatpak"
            return 0
        fi
    fi
    
    echo "unknown"
}

# Gitリポジトリ管理かチェック
check_git_managed() {
    local program_path="$1"
    local dir
    dir=$(dirname "$program_path")
    
    # パスを遡ってGitリポジトリを探す
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            # Gitリポジトリ情報を取得
            local remote_url=""
            local branch=""
            local last_commit=""
            
            if cd "$dir" 2>/dev/null; then
                remote_url=$(git remote get-url origin 2>/dev/null || echo "")
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
                last_commit=$(git log -1 --format="%H %s" 2>/dev/null || echo "")
            fi
            
            echo "git|$dir|$remote_url|$branch|$last_commit"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    
    echo "no"
}

# バージョン情報を取得
get_version_info() {
    local program_path="$1"
    local program_name="$2"
    
    # 一般的なバージョンオプションを試行
    local version_options=(
        "--version"
        "-v"
        "-V"
        "version"
        "--help"
    )
    
    for option in "${version_options[@]}"; do
        local version_output
        version_output=$("$program_path" "$option" 2>&1 | head -n 3 || true)
        
        if [[ -n "$version_output" && "$version_output" != *"invalid"* && "$version_output" != *"unknown"* ]]; then
            # バージョン情報らしき文字列を抽出
            local version
            version=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || echo "")
            
            if [[ -n "$version" ]]; then
                echo "$version"
                return 0
            fi
        fi
    done
    
    echo "unknown"
}

# 更新方法を推定
determine_update_method() {
    local category="$1"
    local program_path="$2"
    local program_name="$3"
    local metadata="$4"
    
    case "$category" in
        "apt")
            echo "apt upgrade $program_name"
            ;;
        "snap")
            echo "snap refresh $program_name"
            ;;
        "npm")
            echo "npm update -g $program_name"
            ;;
        "pip")
            echo "pip install --upgrade $program_name"
            ;;
        "gem")
            echo "gem update $program_name"
            ;;
        "flatpak")
            echo "flatpak update $program_name"
            ;;
        "git")
            local repo_path
            repo_path=$(echo "$metadata" | jq -r '.repo_path // empty')
            if [[ -n "$repo_path" ]]; then
                echo "cd $repo_path && git pull"
            else
                echo "git pull (repository unknown)"
            fi
            ;;
        "appimage")
            echo "manual download and replace"
            ;;
        "manual")
            # 手動インストールの場合、ファイル名から推測
            if [[ "$program_name" =~ (docker|kubectl|helm|terraform|vault) ]]; then
                echo "check official releases and download"
            elif [[ -f "$(dirname "$program_path")/Makefile" ]] || [[ -f "$(dirname "$program_path")/makefile" ]]; then
                echo "cd $(dirname "$program_path") && make && make install"
            elif [[ -f "$(dirname "$program_path")/configure" ]]; then
                echo "cd $(dirname "$program_path") && ./configure && make && make install"
            else
                echo "manual update required"
            fi
            ;;
        *)
            echo "unknown update method"
            ;;
    esac
}

# 更新頻度を推定
estimate_update_frequency() {
    local category="$1"
    local program_name="$2"
    
    case "$category" in
        "apt"|"snap")
            echo "weekly"
            ;;
        "npm"|"pip"|"gem")
            echo "monthly"
            ;;
        "git")
            echo "daily"
            ;;
        "appimage"|"manual")
            if [[ "$program_name" =~ (docker|kubectl|kubernetes|helm|terraform) ]]; then
                echo "monthly"
            else
                echo "rarely"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# セキュリティリスク評価
assess_security_risk() {
    local category="$1"
    local program_path="$2"
    local program_name="$3"
    
    local risk="low"
    
    # 権限の高いプログラム
    if [[ "$program_path" =~ ^/(bin|sbin|usr/bin|usr/sbin)/ ]]; then
        risk="medium"
    fi
    
    # ネットワーク関連ツール
    if [[ "$program_name" =~ (ssh|curl|wget|nc|nmap|docker|kubectl) ]]; then
        risk="high"
    fi
    
    # 手動インストールは一般的にリスクが高い
    if [[ "$category" == "manual" || "$category" == "git" ]]; then
        risk="medium"
    fi
    
    echo "$risk"
}

# プログラム分類処理
classify_program() {
    local program_json="$1"
    local name
    local path
    local category
    
    name=$(echo "$program_json" | jq -r '.name')
    path=$(echo "$program_json" | jq -r '.path')
    category=$(echo "$program_json" | jq -r '.category // "unknown"')
    
    info "  分類中: $name ($path)"
    
    # パッケージマネージャーチェック
    if [[ "$category" == "unknown" ]]; then
        category=$(check_package_manager "$name" "$path")
    fi
    
    # Gitリポジトリチェック
    local git_info
    git_info=$(check_git_managed "$path")
    
    if [[ "$git_info" != "no" && "$category" == "unknown" ]]; then
        category="git"
    fi
    
    # バージョン情報取得
    local version
    version=$(get_version_info "$path" "$name")
    
    # メタデータ準備
    local metadata="{}"
    if [[ "$git_info" != "no" ]]; then
        IFS='|' read -r _ repo_path remote_url branch last_commit <<< "$git_info"
        metadata=$(jq -n \
            --arg repo_path "$repo_path" \
            --arg remote_url "$remote_url" \
            --arg branch "$branch" \
            --arg last_commit "$last_commit" \
            '{repo_path: $repo_path, remote_url: $remote_url, branch: $branch, last_commit: $last_commit}')
    fi
    
    # 更新方法決定
    local update_method
    update_method=$(determine_update_method "$category" "$path" "$name" "$metadata")
    
    # 更新頻度推定
    local update_frequency
    update_frequency=$(estimate_update_frequency "$category" "$name")
    
    # セキュリティリスク評価
    local security_risk
    security_risk=$(assess_security_risk "$category" "$path" "$name")
    
    # 分類結果をJSONで出力
    echo "$program_json" | jq \
        --arg category "$category" \
        --arg version "$version" \
        --arg update_method "$update_method" \
        --arg update_frequency "$update_frequency" \
        --arg security_risk "$security_risk" \
        --argjson metadata "$metadata" \
        '.category = $category | 
         .version = $version | 
         .update_method = $update_method | 
         .metadata = (.metadata + $metadata + {
             update_frequency: $update_frequency,
             security_risk: $security_risk,
             classified_at: now|todate
         })'
}

# メイン分類処理
main() {
    if [[ ! -f "$DATA_FILE" ]]; then
        warn "データファイルが見つかりません: $DATA_FILE"
        warn "まず detect-all-programs.sh を実行してください"
        exit 1
    fi
    
    info "プログラムの更新方法分類を開始..."
    
    # 一時ファイル作成
    local temp_file
    temp_file=$(mktemp)
    
    # ヘッダー情報をコピー
    jq 'del(.programs) | .programs = []' "$DATA_FILE" > "$temp_file"
    
    # 各プログラムを分類
    jq -c '.programs[]' "$DATA_FILE" | while IFS= read -r program; do
        classified_program=$(classify_program "$program")
        jq --argjson program "$classified_program" '.programs += [$program]' "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
    done
    
    # 分類統計を更新
    info "分類統計を更新中..."
    
    # カテゴリ別統計
    jq '.programs | group_by(.category) | map({key: .[0].category, value: (. | length)}) | from_entries' "$temp_file" > "$temp_file.stats"
    
    # セキュリティリスク統計
    jq '.programs | group_by(.metadata.security_risk) | map({key: ("risk_" + .[0].metadata.security_risk), value: (. | length)}) | from_entries' "$temp_file" > "$temp_file.risk_stats"
    
    # 統計情報をマージ
    jq --slurpfile stats "$temp_file.stats" \
       --slurpfile risk_stats "$temp_file.risk_stats" \
       '.statistics = ($stats[0] + $risk_stats[0]) | .classification_completed_at = now|todate' \
       "$temp_file" > "$temp_file.final"
    
    # ファイル更新
    mv "$temp_file.final" "$DATA_FILE"
    
    # 一時ファイル削除
    rm -f "$temp_file" "$temp_file.stats" "$temp_file.risk_stats"
    
    success "プログラム分類完了"
    
    # 結果サマリー表示
    info "分類結果サマリー:"
    jq -r '.statistics | to_entries[] | "  \(.key): \(.value)"' "$DATA_FILE"
}

# jqの存在チェック
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq が必要です。インストールしてください: sudo apt install jq" >&2
    exit 1
fi

main "$@"