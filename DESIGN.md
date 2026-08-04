# Guía de diseño — Salud Dental

En la app conviven **dos estilos visuales**:

- **Sistema A (Material por defecto):** usa directamente `Theme.of(context).colorScheme`
  con widgets Material estándar y poca personalización. (p. ej. pantallas antiguas / placeholders).
- **Sistema B (el nuestro):** el estilo "de producto" basado en la extensión de tema
  **`AppColors`** (`lib/core/presentation/app_colors.dart`). Es el que usan
  `PacientesPage`, `MedicinaListPage` y el shell.

> **Toda UI nueva debe seguir el Sistema B.** Este documento describe sus tokens y
> la anatomía de las pantallas para poder replicarlo de forma consistente.

---

## 1. Tokens de color (`context.appColors`)

Se acceden con la extensión:

```dart
final ac = context.appColors; // AppColors (light/dark resueltos por el tema)
```

| Token | Uso |
|---|---|
| `bgPage` | Fondo de página (se suele usar `colorScheme.surfaceContainerLowest` como equivalente). |
| `cardBg` | Fondo de tarjetas, headers, footers, barras. |
| `divider` / `rowDivider` | Líneas divisorias. |
| `chipBg` | Fondo de chips / cabeceras de tabla. |
| `searchFill` | Relleno de campos de búsqueda e inputs. |
| `primaryGreen` | **Color de acento principal** (botones, selección, badges, énfasis). |
| `teal` / `tealLight` | Acentos secundarios (p. ej. tratamientos). |
| `amber` / `green` / `indigo` / `purple` / `red` / `orange` | Acentos por categoría/estado. |
| `cardShadow` | Sombra estándar de tarjeta. |
| `railBg` / `railSelectedBg` / `railText` / `railTextSelected` / `railDivider` | Barra lateral (navy fija en ambos temas). |

Texto y bordes finos se toman de `colorScheme` (`onSurface`, `onSurfaceVariant`,
`outlineVariant`). Para opacidades usar **`.withValues(alpha: x)`** (no `withOpacity`,
está deprecado).

---

## 2. Anatomía de una pantalla de listado (Sistema B)

Estructura usada por `PacientesPage`, `MedicinaListPage` y `ConsultasListPage`:

```
ColoredBox(surfaceContainerLowest)
└─ Column
   ├─ Header + buscador (+ filtros)   ← Padding fromLTRB(28, 28, 28, 12)
   │   ├─ Row: Título (headlineSmall, bold, letterSpacing -0.6) + CountBadge
   │   ├─ Subtítulo (bodySmall, onSurfaceVariant @0.8)
   │   ├─ Buscador (TextField)
   │   └─ Fila de filtros (chips + controles)
   └─ Expanded(body)
       ├─ Loading → Center(CircularProgressIndicator)
       ├─ Error   → ícono error_outline_rounded + mensaje + "Reintentar"
       ├─ Empty   → ícono outline @alpha 100 + texto + (acción limpiar)
       └─ Loaded  → ListView.separated(cards, sep 10) + Footer
```

### Tokens de medida
- Padding lateral de página: **28**.
- Radio de tarjetas/inputs: **12–14**; chips/badges internos: **8–10**; pill de conteo: **20**.
- Separación entre cards: **10**.
- Borde de card: `outlineVariant @ alpha 0.4`, width `1.1`.

### CountBadge (pill de conteo junto al título)
Fondo `primaryGreen @0.07`, radio 20, número en `primaryGreen` bold + ícono 13px.

### Buscador
`TextField` con `filled` + `fillColor: ac.searchFill`, radio 12, `prefixIcon`
`search_rounded`, `suffixIcon` `clear_rounded` cuando hay texto, `focusedBorder`
en `primaryGreen` width 1.2. Búsqueda **con debounce de 400 ms**.

### Footer
`Container(color: ac.cardBg)`, padding `28 x 16`, texto
`"Mostrando X de Y …"` en `bodySmall`, `onSurfaceVariant`, w500.

### Estados (Cubit)
Patrón `Initial / Loading / Loaded(todas + filtradas + …) / Error`, con
`Equatable`. El filtrado es **client-side** sobre la lista cargada (ver
`PacienteCubit`, `ConsultasListCubit`).

---

## 3. Filtros

- **Buscador por nombre:** `TextField` debounced → método del cubit.
- **`FilterChip`:** `showCheckmark: false`, seleccionado en `primaryGreen @0.1`
  con borde `primaryGreen @0.4` y label bold; no seleccionado en `searchFill`.
  Siempre incluir un chip "Todos …" para limpiar la dimensión.
- **Rango de fecha:** `OutlinedButton.icon` con `date_range_rounded`; al activarse
  cambia a fondo `primaryGreen @0.08`. Abre `showDateRangePicker`. Mostrar botón
  para quitar el rango y un botón global **"Limpiar"** cuando hay filtros activos.

---

## 4. Card de consulta (`ConsultasListPage`)

`DecoratedBox(cardBg, radio 14, borde outlineVariant@0.4)` → `InkWell(onTap)`:

```
Row
├─ _DateBadge (54x54, primaryGreen@0.07, radio 12): día grande + "mmm aaaa"
├─ Expanded: nombre paciente (bodyMedium bold 15) + fila doctor (ícono + nombre)
├─ Indicadores (solo si aplican):
│    • healing_rounded  (teal)        → tiene tratamientos aplicados
│    • receipt_long_rounded (primaryGreen) → tiene receta
└─ chevron_right_rounded
```

Cada indicador es un cuadro `color @0.1`, radio 8, ícono 16px, con `Tooltip`.

---

## 5. Fechas (es-DO)

No hay `intl`/`flutter_localizations` configurados. Usar
`lib/core/util/fecha_es.dart`:

- `fechaLargaEs` → `6 de junio de 2026`
- `fechaCortaEs` → `6 jun 2026`
- `fechaNumericaEs` → `06/06/2026`
- `mesAbrevEs` → `jun`

> Nota: `showDateRangePicker` se muestra con las localizaciones por defecto (inglés)
> porque la app no registra `flutter_localizations`. El formato es-DO se aplica
> manualmente al renderizar.

---

## 6. Notas de datos relevantes para Consultas

- El listado global usa `ConsultaRepository.getConsultas()` (añadido en este ticket).
  El repositorio **lanza excepciones** (no `Either`), por eso el cubit usa `try/catch`.
- `Consulta` solo guarda `pacienteId`/`doctorId`; los nombres se resuelven cruzando
  con `IPacienteRepository.getPacientes()` y `DoctorRepository.getDoctores()`.
- **"Tiene tratamientos aplicados"** no es un campo directo: la relación es
  `consulta → odontograma → dientes → Diente.tratamientos`. El `select` de
  `fetchConsultas()` anida esa cadena y la entidad expone
  `Consulta.tieneTratamientosAplicados` / `Consulta.tieneRecetas`.
