#!/usr/bin/env bash
#
# Crea/actualiza los dos Static Web Apps y registra su configuración pública y
# sus deployment tokens en GitHub Environments. No imprime ningún token.
#
# Requiere sesiones activas en `az` y `gh`, además de:
#   AZURE_SUBSCRIPTION_ID
#   AZURE_APP_NAME_PREFIX       (globalmente único)
# Opcionales:
#   AZURE_RESOURCE_GROUP       (rg-salud-dental-web)
#   AZURE_DEPLOYMENT_LOCATION  (eastus)
#   AZURE_SWA_LOCATION         (eastus2)
#   AZURE_SWA_SKU              (Free)
#
# Las variables SUPABASE_* son opcionales. Si se proporcionan, se registran en
# el environment correspondiente sin guardarlas en disco:
#   TEST_SUPABASE_URL / TEST_SUPABASE_PUBLISHABLE_KEY
#   PRODUCTION_SUPABASE_URL / PRODUCTION_SUPABASE_PUBLISHABLE_KEY

set -euo pipefail

cd "$(dirname "$0")/../.."

for command_name in az gh jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Falta el comando requerido: $command_name" >&2
    exit 1
  fi
done

: "${AZURE_SUBSCRIPTION_ID:?Falta AZURE_SUBSCRIPTION_ID}"
: "${AZURE_APP_NAME_PREFIX:?Falta AZURE_APP_NAME_PREFIX}"

resource_group="${AZURE_RESOURCE_GROUP:-rg-salud-dental-web}"
deployment_location="${AZURE_DEPLOYMENT_LOCATION:-eastus}"
swa_location="${AZURE_SWA_LOCATION:-eastus2}"
sku="${AZURE_SWA_SKU:-Free}"
deployment_name="sd-133-static-web-apps"
repository="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

az account set --subscription "$AZURE_SUBSCRIPTION_ID"

deployment="$(
  az deployment sub create \
    --name "$deployment_name" \
    --location "$deployment_location" \
    --template-file infra/azure/main.bicep \
    --parameters \
      resourceGroupName="$resource_group" \
      resourceGroupLocation="$deployment_location" \
      staticWebAppsLocation="$swa_location" \
      appNamePrefix="$AZURE_APP_NAME_PREFIX" \
      skuName="$sku" \
    --output json
)"

test_app="$(jq -er '.properties.outputs.testAppName.value' <<<"$deployment")"
test_url="$(jq -er '.properties.outputs.testUrl.value' <<<"$deployment")"
production_app="$(jq -er '.properties.outputs.productionAppName.value' <<<"$deployment")"
production_url="$(
  jq -er '.properties.outputs.productionUrl.value' <<<"$deployment"
)"

configure_environment() {
  local environment_name="$1"
  local authorized_branch="$2"
  local app_name="$3"
  local app_url="$4"
  local supabase_url="$5"
  local supabase_key="$6"
  local branch_policies
  local authorized_policy_exists=false
  local token

  gh api \
    --method PUT \
    "repos/$repository/environments/$environment_name" \
    --input - <<EOF >/dev/null
{
  "wait_timer": 0,
  "prevent_self_review": false,
  "can_admins_bypass": false,
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF

  branch_policies="$(
    gh api \
    --method GET \
      "repos/$repository/environments/$environment_name/deployment-branch-policies"
  )"

  while IFS=$'\t' read -r policy_id policy_name; do
    if [[ "$policy_name" == "$authorized_branch" ]]; then
      authorized_policy_exists=true
      continue
    fi

    gh api \
      --method DELETE \
      "repos/$repository/environments/$environment_name/deployment-branch-policies/$policy_id" \
      >/dev/null
  done < <(jq -r '.branch_policies[] | [.id, .name] | @tsv' <<<"$branch_policies")

  if [[ "$authorized_policy_exists" == false ]]; then
    gh api \
      --method POST \
      "repos/$repository/environments/$environment_name/deployment-branch-policies" \
      -f name="$authorized_branch" \
      -f type="branch" >/dev/null
  fi

  token="$(
    az staticwebapp secrets list \
      --name "$app_name" \
      --resource-group "$resource_group" \
      --query properties.apiKey \
      --output tsv
  )"
  if [[ -z "$token" ]]; then
    echo "Azure no devolvió el deployment token de $app_name." >&2
    exit 1
  fi

  printf '%s' "$token" |
    gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --env "$environment_name"
  gh variable set AZURE_STATIC_WEB_APP_URL \
    --env "$environment_name" \
    --body "$app_url"

  if [[ -n "$supabase_url" || -n "$supabase_key" ]]; then
    if [[ -z "$supabase_url" || -z "$supabase_key" ]]; then
      echo "Supabase de $environment_name requiere URL y publishable key." >&2
      exit 1
    fi
    gh variable set SUPABASE_URL \
      --env "$environment_name" \
      --body "$supabase_url"
    printf '%s' "$supabase_key" |
      gh secret set SUPABASE_PUBLISHABLE_KEY --env "$environment_name"
  fi
}

configure_environment \
  test \
  dev \
  "$test_app" \
  "$test_url" \
  "${TEST_SUPABASE_URL:-}" \
  "${TEST_SUPABASE_PUBLISHABLE_KEY:-}"

configure_environment \
  production \
  main \
  "$production_app" \
  "$production_url" \
  "${PRODUCTION_SUPABASE_URL:-}" \
  "${PRODUCTION_SUPABASE_PUBLISHABLE_KEY:-}"

printf 'Infraestructura lista.\n'
printf '  test:       %s (%s)\n' "$test_app" "$test_url"
printf '  production: %s (%s)\n' "$production_app" "$production_url"
