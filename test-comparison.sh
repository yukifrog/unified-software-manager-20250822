#!/bin/bash

# テスト用の比較実行スクリプト

echo "=== 実際のシステムでバージョン比較テスト ==="
echo

# 実際にインストールされているプログラムをチェック
programs=("gh" "docker" "node" "jq")

for program in "${programs[@]}"; do
    echo "--- $program のバージョン比較 ---"
    ./version-comparison.sh --check "$program"
    echo
done

echo "=== 既知の古くなりがちなプログラム例 ==="
echo

# 一般的に古くなりがちなプログラムの例
outdated_examples=(
    "kubectl:1.25.0:kubernetes/kubernetes"
    "terraform:1.3.0:hashicorp/terraform"
    "helm:3.8.0:helm/helm"
    "docker:20.10.21:docker/cli"
    "vault:1.12.0:hashicorp/vault"
)

for example in "${outdated_examples[@]}"; do
    IFS=':' read -r name local_ver repo <<< "$example"
    
    echo "プログラム: $name"
    echo "  想定ローカル版: $local_ver"
    
    # GitHub最新版を取得
    api_url="https://api.github.com/repos/$repo/releases/latest"
    if command -v curl >/dev/null 2>&1; then
        github_ver=$(curl -s "$api_url" 2>/dev/null | grep '"tag_name":' | head -1 | sed 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/' | sed 's/^v//')
        if [[ -n "$github_ver" && "$github_ver" != "null" ]]; then
            echo "  GitHub最新版: $github_ver"
            echo "  📊 差分: ローカル版が古い可能性が高い"
        fi
    fi
    echo "  🔗 https://github.com/$repo/releases"
    echo
done