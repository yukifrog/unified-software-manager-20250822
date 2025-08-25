# Claude Code 開発ツール

## 概要

このドキュメントは、Claude Codeと組み合わせることで開発効率を大幅に向上させる推奨ツールを一覧化しています。これらのツールはコマンドライン開発ワークフローに最適化されており、Claude Codeの機能とシームレスに統合されます。

## 📚 **目次**

- [🚀 カテゴリ別推奨ツール](#-カテゴリ別推奨ツール)
  - [📝 エディタ & IDE 統合](#-エディタ--ide-統合)
  - [🔍 検索 & ファイル操作](#-検索--ファイル操作)  
  - [🐛 デバッグ & システム分析](#-デバッグ--システム分析)
  - [⚡ 開発効率](#-開発効率)
  - [🛠️ ビルド & 開発ツール](#️-ビルド--開発ツール)
  - [📊 コード品質 & 解析](#-コード品質--解析)
  - [🐳 コンテナ技術 & 環境再現](#-コンテナ技術--環境再現)
  - [🧪 テスト & 品質保証](#-テスト--品質保証)
  - [🤖 AI & LLM ツール](#-ai--llm-ツール)
  - [🔧 システムユーティリティ](#-システムユーティリティ)
- [🎯 優先インストール推奨事項](#-優先インストール推奨事項)
- [🔄 Unified Software Managerとの統合](#-unified-software-managerとの統合)
- [🚀 クイックスタートコマンド](#-クイックスタートコマンド)
- [📚 ドキュメント & リソース](#-ドキュメント--リソース)
- [🤖 AI協調開発ツール評価レポート](#-ai協調開発ツール評価レポート)
- [🔄 AI協調開発ワークフロー](#-ai協調開発ワークフロー)

## 🚀 **カテゴリ別推奨ツール**

### **📝 エディタ & IDE 統合**

#### Neovim/Vim エコシステム
```bash
# プラグインマネージャー
lazy.nvim          # 遅延読み込み対応の高速で柔軟なプラグインマネージャー
                   # Neovimの起動時間を大幅に改善
packer.nvim        # 宣言的設定が可能な代替プラグインマネージャー

# 必須プラグイン
telescope.nvim     # ファイル、バッファ、gitコミット、LSPシンボルのファジーファインダー
                   # 複数のツールを統一インターフェースで置換
nvim-lspconfig     # コード補完、診断、フォーマットのための簡単LSP設定
                   # NeovimにIDE的機能をもたらす
nvim-treesitter    # tree-sitterパーサーを使用した高度なシンタックスハイライト
                   # コード構造の意味的理解を提供
```

#### VS Code 拡張機能 (Claude Code 対応)
```bash
# 開発効率向上
GitLens            # blame、履歴、ブランチを表示する包括的Git統合
                   # コードの進化と協業パターンを可視化
Thunder Client     # エディタを離れることなく使用できる内蔵REST APIテストツール
                   # シンプルなAPI開発におけるPostmanの代替
Error Lens         # エラーと警告をエディタの行に直接表示
                   # 問題パネルを常にチェックする必要性を削減
Bracket Pair       # 対応する括弧とカッコを色分けコーディング
                   # ネストしたコード構造の可視化に必須
```

### **🔍 検索 & ファイル操作**

#### 既に設定済み ✅
```bash
ripgrep (rg)       # 正規表現とUnicodeサポート付きの超高速テキスト検索
                   # grepより10-100倍高速、バイナリファイルと.gitignoreを無視
fd                 # 合理的なデフォルト設定を持つ直感的なfind置換
                   # findより高速、.gitignoreを尊重、カラー出力
fzf                # ファイル、履歴、プロセス用のインタラクティブファジーファインダー
                   # シェル履歴、git、多くのツールと統合
bat                # シンタックスハイライトとGit統合付きcatクローン
                   # 行番号、ファイル変更を表示、テーマサポート
```

#### 追加推奨
```bash
eza                # Gitステータス、アイコン、カラー付きモダンls置換
                   # ファイルメタデータ、権限、ディレクトリツリーを美しく表示
zoxide             # 頻繁に使用するパスを学習するインテリジェントcd置換
                   # 部分名と使用頻度を使用してディレクトリにジャンプ
broot              # ファジー検索とプレビュー付きインタラクティブツリーナビゲーター
                   # vim的コマンドで大きなディレクトリ構造をナビゲート
```

### **🐛 デバッグ & システム分析**

#### システム監視
```bash
htop               # CPU、メモリ、プロセス管理付きインタラクティブプロセスビューアー
                   # システム監視用のカラーコード化されたソート可能インターフェース
iotop              # プロセス別ディスク読み書きを表示するリアルタイムI/O統計
                   # 開発中のI/Oボトルネック特定に不可欠
ncdu               # ドリルダウンナビゲーション付きインタラクティブディスク使用量解析ツール
                   # ディスク容量を消費している大きなファイルやディレクトリを発見
btop               # 高性能グラフィックとマウスサポート付きモダンhtop代替
                   # GPU監視、ネットワーク統計、美しいターミナルUI
```

#### ネットワーク & API ツール
```bash
httpie             # JSONサポートとシンタックスハイライト付き直感的HTTPクライアント
                   # 読みやすいリクエスト/レスポンス形式でAPIテストに最適
curlie             # httpieスタイルの構文でcurlのパワーを持つcurlラッパー
                   # curlの機能とhttpieの使いやすさを結合
dog                # カラー出力と複数レコードタイプ対応のDNSルックアップツール
                   # より優れたフォーマットでのdigのモダン置換
bandwhich          # プロセス別リアルタイムネットワーク使用率監視
                   # どのプロセスが帯域を使用しているかを表示
```

### **⚡ 開発効率**

#### Git & バージョン管理 ✅
```bash
lazygit            # ブランチ可視化付きフル機能Git TUI
                   # マウスサポート付きインタラクティブステージング、コミット、プッシュ、マージ
delta              # 行番号とテーマ付きシンタックスハイライトdiffビューアー
                   # コード変更のレビューと理解をより簡単に
gh                 # issue、PR、リリース、ワークフロー用公式GitHub CLI
                   # ターミナルを離れることなくGitHubリポジトリを管理
```

#### データ処理 ✅
```bash
jq                 # フィルタリング、マッピング、フォーマッティング機能付き強力JSONプロセッサー
                   # API開発とデータ操作に不可欠
yq                 # jq互換構文を持つYAML/XMLプロセッサー
                   # 設定ファイル操作とCI/CDに最適
```

#### ファイル操作
```bash
rsync              # 差分転送付き堅牢なファイル同期ツール
                   # ネットワークサポート付き効率的バックアップとデプロイ
meld               # 3-way比較機能付きビジュアルdiffとマージツール
                   # マージ競合解決とファイル比較用GUIツール
rclone             # 70+のプロバイダーをサポートする汎用クラウドストレージCLI
                   # Google Drive、AWS S3、Dropboxなどとファイル同期
```

### **🛠️ ビルド & 開発ツール**

#### 言語固有ツール
```bash
# Node.js Ecosystem (via nvm) ✅
node               # JavaScript/TypeScript runtime environment
                   # Latest v24.6.0 with modern ES features and performance improvements
npm                # Default Node.js package manager with workspaces support
                   # Built-in security auditing and dependency management
yarn               # Alternative package manager with deterministic installs
                   # Faster installs, better monorepo support, plug'n'play mode
pnpm               # Fast, disk space efficient package manager with hard links
                   # Saves gigabytes of disk space, faster CI builds

# Python Tools
pyenv              # Python version management with seamless switching
                   # Install multiple Python versions, per-project configuration
pipx               # Install Python CLI applications in isolated environments
                   # Prevents dependency conflicts between tools
poetry             # Modern dependency management with lock files
                   # Virtual environment management and package publishing

# Go Tools
gvm                # Go version manager for multiple Go installations
                   # Switch between Go versions per project
air                # Live reload for Go applications during development
                   # Watches files and rebuilds automatically on changes
```

#### 汎用開発
```bash
direnv             # ディレクトリ別自動環境変数読み込み
                   # ディレクトリに入る際にプロジェクト固有の環境変数を読み込み
just               # シンプルな構文のコマンドランナー (Makeより優秀)
                   # パラメーターサポート付きプロジェクト固有コマンド
watchexec          # 変更時にコマンドを実行するファイルウォッチャー
                   # クロスプラットフォーム、globパターンと無視ファイルサポート
entr               # ファイル変更時にコマンド実行 (Unixフォーカス)
                   # ビルド自動化用のシンプルで信頼性の高いファイル監視

# 統一ランタイム管理 (推奨) ⭐⭐⭐
mise               # 全言語のバージョン管理を統合 (旧rtx)
                   # .mise.tomlで統一管理、direnv連携、nvm/pyenv/gvmを置換
```

### **📊 コード品質 & 解析**

```bash
# Universal Linters
prettier           # Opinionated code formatter supporting 20+ languages
                   # Consistent formatting for JS, TS, JSON, CSS, HTML, Markdown
eslint             # Pluggable JavaScript/TypeScript linter with auto-fixing
                   # Catches bugs, enforces style, supports modern frameworks
shellcheck         # Static analysis tool for shell scripts with helpful suggestions
                   # Finds bugs, suggests improvements, supports all shell types
hadolint           # Dockerfile linter following best practices
                   # Security, optimization, and maintainability checks

# セキュリティツール
gitleaks           # gitリポジトリ内の高速秘密情報検出
                   # APIキー、パスワードのためのコミット、ブランチ、ファイルスキャン
truffleHog         # エントロピー解析付き高度秘密情報スキャナー
                   # 高エントロピー文字列と既知の秘密情報パターンを発見

# コミットフック管理 ⭐⭐
pre-commit         # Git pre-commitフックの統一管理フレームワーク
                   # AI生成コードの自動品質チェック、複数リンターの統合実行
```

### **🐳 コンテナ技術 & 環境再現**

```bash
# コンテナエンジン
docker             # 業界標準コンテナプラットフォーム
                   # アプリケーション配布、環境標準化、CI/CD統合
podman             # Dockerの軽量・セキュア代替 (rootless実行)
                   # Kubernetesネイティブ、systemd統合

# 環境定義・構成管理 ⭐⭐⭐
docker-compose     # マルチコンテナアプリケーション定義
                   # 開発・テスト環境の統一管理
devcontainer       # VS Code Development Containers
                   # リポジトリ内環境定義、mise/pre-commitと統合
act                # GitHub ActionsをローカルでCI/CDデバッグ
                   # 高速フィードバックサイクル、コスト削減
```

### **🧪 テスト & 品質保証**

```bash
# 言語別テストフレームワーク
pytest             # Python包括テスティングフレームワーク
                   # カバレッジ計測、パラメータ化テスト、プラグインエコシステム
jest               # JavaScript/TypeScript標準テスト環境
                   # スナップショット、モック、ウォッチモード
go                 # Go内蔵テストツール (go test)
                   # ベンチマーク、競合状態検出、カバレッジ計測

# AI支援テスト生成 ⭐⭐
# llmでテストケース生成
# cat main.go | llm -m claude-3.5-sonnet "テーブル駆動テストを生成"
# geminiでエッジケース発見
# gemini -p "この関数の境界値・異常系テストケースを提案"

# カバレッジ & 分析
pytest-cov         # Pythonコードカバレッジ計測
                   # HTML/XML レポート、CI統合
istanbul           # JavaScript カバレッジツール
                   # ブランチ・関数・行カバレッジ詳細分析
```

### **🤖 AI & LLM ツール**

```bash
# AI協調開発 ⭐⭐⭐
llm                # Simon Willison製 汎用LLM CLI (Claude API対応)
                   # プロンプト管理、テンプレート、複数モデル統合
ollama             # ローカルLLM実行環境 (Llama, Mistral等)
                   # プライベート環境でのAI活用、オフライン対応
gemini-cli         # Google Gemini公式CLI
                   # リアルタイム実行、Google検索統合、MCP対応
```

### **🔧 システムユーティリティ**

```bash
# Terminal Enhancements
starship           # Fast, customizable shell prompt with Git, language info
                   # Shows project context, Git status, execution time
tmux               # Terminal multiplexer for persistent sessions and window management
                   # Essential for remote development and session persistence
zellij             # Modern tmux alternative with layouts, plugins, and floating panes
                   # User-friendly terminal workspace manager with sensible defaults

# File Management
duf                # User-friendly disk usage display with colors and graphs
                   # Shows available space, mount points, and file system types
dust               # Interactive directory size analyzer with visual tree
                   # Quickly identify large directories and files
procs              # Modern process viewer with tree view and search
                   # Colored output, shows process relationships and resource usage
```

## 🎯 **優先インストール推奨事項**

### **即効性（最初にインストール）**
1. **eza** - カラーとアイコン付き拡張ファイル一覧表示
2. **zoxide** - インテリジェントディレクトリナビゲーション
3. **httpie** - APIテストとHTTPリクエスト
4. **starship** - 美しく情報豊富なシェルプロンプト

### **開発ワークフロー強化**
1. **direnv** - プロジェクト固有環境管理
2. **watchexec** - ファイル変更時の自動コマンド実行
3. **just** - 簡略化されたコマンド実行
4. **btop** - システム監視

### **コード品質 & セキュリティ**
1. **prettier** - 汎用コードフォーマット
2. **shellcheck** - シェルスクリプト検証
3. **gitleaks** - セキュリティスキャン

## 🔄 **Unified Software Managerとの統合**

### ツールを管理に追加
```bash
# 新しいツールを追加するためにtools.yamlを編集
vim monitoring-configs/tools.yaml

# 新しいツールのエントリ例:
eza:
  current_version: "0.15.0"
  github_repo: "eza-community/eza"
  update_method: "binary_download"
  category: "cli"
  priority: "medium"
```

### 監視戦略
- **コマンドラインツール**: `tools.yaml`でbinary_download経由で管理
- **言語固有ツール**: バージョンマネージャー (nvm, pyenv, etc.) 経由で管理
- **エディタプラグイン**: それぞれのエディタ内で管理

## 🚀 **クイックスタートコマンド**

### 基本セットアップ
```bash
# まず統合ソフトウェアマネージャーをインストール
./unified-software-manager-manager.sh

# 優先ツールをtools.yamlに追加してアップデート実行
./version-checker.sh --check-all

# 言語固有ツール用のバージョンマネージャーをインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
curl https://pyenv.run | bash
```

### 検証
```bash
# ツールをテスト
eza -la --icons
zoxide query --list
httpie --version
starship --version
```

## 📚 **ドキュメント & リソース**

### ツールドキュメント
- [ripgrep ユーザーガイド](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [fzf 高度な使用法](https://github.com/junegunn/fzf#usage)
- [Neovim LSP 設定](https://github.com/neovim/nvim-lspconfig)
- [Starship 設定](https://starship.rs/config/)

### 統合ガイド
- [Zoxide セットアップガイド](https://github.com/ajeetdsouza/zoxide#installation)
- [Direnv フックインストール](https://direnv.net/docs/hook.html)
- [GitHub CLI 認証](https://cli.github.com/manual/gh_auth_login)

## 🤖 **AI協調開発ツール評価レポート**

### 🎯 レポートの評価

このレポートは非常に価値の高い提案だと思います！特にAI協調開発の観点で素晴らしい洞察です。

### 🌟 特に優秀な提案:

1. **mise (rtx)** ⭐⭐⭐
   - 現在のnvm/pyenv分散管理の統合ソリューション
   - .mise.tomlでの一元管理は理想的
   - direnv統合で環境切り替え自動化

2. **llm (Simon Willison)** ⭐⭐⭐
   - Claude APIとの直接統合可能
   - プロンプト管理・テンプレート機能
   - unified-software-manager-managerとの哲学が一致

3. **pre-commit** ⭐⭐
   - 既存のlinter(prettier, shellcheck)統合
   - コード品質の自動化
   - Claude生成コードの一貫性確保

### 🤔 慎重に検討すべき項目:

- **ai (GitHub Copilot CLI)**: 有料サービス依存、Claude Codeとの重複
- **cody**: VS Code拡張中心、CLI統合が限定的
- **grip**: 用途が限定的、occasional use

### 💡 統合提案

**Phase 4として追加推奨:**

#### 最優先
- **mise**: 全ランタイム統合管理
- **llm**: Claude API CLI統合
- **pre-commit**: 自動品質管理

#### 次優先
- **tig**: Git可視化（lazygitの軽量版）
- **grip**: Markdownプレビュー

### 🔗 unified-software-manager-managerへの統合アプローチ:

- **mise**: バージョン管理の根本改善
- **llm**: Claude Code workflows直接統合
- **pre-commit**: 品質保証の自動化

このレポートは開発環境の次の進化段階を的確に指摘しています。特にmise + llm + pre-commitの組み合わせは、AI協調開発の理想的な基盤になりそうです。

**実装推奨**: 特にmiseから始めることを強く推奨します！

## 🔄 **AI協調開発ワークフロー**

### 📋 **統合開発プロセス**

#### Phase 1: 環境構築・設計
```bash
# 1. Claude Code: プロジェクト分析・構造設計
# 2. mise: 統一ランタイム環境構築
mise use node@latest python@latest
# 3. pre-commit: コード品質フレームワーク設定
pre-commit install
```

#### Phase 2: 実装・検証サイクル  
```bash
# 1. Claude Code: 精密な実装
# 2. Gemini CLI: リアルタイム実行・検証
gemini -p "実装されたコードをテスト実行して問題点を特定"
# 3. llm: 軽量な修正提案
llm -m claude-3.5-sonnet "エラー解決策を提案: $(cat error.log)"
```

#### Phase 3: 品質保証・最適化
```bash
# 1. pre-commit: 自動品質チェック実行
pre-commit run --all-files
# 2. Claude Code: 構造的リファクタリング
# 3. Gemini CLI: パフォーマンス測定・最適化提案
```

### ⚡ **実用的統合コマンド**

#### AI支援デバッグワークフロー
```bash
# 問題検出 → 分析 → 解決のパイプライン
gemini -p "バグを再現して詳細ログを出力" | \
llm -m claude-3.5-sonnet "ログを分析してroot cause特定" | \
# Claude Code で構造的修正実装
```

#### コードレビューチェーン
```bash
# 多角的レビューで品質向上
git diff HEAD^ | llm -m claude-3.5-sonnet "コードレビュー実施" && \
gemini -p "実行可能性とパフォーマンスをチェック" && \
pre-commit run --files $(git diff --name-only HEAD^)
```

### 🎯 **推奨ツールセット**

**最小構成 (即効性重視):**
- **mise** + **llm** + **pre-commit**

**本格構成 (総合開発効率):**  
- **mise** + **llm** + **gemini-cli** + **pre-commit** + **just**

**エンタープライズ構成:**
- 上記 + **direnv** + **watchexec** + **gitleaks**

---

**最終更新**: 2025-08-25  
**互換性**: Unified Software Manager v2.0+  
**メンテナンス**: アップデートには `./version-checker.sh --check-all` を使用