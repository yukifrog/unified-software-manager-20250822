#!/usr/bin/env bats

setup() {
    VERSION_CHECKER="${BATS_TEST_DIRNAME}/../version-checker.sh"
}

@test "security baseline - help command works" {
    run "$VERSION_CHECKER" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"バージョンチェッカー"* ]]
}

@test "security baseline - handles non-existent config gracefully" {
    run bash -c "CONFIG_FILE=/nonexistent/config $VERSION_CHECKER --help"
    # Currently this should still work (will change after set -e)
    [ "$status" -eq 0 ]
}

@test "security baseline - handles invalid tool name" {
    run "$VERSION_CHECKER" --check "../../../etc/passwd"  
    [ "$status" -ne 0 ]
}