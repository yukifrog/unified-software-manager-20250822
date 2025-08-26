#!/usr/bin/env bats

# version-checker.sh のunit tests

setup() {
    # テスト用の一時ディレクトリ
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # 関数ライブラリを読み込み
    source "${BATS_TEST_DIRNAME}/../lib/version-functions.sh"
}

teardown() {
    # 一時ディレクトリをクリーンアップ
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# normalize_version() 関数のテスト
@test "normalize_version removes jq- prefix" {
    result=$(normalize_version "jq-1.8.1")
    [ "$result" = "1.8.1" ]
}

@test "normalize_version removes v prefix" {
    result=$(normalize_version "v2.1.0")
    [ "$result" = "2.1.0" ]
}

@test "normalize_version removes tool-v prefix" {
    result=$(normalize_version "tool-v3.0.0")
    [ "$result" = "3.0.0" ]
}

@test "normalize_version removes kubectl- prefix" {
    result=$(normalize_version "kubectl-1.28.0")
    [ "$result" = "1.28.0" ]
}

@test "normalize_version handles already clean version" {
    result=$(normalize_version "1.2.3")
    [ "$result" = "1.2.3" ]
}

@test "normalize_version handles unknown version" {
    result=$(normalize_version "unknown")
    [ "$result" = "unknown" ]
}

@test "normalize_version handles empty string" {
    result=$(normalize_version "")
    [ "$result" = "" ]
}

# version_compare() 関数のテスト
@test "version_compare detects equal versions" {
    result=$(version_compare "1.8.1" "1.8.1")
    [ "$result" = "equal" ]
}

@test "version_compare detects equal versions with prefix normalization" {
    result=$(version_compare "1.8.1" "jq-1.8.1")
    [ "$result" = "equal" ]
}

@test "version_compare detects github newer" {
    result=$(version_compare "1.8.0" "1.8.1")
    [ "$result" = "github_newer" ]
}

@test "version_compare detects package newer" {
    result=$(version_compare "1.8.1" "1.8.0")
    [ "$result" = "package_newer" ]
}

@test "version_compare handles semantic versioning" {
    result=$(version_compare "1.0.0" "1.0.1")
    [ "$result" = "github_newer" ]
}

@test "version_compare handles major version differences" {
    result=$(version_compare "1.9.9" "2.0.0")
    [ "$result" = "github_newer" ]
}

@test "version_compare handles unknown versions" {
    result=$(version_compare "unknown" "1.0.0")
    [ "$result" = "unknown" ]
    
    result=$(version_compare "1.0.0" "unknown")
    [ "$result" = "unknown" ]
}

# 実際のバージョン比較のintegrationテスト
@test "integration: jq version comparison works correctly" {
    # jqの実際のケース: local=1.8.1, github=jq-1.8.1
    result=$(version_compare "1.8.1" "jq-1.8.1")
    [ "$result" = "equal" ]
}

@test "integration: mixed prefix version comparison" {
    # 様々なプレフィックスパターンのテスト
    result=$(version_compare "v1.2.3" "tool-v1.2.3")
    [ "$result" = "equal" ]
}

# エラーハンドリングのテスト
@test "version_compare handles malformed versions gracefully" {
    result=$(version_compare "not-a-version" "1.0.0")
    # malformed versionでも比較は実行される（数値部分を抽出）
    [ -n "$result" ]
}

# パフォーマンステスト（基本的なもの）
@test "normalize_version performance test" {
    # 100回実行して関数が正常に動作することを確認
    for i in {1..100}; do
        result=$(normalize_version "test-v${i}.0.0")
        [ "$result" = "${i}.0.0" ]
    done
}