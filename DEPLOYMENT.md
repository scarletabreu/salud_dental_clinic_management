# Despliegue de Flutter Web en Azure

Esta guía es el runbook de SD-133. La publicación web no depende de una
computadora concreta: Azure se define en Bicep, la configuración se inyecta en
GitHub Actions y cada despliegue queda asociado a un commit y a un artefacto.

## 1. Arquitectura y ambientes

| Ambiente | Rama autorizada | Azure Static Web App | Supabase | GitHub Environment |
|---|---|---|---|---|
| Prueba | `dev` | `<prefijo>-test` | proyecto de prueba | `test` |
| Producción | `main` | `<prefijo>-prod` | proyecto de producción | `production` |

Son dos recursos independientes. No se usan previews de pull requests porque
una rama no confiable no debe recibir acceso a un backend clínico. Cada push a
`dev` o `main` ejecuta análisis, el trinquete de tests, build web, archivo del
resultado y despliegue. Cualquier otra rama queda fuera del trigger y el propio
job vuelve a comprobar la rama antes de leer el build.

Azure Static Web Apps redirige HTTP a HTTPS y administra el certificado tanto
para su hostname como para dominios validados. `staticwebapp.config.json`
añade el fallback SPA, MIME types, CSP y demás headers de seguridad.

## 2. Configuración de compilación

`lib/core/config/app_config.dart` requiere estas tres definiciones:

| Define | Valores | Tratamiento |
|---|---|---|
| `APP_ENVIRONMENT` | `development`, `test`, `production` | fijada por el workflow |
| `SUPABASE_URL` | URL HTTPS del proyecto del ambiente | variable del GitHub Environment |
| `SUPABASE_PUBLISHABLE_KEY` | publishable/anon key del mismo proyecto | secret del GitHub Environment |

La publishable key es pública por diseño y puede verse en el JavaScript final.
Se guarda como secret para que GitHub la enmascare en logs y para evitar
copiarla en YAML; no debe confundirse con una credencial de servidor. Las
claves `sb_secret_*` y `service_role` están prohibidas en el frontend.

Build local equivalente a producción:

```bash
flutter build web \
  --release \
  --pwa-strategy=none \
  --dart-define=APP_ENVIRONMENT=production \
  --dart-define=SUPABASE_URL=https://PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA
rm -f build/web/flutter_service_worker.js
cp staticwebapp.config.json build/web/
```

Se desactiva el service worker legado de Flutter para que una versión anterior
no mantenga indefinidamente el bootstrap. `index.html`, `flutter_bootstrap.js`,
`flutter.js`, `main.dart.js` y `version.json` se sirven con `no-store`; los
assets con nombres estables se almacenan solo un día y deben revalidarse. No se
marca ningún fichero de Flutter como `immutable` porque hoy sus nombres no
contienen un hash. CanvasKit remoto sí usa una ruta versionada por la revisión
del engine.

## 3. Aprovisionamiento inicial

Requisitos de bootstrap que no se guardan en Git:

- una suscripción de Azure y permiso para desplegar a nivel de suscripción;
- Azure CLI autenticado (`az login`);
- GitHub CLI autenticado con administración del repositorio;
- un prefijo globalmente único para los dos Static Web Apps;
- dos proyectos Supabase separados, o una decisión explícita de aceptar datos
  compartidos (no recomendado).

Revisar primero los cambios:

```bash
az deployment sub what-if \
  --location eastus \
  --template-file infra/azure/main.bicep \
  --parameters \
    resourceGroupName=rg-salud-dental-web \
    appNamePrefix=salud-dental-PREFIJO-UNICO
```

El script idempotente despliega Bicep, crea los GitHub Environments, limita
cada uno a su rama, obtiene los deployment tokens sin imprimirlos y registra
las URLs:

```bash
export AZURE_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
export AZURE_APP_NAME_PREFIX=salud-dental-PREFIJO-UNICO

# Opcionales en la primera ejecución; se leen del entorno y no del historial.
export TEST_SUPABASE_URL=https://PROYECTO_TEST.supabase.co
export TEST_SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA_TEST
export PRODUCTION_SUPABASE_URL=https://PROYECTO_PROD.supabase.co
export PRODUCTION_SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA_PROD

tool/azure/provisionar.sh
unset TEST_SUPABASE_PUBLISHABLE_KEY PRODUCTION_SUPABASE_PUBLISHABLE_KEY
```

Los valores finales por GitHub Environment son:

| Nombre | Tipo |
|---|---|
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | secret |
| `SUPABASE_PUBLISHABLE_KEY` | secret |
| `SUPABASE_URL` | variable |
| `AZURE_STATIC_WEB_APP_URL` | variable |

La política de `production` debe requerir `main`; la de `test`, `dev`. Si el
plan de GitHub impide crear la política, el script falla en vez de dejar un
environment abierto.

Los templates están en `infra/azure/`. `main.bicep` crea el resource group y
ambos sitios; `stagingEnvironmentPolicy: Disabled` impide entornos accidentales
en cada recurso. El fichero `main.parameters.example.json` contiene parámetros
no sensibles de referencia.

## 4. Dominio y HTTPS

El dominio se configura después de crear producción porque primero debe
conocerse el hostname de Azure y se necesita acceso al proveedor DNS.

Para un subdominio como `app.clinica.example`:

1. Crear un `CNAME` hacia el hostname `*.azurestaticapps.net` de producción.
2. Iniciar/actualizar la asociación reproducible:

   ```bash
   az deployment group create \
     --resource-group rg-salud-dental-web \
     --name sd-133-production-domain \
     --template-file infra/azure/custom-domain.bicep \
     --parameters \
       staticWebAppName=salud-dental-PREFIJO-UNICO-prod \
       customDomainName=app.clinica.example
   ```

3. Si Azure solicita validación TXT, consultar el token:

   ```bash
   az staticwebapp hostname show \
     --resource-group rg-salud-dental-web \
     --name salud-dental-PREFIJO-UNICO-prod \
     --hostname app.clinica.example \
     --query validationToken \
     --output tsv
   ```

4. Crear el TXT `_dnsauth.app.clinica.example`, repetir el deployment y esperar
   el estado `Ready`. Azure emite y renueva el certificado HTTPS.
5. Cambiar `AZURE_STATIC_WEB_APP_URL` de `production` al dominio definitivo y
   actualizar la configuración Auth descrita abajo.

El DNS es deliberadamente una segunda etapa: su zona puede estar fuera de
Azure y Bicep no debe asumir autoridad sobre ella.

## 5. Supabase Auth y callbacks PKCE

La aplicación inicializa `supabase_flutter` con `AuthFlowType.pkce`. Supabase
solo devuelve el código a orígenes permitidos, por lo que cada proyecto debe
tener su propia Site URL:

- prueba: URL del Static Web App de prueba;
- producción: dominio definitivo; el hostname de Azure puede mantenerse como
  callback adicional para diagnóstico y contingencia.

La configuración se aplica mediante la Management API y conserva callbacks
preexistentes (por ejemplo, los de móvil):

```bash
export SUPABASE_ACCESS_TOKEN=TOKEN_PERSONAL_CON_AUTH_CONFIG_WRITE

tool/azure/configurar_supabase_auth.sh \
  REF_PROYECTO_TEST \
  https://HOST_TEST.azurestaticapps.net

tool/azure/configurar_supabase_auth.sh \
  REF_PROYECTO_PROD \
  https://app.clinica.example \
  https://HOST_PROD.azurestaticapps.net

unset SUPABASE_ACCESS_TOKEN
```

El token de Management API es una credencial administrativa: no se versiona,
no se pasa al build y se elimina del shell al terminar. Los callbacks son
orígenes HTTPS exactos; no se usan comodines en producción. El SDK detecta el
`code` de PKCE en la URL y restaura la sesión, mientras el fallback SPA entrega
`index.html` en una recarga.

## 6. Flujo normal

1. Un PR de una rama de trabajo hacia `dev` pasa por `.github/workflows/ci.yml`.
2. Al integrar en `dev`, `deploy-web-azure.yml` valida y publica prueba.
3. Validar prueba funcionalmente.
4. Promover mediante PR de `dev` a `main`.
5. Al integrar en `main`, el mismo workflow recompila con las variables de
   producción y publica el recurso de producción.

No se debe ejecutar `flutter build web` en una computadora y subir el
directorio manualmente. El artefacto `web-<ambiente>-<sha>` se conserva 30
días y el GitHub Deployment enlaza ejecución, commit, aprobaciones y ambiente.

## 7. Validación después del despliegue

Comprobaciones HTTP:

```bash
base=https://HOST_DEL_AMBIENTE
curl --fail --silent --show-error "$base/" >/dev/null
curl --fail --silent --show-error "$base/ruta/SPA/de/prueba" >/dev/null
curl --head "$base/"
curl --head "$base/flutter_bootstrap.js"
curl --head "$base/assets/AssetManifest.bin"
```

Verificar:

- `/` y una ruta SPA responden `200`;
- `Strict-Transport-Security`, `Content-Security-Policy`,
  `X-Content-Type-Options` y `X-Frame-Options` están presentes;
- bootstrap e índice devuelven `Cache-Control: no-cache, no-store`;
- assets devuelven caché limitada con revalidación;
- HTTP redirige a HTTPS y el certificado corresponde al hostname;
- el login usa el proyecto Supabase correcto;
- cerrar/abrir el navegador conserva una sesión válida;
- un flujo que vuelva con `?code=...` completa PKCE sin `redirect_uri` inválido;
- prueba no crea ni modifica datos en producción.

## 8. Rollback

Azure Static Web Apps no ofrece aquí una promoción binaria entre slots. El
rollback auditable consiste en revertir el cambio defectuoso en la rama
autorizada:

```bash
git switch dev                 # o main para producción
git pull --ff-only
git revert SHA_DEFECTUOSO
```

El revert debe pasar por el mismo PR y las mismas protecciones que cualquier
cambio. Al integrarlo, el workflow recompila la versión anterior con la
configuración vigente y crea un deployment nuevo. No se sube un ZIP local ni
se reutiliza un build de prueba en producción.

Si el problema es infraestructura, ejecutar `az deployment sub what-if` con el
template de un commit conocido y luego desplegarlo. Si es una rotación de
token, usar `az staticwebapp secrets reset-api-key` y volver a registrar
`AZURE_STATIC_WEB_APPS_API_TOKEN` en el GitHub Environment correspondiente.
No borrar el recurso ni el historial de la rama como parte del rollback.

## 9. APK y escritorio

Azure recibe únicamente `build/web`. APK, app bundle y binarios de escritorio
son artefactos de release independientes:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=APP_ENVIRONMENT=production \
  --dart-define=SUPABASE_URL=https://PROYECTO_PROD.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA_PROD

flutter build windows --release \
  --dart-define=APP_ENVIRONMENT=production \
  --dart-define=SUPABASE_URL=https://PROYECTO_PROD.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA_PROD
```

La firma, custodia del keystore, verificación y símbolos de Android están en
`RELEASE.md`. Los instalables se adjuntan a una release/version y nunca se
copian al Static Web App.

## Referencias oficiales

- Azure Static Web Apps: configuración y fallback:
  https://learn.microsoft.com/azure/static-web-apps/configuration
- Tokens de despliegue:
  https://learn.microsoft.com/azure/static-web-apps/deployment-token-management
- Dominios:
  https://learn.microsoft.com/azure/static-web-apps/custom-domain
- Supabase PKCE:
  https://supabase.com/docs/guides/auth/sessions/pkce-flow
- Supabase Management API:
  https://supabase.com/docs/reference/api/updates-a-projects-auth-config
