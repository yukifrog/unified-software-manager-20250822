# Claude Code 設定

## Git Commit 設定
- **自動commit提案**: 適切なcommitタイミングでClaude Codeから「commitしましょうか？」と提案する
- **提案タイミング**:
  - 複数ファイルの修正完了時
  - 機能追加・バグ修正の完了時
  - テスト・動作確認の完了時
  - 一連のタスクの完了時

## AI使用設定
- **ローカルAI優先**: llm + ollama を使用してClaude API使用量を節約
- **使用モデル**: 軽量モデル (1-3B parameters) を優先して高速応答
- **静的解析ツール優先**: AIを使わなくても解析できるlint、typecheck、shellcheck等は積極的に使用（速度面で有利）

## 開発設定
- **静的解析ツール**: shellcheck, shfmt, yamllint, bats
- **テストコマンド**: `bats tests/` (Bashテストフレームワーク)
- **リントコマンド**: `shellcheck *.sh`, `yamllint .github/`
- **フォーマットコマンド**: `shfmt -w *.sh`