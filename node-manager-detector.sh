#!/bin/bash

# Node.js管理方法検出スクリプト
# どのツールでNode.jsが管理されているかを判定

detect_node_manager() {
    local node_path
    node_path=$(which node 2>/dev/null || echo "")
    
    if [[ -z "$node_path" ]]; then
        echo "Node.js がインストールされていません"
        return 1
    fi
    
    echo "Node.js 管理方法の検出結果："
    echo "  パス: $node_path"
    echo "  バージョン: $(node --version 2>/dev/null || echo 'unknown')"
    echo
    
    # 各管理ツールをチェック
    
    # 1. nvm
    if [[ "$node_path" =~ \.nvm ]] || [[ -n "${NVM_DIR:-}" ]]; then
        echo "✅ nvm で管理されています"
        if command -v nvm >/dev/null 2>&1; then
            echo "  現在のバージョン: $(nvm current 2>/dev/null || echo 'unknown')"
            echo "  利用可能版: $(nvm list 2>/dev/null | grep -v 'system' | head -3 || echo 'none')"
            echo "  更新コマンド: nvm install node && nvm use node"
        fi
        return 0
    fi
    
    # 2. volta
    if [[ "$node_path" =~ volta ]] || command -v volta >/dev/null 2>&1; then
        echo "✅ Volta で管理されています"
        if command -v volta >/dev/null 2>&1; then
            echo "  現在設定: $(volta list node 2>/dev/null || echo 'unknown')"
            echo "  更新コマンド: volta install node@latest"
        fi
        return 0
    fi
    
    # 3. fnm
    if [[ "$node_path" =~ fnm ]] || [[ -n "${FNM_DIR:-}" ]]; then
        echo "✅ fnm で管理されています"
        if command -v fnm >/dev/null 2>&1; then
            echo "  現在のバージョン: $(fnm current 2>/dev/null || echo 'unknown')"
            echo "  更新コマンド: fnm install --lts && fnm use lts-latest"
        fi
        return 0
    fi
    
    # 4. n
    if [[ "$node_path" =~ /n/versions ]] || command -v n >/dev/null 2>&1; then
        echo "✅ n で管理されています"
        echo "  更新コマンド: n latest"
        return 0
    fi
    
    # 5. asdf
    if [[ "$node_path" =~ asdf ]] || [[ -f "$HOME/.asdfrc" ]]; then
        echo "✅ asdf で管理されています"
        if command -v asdf >/dev/null 2>&1; then
            echo "  現在のバージョン: $(asdf current nodejs 2>/dev/null || echo 'unknown')"
            echo "  更新コマンド: asdf install nodejs latest && asdf global nodejs latest"
        fi
        return 0
    fi
    
    # 6. Homebrew (macOS)
    if [[ "$node_path" =~ /brew ]] || [[ "$node_path" =~ /opt/homebrew ]]; then
        echo "✅ Homebrew で管理されています"
        echo "  更新コマンド: brew upgrade node"
        return 0
    fi
    
    # 7. システムパッケージ
    if [[ "$node_path" =~ ^/usr/bin ]] && dpkg -S "$node_path" >/dev/null 2>&1; then
        local package
        package=$(dpkg -S "$node_path" | cut -d: -f1)
        echo "✅ APT (システムパッケージ) で管理されています"
        echo "  パッケージ名: $package"
        echo "  更新コマンド: sudo apt update && sudo apt upgrade $package"
        return 0
    fi
    
    # 8. Snap
    if [[ "$node_path" =~ /snap ]]; then
        echo "✅ Snap で管理されています"
        echo "  更新コマンド: sudo snap refresh node"
        return 0
    fi
    
    # 9. 手動インストール
    if [[ "$node_path" =~ /usr/local ]] || [[ "$node_path" =~ /opt ]]; then
        echo "⚠️  手動インストールと思われます"
        echo "  更新方法: 公式サイトから最新版をダウンロード"
        echo "  https://nodejs.org/en/download/"
        return 0
    fi
    
    # 不明
    echo "❓ Node.js の管理方法が不明です"
    echo "  パス: $node_path"
    echo "  手動で管理方法を確認してください"
    return 1
}

# 推奨管理ツール提案
recommend_node_manager() {
    echo
    echo "=== Node.js 管理ツール推奨度 ==="
    echo
    echo "🥇 nvm (Node Version Manager)"
    echo "   - 最も人気で安定"
    echo "   - 複数バージョン管理が簡単"
    echo "   - インストール: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo
    echo "🥈 fnm (Fast Node Manager)"
    echo "   - nvmより高速"
    echo "   - Rust製で軽量"
    echo "   - インストール: curl -fsSL https://fnm.vercel.app/install | bash"
    echo
    echo "🥉 Volta"
    echo "   - プロジェクト単位で自動切り替え"
    echo "   - 設定ファイル管理"
    echo "   - インストール: curl https://get.volta.sh | bash"
    echo
    echo "システムパッケージ（apt/snap）は更新が遅いため、開発用途では上記の専用ツール推奨"
}

# メイン実行
main() {
    echo "=== Node.js 管理ツール検出 ==="
    echo
    
    detect_node_manager
    
    case "${1:-}" in
        --recommend)
            recommend_node_manager
            ;;
        *)
            echo
            echo "推奨ツールを見る場合: $0 --recommend"
            ;;
    esac
}

main "$@"