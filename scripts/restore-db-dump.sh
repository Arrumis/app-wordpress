#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
使い方:
  scripts/restore-db-dump.sh --dump /path/to/wordpress.sql [--reset-db-data]

目的:
  稼働中DBを rsync したあとに MariaDB/InnoDB が起動できない場合、
  論理 dump を正として WordPress DB を復旧します。

注意:
  --reset-db-data を付けた場合、WORDPRESS_DB_DIR 配下の中身を削除してから
  MariaDB を初期化し直します。リンクそのものや WordPress の html は削除しません。

例:
  scripts/restore-db-dump.sh --dump /tmp/wp-db.sql --reset-db-data
EOF
}

dump_file=""
reset_db_data=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dump)
      dump_file="${2:-}"
      shift 2
      ;;
    --reset-db-data)
      reset_db_data=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "不明な引数です: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${dump_file}" || ! -f "${dump_file}" ]]; then
  echo "--dump に存在する SQL dump ファイルを指定してください。" >&2
  exit 1
fi

if [[ -f ".env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env.local"
  set +a
fi

env_file=".env.local"
data_dir="${HOST_DATA_DIR:-./data}"
db_dir="${WORDPRESS_DB_DIR:-${data_dir}/db_data}"
db_name="${WORDPRESS_DB_NAME:-wordpress}"

sql_quote_identifier() {
  local value="$1"
  value="${value//\`/\`\`}"
  printf '`%s`' "${value}"
}

run_compose() {
  docker compose --env-file "${env_file}" "$@"
}

wait_for_mariadb() {
  local i
  local db_container="$1"

  for i in $(seq 1 90); do
    if docker exec "${db_container}" sh -lc \
      'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e "select 1"' >/dev/null 2>&1; then
      echo "MariaDB の root ログイン確認が通りました: ${i}回目"
      return 0
    fi
    sleep 2
  done

  echo "MariaDB が root ログイン可能な状態になりませんでした。" >&2
  docker logs --tail=120 "${db_container}" >&2 || true
  return 1
}

echo "WordPress コンテナを停止します。"
run_compose down

if [[ "${reset_db_data}" -eq 1 ]]; then
  echo "DB ディレクトリの中身を削除して再初期化します: ${db_dir}"
  mkdir -p "${db_dir}"
  if ! find "${db_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; then
    echo "通常ユーザーで削除できないため sudo で削除します: ${db_dir}"
    sudo find "${db_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  fi
else
  echo "DB ディレクトリは削除しません。既存DBへ dump を流し込みます: ${db_dir}"
fi

echo "MariaDB を起動します。"
run_compose up -d db
db_container="$(run_compose ps -q db)"
if [[ -z "${db_container}" ]]; then
  echo "db コンテナを特定できませんでした。" >&2
  exit 1
fi
wait_for_mariadb "${db_container}"

echo "SQL dump をインポートします: ${dump_file}"
docker exec -i "${db_container}" sh -lc \
  'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD"' <"${dump_file}"

quoted_db="$(sql_quote_identifier "${db_name}")"
echo "インポート後の wp_posts 件数を確認します。"
printf 'select count(*), max(post_modified) from %s.wp_posts;\n' "${quoted_db}" |
  docker exec -i "${db_container}" sh -lc 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -N'

echo "WordPress を起動します。"
run_compose up -d wordpress
run_compose ps -a
