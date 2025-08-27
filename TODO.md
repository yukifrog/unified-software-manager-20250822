# TODO - Unified Software Manager Manager

## 🚨 高優先度 (即座に対応)

- [ ] **Smoke Tests 問題解決** (Issue #54)
  - CI成功率を75% → 100%に向上
  - OAuth制限回避のためSmoke Tests削除または代替手法
  - **推定**: 1日

- [ ] **Bashセキュリティ強化** (Issue #56)
  - `set -euo pipefail` を全スクリプトに追加
  - 入力検証とクォート修正の実装
  - **推定**: 1-2日

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

### CI Pipeline Status (75% 成功率)
- ✅ **Unit Tests (29 tests)**: 全通過
- ✅ **Shell Script Linting**: 全通過
- ✅ **YAML Validation**: 全通過
- ❌ **Smoke Tests**: OAuth制限により修正不可能

### 最近の成果
- ✅ **PR #46 対応**: クローズ → PR #53 部分採用・マージ
- ✅ **Integration test fixes**: 全29テスト通過
- ✅ **LLM分析**: 5つの改善Issue作成 (#56-60)
- ✅ **依存関係改善**: yq追加、setup.sh改良

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

**Last Updated**: 2025-08-27  
**Total Items**: 8 items  
**High Priority**: 3 items  
**Estimated Total Effort**: 4-6 weeks