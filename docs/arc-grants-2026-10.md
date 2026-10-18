# Grants de Arc y Circle — estado al 09/10/2026

Verificado en las páginas primarias el 09/10/2026 (DoraHacks, circle.questbook.app, community.arc.io).
Sin commitear a propósito: es nota de trabajo.

## Resumen

| Programa | Estado | Plazo | Monto | Exige | ¿Estamos? |
|---|---|---|---|---|---|
| **Arc Microgrants** (DoraHacks) | Abierto, revisión rolling | **14/10/2026 23:59 ET** (DoraHacks lo muestra como 15/10 00:59 hora local); decisiones al 21/10 | 20 × 500 USDC, sin equity | Deploy **vivo en Arc MAINNET** con link, repo público, perfil público de builder (GitHub/X/Farcaster), descripción corta. **Testnet-only NO es elegible.** Una sumisión por proyecto | **No todavía**: estamos en testnet y tenemos 0 USDC en Arc mainnet |
| **Circle Grants Program** (circle.questbook.app) | **Cohort 2 ABIERTA** (857 propuestas, 14 aceptadas, $80k pagados); Cohort 1 cerrada | Sin fecha publicada; rolling | Por hitos, en USDC; monto no publicado (referencias previas: 5k–100k) | "Arc central al flujo de valor"; equipos con shipping probado; uso, pilotos, ingresos o camino creíble; integraciones con productos de Circle; prioridad **lending & borrowing** | Sí para aplicar: 4.500+ préstamos en Celo, stack desplegado en Arc testnet, app viva, hitos definidos |
| Arc Builders Fund (Circle Ventures) | Por intro | — | Equity | — | Después del Demo Day |

## Arc Microgrants — qué hay que hacer para llegar al 14/10

1. **USDC en Arc mainnet** (hoy 0 en las 4 wallets: deployer de testnet, 0x4CC1, 0xe1a6, 0x07f1).
   Necesitamos ~10 USDC: deploy ≈ 41 M gas × 20 gwei ≈ 1 USDC, más cableado, depósito y un préstamo.
   Caminos: CCTP desde Base/Ethereum/Avalanche (Celo NO está en CCTP) o retiro desde un exchange que
   soporte Arc. RPC mainnet que responde: `https://rpc.mainnet.arc.io` (chain 5042). `rpc.arc.io` no resuelve.
2. **Deploy en mainnet** con los mismos scripts (`lendoor-arc/scripts/arc-deploy.sh` cambiando RPC y
   chain id) con una wallet nueva, nunca la de prod de Celo. Incluir el fix del slot y el LoanManager v2.
3. **Un link que se pueda abrir**: lo más fuerte es la app contra mainnet en un subdominio aparte
   (p. ej. `mainnet.arc.lendoor.xyz`, Lucho pone el DNS), segundo stack como el de testnet. Mínimo: la
   página `/deliverable-1` con las direcciones de mainnet y el explorer `https://explorer.arc.io`.
4. **Sumisión en DoraHacks**: cuenta en dorahacks.io (login con GitHub o wallet), "Submit Build" en
   `https://dorahacks.io/hackathon/arc-microgrants`, con link vivo + repo `github.com/fabian416/lendoor-arc`
   + perfil público (GitHub fabian416 ya sirve). Diez minutos.
5. Reglas: no elegible si ya fue financiado por un programa de Circle/Arc (la aceleradora no financia, OK);
   el pago es en USDC en Arc, a una wallet que pueda recibirlo; verificación privada sólo si seleccionan.

## Circle Grants Program — cómo aplicar

- Portal: `https://circle.com/grant` → redirige a `https://circle.questbook.app/` (Questbook pide login,
  normalmente con wallet o Google) → "Circle 2026 Cohort 2" → nueva propuesta.
- La propuesta tiene que mostrar: qué shippeamos (4.500+ préstamos en Celo, 65→89 % de repago, stack en
  Arc testnet con app viva), qué viene (hitos del Entregable 1: riesgo legible on-chain, first-loss,
  mainnet, préstamo real) y cómo se traduce en uso/liquidez/ingresos. Integraciones Circle: USDC nativo
  (hoy), Wallets + Gas Station y StableFX (plan).
- Proceso en 5 pasos: alineación inicial → revisión técnica (Ventures/Producto/BD) → aceptación con hitos a
  medida → cumplimiento y aprobación de hitos → desembolso en USDC.
- Revisores: la misma gente del programa (Jenna Teeman está en el grupo). El doc "Queries to Arc team"
  es el canal directo.

## Arc House (community.arc.io)

Comunidad con puntos: graduarse de la aceleradora da 2.000; desde 3.500 hay briefings trimestrales con
el liderazgo de Arc y Circle. Conviene: crear la cuenta, verificar identidad, completar el onboarding y
sumarse al club Argentina. No es requisito del microgrant ni del grant, pero es donde miran "builder profile".

## Recomendación

- **Microgrant: intentar.** Es 500 USDC y, más importante, "una ruta al Circle Grant Program". Cuesta
  ~10 USDC y un día de trabajo (deploy mainnet + página). Decisión: ¿conseguimos USDC en Arc mainnet
  antes del lunes 13/10?
- **Circle Grant: aplicar la semana que viene**, después de tener el hito 1 y, si llegamos, el deploy
  en mainnet. Con la aplicación del microgrant como antecedente.

## Dónde hay que registrarse (lo que preguntaba Fabián)

1. **Arc House** (`https://community.arc.io`, botón "Join Community"): crear cuenta, verificar identidad,
   completar el onboarding y sumarse al club Argentina. Hoy NO estamos logueados. Suma puntos (graduarse
   de la aceleradora = 2.000; desde 3.500, briefings con Arc/Circle) y es el "perfil de builder" que mira el
   ecosistema. Las office hours públicas de Arc se anuncian ahí.
2. **DoraHacks** (`https://dorahacks.io`): cuenta con GitHub o wallet para poder "Submit Build" en el
   microgrant. Pide link vivo en mainnet + repo + perfil público (GitHub `fabian416` alcanza).
3. **Questbook** (`https://circle.questbook.app`): login (wallet o Google) para crear la propuesta en
   "Circle 2026 Cohort 2".
4. **1:1 con Crecimiento**, pendiente de agendar: `https://calendar.app.google/L6tiJVZh5Tix2tW16`
   (lo dijimos en el formulario: semana 3, para revisar el first-loss con Tomás).
5. Canal directo con Circle: doc "Queries to Arc team"
   `https://docs.google.com/document/d/1RvxLfs71grxDrvpNV41DfiFKayoUTAsgRxPytj1g8K4`.

## Decisión pendiente

¿Vamos por el microgrant? Hace falta decidirlo el **viernes 10 o sábado 11**: conseguir ~10 USDC en Arc
mainnet (CCTP desde Base/Ethereum, o exchange con retiro a Arc), desplegar el lunes 13, subir la sumisión
el martes 14 antes de las 23:59 ET.
