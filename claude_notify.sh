#!/bin/bash

# Claude Code Telegram通知システム
# 使用方法: ./claude_notify.sh "メッセージ内容"

claude_notify() {
    local message="$1"
    
    # 静音時間チェック
    if [ -n "${CLAUDE_NOTIFY_QUIET_HOURS:-}" ]; then
        local current_time=$(date +"%H:%M")
        local quiet_start="${CLAUDE_NOTIFY_QUIET_HOURS%%-*}"
        local quiet_end="${CLAUDE_NOTIFY_QUIET_HOURS##*-}"
        
        # 時刻比較（23:59-08のような日跨ぎも対応）
        local current_hour_min="${current_time//:}"
        local quiet_start_num="${quiet_start//:}"
        local quiet_end_num="${quiet_end//:}"
        
        if [ "$quiet_start_num" -gt "$quiet_end_num" ]; then
            # 日跨ぎパターン (23:59-08)
            if [ "$current_hour_min" -ge "$quiet_start_num" ] || [ "$current_hour_min" -le "$quiet_end_num" ]; then
                echo "🔇 静音時間中 ($quiet_start-$quiet_end) - 通知をスキップ"
                return 0
            fi
        else
            # 通常パターン (08-22)
            if [ "$current_hour_min" -ge "$quiet_start_num" ] && [ "$current_hour_min" -le "$quiet_end_num" ]; then
                echo "🔇 静音時間中 ($quiet_start-$quiet_end) - 通知をスキップ"
                return 0
            fi
        fi
    fi
    
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