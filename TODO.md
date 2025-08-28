# TODO - Unified Software Manager Manager

## 🚨 高優先度 (即座に対応)

- [ ] **Smoke Tests 問題解決** (Issue #54)
  - CI成功率を75% → 100%に向上
  - OAuth制限回避のためSmoke Tests削除または代替手法
  - **推定**: 1日

- [x] **Bashセキュリティ強化 - 主要スクリプト** (Issue #56) 
  - `set -euo pipefail` を version-checker.sh, setup.sh に追加完了
  - セキュリティテスト 3個作成・全32テスト通過確認
  - **完了**: 2025-08-28

- [ ] **Bashセキュリティ強化 - 残りスクリプト** (Issue #56 継続)
  - 残り6個のスクリプトに `set -euo pipefail` 追加:
    - claude_notify.sh, test-comparison.sh, runtime-manager-detector.sh
    - lib/version-functions.sh, node-manager-detector.sh, telegram_env.sh
  - 入力検証とクォート修正の実装  
  - **推定**: 半日

- [ ] **Dependabot PR処理** (#47, #48, #49, #50, #51, #24)
  - セキュリティ更新の早期適用
  - 6個のPRレビュー・マージ
  - **推定**: 半日

## ⚡ 中優先度 (パフォーマンス向上)

- [ ] **GitHub API並列処理** (Issue #57)
  - 実行時間短縮: 2-3分 → 15-20秒 (85%削減)
  - xargs -P または GNU parallel での並列化
  - **推定**: 1週間

- [ ] **構造化ログとデバッグモード** (Issue #58)
  - JSON形式ログでメトリクス収集可能に
  - `--debug` オプション追加
  - **推定**: 3-4日

## 🛡️ 長期改善 (品質・拡張性)

- [ ] **エラーハンドリング強化** (Issue #60)
  - ネットワークエラー時のリトライ機構
  - 設定ファイル検証の包括化
  - **推定**: 1週間

- [ ] **プラグインシステム設計** (Issue #59)
  - 新ツール追加の自動化
  - 拡張可能アーキテクチャ設計
  - **推定**: 2週間

## 🔧 設定・環境整備

- [ ] **CLAUDE.md設定と現実の乖離修正**
  - 未実装のSubagent機能削除または実装
  - 動作していないHook設定の整理
  - Signal/Telegram通知設定の見直し
  - **推定**: 2-3日

- [ ] **Emacs Doom設定カスタマイズ**
  - Claude Code開発ワークフロー最適化
  - 生産性向上のための環境整備
  - **推定**: 1日

## 📊 現在の状況

### CI Pipeline Status (80% 成功率) - 最新更新: 2025-08-28
- ✅ **Unit Tests (29 tests)**: 全通過 (1m53s)
- ✅ **Shell Script Linting**: 全通過 (13s)
- ✅ **YAML Validation**: 全通過 (12s)
- ✅ **Auto Update Check**: 通過 (32s) - スケジュール実行成功
- ❌ **Smoke Tests**: 継続失敗 (12s) - OAuth制限により修正不可能

### 待機中のPR (7個) - Dependabot更新
- **Ruby tools**: #52 (Jekyll 4.3→4.4.1), #51 (Rabbit 3.0→4.0.1), #50 (Rouge 4.4→4.6.0), #48 (RDoc 6.6→6.14.2)
- **Node.js tools**: #49 (Gemini CLI 0.1.22→0.2.1), #47 (Claude Code 1.0.92→1.0.93)  
- **Python tools**: #24 (Click 8.1.7→8.1.8)

### 最近の成果
- ✅ **PR #46 対応**: クローズ → PR #53 部分採用・マージ
- ✅ **Integration test fixes**: 全29テスト通過
- ✅ **LLM分析**: 5つの改善Issue作成 (#56-60)
- ✅ **依存関係改善**: yq追加、setup.sh改良
- ✅ **.gitignore修正**: 重要ファイル除外問題解決
- ✅ **TODO.md作成**: タスク永続化完了
- ✅ **Dependabot自動更新**: 3つの成功した更新 (Ruby/Node.js/Python)

## 🎯 推奨実行順序

**Week 1**: Issue #54 → セキュリティ強化 → Dependabot PRs → CLAUDE.md修正  
**Week 2**: GitHub API並列処理実装  
**Week 3**: ログ改善 + エラーハンドリング強化  
**長期**: プラグインシステム設計・実装

## 📝 メモ

### 発見された技術的問題
- OAuth workflow scope制限: `.github/workflows/` 変更不可
- CLAUDE.mdに多数の未実装機能が記載
- Subagent/Hook機能が実際には動作していない
- 設定ファイルと現実の運用に大きな乖離

### 改善により期待される効果
- **CI成功率**: 75% → 100%
- **実行時間**: 2-3分 → 15-20秒
- **開発体験**: 大幅な生産性向上
- **コード品質**: セキュリティ・信頼性向上

---

**Last Updated**: 2025-08-28  
**Total Items**: 8 items + 7 pending PRs  
**High Priority**: 3 items  
**Estimated Total Effort**: 4-6 weeks