
**アプリケーション名**

- `placenest`

**アプリケーション概要**

- **説明**: `placenest` はユーザーごとに階層化された「場所(Place)」を作成し、その下に「品目(Item)」を登録・管理できる個人用在庫管理／整理アプリです。主な特徴は以下の通りです。
	- 階層構造の場所管理（`ancestry` を利用）
	- 品目の追加・編集・削除、未分類へのクイック追加
	- ユーザー認証（`devise`）とユーザー固有データ管理
	- Turbo による部分更新（ツリーのインライン追加など）

**URL**

- デプロイ済みURL: https://placenest-q7m4.onrender.com

**テスト用アカウント**

- サンプルユーザー（ローカル用）: `test@test,com` / `111111`
- basic認証: `admin` / `1111`

**利用方法**

- サイトへアクセスし、アカウント登録またはサンプルアカウントでログイン。
- 「場所」ツリーで階層を作成し、ツリーを選択して右ペインでその場所の品目を表示。
- 品目は新規追加・編集・削除が可能。未分類へのクイック追加機能あり。
- 検索ボックスにキーワードを入れると現在選択中の場所内で絞り込み可能。

**アプリケーションを作成した背景**

- 日常的な物品やコレクションを場所ごとに整理・管理したく、階層的に分類できるUIと、素早く品目を追加できる操作性を目指して作成しました。個人の持ち物管理や小規模チームの備品管理などに向きます。

**実装した機能についての画像やGIFおよびその説明※**

- ログイン・認証: `devise` を利用した登録・ログイン画面（Gyazoリンクをここに貼る）
- 場所ツリー: `ancestry` を用いた階層ツリー表示。インラインで場所を追加できる（GyazoGIF推奨）
- 品目管理: 品目の新規作成・編集・削除、未分類クイック追加（Gyazo画像）
- 検索機能: 選択中の場所内でのキーワード検索（Gyazo画像）

**実装予定の機能**

- ソーシャルログイン（OAuth）
- 画像アップロードとサムネイル生成（ActiveStorage + S3）
- ユーザー間での共有・権限管理機能

**データベース設計**

- 主なテーブル:
	- `users` (Deviseで認証、`nickname` を保持)
	- `places` (階層構造: `ancestry`, `name`, `description`, `user_id`)
	- `items` (`name`, `quantity`, `note`, `status`, `place_id`, `user_id`)
- ER図: [![Image from Gyazo](https://i.gyazo.com/b2b7c38a34c63943f3cb85dabf052738.png)](https://gyazo.com/b2b7c38a34c63943f3cb85dabf052738)

**画面遷移図**

- 画面遷移図: [![Image from Gyazo](https://i.gyazo.com/d2d7bc9f018b7581649f7782b0410878.png)](https://gyazo.com/d2d7bc9f018b7581649f7782b0410878)

**開発環境**

- 言語・フレームワーク: Ruby 3.2 / Ruby on Rails 7.1
- 認証: `devise`, i18n: `devise-i18n`
- 階層管理: `ancestry`
- DB: 開発は MySQL (`mysql2`)、本番は PostgreSQL 想定（`Gemfile`参照）
- フロント: importmap / Turbo / Stimulus

**ローカルでの動作方法**

1. リポジトリをクローン

```bash
git clone https://github.com/f-sekiya/placenest.git
cd placenest
```

2. Ruby と DB（MySQL）を準備し、`config/database.yml` に接続情報を設定

3. 依存関係インストール・DBセットアップ

```bash
bundle install
bin/importmap
yarn install --check-files # if using yarn-managed packages
rails db:create db:migrate db:seed
```

4. サーバ起動

```bash
rails server
# ブラウザで http://localhost:3000 を開く
```

**工夫したポイント**

- `ancestry` を利用して場所の入れ子構造を扱いやすく実装。削除時の制約や並び替えをコントローラ側で配慮。
- `devise` による堅牢な認証と、ユーザーごとに未分類のPlaceを自動生成する仕組みで初期状態を保証。
- Explorer風のUI（左ツリー／右詳細）と Turbo を組み合わせ、画面遷移を減らし操作性を向上。

**改善点**

- 画像や添付ファイルの ActiveStorage + S3 化とサムネイル処理の導入。
- テストカバレッジ（RSpec・System Spec）の拡充とCIの導入。
- パフォーマンス改善（インデックス追加、N+1対策、クエリ最適化）。

**制作時間**

- 約 40〜60 時間（設計・実装・テスト・調整を含む）
