#!/bin/bash

# 各言語ランタイムの管理ツール検出スクリプト
# Node.js, Python, Ruby, Go, Rust等の管理方法を統合的に検出

detect_runtime_managers() {
    echo "=== 言語ランタイム管理ツール検出 ==="
    echo
    
    # Node.js
    detect_nodejs_manager
    echo
    
    # Python  
    detect_python_manager
    echo
    
    # Ruby
    detect_ruby_manager
    echo
    
    # Go
    detect_go_manager
    echo
    
    # Rust
    detect_rust_manager
    echo
}

detect_nodejs_manager() {
    echo "📦 Node.js:"
    
    if ! command -v node >/dev/null 2>&1; then
        echo "  ❌ インストールされていません"
        return 1
    fi
    
    local node_path
    node_path=$(which node)
    echo "  📍 パス: $node_path"
    echo "  🏷️  バージョン: $(node --version 2>/dev/null || echo 'unknown')"
    
    # 管理ツール検出
    if [[ "$node_path" =~ \.asdf ]] || (command -v asdf >/dev/null 2>&1 && asdf current nodejs >/dev/null 2>&1); then
        echo "  🔧 管理: asdf"
        echo "  📈 更新: asdf install nodejs latest && asdf global nodejs latest"
        if command -v asdf >/dev/null 2>&1; then
            local current_ver
            current_ver=$(asdf current nodejs 2>/dev/null | awk '{print $2}' || echo 'unknown')
            echo "  📌 asdf設定版: $current_ver"
        fi
    elif [[ "$node_path" =~ \.nvm ]] || [[ -n "${NVM_DIR:-}" ]]; then
        echo "  🔧 管理: nvm"
        echo "  📈 更新: nvm install node"
    elif [[ "$node_path" =~ volta ]]; then
        echo "  🔧 管理: Volta"
        echo "  📈 更新: volta install node@latest"
    elif [[ "$node_path" =~ fnm ]]; then
        echo "  🔧 管理: fnm"
        echo "  📈 更新: fnm install --lts"
    elif [[ "$node_path" =~ ^/usr/bin ]]; then
        echo "  🔧 管理: システムパッケージ (apt/yum等)"
        echo "  📈 更新: sudo apt upgrade nodejs"
        echo "  ⚠️  更新が遅い可能性"
    else
        echo "  🔧 管理: 不明"
    fi
}

detect_python_manager() {
    echo "🐍 Python:"
    
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  ❌ インストールされていません"
        return 1
    fi
    
    local python_path
    python_path=$(which python3)
    echo "  📍 パス: $python_path"
    echo "  🏷️  バージョン: $(python3 --version 2>/dev/null || echo 'unknown')"
    
    # 管理ツール検出
    if [[ "$python_path" =~ \.asdf ]] || (command -v asdf >/dev/null 2>&1 && asdf current python >/dev/null 2>&1); then
        echo "  🔧 管理: asdf"
        echo "  📈 更新: asdf install python latest && asdf global python latest"
        if command -v asdf >/dev/null 2>&1; then
            local current_ver
            current_ver=$(asdf current python 2>/dev/null | awk '{print $2}' || echo 'unknown')
            echo "  📌 asdf設定版: $current_ver"
        fi
    elif [[ -n "${PYENV_ROOT:-}" ]] || command -v pyenv >/dev/null 2>&1; then
        echo "  🔧 管理: pyenv"
        echo "  📈 更新: pyenv install 3.12.0 && pyenv global 3.12.0"
    elif [[ "$python_path" =~ anaconda ]] || command -v conda >/dev/null 2>&1; then
        echo "  🔧 管理: Anaconda/Miniconda"
        echo "  📈 更新: conda update python"
    elif [[ "$python_path" =~ ^/usr/bin ]]; then
        echo "  🔧 管理: システムパッケージ"
        echo "  📈 更新: sudo apt upgrade python3"
        echo "  ⚠️  更新が遅い可能性"
    else
        echo "  🔧 管理: 不明"
    fi
}

detect_ruby_manager() {
    echo "💎 Ruby:"
    
    if ! command -v ruby >/dev/null 2>&1; then
        echo "  ❌ インストールされていません"
        return 1
    fi
    
    local ruby_path
    ruby_path=$(which ruby)
    echo "  📍 パス: $ruby_path"
    echo "  🏷️  バージョン: $(ruby --version 2>/dev/null || echo 'unknown')"
    
    # 管理ツール検出
    if [[ "$ruby_path" =~ \.rbenv ]] || command -v rbenv >/dev/null 2>&1; then
        echo "  🔧 管理: rbenv"
        echo "  📈 更新: rbenv install 3.3.0 && rbenv global 3.3.0"
    elif [[ "$ruby_path" =~ \.rvm ]] || [[ -n "${rvm_loaded_flag:-}" ]]; then
        echo "  🔧 管理: RVM"
        echo "  📈 更新: rvm install ruby-head && rvm use ruby-head"
    elif [[ "$ruby_path" =~ ^/usr/bin ]]; then
        echo "  🔧 管理: システムパッケージ"
        echo "  📈 更新: sudo apt upgrade ruby"
        echo "  ⚠️  更新が遅い可能性"
    else
        echo "  🔧 管理: 不明"
    fi
}

detect_go_manager() {
    echo "🐹 Go:"
    
    if ! command -v go >/dev/null 2>&1; then
        echo "  ❌ インストールされていません"
        return 1
    fi
    
    local go_path
    go_path=$(which go)
    echo "  📍 パス: $go_path"
    echo "  🏷️  バージョン: $(go version 2>/dev/null || echo 'unknown')"
    
    # 管理ツール検出
    if [[ "$go_path" =~ /usr/local/go ]]; then
        echo "  🔧 管理: 公式バイナリ (手動インストール)"
        echo "  📈 更新: 公式サイトから最新版ダウンロード"
        echo "  🔗 https://golang.org/dl/"
    elif [[ "$go_path" =~ ^/usr/bin ]]; then
        echo "  🔧 管理: システムパッケージ"
        echo "  📈 更新: sudo apt upgrade golang-go"
        echo "  ⚠️  更新が遅い可能性"
    elif command -v g >/dev/null 2>&1; then
        echo "  🔧 管理: g (Go version manager)"
        echo "  📈 更新: g install latest"
    else
        echo "  🔧 管理: 不明"
    fi
}

detect_rust_manager() {
    echo "🦀 Rust:"
    
    if ! command -v rustc >/dev/null 2>&1; then
        echo "  ❌ インストールされていません"
        return 1
    fi
    
    local rustc_path
    rustc_path=$(which rustc)
    echo "  📍 パス: $rustc_path"
    echo "  🏷️  バージョン: $(rustc --version 2>/dev/null || echo 'unknown')"
    
    # 管理ツール検出
    if [[ "$rustc_path" =~ \.cargo ]] || command -v rustup >/dev/null 2>&1; then
        echo "  🔧 管理: rustup (推奨)"
        echo "  📈 更新: rustup update"
    elif [[ "$rustc_path" =~ ^/usr/bin ]]; then
        echo "  🔧 管理: システムパッケージ"
        echo "  📈 更新: sudo apt upgrade rustc"
        echo "  ⚠️  更新が非常に遅い可能性"
    else
        echo "  🔧 管理: 不明"
    fi
}

# 推奨事項表示
show_recommendations() {
    echo
    echo "=== 推奨管理ツール ==="
    echo
    echo "各言語に特化したバージョン管理ツールの使用を強く推奨："
    echo
    echo "🔥 最優先で導入すべき:"
    echo "  • nvm/fnm (Node.js) - 複数バージョン管理が容易"
    echo "  • rustup (Rust) - 公式ツール、更新が確実"
    echo
    echo "🚀 開発効率向上:"
    echo "  • pyenv (Python) - 仮想環境管理も統合"
    echo "  • rbenv (Ruby) - シンプルで軽量"
    echo
    echo "⚠️  システムパッケージの問題:"
    echo "  • 更新が遅い（数ヶ月〜年単位の遅れ）"
    echo "  • 古いバージョンで開発することになりがち"
    echo "  • セキュリティアップデートも遅れる"
    echo
    echo "📋 移行ガイド: 各公式サイトで詳細なインストール手順を確認"
}

# メイン処理
main() {
    case "${1:-}" in
        --recommend)
            detect_runtime_managers
            show_recommendations
            ;;
        *)
            detect_runtime_managers
            echo
            echo "推奨ツール情報を見る場合: $0 --recommend"
            ;;
    esac
}

main "$@"