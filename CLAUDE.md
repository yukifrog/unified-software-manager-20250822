# Claude Code 設定

## Git ワークフロー設定
### **Commit提案**
- **自動commit提案**: Claude Code組み込み選択機能を試行する
- **提案形式**: 
  - 通常: 「変更をcommitしますか？ 1) yes 2) no」
  - 試験的: Claude Code組み込みUI使用（利用可能な場合）
- **フォールバック**: テキスト選択形式
- **提案タイミング**:
  - 複数ファイルの修正完了時
  - 機能追加・バグ修正の完了時
  - テスト・動作確認の完了時
  - 一連のタスクの完了時
  - 現在のタスクが終了して、別のタスクに移ろうとするとき

### **Push提案**
- **自動push提案**: commitが蓄積したタイミングで選択形式で提案する
  - 「リモートにpushしますか？ 1) yes 2) no」
  - 「変更をpushしておきますか？ 1) yes 2) no」
  - 「そろそろpushした方がよさそうです 1) yes 2) no」
  - 「バックアップのためにpushしますか？ 1) yes 2) no」
- **提案タイミング**:
  - 複数commit蓄積時（2-3個以上）
  - 大きな機能完成時
  - 作業セッション終了前
  - 重要な修正完了時
  - 現在のタスクが終了して、別のタスクに移ろうとするとき

### **プルリクエスト提案**
- **自動PR提案**: feature完成時に選択形式でプルリクエスト作成を提案する
  - 「プルリクエストを作成しますか？ 1) yes 2) no」
  - 「PRを作ってレビュー依頼しますか？ 1) yes 2) no」
  - 「変更をPRにまとめますか？ 1) yes 2) no」
  - 「この機能のPRを作成しますか？ 1) yes 2) no」
- **提案タイミング**:
  - 機能ブランチでの開発完了時
  - 複数の関連commitが完成時
  - バグ修正完了時
  - ドキュメント更新完了時
  - 現在のタスクが終了して、別のタスクに移ろうとするとき

## AI使用設定
- **ローカルAI優先**: llm + ollama を使用してClaude API使用量を節約
- **使用モデル**: 軽量モデル (1-3B parameters) を優先して高速応答
- **静的解析ツール優先**: AIを使わなくても解析できるlint、typecheck、shellcheck等は積極的に使用（速度面で有利）

## 開発設定
- **静的解析ツール**: shellcheck, shfmt, yamllint, bats
- **テストコマンド**: `bats tests/` (Bashテストフレームワーク)
- **リントコマンド**: `shellcheck *.sh`, `yamllint .github/`
- **フォーマットコマンド**: `shfmt -w *.sh`
- **バージョンチェッカー**: `./version-checker.sh --check-all` (全ツールの更新確認)

## ツール更新方針
### **sudo必要ツール**
- ollama, terraform等のシステム全体インストールツールはClaude Codeセッション外で手動更新
- ディスク容量節約とセキュリティの観点から推奨
- 更新後は `tools.yaml` のcurrent_versionを手動更新

### **バイナリダウンロード型ツール**  
- ~/.local/bin/ 配下に配置してPATH経由で実行
- 自動更新可能: fzf, bat, fd, lazygit, delta, btop, zoxide, yq, direnv等
- 更新後は `tools.yaml` のcurrent_versionを自動更新

### **パッケージマネージャー型ツール**
- npm global: `npm update -g <package>` で更新
- pip: `pip install --user --upgrade <package>` で更新  
- cargo: `cargo install <package>` で更新
- Dependabotモニタリングファイルで更新通知受信

## 自動化設定
### **Subagent活用**
- **code-quality-agent**: シェルスクリプト編集完了時に静的解析ツール一括実行
- **pr-creation-agent**: 機能完成時にPR作成プロセスを自動化
- **dependency-update-agent**: 全パッケージマネージャー更新チェック→実行→テスト→commit自動化
  - バージョンチェッカー実行 (`./version-checker.sh --check-all`)
  - 各ツールの自動更新実行
  - tools.yaml の current_version フィールド自動更新
  - Dependabotモニタリングファイル同期 (package.json, requirements.txt等)
- **project-setup-agent**: 新プロジェクト用の環境構築自動化 (mise, pre-commit, direnv等)
- **documentation-sync-agent**: ドキュメントと実装の整合性チェック・同期
- **ai-model-switch-agent**: タスクに応じた最適AI選択・実行 ⭐

### **Hook活用**  
- **tool-call-hook**: .shファイル編集時のshellcheck自動実行
- **user-prompt-submit-hook**: 複数ファイル変更完了時のcommit提案
- **user-input-wait-hook**: ユーザー入力待ち状態での通知・状況確認 ⭐
- **dependency-change-hook**: package.json等変更検知時の依存関係更新提案
- **large-file-warning-hook**: 大容量ファイル検知時の.gitignore追加提案  
- **security-scan-hook**: APIキー・シークレット検知時のgitleaks自動実行

### **AI モデル選択ルール** 🧠
- **軽量タスク** (1-8秒): ollama 1-3Bモデル
  - ファイル名生成、簡単な修正提案、構文チェック解釈
- **中程度タスク** (8-15秒): ollama 7-8Bモデル  
  - コードレビュー、リファクタリング提案、テスト生成
- **複雑タスク** (15秒+): Claude API
  - 新機能設計、複雑なデバッグ、アーキテクチャ設計
- **特殊タスク**: Gemini CLI
  - リアルタイム実行確認、Web検索連携、MCP統合

### **ユーザー入力待ちHook詳細** 🔔
- **通知方法**: Signal Bot via HTTPie (動的メッセージ)
- **メッセージパターン**:
  ```bash
  # 長時間コマンド完了時 (>30秒)
  http POST $TELEGRAM_BOT_URL message="✅ $COMMAND_NAME 完了しました (実行時間: ${DURATION}s)"
  
  # commit/push/PR提案時  
  http POST $TELEGRAM_BOT_URL message="📝 変更をcommitしますか？ $CHANGED_FILES_COUNT ファイル修正"
  http POST $TELEGRAM_BOT_URL message="🚀 リモートにpushしますか？ $COMMITS_COUNT 個のcommit"
  http POST $TELEGRAM_BOT_URL message="🔀 PRを作成しますか？ $FEATURE_NAME 開発完了"
  
  # エラー・警告時
  http POST $TELEGRAM_BOT_URL message="❌ $COMMAND_NAME でエラー: $ERROR_SUMMARY 対処が必要です"
  http POST $TELEGRAM_BOT_URL message="⚠️ 大容量ファイル検出: $FILE_SIZE MB ($FILE_NAME)"
  http POST $TELEGRAM_BOT_URL message="🔒 シークレット検出: $SECRET_TYPE in $FILE_NAME"
  
  # システム・環境変化
  http POST $TELEGRAM_BOT_URL message="📦 新パッケージ検出: $PACKAGE_NAME ($VERSION)"
  http POST $TELEGRAM_BOT_URL message="🔄 依存関係更新: $UPDATE_COUNT 個の更新候補"
  http POST $TELEGRAM_BOT_URL message="🏃 バックグラウンドタスク完了: $BACKGROUND_TASK_NAME"
  
  # AI・開発支援
  http POST $TELEGRAM_BOT_URL message="🧠 AIモデル切り替え: $OLD_MODEL → $NEW_MODEL (タスク: $TASK_TYPE)"
  http POST $TELEGRAM_BOT_URL message="📊 静的解析完了: $ISSUES_COUNT 件の指摘 ($TOOL_NAME)"
  http POST $TELEGRAM_BOT_URL message="🎯 作業セッション完了: $SESSION_DURATION 分間、$FILES_MODIFIED ファイル修正"
  ```
- **変数展開**:
  - $COMMAND_NAME: 実行したコマンド名
  - $DURATION: 実行時間
  - $CHANGED_FILES_COUNT: 変更ファイル数
  - $COMMITS_COUNT: commit数
  - $FEATURE_NAME: 機能名・ブランチ名
  - $ERROR_SUMMARY: エラー要約
  - $FILE_SIZE: ファイルサイズ
  - $FILE_NAME: ファイル名
  - $SECRET_TYPE: 検出されたシークレット種類
  - $PACKAGE_NAME: パッケージ名
  - $VERSION: バージョン
  - $UPDATE_COUNT: 更新候補数
  - $OLD_MODEL/$NEW_MODEL: AIモデル名
  - $TASK_TYPE: タスク種類
  - $ISSUES_COUNT: 問題数
  - $TOOL_NAME: 解析ツール名
  - $SESSION_DURATION: セッション時間
  - $FILES_MODIFIED: 修正ファイル数
  - $BACKGROUND_TASK_NAME: バックグラウンドタスク名

### **Signal Bot 環境変数設定** 📡
```bash
# ~/.bashrc または ~/.zshrc に追加
export SIGNAL_BOT_URL="https://your-signal-bot-webhook-url.com/api/message"
export SIGNAL_BOT_TOKEN="your_bot_token_here"  # 必要に応じて
export SIGNAL_GROUP_ID="your_group_id"         # グループ通知の場合

# 設定確認
echo "Signal Bot URL: $SIGNAL_BOT_URL"

# テスト送信
http POST $SIGNAL_BOT_URL message="🤖 Claude Code通知テスト" \
  Content-Type:application/json
```

### **通知設定のカスタマイズ** ⚙️
```bash
# ~/.bashrc で設定済み - 必要に応じて変更してください
# export CLAUDE_NOTIFY_LEVEL="all"        # all, error-only, important
# export CLAUDE_NOTIFY_MIN_DURATION="30"  # 30秒以上のコマンドのみ通知
# export CLAUDE_NOTIFY_QUIET_HOURS="22-08" # 静音時間帯 (22:00-08:00)
# export CLAUDE_NOTIFY_ENABLED="true"     # 通知の有効/無効
```

## Dependabotモニタリング設定 📦
### **監視対象ファイル**
- `monitoring/nodejs-tools/package.json` - npm グローバルパッケージ監視
- `monitoring/python-tools/requirements.txt` - pip パッケージ監視
- `monitoring/ruby-tools/Gemfile` - gem パッケージ監視
- `monitoring/go-tools/go.mod` - Go モジュール監視

### **監視対象パッケージ例**
```json
// package.json
{
  "@google/gemini-cli": "0.1.22",
  "@anthropic-ai/claude-code": "1.0.92"
}
```

```txt
# requirements.txt  
httpie==3.2.4
requests==2.31.0
```

### **更新ワークフロー**
1. Dependabotが新バージョンを検知→PR自動作成
2. Claude Code でPRレビュー→マージ
3. tools.yamlのcurrent_version手動更新
4. 実際のツール更新 (手動/自動選択)

## 主要ツール最新バージョン確認 🔍
```bash
# バージョン一括チェック
./version-checker.sh --check-all

# 個別確認
ollama --version        # 0.11.7 (sudo必要)
gemini -v              # 0.1.22 (npm)
fzf --version          # 0.65.1 (binary)
bat --version          # 0.25.0 (binary)
lazygit --version      # 0.54.2 (binary)
btop --version         # 1.4.4+GPU (source build)
```