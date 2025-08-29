#!/bin/bash

# Hook テスト用スクリプト - 意図的な問題を含む
echo "Hook システム テスト開始"

# 問題1: 未使用変数
unused_variable="test"

# 問題2: クォートされていない変数
echo Hello $USER

# 問題3: 条件文での推奨されない書き方  
if [ $? == 0 ]; then
    echo "Success"
fi

echo "テスト完了"