# Runbook — Lendoor en Arc MAINNET (Deliverable 2, viernes 30/10/2026 19:00 UTC)

Mismo stack que testnet (EVK sin colateral + LoanManagerV3), mismos scripts, otra red. Lo que cambia
cabe en una tabla. Lo que no cambia es la regla: **una sola sesión deploya, con Fabián presente y el OK
explícito** (`ARC_MAINNET_OK=1`); sin esa variable el script no firma nada.

## La red (verificado el 25/10 por RPC)

| | testnet (09/10) | **mainnet** |
|---|---|---|
| Chain ID | 5042002 | **5042** (`0x13b2`) |
| RPC | rpc.testnet.arc.io | **https://rpc.mainnet.arc.io** (`rpc.arc.io` no resuelve; urllib sin User-Agent da 403, cast/forge/curl andan) |
| Explorer | explorer.testnet.arc.io | **https://explorer.arc.io** |
| USDC | `0x3600…0000` | **la misma dirección**: predeploy, `decimals()=6`, `symbol()=USDC`, 1.798 bytes de código |
| Permit2 | canónico | **el mismo** `0x0000…BA3`, 9.152 bytes: el 01 no intenta desplegarlo |
| Gas | 25 gwei | **25 gwei** el 25/10 → deploy completo (41,4 M gas) ≈ **1,03 USDC** |
| Plata | faucet 10 USDC | **real**: hay que llevarla |

Inputs: sirven los mismos `evk-periphery/script/*_input_arc.txt` (el 07 lo genera el script con `$USDC`).
El 18-vs-6 decimales sigue igual (saldo nativo 18 dp, ERC-20 6 dp, misma plata).


## Las wallets

`~/.lendoor-arc/wallets.env` (creado el 25/10, permisos 600, nunca al repo):

| | dirección | rol |
|---|---|---|
| DEPLOYER | `0x2200D34feF13071cC0acdb38D9C929e83966636A` | deployer, `owner()` del LoanManagerV3, governor del vault, fondeador |
| BORROWER | `0xC5a129d00D44d5E9c0B81D7d07355A6Ca62a249f` | deudor del préstamo de demostración |

Descartables y nuevas: no son las de prod (`0x4CC1…3185` jamás). ⚠️ A diferencia de testnet, en mainnet la
key del DEPLOYER termina en el `.env` del backend de Arc (firma las ofertas): después del Demo Day, pasar
`owner`/governor a una key seria o a una Safe.

**Fondeo (Fabián): ~10 USDC a DEPLOYER en Arc mainnet.** Caminos: `portal.arc.io` (CCTP desde Base,
Ethereum, Arbitrum, Avalanche, Polygon u OP; **Celo no está**) o un exchange con retiro a Arc. 10 y no 3
porque si el gas sube a 100 gwei el deploy pasa a 4 USDC. Verificar:

```bash
cast call 0x3600000000000000000000000000000000000000 'balanceOf(address)(uint256)' \
  0x2200D34feF13071cC0acdb38D9C929e83966636A --rpc-url https://rpc.mainnet.arc.io   # >= 7000000
```

## Pre-flight (no firma nada)

```bash
cd ~/personal-repos/lendoor-arc
ls evk-periphery/.env 2>/dev/null && echo "!! hay un .env: revisarlo antes de seguir"   # el 25/10 no existía
ARC_NET=mainnet scripts/arc-deploy.sh preflight
```

Debe imprimir `chain-id: 5042`, el deployer esperado, y cortar en el gate ("falta ARC_MAINNET_OK=1")
o en el fondeo. Si imprime `forno.celo.org` o `0x4CC1…`, parar.

## La corrida (una sola sesión; OK explícito de Fabián)

```bash
export ARC_NET=mainnet ARC_MAINNET_OK=1
scripts/arc-deploy.sh deploy   # 01 Integrations → 05 Impl → 06 Factory → 07 EVault → LoanManagerV3 (impl + proxy)
scripts/arc-deploy.sh wire     # setHookConfig(0,0) · setLoanManager · setCreditLimitManager · setUserRisk(5 USDC) · setLoanOffer(7 d, 160 bps)
scripts/arc-deploy.sh flow     # 0,5 USDC al deudor · deposit 5 · enableController · borrowWithTerm 1 · repay 1,016
```

Salidas: `~/.lendoor-arc/result-mainnet.json` (direcciones + hashes), `~/.lendoor-arc/log-forge-mainnet.txt`,
`evk-periphery/broadcast/*/5042/`. Copiarlas al repo como en testnet:
`deployments/arc-mainnet-5042/addresses-and-txs.json` + `broadcast/`.

Si un paso falla el script corta en el primer `status != 0x1`. **No volver a correr `deploy`** (crearía otro
juego de contratos y gastaría otro USDC): mirar la tx en el explorer, corregir y seguir a mano con `cast`
desde el paso que falló. `wire` y `flow` sí se pueden repetir paso a paso.

## Después del deploy: la app contra mainnet (es un paso de prod en staging; lo ejecuta Fabián)

Base: `deploy/arc/README.md`. Cambia solo esto:

- Backend `.env` de `/opt/docker/lendoor-arc`: `ETH_RPC_URL` y `ETH_RPC_URL2` = `https://rpc.mainnet.arc.io`,
  `ETH_LOAN_MANAGER=<LM>`, `ETH_EVAULT=<VAULT>`, `ETH_PRIVATE_KEY=<DEPLOYER_KEY>`. `ETH_USDC` igual.
- Frontend: rebuild con `VITE_EVAULT=<VAULT>`, `VITE_EVAULT_CONTROLLER=<EVC>`, `VITE_LOAN_MANAGER_ADDRESS=<LM>`,
  `VITE_RPC_URL=https://rpc.mainnet.arc.io`, `VITE_EXPECTED_CHAIN_ID=5042`. El SIWE y la oferta firmada (EIP-712)
  toman el chain id de ahí: es la pregunta que otro equipo hizo en el doc de Queries y nos aplica.
- Chain-sync: el backend persiste el cursor en la tabla `chain_scan_cursor` (fila `LOAN_OPENED_CURSOR_ID`); si la fila
  no existe arranca en `currentBlock − 100.000` (`chain-sync.service.ts`). Para mainnet: DB `lendoor_arc` nueva o
  `DELETE FROM chain_scan_cursor` antes de levantar el backend; si queda el cursor de testnet, busca bloques que no existen.
- `docker compose up -d`, logs del backend, `/health`, y una prueba con MetaMask en Arc mainnet: connect,
  onboarding, `setUserRisk` + `setLoanOffer` a la wallet de Fabián (lo hace el backend al pedir), borrow, repay.
  **Ese préstamo desde una wallet real es el H4 del Demo Day; se puede adelantar.**
- `site/index.html` e `index-en.html`: pill "Arc mainnet · chain 5042" y tabla de direcciones y txs de mainnet
  (links a explorer.arc.io), arriba de la de testnet. README: sección "Desplegado en Arc mainnet (dd/10/2026, chain 5042)".

## Go / no-go

- **Lunes 26 a la noche:** ¿hay ≥ 7 USDC en DEPLOYER? Sí → martes se deploya. No → plan B del Deliverable 2
  (§4.4 de `docs/deliverable-2.md`), que exige haberlo hablado antes con Crecimiento.
- **Antes de `flow`:** `wire` terminó con 5 txs `status=0x1` y `creditLimit(BORROWER)=5000000`.
- **Antes de tocar la app:** `result-mainnet.json` copiado al repo y las direcciones en el README.

## Lo que puede salir mal

Los mismos once gotchas del runbook de testnet (hook config, `borrowWithTerm`, oferta obligatoria,
`enableController`, repago exacto, `.env` auto-cargado…) más tres de mainnet:

1. **RPC 403**: librerías sin User-Agent. No es la red caída.
2. **Gas**: el precio puede moverse; por eso el margen de 10 USDC.
3. **El owner key en el server**: es la misma key que firma ofertas en la app. Si el server se compromete, se
   compromete el vault de Arc (hoy con 5 USDC). Aceptable para el Demo Day, no para usuarios reales.

## Ensayo del 25/10 sobre un anvil forkeado de Arc mainnet (bloque ~27,8 M)

Corrió **el mismo script** con `ARC_NET=fork` y claves de juguete fondeadas con `anvil_setBalance`
(el saldo nativo sí se ve por `balanceOf` del ERC-20, así que el preflight pasa):

| Paso | txs | gas | resultado |
|---|---|---|---|
| 01 Integrations (EVC, ProtocolConfig, SequenceRegistry, BalanceTracker) | 4 | 9.083.721 | ✅ |
| 05 EVault implementation + 8 módulos | 9 | 26.800.277 | ✅ |
| 06 EVault factory | 2 | 1.362.001 | ✅ |
| 07 EVault (USDC `0x3600…`) | 1 | 1.115.907 | ✅ |
| LoanManagerV3 impl + proxy | 2 | 3.121.879 | ✅ |
| **deploy total** | **18** | **41.483.785** | **≈ 1,04 USDC a 25 gwei**, 42 s |
| wire: hookConfig, setLoanManager, setCreditLimitManager, setUserRisk, setLoanOffer | 5 | — | ✅ `creditLimit(BORROWER)=5000000` |
| flow: primer `transfer` del predeploy | — | — | ❌ esperado: anvil no implementa el hook del predeploy (igual que en testnet; en la red real anda) |

Conclusión: deploy y cableado están verificados contra el estado real de mainnet; lo único que no se
puede ensayar sin plata es el movimiento de USDC, y ese flujo ya corrió verde en testnet el 09/10.

## ✅ Corrida real del 09/11/2026 (Deliverable 2)

- Fondeo: 9,93 USDC al deployer `0x2200…636A`, llegados por CCTP vía la wallet de Lucho (el primer envío cayó
  por error en Celo y hubo que devolverlo; Celo no está en CCTP). Gas de la red: 20–21 gwei.
- `preflight` → `deploy` → `wire` → `flow`: **30 transacciones, todas exitosas**. Gas de deploy 41.483.785
  (igual que el ensayo en fork). Costo deploy+wire ≈ 0,84 USDC; el deployer terminó con 3,58 USDC.
- Vault `0xF29C85A434Ec303789002E0710001589C313e132`, LoanManagerV3 proxy `0xa82A34E560FCdFE27988C68f877a92825D5f2D0E`,
  EVC `0x4D8218092EE4D292bfC6C980f9B68A86A9C4B1b5`. Lista completa en `deployments/arc-mainnet-5042/addresses-and-txs.json`.
- Estado final medido con `cast`: `totalAssets` 5.016.000, `cash` 5.016.000, `debtOf(borrower)` 0, `creditLimit` 5 USDC.
- El LoanManager de mainnet es la versión sin `setMinHoldDays`: el mismo borrower puede volver a pedir recién
  4 días después de repagar. Para más préstamos de prueba, usar otra wallet con `setUserRisk` + `setLoanOffer`.
- Pendiente: la app contra mainnet (sección "Después del deploy", paso de Fabián/Lucho) y el commit del repo.
