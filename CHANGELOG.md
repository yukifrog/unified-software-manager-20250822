# Changelog - Unified Software Manager Manager

## [2025-08-23] リネーム完了

### 変更内容
- **ツール名変更**: `App Updater` → `Unified Software Manager Manager`
- **日本語名**: `統合ソフトウェア管理ツール管理ツール`
- **設定ディレクトリ**: `~/.update-manager/` → `~/.unified-software-manager-manager/`
- **メインスクリプト**: `update-manager.sh` → `unified-software-manager-manager.sh`

### 影響を受けるファイル
- ✅ `unified-software-manager-manager.sh` (旧: update-manager.sh)
- ✅ `detect-all-programs.sh` 
- ✅ `git-updater.sh`
- ✅ `manual-tracker.sh`
- ✅ `setup.sh`
- ✅ `README.md`

### 設定の移行
既存の設定がある場合は手動で移行してください：
```bash
# 旧設定ディレクトリから新設定ディレクトリへ
mv ~/.update-manager ~/.unified-software-manager-manager
```

### GitHubリポジトリ
- **リポジトリ名**: `unified-software-manager-20250822` (作成日付含む)
- **ツール名**: `unified-software-manager-manager` 
- **理由**: リポジトリ名には作成日付が含まれているため、ツール名とは少し異なります

## [2025-08-23] YAML形式対応

### 新機能
- ✨ YAML形式でのデータ管理
- ✨ jq依存関係の除去
- ✨ GitHubでの美しい表示対応
- ✨ 人間にとって読みやすい設定ファイル

### 技術的変更
- **データ形式**: JSON → YAML
- **依存関係**: jq不要
- **処理方式**: 内蔵シェル関数による処理

## [2025-08-22] 初回リリース

### 初期機能
- 🔍 パッケージマネージャー自動検出
- 📦 apt, snap, npm, git, 手動インストール対応
- 🔄 統合アップデート管理
- 📊 統計情報とレポート機能