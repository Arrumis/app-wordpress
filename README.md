# app-wordpress

WordPress を独立リポジトリとして扱うための新しい正本候補です。実データと秘密情報を repo から切り離し、`.env.local` と `compose.yaml` だけで再構築しやすい形にしています。

## 日本語メモ

GitHub のコミット一覧が英語で分かりにくい場合は、[コミット履歴の日本語メモ](docs/COMMIT_HISTORY_JA.md) を見てください。

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
- `data/db/`

## データ初期化

```bash
./scripts/init-data-dirs.sh
```

## メモ

- reverse proxy 連携は別 override file で追加する想定です
- DB パスワードは必ず `.env.local` で変更してください
