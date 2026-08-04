/**
 * Mide el arranque de la app web bajo CPU limitada.
 *
 * SD-132. De los tres entornos que pide el ticket —Android de gama baja,
 * navegador con CPU limitada y Windows—, este es el único que no necesita
 * hardware aparte: Chrome sabe frenarse a sí mismo. Sirve `build/web`, abre
 * Chromium sin interfaz con el freno de CPU puesto y cronometra hasta el
 * primer pintado con contenido (FCP).
 *
 * FCP es la métrica correcta aquí y no `load`: mide cuándo el usuario deja de
 * ver una pantalla en blanco. En una app Flutter web eso llega después de
 * descargar y compilar `main.dart.js` y de arrancar el motor, que es
 * exactamente el coste que el freno de CPU amplifica.
 *
 * Uso:
 *   deno run -A tool/perf/medir_web_cpu_limitada.ts            # freno 4x
 *   deno run -A tool/perf/medir_web_cpu_limitada.ts --cpu 6    # freno 6x
 *   deno run -A tool/perf/medir_web_cpu_limitada.ts --repeticiones 5
 *
 * Requiere `flutter build web --release` hecho antes, y `chromium` o
 * `google-chrome` en el PATH.
 */

const TIPOS: Record<string, string> = {
  html: "text/html",
  js: "text/javascript",
  mjs: "text/javascript",
  json: "application/json",
  wasm: "application/wasm",
  css: "text/css",
  png: "image/png",
  ico: "image/x-icon",
  otf: "font/otf",
  ttf: "font/ttf",
  symbols: "application/octet-stream",
};

function argumento(nombre: string, pordefecto: number): number {
  const i = Deno.args.indexOf(`--${nombre}`);
  if (i === -1) return pordefecto;
  const v = Number(Deno.args[i + 1]);
  return Number.isFinite(v) ? v : pordefecto;
}

const FRENO = argumento("cpu", 4);
const REPETICIONES = argumento("repeticiones", 3);
// Trinquete sobre lo medido en SD-132 (mediana 3608 ms con freno 4x).
const PRESUPUESTO_MS = argumento("presupuesto", 4500);
const RAIZ = new URL("../../build/web", import.meta.url).pathname;

// ── Servidor estático mínimo ────────────────────────────────────────────────
// Escrito a mano y no con `@std/http` para que el script no dependa de
// descargar nada: si la medición necesita red para arrancar, deja de poder
// correrse en cualquier parte.
function servir(): { puerto: number; cerrar: () => Promise<void> } {
  const servidor = Deno.serve({ port: 0, onListen: () => {} }, async (req) => {
    let ruta = new URL(req.url).pathname;
    if (ruta === "/") ruta = "/index.html";
    try {
      const datos = await Deno.readFile(RAIZ + ruta);
      const ext = ruta.split(".").pop() ?? "";
      return new Response(datos, {
        headers: {
          "content-type": TIPOS[ext] ?? "application/octet-stream",
          // CanvasKit necesita aislamiento de origen cruzado para SharedArrayBuffer.
          "cross-origin-opener-policy": "same-origin",
          "cross-origin-embedder-policy": "require-corp",
          "cross-origin-resource-policy": "cross-origin",
        },
      });
    } catch {
      return new Response("no encontrado", { status: 404 });
    }
  });
  return {
    puerto: (servidor.addr as Deno.NetAddr).port,
    cerrar: () => servidor.shutdown(),
  };
}

// ── Chrome ──────────────────────────────────────────────────────────────────
async function buscarChrome(): Promise<string> {
  for (const bin of ["chromium", "google-chrome", "chrome"]) {
    try {
      const p = new Deno.Command(bin, { args: ["--version"], stdout: "null", stderr: "null" });
      if ((await p.output()).success) return bin;
    } catch { /* siguiente */ }
  }
  throw new Error("No se encontró chromium ni google-chrome en el PATH.");
}

async function esperar(ms: number) {
  await new Promise((r) => setTimeout(r, ms));
}

interface Cdp {
  enviar(metodo: string, params?: unknown): Promise<Record<string, unknown>>;
  alEvento(nombre: string, fn: () => void): void;
  cerrar(): void;
}

async function conectar(wsUrl: string): Promise<Cdp> {
  const ws = new WebSocket(wsUrl);
  await new Promise((ok, err) => {
    ws.onopen = () => ok(null);
    ws.onerror = () => err(new Error("no se pudo abrir la sesión CDP"));
  });

  let id = 0;
  const pendientes = new Map<number, (v: Record<string, unknown>) => void>();
  const oyentes = new Map<string, (() => void)[]>();

  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id !== undefined) pendientes.get(msg.id)?.(msg.result ?? {});
    else if (msg.method) {
      const nombre = msg.method === "Page.lifecycleEvent"
        ? `lifecycle:${msg.params?.name}`
        : msg.method;
      oyentes.get(nombre)?.forEach((f) => f());
    }
  };

  return {
    enviar(metodo, params = {}) {
      const propio = ++id;
      return new Promise((ok) => {
        pendientes.set(propio, ok);
        ws.send(JSON.stringify({ id: propio, method: metodo, params }));
      });
    },
    alEvento(nombre, fn) {
      oyentes.set(nombre, [...(oyentes.get(nombre) ?? []), fn]);
    },
    cerrar: () => ws.close(),
  };
}

/** Una medición: navega y devuelve los ms hasta el primer pintado con contenido. */
async function medirUnaVez(chrome: string, url: string): Promise<number> {
  const perfil = await Deno.makeTempDir({ prefix: "sd132-chrome-" });
  const proceso = new Deno.Command(chrome, {
    args: [
      "--headless=new",
      "--disable-gpu",
      "--no-first-run",
      "--no-default-browser-check",
      "--remote-debugging-port=0",
      `--user-data-dir=${perfil}`,
      "about:blank",
    ],
    stdout: "piped",
    stderr: "piped",
  }).spawn();

  try {
    // Chrome anuncia su puerto real en stderr al arrancar.
    const lector = proceso.stderr.getReader();
    const dec = new TextDecoder();
    let puerto = 0;
    const limite = Date.now() + 15000;
    let buffer = "";
    while (Date.now() < limite && !puerto) {
      const { value, done } = await lector.read();
      if (done) break;
      buffer += dec.decode(value);
      const m = buffer.match(/DevTools listening on ws:\/\/127\.0\.0\.1:(\d+)/);
      if (m) puerto = Number(m[1]);
    }
    lector.releaseLock();
    if (!puerto) throw new Error("Chrome no anunció su puerto de depuración");

    const objetivos = await (await fetch(`http://127.0.0.1:${puerto}/json/list`)).json();
    const pagina = objetivos.find((t: { type: string }) => t.type === "page");
    if (!pagina) throw new Error("Chrome no expuso ninguna pestaña");

    const cdp = await conectar(pagina.webSocketDebuggerUrl);
    await cdp.enviar("Page.enable");
    await cdp.enviar("Page.setLifecycleEventsEnabled", { enabled: true });
    // El freno se aplica *antes* de navegar: si se pone después, la descarga y
    // el arranque del motor —lo que queremos medir— ya han pasado a toda pastilla.
    await cdp.enviar("Emulation.setCPUThrottlingRate", { rate: FRENO });

    const pintado = new Promise<number>((ok, err) => {
      const t0 = performance.now();
      cdp.alEvento("lifecycle:firstContentfulPaint", () => ok(performance.now() - t0));
      setTimeout(() => err(new Error("no hubo primer pintado en 120 s")), 120_000);
    });

    await cdp.enviar("Page.navigate", { url });
    const ms = await pintado;
    cdp.cerrar();
    return ms;
  } finally {
    try { proceso.kill(); } catch { /* ya terminó */ }
    await proceso.status;
    await Deno.remove(perfil, { recursive: true }).catch(() => {});
  }
}

// ── Principal ───────────────────────────────────────────────────────────────
try {
  await Deno.stat(`${RAIZ}/index.html`);
} catch {
  console.error("Falta build/web. Ejecuta antes: flutter build web --release");
  Deno.exit(2);
}

const chrome = await buscarChrome();
const { puerto, cerrar } = servir();
const url = `http://127.0.0.1:${puerto}/`;

console.log(`→ ${chrome} sin interfaz, freno de CPU ${FRENO}x, ${REPETICIONES} repeticiones`);

const medidas: number[] = [];
try {
  for (let i = 0; i < REPETICIONES; i++) {
    const ms = await medirUnaVez(chrome, url);
    medidas.push(ms);
    console.log(`  intento ${i + 1}: ${ms.toFixed(0)} ms`);
    await esperar(300);
  }
} finally {
  await cerrar();
}

// Se reporta la mediana, no el promedio: una sola ejecución lenta por ruido de
// la máquina no debe mover el número de referencia.
medidas.sort((a, b) => a - b);
const mediana = medidas[Math.floor(medidas.length / 2)];

console.log();
console.log(`Primer pintado (mediana de ${medidas.length}): ${mediana.toFixed(0)} ms`);
console.log(`  mejor ${medidas[0].toFixed(0)} ms · peor ${medidas[medidas.length - 1].toFixed(0)} ms`);
console.log();

if (mediana > PRESUPUESTO_MS) {
  console.log(`✗ supera el presupuesto de ${PRESUPUESTO_MS} ms. Ver PERFORMANCE.md.`);
  Deno.exit(1);
}
console.log(`✓ dentro del presupuesto de ${PRESUPUESTO_MS} ms.`);
