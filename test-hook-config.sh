#!/bin/bash
set -euo pipefail

# Claude Code Hook System Configuration Test
echo "🧪 Claude Code Hook設定テスト"
echo "================================"

# 環境変数確認
echo "📋 環境変数確認:"
echo "CLAUDE_NOTIFY_ENABLED: ${CLAUDE_NOTIFY_ENABLED:-'未設定'}"
echo "CLAUDE_NOTIFY_QUIET_HOURS: ${CLAUDE_NOTIFY_QUIET_HOURS:-'未設定'}"
echo "TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:-'未設定'}"
echo "TELEGRAM_CHAT_ID: ${TELEGRAM_CHAT_ID:-'未設定'}"
echo ""

# Hook設定ファイル存在確認
echo "📁 Hook設定ファイル:"
if [ -f ".claude/hooks.json" ]; then
    echo "✅ .claude/hooks.json 存在"
    jq -r '.hooks | keys[]' .claude/hooks.json | while read -r hook_type; do
        count=$(jq -r ".hooks.${hook_type} | length" .claude/hooks.json)
        echo "   - ${hook_type}: ${count}個のhook"
    done
else
    echo "❌ .claude/hooks.json が見つかりません"
fi

if [ -f ".claude/hook-config.env" ]; then
    echo "✅ .claude/hook-config.env 存在"
else
    echo "❌ .claude/hook-config.env が見つかりません"
fi
echo ""

# 依存ツール確認
echo "🔧 依存ツール確認:"
tools=("shellcheck" "yamllint" "jq" "markdownlint" "gitleaks" "bats" "gh" "http")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "✅ $tool"
    else
        echo "⚠️  $tool (未インストール)"
    fi
done
echo ""

# .gitignore確認
echo "📝 .gitignore確認:"
if grep -q "claude-backups" .gitignore; then
    echo "✅ バックアップファイル除外設定済み"
else
    echo "❌ バックアップファイル除外設定なし"
fi

if grep -q "claude-session-start" .gitignore; then
    echo "✅ セッション管理ファイル除外設定済み"
else
    echo "❌ セッション管理ファイル除外設定なし"
fi
echo ""

# Telegram通知テスト
echo "📱 Telegram通知テスト:"
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "🧪 Telegram Bot接続をテストしています..."
    if ./claude_notify.sh "Hook設定テスト完了"; then
        echo "✅ Telegram通知成功"
    else
        echo "❌ Telegram通知失敗"
    fi
else
    echo "⚠️  TELEGRAM_BOT_TOKEN または TELEGRAM_CHAT_ID が未設定"
    echo "   設定手順:"
    echo "   1. .env.telegram ファイルを作成"
    echo "   2. export TELEGRAM_BOT_TOKEN=\"your_token\""
    echo "   3. export TELEGRAM_CHAT_ID=\"your_chat_id\""
    echo "   4. source .env.telegram"
fi

echo ""
echo "🎉 Hook設定テスト完了"