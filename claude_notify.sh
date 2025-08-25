#!/bin/bash

# Claude Code Telegram通知システム
# 使用方法: ./claude_notify.sh "メッセージ内容"

claude_notify() {
    local message="$1"
    
    # 環境変数チェック
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "⚠️  TELEGRAM_BOT_TOKEN が設定されていません"
        echo "設定例: export TELEGRAM_BOT_TOKEN=\"your_bot_token_here\""
        return 1
    fi
    
    if [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "⚠️  TELEGRAM_CHAT_ID が設定されていません"
        echo "設定例: export TELEGRAM_CHAT_ID=\"your_chat_id_here\""
        return 1
    fi
    
    # メッセージチェック
    if [ -z "$message" ]; then
        echo "使用方法: claude_notify \"メッセージ内容\""
        return 1
    fi
    
    # Telegram送信
    http POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
         Content-Type:application/json \
         <<< "{\"chat_id\":\"$TELEGRAM_CHAT_ID\",\"text\":\"🤖 Claude Code: $message\"}"
}

# スクリプトとして直接実行された場合
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    claude_notify "$1"
fi