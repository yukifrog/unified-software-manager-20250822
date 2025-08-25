#!/bin/bash

# asdf セットアップガイド
# asdf のインストールと基本的な使用方法をガイド

set -euo pipefail

# 色付きメッセージ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

highlight() {
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

show_asdf_benefits() {
    cat << 'EOF'
=== asdf を使うメリット ===

🎯 統一インターフェース:
  • すべての言語を同じコマンドで管理
  • 覚えるコマンドが少ない

📁 プロジェクト固有管理:
  • .tool-versions ファイルでプロジェクトごとに設定
  • チームメンバーと同じ環境を共有

🚀 豊富な対応ツール:
  • Node.js, Python, Ruby, Go, Rust
  • kubectl, terraform, helm, jq 等
  • 200以上のプラグインが利用可能

🔄 簡単な切り替え:
  • ディレクトリ移動時に自動でバージョン切り替え
  • グローバル設定とローカル設定の使い分け

EOF
}

check_asdf_status() {
    echo "=== asdf 現在の状況 ==="
    echo
    
    if command -v asdf >/dev/null 2>&1; then
        success "asdf がインストールされています"
        echo "  バージョン: $(asdf version 2>/dev/null || echo 'unknown')"
        echo "  パス: $(which asdf)"
        echo
        
        # インストール済みプラグイン確認
        if asdf plugin list >/dev/null 2>&1; then
            local plugins
            plugins=$(asdf plugin list 2>/dev/null || echo "")
            if [[ -n "$plugins" ]]; then
                info "インストール済みプラグイン:"
                echo "$plugins" | while IFS= read -r plugin; do
                    local versions
                    versions=$(asdf list "$plugin" 2>/dev/null | tr '\n' ' ' || echo "なし")
                    echo "  • $plugin: $versions"
                done
            else
                info "プラグインはまだインストールされていません"
            fi
        fi
        
        # .tool-versionsファイル確認
        if [[ -f "$HOME/.tool-versions" ]]; then
            info "グローバル設定 (~/.tool-versions):"
            sed 's/^/    /' < "$HOME/.tool-versions"
        fi
        
        return 0
    else
        warn "asdf がインストールされていません"
        return 1
    fi
}

install_asdf() {
    echo "=== asdf インストール手順 ==="
    echo
    
    info "1. asdf 本体のインストール:"
    highlight "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0"
    echo
    
    info "2. シェル設定の追加:"
    local shell_name
    shell_name=$(basename "$SHELL")
    
    case "$shell_name" in
        "bash")
            highlight "echo '. \"\$HOME/.asdf/asdf.sh\"' >> ~/.bashrc"
            highlight "echo '. \"\$HOME/.asdf/completions/asdf.bash\"' >> ~/.bashrc"
            ;;
        "zsh")
            highlight "echo '. \"\$HOME/.asdf/asdf.sh\"' >> ~/.zshrc"
            highlight "echo '. \"\$HOME/.asdf/completions/asdf.bash\"' >> ~/.zshrc"
            ;;
        *)
            highlight "シェル設定ファイル (~/.${shell_name}rc) に以下を追加:"
            highlight ". \"\$HOME/.asdf/asdf.sh\""
            ;;
    esac
    echo
    
    info "3. シェルを再起動または設定を再読み込み:"
    highlight "source ~/.${shell_name}rc"
    echo
}

show_basic_usage() {
    cat << 'EOF'
=== asdf 基本的な使い方 ===

📦 プラグイン管理:
  asdf plugin list all              # 利用可能なプラグイン一覧
  asdf plugin add nodejs            # Node.js プラグイン追加
  asdf plugin add python            # Python プラグイン追加
  asdf plugin add terraform         # Terraform プラグイン追加

🔧 バージョン管理:
  asdf list all nodejs              # Node.js 利用可能バージョン一覧
  asdf install nodejs latest        # Node.js 最新版インストール
  asdf install python 3.12.0        # Python 特定版インストール

⚙️  バージョン設定:
  asdf global nodejs latest         # グローバル設定
  asdf local python 3.11.5          # 現在ディレクトリのみ設定
  asdf current                       # 現在の設定表示

🗂️  .tool-versions ファイル例:
  nodejs 20.10.0
  python 3.12.0
  terraform 1.6.0

EOF
}

show_migration_tips() {
    cat << 'EOF'
=== 現在のシステムパッケージからの移行 ===

🔄 Node.js の移行:
  1. asdf plugin add nodejs
  2. asdf install nodejs latest
  3. asdf global nodejs latest
  4. 確認: node --version

🔄 Python の移行:
  1. asdf plugin add python  
  2. asdf install python 3.12.0
  3. asdf global python 3.12.0
  4. 確認: python --version

⚠️  注意点:
  • システムパッケージは残しておくのが安全
  • asdf版が優先されるようにPATHが設定される
  • 既存のnvm/pyenv等とは競合する可能性

📋 .tool-versions での管理:
  • プロジェクトルートに配置
  • Gitで管理してチーム共有
  • ディレクトリ移動時に自動切り替え

EOF
}

auto_install() {
    if ! command -v git >/dev/null 2>&1; then
        warn "git が必要です。先にインストールしてください: sudo apt install git"
        return 1
    fi
    
    info "asdf の自動インストールを開始..."
    
    # asdfをクローン
    if [[ ! -d "$HOME/.asdf" ]]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
        success "asdf をクローンしました"
    else
        info "asdf は既にクローン済みです"
    fi
    
    # シェル設定の追加
    local shell_config=""
    if [[ "$SHELL" =~ bash ]]; then
        shell_config="$HOME/.bashrc"
    elif [[ "$SHELL" =~ zsh ]]; then
        shell_config="$HOME/.zshrc"
    fi
    
    if [[ -n "$shell_config" && -f "$shell_config" ]]; then
        if ! grep -q "asdf.sh" "$shell_config"; then
            cat <<'EOF' >> "$shell_config"
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
EOF
            success "シェル設定を追加しました: $shell_config"
            info "次回ターミナル起動時または source $shell_config で有効になります"
        else
            info "シェル設定は既に追加済みです"
        fi
    fi
    
    info "asdf インストール完了！"
    info "新しいターミナルを開くか、以下を実行してください:"
    highlight "source $shell_config"
}

show_help() {
    cat << 'EOF'
asdf セットアップガイド - 統一バージョン管理ツール

使用法:
    ./asdf-setup-guide.sh [オプション]

オプション:
    --status        現在のasdf状況を確認
    --install       インストール手順を表示  
    --auto-install  asdfを自動インストール
    --usage         基本的な使い方を表示
    --migrate       移行方法を表示
    --help          このヘルプを表示

例:
    ./asdf-setup-guide.sh --status
    ./asdf-setup-guide.sh --auto-install
    ./asdf-setup-guide.sh --usage

EOF
}

main() {
    case "${1:-}" in
        --status)
            check_asdf_status
            ;;
        --install)
            show_asdf_benefits
            echo
            install_asdf
            ;;
        --auto-install)
            auto_install
            ;;
        --usage)
            show_basic_usage
            ;;
        --migrate)
            show_migration_tips
            ;;
        --help)
            show_help
            ;;
        "")
            show_asdf_benefits
            echo
            if check_asdf_status; then
                show_basic_usage
            else
                install_asdf
            fi
            ;;
        *)
            echo "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"