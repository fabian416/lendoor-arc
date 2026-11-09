# Arc Microgrants, ronda 2: "Built with Arc Studio"

**Página:** https://dorahacks.io/hackathon/arc-microgrants-2/detail
**Cierre:** 1 de noviembre de 2026 (DoraHacks lo muestra como 02/11 01:59, hora argentina). Revisión por orden de llegada: cuanto antes, mejor.
**Monto:** 8 microgrants de 500 USDC, sin equity ni exclusividad.
**Escrito:** 21/10/2026.

## 1. Lo que exigen, leído de la página

| Requisito | Detalle | Estado |
|---|---|---|
| Construido en **Arc Studio** | Desde el primer contrato hasta la app. Lo verifican con la URL del proyecto (`https://studio.arc.io/app/<id>`). "Projects built outside Arc Studio" no son elegibles | Pendiente: el vault de Euler **no** califica; hay que hacer un proyecto nuevo |
| Desplegado en **Arc mainnet** | Con al menos una transacción que mueva USDC real a través del contrato y la app | Pendiente: tenemos 0 USDC en Arc mainnet |
| App pública viva | Un link que puedan abrir | Pendiente |
| Direcciones + 1 hash de transacción | Con link en explorer.arc.io | Pendiente |
| Repo público | Arc Studio exporta a GitHub | Pendiente |
| **Video** | Tiene que mostrar la construcción dentro de Arc Studio y la transacción en mainnet | Pendiente: grabar la pantalla desde el primer prompt |
| Descripción corta | Qué hace y cómo usamos Arc Studio | Borrador abajo |
| Perfil público de builder | GitHub, X o Farcaster | Listo: github.com/fabian416 |

**Puntaje:** 30% USDC real moviéndose en mainnet · 25% uso de Arc Studio en contratos, tests y app · 25% producto funcionando · 20% potencial.

**Una sola submission por proyecto.** Un equipo puede mandar más de un proyecto distinto.

## 2. Dos datos de Arc Studio que condicionan el plan

1. **Arc Studio solo despliega a testnet.** Su propia página dice que "no deploya, firma, fondea ni envía transacciones de mainnet en tu nombre". El flujo es: construir y testear en Arc Studio → sacar el código (`arc-studio pull` o push a GitHub) → desplegar a mainnet nosotros con Foundry, con nuestra wallet y USDC para gas. Eso es exactamente lo que ya hicimos en testnet el 09/10.
2. **Hay un CLI que se usa desde Claude Code.** `npm install -g @circle-fin/arc-studio-cli`, `arc-studio login` (abre el navegador y da un token), `arc-studio skills install --tool claude-code`. Los proyectos hechos en la web se listan con `arc-studio apps --json`. Un deploy a testnet tarda de 5 a 20 minutos. Los turnos tienen límite de presupuesto (`budget_exceeded`); no publican precios.

## 3. Qué construir: "Lendoor Credit Line"

Un proyecto chico, nuevo y nativo de Arc Studio, que muestra nuestra tesis con plata real y entra en dos de las tres categorías que ellos sugieren (pagos condicionales y reparto de pagos).

**Flujo:**
1. Un prestamista deposita USDC en el contrato (pool).
2. Lendoor, como operador, fija un límite de crédito por wallet. En la demo lo firma el deployer; en producción lo firmaría el motor de riesgo.
3. El prestatario retira hasta su límite.
4. Devuelve capital más un cargo fijo.
5. El cargo se reparte: una parte al pool (prestamista) y otra a Lendoor (reparto de pagos).
6. Si no devuelve a tiempo, el límite baja a cero (condición de pago).

**Montos para la demo en mainnet:** depósito 5 USDC, préstamo 1 USDC, repago 1,02 USDC. Gas total estimado por debajo de 2 USDC. Con 10 USDC en mainnet alcanza.

**Qué no hacer:** no replicar el vault de Euler, no tocar el backend de Lendoor, no prometer first-loss acá. Es un experimento de 10 días que además sirve como hito 3 de la aceleradora (mainnet, 30/10) en versión reducida y como pieza de la demo del Demo Day.

## 4. Prompt inicial para Arc Studio (en inglés, es lo que entiende mejor)

```
Build "Lendoor Credit Line": a minimal USDC micro-credit app on Arc.

Contracts (Solidity, tested):
- CreditLine.sol holds a USDC pool. Roles: owner (Lendoor), lenders, borrowers.
- Lenders call deposit(amount) and withdraw(amount) of USDC; track each lender's share.
- Owner calls setLimit(borrower, limitUsdc, dueDays) to grant or update a credit limit.
- Borrower calls borrow(amount) up to their limit; one open loan per borrower; records dueAt.
- Borrower calls repay(): pays principal + a fixed fee of 2% of principal.
  The fee is split 80% to the pool (lenders) and 20% to a treasury address (Lendoor).
- Anyone can call markLate(borrower) after dueAt: sets the borrower's limit to 0.
- Events for every state change. USDC on Arc is the native token with an ERC-20 interface
  at 0x3600000000000000000000000000000000000000 with 6 decimals; use that interface.

App:
- Three views: Lender (deposit/withdraw, pool balance), Borrower (limit, borrow, repay, due date),
  Operator (set limit, mark late). Show live balances and the last transactions with explorer links.
Write tests for deposit, borrow, repay with fee split, and markLate. Deploy to Arc testnet.
```

Después del primer resultado, pedir en el chat: "add tests for the fee split rounding", "make the app show the explorer link of each transaction", "export the project to GitHub".

## 5. Paso a paso y calendario

| Día | Qué | Quién |
|---|---|---|
| **Mié 21/10** | Iniciar sesión en DoraHacks y apretar "Register" en la página del microgrant. Crear la cuenta en Arc Studio. Preguntar en las office hours de las 15:00 (hay tres personas de Arc Studio): límites de uso, y si el "project URL" se obtiene desde el CLI | **Fabián** (son cuentas: no las puedo crear yo) |
| Mié 21 a vie 23/10 | Construir en Arc Studio con el prompt de arriba, **grabando la pantalla desde el primer mensaje**. Iterar hasta que los tests pasen y la app corra en testnet | Fabián en la web, o Claude Code vía el CLI con su login |
| Jue 22/10 | 1:1 con Crecimiento: contar que vamos por el microgrant y validar que la "Credit Line" cuenta como hito 3 | Fabián |
| Vie 23/10 | Llevar 10 USDC a Arc mainnet: portal.arc.io desde Base, Ethereum, Arbitrum, Avalanche, Polygon u Optimism, o retiro directo desde un exchange que soporte Arc | **Fabián** (plata real) |
| Sáb 24 a lun 26/10 | `arc-studio pull` del código, revisión a mano del contrato, deploy a mainnet con Foundry desde una wallet nueva, correr el flujo completo: depósito, préstamo, repago. Guardar los hashes | Sesión de deploy (una sola) con OK explícito de Fabián |
| Lun 26/10 | Publicar la app (Vercel o el mismo host de arc.lendoor.xyz) apuntando a mainnet. Repo público con README | Sesión de deploy |
| Mar 27/10 | Terminar el video (2 a 3 minutos): la construcción en Arc Studio, la app, la transacción en el explorer | Fabián graba, yo armo el guion |
| **Mié 28/10** | **Enviar en DoraHacks.** Cuatro días de margen sobre el cierre y antes que la mayoría | Fabián |
| 30/10 | Hito 3 de la aceleradora: mismo deploy | — |
| Semana del 02/11 | Demo Day | — |

## 6. Textos para la submission (borrador en inglés)

**Nombre:** Lendoor Credit Line

**Descripción corta:**
> Lendoor Credit Line is a minimal uncollateralized USDC credit line on Arc, built end to end in Arc Studio. Lenders fund a pool; Lendoor sets a credit limit per wallet (in production, from our risk engine, which already scores ~4,800 real micro-loans in LatAm); borrowers draw and repay with a fixed fee that is split between the pool and Lendoor; late borrowers lose their limit. Arc Studio wrote and tested the contracts and built the three-view app; we exported the code and deployed it to Arc mainnet ourselves, where it has moved real USDC.

**Cómo usamos Arc Studio:** contratos, tests y app generados en Arc Studio desde un prompt; iteraciones por chat para el reparto del cargo y los links al explorer; export a GitHub; deploy a mainnet con Foundry desde el código exportado.

**Potencial:** es la versión mínima del motor de crédito que Lendoor opera en producción en otra cadena; el siguiente paso es un vault con tramo de primera pérdida y la escalera de crédito como API para otras apps en Arc.

## 7. Guion del video (2 a 3 minutos)

1. 0:00 Pantalla de Arc Studio: pegar el prompt, mostrar cómo escribe los contratos y corre los tests.
2. 0:45 La app en preview: vista de prestamista, prestatario y operador.
3. 1:15 Terminal: export del código y deploy a mainnet con Foundry; mostrar la dirección del contrato.
4. 1:45 La app apuntando a mainnet: depósito de 5 USDC, préstamo de 1, repago de 1,02. Mostrar el reparto del cargo.
5. 2:30 El explorer de Arc con la transacción de repago y los eventos. Cierre: qué sigue (first-loss, API de crédito).

## 8. Riesgos

- **Que Arc Studio no deje exportar limpio o tenga límite de uso.** Preguntarlo hoy en las office hours. Si el límite muerde, construir el contrato en Studio y la app a mano no vale: el 25% del puntaje es el uso de Studio en todo el build.
- **Ventana ajustada:** 10 días. Por eso el alcance es mínimo y el envío apunta al 28/10, no al 1/11.
- **USDC en mainnet:** sin los 10 USDC no hay transacción y no hay submission. Es el único paso que no se puede empezar hasta que Fabián mueva la plata.

## 9. Cómo encajan los tres programas (verificado 21/10)

| Programa | Qué dice de prioridad | Exclusiones | Estado 21/10 |
|---|---|---|---|
| Microgrant ronda 2 (DoraHacks) | Ninguna. Rúbrica 30/25/25/20, decisión por tandas, "earlier submissions get earlier answers" | "work already funded by a Circle or Arc program" | Abierto hasta el 01/11 |
| Circle Grants Program (circle.questbook.app) | Ninguna sobre aceleradoras. Criterios: Arc central al flujo de valor, equipo que shippea, tracción, impacto; "prioritize builders progressing from testnet to mainnet". Lending/borrowing es área prioritaria | No publica | **Cohort 2 abierta: 887 propuestas, 14 aceptadas (1,6 %), $95k pagados, $135k disponibles.** Sin deadline publicado |
| Arc Acceleration Season (Notion) | No da plata; su "Funding opportunities" apunta a circle.com/grant | — | Demo Day online **jueves 05/11**; revisión de decks martes 03/11 (Tomi, en el doc de Queries) |

**Orden:** microgrant primero (28/10), Questbook después (semana del 26/10, con el deploy en mainnet). La página del microgrant lo llama "a route into the Circle Grant Program". Al revés hay riesgo: un grant previo convierte el proyecto en "already funded".

**Dato del doc de Queries (pestaña "Office Hours Oct. 21"):** A-Identity preguntó "Will priority be given to teams that have participated in the Arc accelerator program and applied to the Circle Grant Program?"; MidatoPay preguntó si su piloto cuenta para los hitos y para un grant. A-Identity cuenta que el equipo de grants "liked our initial proposal and invited us to resubmit an updated version on Questbook": hay loop de feedback para la cohorte. Alguien ya preguntó por la lista de cambios entre el export de Studio y mainnet (RPC, chain id, dirección de USDC, dominio EIP-712) y si el agente genera el script de deploy a mainnet: esa respuesta nos sirve directo.

## 10. Preguntas de Lendoor para el doc de Queries (en inglés, para pegar)

**Circle BD**
1. Lendoor runs uncollateralized USDC micro-credit (USD 1–50, 7–28 days) inside the Lemon wallet on Celo, ~4,800 loans to date; Arc testnet deployment was in deliverable #1 and mainnet is our milestone for 30/10. For the Circle Grants Program on Questbook: should we submit now with the testnet deployment and the mainnet milestone, or wait until the Arc deployment has moved real USDC? What evidence weighs most for a credit product: loans on Arc, borrowers, a distribution partner, or the risk model's track record on another chain?
2. Microgrant round 2 excludes "work already funded by a Circle or Arc program". Does being in the Arc Acceleration Season (no funding received) affect eligibility? And if a project receives the microgrant, can the production version of the same product apply to the Circle Grants Program afterwards?
3. Is there a way for cohort teams to get feedback on a Questbook draft before submitting, or to have the mentors flag it to the reviewers?

**Arc Studio**
4. For microgrant round 2 we plan a small new project built entirely in Arc Studio ("Lendoor Credit Line": USDC pool, per-wallet limit, borrow/repay with a fee split), then deploy the exported code to mainnet ourselves. Is the project URL from `arc-studio apps --json` valid as proof? Are there per-account usage limits we should plan for in a 3-day build?

## 11. Novedades del grupo de Telegram (releído 21/10 16:30, del 09/10 al 21/10 15:01)

- **Alchemy abrió créditos para equipos de Arc: hasta 10.000 USD por equipo** (`https://www.alchemy.com/credits-program/arc`). Tomás Cordero (BuFi, Arc Country Lead) pide el mail usado en el form para acelerar la aprobación. Lendoor ya paga Alchemy (RPC del firmante + data API de wallets): aplicar.
- Office hours del 21/10 (18:00 UTC): Jenna Teeman (Ecosystem, Circle), Matt Enslin (Senior Manager BD, Circle) y Rustam Mamedov (Engineering Manager, Arc Studio). Tomi: "we will be discussing … the grants process".
- **Jueves 22/10: 1:1 con Crecimiento** para revisar hitos, métricas y el feedback del Entregable 1 (el doc privado del 15/10 que no apareció en Gmail: pedírselo a Tomi).
- Viernes 23/10: Founder's Masterclass con Gonzalo Waisman (Hashi). Lunes 19/10 Tomi dijo que compartiría "updates que pasó el equipo de Circle" en el group mentoring: si no estuviste, pedir el resumen.
- Encuesta de Olympix (scan de seguridad pagado por Circle): 8 votos; votar "Yes".
- StableFX es self-serve: `circle.com/join-stablefx`, empresa en jurisdicción aceptada + KYB. Lendoor (C-corp Delaware) califica; no hace falta para el grant.
- A-Identity, SlipPay y Aomi se están usando entre sí en mainnet para mostrar "external usage to Circle": la cohorte entendió que la evidencia que pesa es uso real on-chain entre equipos.

**Idea para plegar el hito 2 (first-loss, 23/10) en la Credit Line:** el 20 % del cargo que va a Lendoor entra a una reserva dentro del contrato; cuando `markLate` castiga a un prestatario, la reserva le devuelve al pool lo perdido antes que nadie. Es primera pérdida del originador en miniatura, verificable on-chain, y son pocas líneas más en el mismo contrato que escribe Arc Studio.

## 12. Lo que respondieron en las office hours del 21/10 (notas de Gemini compartidas por Crecimiento a las 16:15)

Doc: `docs.google.com/document/d/1RWkj0HEoWcnBSAtfq1FutB02aUPbwmFPcIT5y8pUOQo` (en "Compartido conmigo" de Drive).

- **Prioridad para la cohorte: SÍ, pero no garantía.** Jenna Teeman: los participantes de la aceleradora reciben "expedited reviews" en el Circle Grants Program y se los evalúa "based on their accelerator accomplishments"; igual tienen que pasar los criterios. Quedó como decisión "Aligned" en las notas.
- MidatoPay preguntó si un piloto con comercios reales en mainnet es obligatorio para el grant. Jenna: tracción, piloto exitoso y roadmap claro fortalecen la propuesta; no hay número mínimo de clientes.
- **El lunes 26/10, en el group mentorship, van a dar más detalles de los grants de Circle y "platform funding".** No faltar.
- Arc Studio y mainnet, confirmado por Rustam Mamedov y Thomas Low: el agente indica qué cambiar (chain id, direcciones) pero **no despliega a mainnet**; cada proyecto redeploya por su cuenta siguiendo la doc de Arc Studio. Es exactamente nuestro plan.
- Thomas Low: el Morpho SDK devuelve las direcciones de dev y mainnet. Arc Studio no acepta MCP servers propios.
- Rustam prefiere coordinar por Arc House y no por Telegram.
- On/off-ramps en LatAm en Arc (Spencer Jaffe, BD): Ripio Transact, Hi-Fi, Tazapeo, Alfred Pay; en EE. UU. Moonpay y Zero Hash. Directorio de contactos: Circle Alliance (partners.circle.com).
- Co-marketing: los anuncios de lanzamiento se consolidan vía Crecimiento (posts grupales y spotlights). Mandar el borrador por ese canal.

**Doc de feedback y tracking del 15/10:** no está en el Gmail de Fabián, ni en Drive "Compartido conmigo", ni hay DM de TomiK8 en su Telegram. Lucho (carrenoluciano@gmail.com) también estaba invitado a las office hours: puede haberle llegado a él. Si no, pedírselo a Tomi.

## 13. Semana 5 publicada (medido el 25/10): el mainnet dejó de ser opcional

- **Deliverable 2, obligatorio, viernes 30/10 19:00 UTC (16:00 AR):** integración viva en **Arc mainnet** + documentación + tracking de hitos. Es "el criterio de éxito de la temporada"; testnet-only no califica. Quien no llegue debe haberlo **hablado antes con Crecimiento** y entrega igual omitiendo la sección mainnet.
- Calendario: lun 26 kickoff + group mentoring 18:00 UTC (van a dar detalles de grants y platform funding) · mar 27 masterclass BD & Funding (Simón Puebla, Andén) 18:00 UTC · jue 29 office hours públicas en Arc House 12:00 UTC · vie 30 entrega. Semana 6 (02/11): prep de Demo Day; deck review mar 03/11; Demo Day jue 05/11.
- La agenda de 1:1 no tiene turnos hasta el 07/11. El 1:1 del 22/10 no se hizo (no está en el calendario de Fabián).
- Esto cambia el orden del plan: **el mainnet del EVK (H3) pasa a ser lo primero**, antes que la Credit Line del microgrant. Los dos comparten el prerequisito: USDC en Arc mainnet en el deployer (`0x11ff…0036`, hoy 0).
- Fabián está en Lisboa (HackMeridian, entrega lun 26 12:00; finale mié 28 13:50) hasta el 30/10; cualquier deploy a mainnet es una sesión única con OK explícito, con el firmante disponible.
