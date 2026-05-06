# app-wordpress

WordPress を独立リポジトリとして扱うための新しい正本候補です。実データと秘密情報を repo から切り離し、`.env.local` と `compose.yaml` だけで再構築しやすい形にしています。

## 日本語メモ

GitHub のコミット一覧が英語で分かりにくい場合は、[コミット履歴の日本語メモ](docs/COMMIT_HISTORY_JA.md) を見てください。

## サンプル値の置き換え

`.env.example` は公開用の見本です。実際に使う値は `.env.local` に書きます。

- `HOST_DATA_DIR` は WordPress 本体と DB を保存する場所へ変更します
- `WORDPRESS_DB_PASSWORD` と `MYSQL_PASSWORD` は同じ値にします
- `MYSQL_ROOT_PASSWORD` は自分で決めた強い値へ変更します
- `APP_PORT` / `DB_PORT` は他サービスと衝突するときだけ変更します
- 親 repo からまとめて使う場合は、`stack.service.env.local` の `GLOBAL__HOST_DATA_ROOT` や `APP_WORDPRESS__...` を使います

データ配置は旧コンテナと同じ `html` / `db_data` を標準にしています。
HDD移行で `wp` ディレクトリをそのまま使う場合は、`HOST_DATA_DIR=/path/to/wp` とします。

## 起動

```bash
cp .env.example .env.local
./scripts/init-data-dirs.sh
docker compose --env-file .env.local up -d
```

ブラウザ:

- WordPress: `http://localhost:8080`
- MariaDB: `localhost:33060`

必要に応じて `.env.local` の `APP_PORT` と `DB_PORT` を変更してください。

## 管理対象

Git に含めるもの:

- `compose.yaml`
- `.env.example`
- `scripts/`
- `README.md`

Git に含めないもの:

- `.env.local`
- `data/html/`
- `data/db_data/`

## データ初期化

```bash
./scripts/init-data-dirs.sh
```

## 既存DBの移行

稼働中の MariaDB データディレクトリを `rsync` でそのままコピーすると、コピー先で InnoDB のログ整合性が崩れて起動できないことがあります。
WordPress の `html` はファイルコピーで引き継げますが、DB は稼働中コンテナから論理 dump を取り、移行先で流し込む方が安全です。

移行元で dump を作ります。コンテナ名やパスワードは移行元環境に合わせます。

```bash
docker exec wp-mariadb-20250920 sh -lc \
  'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --quick --routines --triggers --events --databases "wp-db"' \
  > /tmp/wp-db.sql
```

移行先へ dump を置いたら、次で DB だけを再初期化して取り込みます。

```bash
./scripts/restore-db-dump.sh --dump /tmp/wp-db.sql --reset-db-data
```

`--reset-db-data` は `WORDPRESS_DB_DIR` の中身だけを削除します。`HOST_DATA_DIR` の symlink、`html`、アップロード済みファイルは削除しません。

## メモ

- reverse proxy 連携は別 override file で追加する想定です
- DB パスワードは必ず `.env.local` で変更してください
