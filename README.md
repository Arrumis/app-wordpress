# app-wordpress

WordPress と MariaDB を Docker で動かすためのリポジトリです。
WordPress 本体ファイルとデータベースを指定した保存先へ置けます。

## 使い方

```bash
cp .env.example .env.local
./scripts/init-data-dirs.sh
docker compose --env-file .env.local up -d
```

ブラウザで開く画面:

- WordPress: `http://localhost:8080`

## 変更する値

`.env.example` は公開用の見本です。実際の値は `.env.local` に書きます。

- `HOST_DATA_DIR`: WordPress 本体とデータベースを置く場所です。
- `WORDPRESS_DB_PASSWORD` と `MYSQL_PASSWORD`: 同じ値にします。
- `MYSQL_ROOT_PASSWORD`: データベース管理者のパスワードです。必ず変更します。
- `APP_PORT` と `DB_PORT`: 他サービスと重なるときだけ変えます。
- `APP_WORDPRESS__...`: 親リポジトリからまとめて設定するときに使います。

## データ

GitHub に上げるもの:

- `compose.yaml`
- `.env.example`
- `scripts/`
- `README.md`

GitHub に上げないもの:

- `.env.local`
- `data/html/`
- `data/db/`

既存環境から移す場合は、旧 `wp` ディレクトリを `HOST_DATA_DIR` に指定します。

## 既存データベースの移行

稼働中の MariaDB ディレクトリをそのままコピーすると壊れることがあります。
WordPress の `html` はファイルコピーで移せますが、データベースはダンプで移す方が安全です。

```bash
docker exec wp-mariadb-20250920 sh -lc \
  'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --quick --routines --triggers --events --databases "wp-db"' \
  > /tmp/wp-db.sql
```

移行先で取り込みます。

```bash
./scripts/restore-db-dump.sh --dump /tmp/wp-db.sql --reset-db-data
```

`--reset-db-data` はデータベース保存先だけを消して入れ直します。WordPress の `html` は消しません。
