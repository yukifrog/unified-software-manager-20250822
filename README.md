# App Updater - 統合プログラム更新管理ツールスイート

**⚠️ 注意: このプロジェクトは現在開発途上です。一部の機能は未実装または未統合です。**

このリポジトリは、システム内のプログラムを検出し、更新を管理するための一連のスクリプト（ツールスイート）を提供します。YAML形式でのデータ管理へ移行中ですが、一部のスクリプトは古いJSON形式に依存しており、完全には統合されていません。

## ✨ 主な特徴

- **多彩なプログラム検出**: パッケージマネージャー（apt, snap）、手動インストール、AppImageなどを検出。
- **YAMLベースのデータ管理**: 人間が読みやすく、Gitとの相性が良いYAML形式でプログラム情報を管理 (`update-manager.sh` 使用時)。
- **スタンドアロンツール**: Gitリポジトリや手動インストールされたバイナリを個別に管理する強力なスクリプトを提供。

## ❗ 現在のステータスと既知の問題

このツールスイートは、統一された単一のアプリケーションとしてではなく、**複数の独立したスクリプトの集合体**として機能します。

- **データ形式の非互換性**:
    - メインの`update-manager.sh`はデータを **`~/.update-manager/programs.yaml`** に保存します。
    - `git-updater.sh`と`manual-tracker.sh`は **`~/.update-manager/programs.json`** を読み込もうとします。このファイルは現在自動生成されません。
- **機能の未統合**: `update-manager.sh`は、`git-updater.sh`や`manual-tracker.sh`の機能を呼び出すことができません。これらは個別に実行する必要があります。
- **一部機能の未実装**: `update-manager.sh`の`--update`オプションなど、READMEの過去のバージョンに記載されていた機能はまだ実装されていません。

## 🛠️ インストールとセットアップ

1.  **リポジトリをクローン:**
    ```bash
    git clone https://github.com/your-username/app-updater.git
    cd app-updater
    ```

2.  **セットアップスクリプトを実行:**
    このスクリプトは、依存関係（`git`, `curl`）をチェックし、各スクリプトに実行権限を付与します。
    ```bash
    ./setup.sh
    ```
    必要に応じて、`~/.local/bin`にシンボリックリンクを作成することもできます。
    ```bash
    ./setup.sh --symlinks
    ```

## 📜 各スクリプトの使用法

### 1. `update-manager.sh` (メインスキャン＆リスト管理)

システムのプログラムをスキャンし、`programs.yaml`ファイルを生成・管理する中心的なスクリプトです。

**主な機能:**
- **初回スキャン (推奨):**
  `detect-all-programs.sh`を呼び出し、詳細なスキャンを実行します。
  ```bash
  ./update-manager.sh --full-scan
  ```
- **プログラム一覧表示:**
  ```bash
  # 全プログラム
  ./update-manager.sh --list

  # カテゴリ別 (例: apt)
  ./update-manager.sh --list apt
  ```
- **統計情報表示:**
  ```bash
  ./update-manager.sh --stats
  ```
- **更新チェック (APT/Snapのみ):**
  パッケージマネージャーで更新可能なパッケージを確認します。
  ```bash
  ./update-manager.sh --check-updates
  ```

### 2. `git-updater.sh` (Gitリポジトリ管理)

**注意:** このスクリプトは`programs.json`を読み込もうとするため、現状では`update-manager.sh`と連携しません。手動での利用や、将来の統合を前提としたツールです。

**主な機能:**
- `--check-only`: 更新の有無をチェックします。
- `--update-all`: 全てのGitリポジトリを更新します。
- `--update <name>`: 特定のリポジトリを更新します。

### 3. `manual-tracker.sh` (手動インストール管理)

**注意:** こちらも`programs.json`に依存しています。`manual-config.json`ファイルで更新元（GitHubリリース等）を定義することで、手動インストールしたプログラムの更新を追跡できます。

**主な機能:**
- **更新チェック:**
  ```bash
  ./manual-tracker.sh --check-updates
  ```
- **追跡対象の追加:**
  ```bash
  # GitHubリポジトリを更新元として追加
  ./manual-tracker.sh --add /usr/local/bin/kubectl github:kubernetes/kubernetes
  ```
- **バックアップ作成:**
  ```bash
  ./manual-tracker.sh --backup /usr/local/bin/kubectl
  ```

## 📁 ディレクトリ構造

スクリプトを実行すると、`~/.update-manager/`に以下のファイルが生成されます。

- `programs.yaml`: `update-manager.sh --full-scan`で生成されるメインのデータベース。
- `update.log`: `update-manager.sh`のログファイル。
- `manual-config.json`: `manual-tracker.sh`用の設定ファイル。更新ソースなどを定義します。
- `checksums.txt`: `manual-tracker.sh`がファイルの変更を追跡するためのチェックサム履歴。
- `git-updates.log`: `git-updater.sh`のログファイル。
- `backups/`: `manual-tracker.sh`で作成したバックアップが保存されるディレクトリ。

## 🤝 貢献

このプロジェクトは開発の初期段階です。特に、以下の点に関する貢献を歓迎します。
- 各スクリプトの機能を`update-manager.sh`に統合する。
- `git-updater.sh`と`manual-tracker.sh`をYAML (`programs.yaml`) に対応させる。
- `update-manager.sh`に更新実行機能 (`--update`) を実装する。

バグ報告や機能要望は、Issues を通じて報告してください。

## 📄 ライセンス

このツールセットはMITライセンスの下で提供されます。
