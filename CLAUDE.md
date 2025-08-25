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

## AI使用設定
- **ローカルAI優先**: llm + ollama を使用してClaude API使用量を節約
- **使用モデル**: 軽量モデル (1-3B parameters) を優先して高速応答
- **静的解析ツール優先**: AIを使わなくても解析できるlint、typecheck、shellcheck等は積極的に使用（速度面で有利）

## 開発設定
- **静的解析ツール**: shellcheck, shfmt, yamllint, bats
- **テストコマンド**: `bats tests/` (Bashテストフレームワーク)
- **リントコマンド**: `shellcheck *.sh`, `yamllint .github/`
- **フォーマットコマンド**: `shfmt -w *.sh`

## 自動化設定
### **Subagent活用**
- **code-quality-agent**: シェルスクリプト編集完了時に静的解析ツール一括実行
- **pr-creation-agent**: 機能完成時にPR作成プロセスを自動化
- **dependency-update-agent**: 全パッケージマネージャー更新チェック→実行→テスト→commit自動化
- **project-setup-agent**: 新プロジェクト用の環境構築自動化 (mise, pre-commit, direnv等)
- **documentation-sync-agent**: ドキュメントと実装の整合性チェック・同期
- **ai-model-switch-agent**: タスクに応じた最適AI選択・実行 ⭐

### **Hook活用**  
- **tool-call-hook**: .shファイル編集時のshellcheck自動実行
- **user-prompt-submit-hook**: 複数ファイル変更完了時のcommit提案
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