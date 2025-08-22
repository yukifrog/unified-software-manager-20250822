# App Updater - 包括的プログラム更新管理ツール

システム内のすべての実行可能プログラムを検出・分類し、適切なアップデータを使用して統合管理するツールセットです。

## 概要

このツールは以下のプログラム管理方式に対応しています：

- **パッケージマネージャー**: apt, snap, npm, pip, gem, cargo, brew, flatpak
- **手動バイナリ**: `/usr/local/bin`, `~/.local/bin`, `~/bin`の実行ファイル
- **Gitリポジトリ**: `git pull`で更新可能なローカルクローン
- **ダウンロードファイル**: AppImage, .deb, .tar.gz等の手動インストール
- **ソースビルド**: `make`, `configure`スクリプト付きディレクトリ

## インストール

1. 必要な依存関係をインストール:
```bash
sudo apt install jq git curl
```

2. スクリプトを実行可能にする:
```bash
chmod +x *.sh
```

## 基本的な使い方

### 1. 初回スキャン
```bash
./update-manager.sh --scan
```

### 2. プログラム一覧表示
```bash
# 全プログラム
./update-manager.sh --list

# カテゴリ別
./update-manager.sh --list apt
./update-manager.sh --list git
./update-manager.sh --list manual
```

### 3. 更新チェック
```bash
./update-manager.sh --check-updates
```

### 4. プログラム更新
```bash
# 全プログラム更新
./update-manager.sh --update all

# 特定プログラム更新
./update-manager.sh --update プログラム名
```

## 各スクリプトの詳細

### update-manager.sh (メインスクリプト)
全体の統合管理を行うメインスクリプトです。

**主な機能:**
- `--scan`: 全プログラムスキャン
- `--list [category]`: プログラム一覧表示
- `--categories`: カテゴリ一覧
- `--check-updates`: 更新チェック
- `--update <target>`: プログラム更新
- `--add-manual <path>`: 手動プログラム追加

### detect-all-programs.sh
システム内の実行可能ファイルを検出・分類します。

**検出対象:**
- PATH内の全実行ファイル
- 手動インストールディレクトリ (`/usr/local/bin`, `/opt`, etc.)
- Gitリポジトリ内の実行ファイル
- AppImageファイル

### classify-update-method.sh
検出されたプログラムの更新方法を分析・分類します。

**分類内容:**
- パッケージマネージャー判定
- 更新方法の推定
- セキュリティリスク評価
- 更新頻度の推定

### git-updater.sh
Git管理されたプログラムの更新を自動化します。

**機能:**
- `--check-only`: 更新可能性チェック
- `--update <name>`: 特定リポジトリ更新
- `--update-all`: 全リポジトリ更新
- 自動ビルド機能（Makefile, CMake, 等）

### manual-tracker.sh
手動インストールプログラムの追跡・管理を行います。

**機能:**
- `--check-updates`: 更新チェック
- `--add <path> [source]`: 追跡対象追加
- `--backup <path>`: バックアップ作成
- `--show-tracking`: 追跡情報表示

## ディレクトリ構造

```
~/.update-manager/
├── programs.json         # プログラム情報データベース
├── manual-config.json    # 手動更新設定
├── checksums.txt         # ファイルチェックサム履歴
├── update.log           # 更新ログ
├── git-updates.log      # Git更新ログ
└── backups/             # バックアップディレクトリ
    └── program_name.timestamp.backup
```

## 設定ファイル

### ~/.update-manager/manual-config.json
手動インストールプログラムの更新ソース設定:

```json
{
  "update_sources": {
    "github_releases": [
      {
        "name": "kubectl",
        "repo": "kubernetes/kubernetes",
        "binary_pattern": "kubectl"
      }
    ],
    "direct_download": [
      {
        "name": "ollama",
        "url": "https://ollama.ai/install.sh",
        "install_method": "curl -fsSL https://ollama.ai/install.sh | sh"
      }
    ]
  }
}
```

## 使用例

### 手動プログラムを追跡対象に追加
```bash
# GitHub リリースから更新
./manual-tracker.sh --add /usr/local/bin/kubectl github:kubernetes/kubernetes

# 直接ダウンロードから更新
./manual-tracker.sh --add /usr/local/bin/ollama url:https://ollama.ai/install.sh
```

### 特定カテゴリの更新チェック
```bash
# Git リポジトリのみチェック
./git-updater.sh --check-only

# 手動インストールプログラムのみチェック
./manual-tracker.sh --check-updates
```

### バックアップ作成
```bash
./manual-tracker.sh --backup /usr/local/bin/important-tool
```

## トラブルシューティング

### jqが見つからない場合
```bash
sudo apt install jq
```

### 権限エラーが発生する場合
一部のプログラム更新には管理者権限が必要です：
```bash
sudo ./update-manager.sh --update all
```

### データファイルが見つからない場合
初回スキャンを実行してください：
```bash
./update-manager.sh --scan
```

## ライセンス

このツールセットはMITライセンスの下で提供されます。

## 貢献

バグ報告や機能要望は、Issues を通じて報告してください。