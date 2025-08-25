#!/bin/bash
# Claude Code Telegram Bot 環境変数設定
# 使用方法: source telegram_env.sh

# 機密情報を.env.telegramから読み込み
if [ -f ".env.telegram" ]; then
    source .env.telegram
    echo "✅ Telegram認証情報を読み込みました"
else
    echo "⚠️  .env.telegram ファイルが見つかりません"
    echo "📝 .env.telegram を作成して以下を設定してください:"
    echo "export TELEGRAM_BOT_TOKEN=\"your_actual_bot_token\""
    echo "export TELEGRAM_CHAT_ID=\"your_actual_chat_id\""
fi

# 通知設定カスタマイズ
export CLAUDE_NOTIFY_LEVEL="all"        # all, error-only, important  
export CLAUDE_NOTIFY_MIN_DURATION="30"  # 30秒以上のコマンドのみ通知
export CLAUDE_NOTIFY_QUIET_HOURS="22-08" # 静音時間帯 (22:00-08:00)

echo "🧪 テスト: ./claude_notify.sh \"テストメッセージ\""