# Deliverable 2 — Live Integration, Documentation & Milestones

**Vencía el viernes 30/10/2026 a las 19:00 UTC. No se envió.** Nada de esto se manda sin el OK de Fabián.
Fuente: Notion semana 5 (`crecimientofoundation.notion.site/week5-arc-accelerationseason`) y el form
`https://docs.google.com/forms/d/e/1FAIpQLSfspPAxAw4pIcymDgnnvEuAipm54eoTIrRyzAMnNYOxApvk3Q/viewform`.

## 0. Estado medido el lunes 02/11 (16:20 Lisboa)

| Cosa | Estado |
|---|---|
| Form del Deliverable 2 | **Sigue abierto** y acepta respuestas; la pregunta de mainnet admite "Yes / In progress / No" y pide, si no estás en mainnet, "what's missing and when you expect to get there" |
| Lo que dijo Tomi (Crecimiento) en el grupo, vie 30/10 20:45 | **Demo Day pasó al viernes 13/11.** "Teams that need a few more days to polish their Mainnet launch now have the time to finish it." Semana 6: lunes mentoría grupal; martes a viernes 1:1 con Crecimiento para practicar pitch, pulir deck o revisar hitos |
| Hoy lun 02/11 | Mentoría grupal **18:00 UTC = 18:00 Lisboa** (`meet.google.com/meet/hxh-gahc-esr`): "We will talk about this week, Deliverable 2 and answer several questions from Demo Day" |
| 1:1 con Crecimiento | Hay turnos libres mar 3 a vie 6, 13:00–14:30 y 17:00–19:30 Lisboa (`calendar.app.google/naBQo44ji6uRod7W8`) |
| Otros equipos | A-Identity y Cycles enviaron el viernes. Lendoor no escribió nada en el grupo |
| Contratos en Arc **mainnet** (5042) | ❌ nada desplegado: deployer `0x2200…636A` con 0 USDC y nonce 0; sin broadcast local |
| Contratos en Arc **testnet** (5042002) | ✅ EVault `0xc90F…fc0c`, LoanManagerV3 v2 `0xe385…27d0`, EVC `0x50c3…Ba2C`; 14 txs; vault 13,016 USDC; 1 préstamo de 1 USDC abierto y repagado |
| App | ✅ arc.lendoor.xyz contra testnet |
| Deploy a mainnet | Ensayado en fork el 25/10 (18 txs, ≈1 USDC de gas). Falta: ~10 USDC en el deployer + `ARC_MAINNET_OK=1` con Fabián presente. Una hora |

## 1. Los dos caminos

| | A. Enviar ya como "In progress" | B. Deployar mainnet primero y enviar con "Yes" |
|---|---|---|
| Cuándo | Hoy o mañana, después de avisarle a Tomi | Esta semana: fondear → deploy (1 h) → form |
| Riesgo | Queda registrado "no está en mainnet"; después hay que actualizar por 1:1 o DM | El form puede cerrarse antes; hay que confirmarlo con Tomi |
| Qué necesita de Fabián | Avisar a Tomi, tildar asistencia, apretar Enviar | 10 USDC al deployer, OK explícito, estar en la sesión, y después lo mismo que A |

Recomendación: preguntar hoy a las 18:00 en la mentoría (o por DM a Tomi) si una entrega tardía esta semana
cuenta y si conviene esperar a mainnet. Si Tomi dice "mandá ya", va A con los textos de §2 y después se
actualiza. Si dice "esperá a mainnet", va B.

## 2. Respuestas campo por campo (en inglés, como las pide el form)

Donde los dos caminos difieren hay **[A]** y **[B]**. Lo que está entre `<…>` se completa con datos reales.

**Startup Name** → `Lendoor`

**Founder filling out the form** → `Fabián Díaz`

**Is your integration live on Arc Mainnet?** → [A] `In progress` · [B] `Yes`

**Link to your mainnet deployment (URL required)**
- [A] `https://arc.lendoor.xyz` (hoy corre contra testnet; decirlo en la pregunta siguiente)
- [B] `https://explorer.arc.io/address/<VAULT>` y `https://arc.lendoor.xyz`

**How did the mainnet deployment go? …**
- [A]
  > Not on mainnet yet. The full stack (EVK vault + our uncollateralized credit module + LoanManagerV3) has
  > been live on Arc testnet since Oct 9 (14 txs, 13 USDC deposited, one 7-day loan opened and repaid), and
  > the app at arc.lendoor.xyz runs against it. On Oct 25 we rehearsed the exact mainnet deployment on a
  > local fork of Arc mainnet: 18 transactions, ~41.5M gas, ~1 USDC at 25 gwei, 42 seconds. What is missing
  > is operational: funding the mainnet deployer with USDC (Celo, where our production runs, is not on
  > CCTP/Gateway, so USDC has to be bridged from another chain) and the team being in one place to sign:
  > we were at HackMeridian in Lisbon the week of the deadline. Expected on mainnet: <día de esta semana>.
  > What changed between testnet and mainnet in our scripts: chain id (5042 vs 5042002), the explicit
  > mainnet gate in the deploy script, and nothing in the contracts (same USDC predeploy address, same Permit2).
- [B]
  > Deployed on <fecha> with the same Foundry scripts we used on testnet, rehearsed on a mainnet fork on
  > Oct 25. 18 transactions, ~<gas> gas, <costo> USDC. Vault `<VAULT>`, LoanManagerV3 proxy `<LM>`, EVC
  > `<EVC>`. After deploying we wired the vault (hook config, loan manager, credit limit manager), opened a
  > credit line, deposited 5 USDC, borrowed 1 USDC for 7 days and repaid 1.016 USDC. What took longer than
  > expected: funding the deployer (Celo is not on CCTP, so USDC came via <ruta>) and the team being at
  > HackMeridian the week of the deadline. What broke: nothing in the contracts; the only testnet/mainnet
  > differences were chain id and the funding path. Caveat: `transfer` on the USDC predeploy reverts on a
  > local anvil fork, so the money flow could only be rehearsed on the real network.

**Link to your updated documentation (URL required)**
- `https://github.com/fabian416/lendoor-arc` (README + `docs/arc-testnet-runbook.md` + `docs/arc-mainnet-runbook.md`)
- [B] agregar `deployments/arc-mainnet-5042/` con direcciones y hashes, y la tabla de mainnet en `https://arc.lendoor.xyz`
- Para el "where the docs or the tooling fell short": the mainnet RPC returns 403 to clients without a
  User-Agent; Arc Studio does not deploy to mainnet; no public gas/fee docs for mainnet (we measured 25 gwei).

**Milestone Status** (las filas del form son Milestone 1–4; nuestros hitos del Entregable 1 son 5)
| Fila del form | Nuestro hito (Entregable 1) | [A] | [B] |
|---|---|---|---|
| Milestone 1 | Core flow on Arc testnet (Oct 9) | Done | Done |
| Milestone 2 | Risk readable on-chain (Oct 16): AccountLens + 10 test loans by script | In progress | In progress |
| Milestone 3 | Loss layer / first-loss (Oct 23) | Changed | Changed |
| Milestone 4 | Vault on Arc mainnet (Oct 30) | In progress | Done |
| (M5, Demo Day loan) | va en texto, no hay fila | — | — |

**Progress on each success metric** (uno por uno, número actual junto al target)
> M1 — "Transactions visible on the explorer": done, 14 of 14 planned txs on testnet (explorer.testnet.arc.io).
> M2 — "AccountLens returns the correct credit line; 10 test loans opened and repaid by script": credit line
> readable on-chain via `creditLimit`/`loans`/`debtOf` (done); AccountLens not deployed (0 of 1); 1 of 10
> scripted loans opened and repaid.
> M3 — "A default does not move the senior share price until the first-loss tranche is exhausted": changed,
> 0 of 1. We moved first-loss from a separate tranche contract to a reserve inside the LoanManager fee split
> (20% of each fee to an on-contract reserve that absorbs `markLate` losses first). New target: <fecha>.
> M4 — "Vault deployed and verified on mainnet, share price equal to its real value": [A] 0 of 1, rehearsed on
> a fork, ETA <fecha> · [B] 1 of 1, share price <PPS> with <X> USDC deposited.
> M5 — "A real loan funded from Arc, repaid and visible end to end": [A] 0 of 1 · [B] 1 loan opened and repaid
> by the team; the Demo Day loan will come from a user wallet, not the deployer. Demo Day is now Nov 13.

**Usage so far** (externo vs equipo, por separado)
> External: 0 wallets, 0 customers, 0 USDC on Arc (we have not opened the Arc app to users yet).
> Team/test: [A] testnet only: 2 wallets, 14 txs, 13.016 USDC deposited, 1 loan of 1 USDC (7 days, 160 bps)
> repaid. [B] mainnet: 2 wallets, <N> txs, <X> USDC in the vault, 1 loan opened and repaid; plus the testnet
> numbers above.
> Context off-Arc: our Celo production has <usuarios activos> active borrowers and <préstamos> loans this
> month (<completar desde lendoor.xyz/panel el mismo día>).

**Evidence (URL required)**
> Testnet: vault `https://explorer.testnet.arc.io/address/0xc90F…fc0c` (dirección completa en
> `deployments/arc-testnet-5042002/addresses-and-txs.json`), LoanManager `0xe385…27d0`, tx list in the repo.
> [B] Mainnet: vault `https://explorer.arc.io/address/<VAULT>`, LoanManager `<LM>`, deposit `<tx>`, loan `<tx>`,
> repay `<tx>`; all in `deployments/arc-mainnet-5042/addresses-and-txs.json`.
> App: `https://arc.lendoor.xyz`. Product in production (Celo): `https://lendoor.xyz/panel`.

**Changes to your milestones**
> M3 (first-loss) changed scope: instead of a separate junior tranche we are building a reserve inside the
> LoanManager fee split, because a second vault doubled the audit surface for a program-sized deployment.
> M4 (mainnet) slipped past Oct 30 because of the funding path and HackMeridian; same scripts, rehearsed on a
> fork. M5 moves with Demo Day to Nov 13.

**What would you need from Arc or the Circle stack that does not exist yet?**
> (1) USDC on Arc for teams whose production runs on a chain outside CCTP (Celo): a faucet-like or Gateway
> path for program teams would have removed our main blocker. (2) A documented way to list a non-Morpho
> ERC-4626 vault (Euler-based) in the Earn Kit; we asked in Deliverable 1 and did not get an answer.
> (3) Mainnet gas/fee documentation (we measured 25 gwei by RPC). (4) The mainnet RPC rejects requests
> without a User-Agent with 403; worth documenting. (5) Arc Studio deploying to mainnet. Benchmarking: on
> Celo we use Alchemy for signer txs and forno for reads; on Arc the public RPC was enough for deployment.

**Which of the following did you attend?** → lo tilda Fabián (12 opciones; estuvo en Lisboa en HackMeridian la semana 5).

**Your greatest constraint or blocker right now**
> Capital and time, not tech: funding the Arc deployer and the pool from outside CCTP, and the team being
> two people at a hackathon the same week as the deliverable. Technically the stack is ready: same contracts
> as our Celo production, deploy rehearsed on a mainnet fork.

**Demo Day question**
> We saw Demo Day moved to Nov 13. We plan to show a real loan on Arc mainnet from a user wallet. Two
> questions: will there be a deck review slot before the 13th, and can the submitted Deliverable 2 be
> updated once we are on mainnet?

## 3. Qué NO prometer en el form

- "Recuperación de incumplidos": `markDefault` deja `active = true`, el ciclo no cierra (runbook testnet, "Qué NO se hace acá").
- Earn Kit / listado del vault: lo preguntamos en el Entregable 1 y no hubo respuesta.
- Números de Celo que no salgan del panel el mismo día.
- Fechas de mainnet que dependan de plata que todavía no está en el deployer.

## 4. Actualización 09/11/2026 — camino B ejecutado

Mainnet deployado y corrido el 09/11 (30 txs OK; vault `0xF29C…e132`, LoanManagerV3 `0xa82A…2D0E`). Las respuestas
finales, con direcciones, hashes y los números de Celo del día, están en `docs/deliverable-2-respuestas.md`.
Falta: commit + push del repo (la URL de documentación del form), que Fabián tilde asistencia y envíe el form,
y el mensaje a Tomi con el pedido de slot temprano en el Demo Day (escala en São Paulo, embarque ~16:30 UTC).
