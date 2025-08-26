#!/bin/bash

# version-checker.sh の関数ライブラリ
# テストやその他のスクリプトから関数のみを読み込むために使用

# バージョン正規化 - プレフィックスを除去してバージョン番号のみ抽出
normalize_version() {
    local version="$1"
    if [[ -z "$version" || "$version" == "unknown" ]]; then
        echo "$version"
        return
    fi
    
    # 一般的なプレフィックスパターンを除去
    # Examples: jq-1.8.1 → 1.8.1, v1.2.3 → 1.2.3, tool-v2.0.0 → 2.0.0
    echo "$version" | sed -E 's/^[a-zA-Z]+-?v?//' | sed 's/^v//'
}

# バージョン比較 (簡易版)
version_compare() {
    local ver1="$1"
    local ver2="$2"
    
    if [[ "$ver1" == "unknown" || "$ver2" == "unknown" ]]; then
        echo "unknown"
        return 0
    fi
    
    # 両方のバージョンを正規化
    ver1=$(normalize_version "$ver1")
    ver2=$(normalize_version "$ver2")
    
    if [[ "$ver1" == "$ver2" ]]; then
        echo "equal"
        return 0
    fi
    
    # セマンティックバージョニング対応の比較
    local ver1_nums
    local ver2_nums
    ver1_nums=$(echo "$ver1" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0.0.0")
    ver2_nums=$(echo "$ver2" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 || echo "0.0.0")
    
    # sort -V で比較
    if [[ $(printf '%s\n%s' "$ver1_nums" "$ver2_nums" | sort -V | tail -1) == "$ver2_nums" ]]; then
        echo "github_newer"
    else
        echo "package_newer"
    fi
}