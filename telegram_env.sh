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

# 通知設定は ~/.bashrc で設定してください
# 設定例: export CLAUDE_NOTIFY_QUIET_HOURS="22-08"

echo "🧪 テスト: ./claude_notify.sh \"テストメッセージ\""