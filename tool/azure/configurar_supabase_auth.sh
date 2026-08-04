#!/usr/bin/env bash
#
# Configura Site URL y callbacks PKCE mediante la Management API de Supabase.
# Conserva las URLs permitidas que ya existan y añade las indicadas.
#
# Uso:
#   SUPABASE_ACCESS_TOKEN=... tool/azure/configurar_supabase_auth.sh \
#     PROJECT_REF https://app.example.com \
#     https://salud-dental-prod.example.azurestaticapps.net

set -euo pipefail

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "Se requieren curl y jq." >&2
  exit 1
fi

: "${SUPABASE_ACCESS_TOKEN:?Falta SUPABASE_ACCESS_TOKEN}"

if [[ "$#" -lt 2 ]]; then
  echo "Uso: $0 PROJECT_REF SITE_URL [ADDITIONAL_REDIRECT_URL ...]" >&2
  exit 2
fi

project_ref="$1"
site_url="${2%/}"
shift 2

if [[ ! "$project_ref" =~ ^[a-z0-9]{20}$ ]]; then
  echo "PROJECT_REF no tiene el formato esperado." >&2
  exit 2
fi
if [[ ! "$site_url" =~ ^https://[^/]+$ ]]; then
  echo "SITE_URL debe ser un origen HTTPS sin ruta ni slash final." >&2
  exit 2
fi

api_url="https://api.supabase.com/v1/projects/$project_ref/config/auth"
authorization="Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
current="$(curl --fail --silent --show-error "$api_url" -H "$authorization")"

redirects_file="$(mktemp)"
trap 'rm -f "$redirects_file"' EXIT

jq -r '.uri_allow_list // ""' <<<"$current" |
  tr ',' '\n' |
  sed '/^[[:space:]]*$/d' >"$redirects_file"
printf '%s\n' "$site_url" >>"$redirects_file"

for redirect_url in "$@"; do
  normalized="${redirect_url%/}"
  if [[ ! "$normalized" =~ ^https://[^/]+$ ]]; then
    echo "Callback inválido: $redirect_url" >&2
    exit 2
  fi
  printf '%s\n' "$normalized" >>"$redirects_file"
done

uri_allow_list="$(sort -u "$redirects_file" | paste -sd, -)"
payload="$(
  jq -n \
    --arg site_url "$site_url" \
    --arg uri_allow_list "$uri_allow_list" \
    '{site_url: $site_url, uri_allow_list: $uri_allow_list}'
)"

curl \
  --fail \
  --silent \
  --show-error \
  --request PATCH \
  "$api_url" \
  -H "$authorization" \
  -H 'Content-Type: application/json' \
  --data "$payload" >/dev/null

verified="$(curl --fail --silent --show-error "$api_url" -H "$authorization")"
if [[ "$(jq -r '.site_url' <<<"$verified")" != "$site_url" ]]; then
  echo "Supabase no confirmó Site URL para $project_ref." >&2
  exit 1
fi

echo "Auth de Supabase configurado para $site_url."
