# Runbook — Lendoor en Arc testnet (Entregable 1 de la aceleradora)

**Fecha límite: viernes 09/10/2026 19:00 UTC.** Meta interna: jueves 08/10 con los
hashes en el explorer. Alcance acordado: EVault + LoanManagerV3 en Arc **testnet**,
un depósito y **un préstamo abierto y repagado** con una wallet de prueba. Sólo
scripts de foundry: **sin backend, sin mainnet, sin write-off**.

## La red

| | |
|---|---|
| Chain ID | **5042002** (`0x4CF372`) · mainnet 5042 |
| RPC | `https://rpc.testnet.arc.io` |
| Explorer | `https://explorer.testnet.arc.io` |
| Faucet | `https://faucet.circle.com` → Arc Testnet · **10 USDC por pedido** |
| USDC | `0x3600000000000000000000000000000000000000` |

**UN SOLO faucet: el gas se paga en USDC.** No hay USDC envuelto.

### 🔴 El gotcha que puede arruinar todo

El saldo **nativo** (gas, `msg.value`, `eth_getBalance`) usa **18 decimales**. La
interfaz **ERC-20** del mismo token en `0x3600…` usa **6**. **Comparten el mismo
saldo.** El EVault y el LoanManager tienen que ir por la interfaz ERC-20 (6 dp),
igual que en Celo. Cualquier cálculo que use el balance nativo queda **10¹²
corrido**. Antes de mover un peso, verificar:

```bash
cast call 0x3600000000000000000000000000000000000000 "decimals()(uint8)" \
  --rpc-url https://rpc.testnet.arc.io          # tiene que dar 6
cast balance $DEPLOYER --rpc-url https://rpc.testnet.arc.io   # 18 dp
cast call 0x3600000000000000000000000000000000000000 \
  "balanceOf(address)(uint256)" $DEPLOYER --rpc-url https://rpc.testnet.arc.io  # 6 dp
```
Los dos últimos describen **el mismo dinero** con distinta escala.

## La clave

**Una wallet nueva, generada para esto y nada más.** No se usa `ETH_PRIVATE_KEY`
ni `PRIVATE_KEY` del `.env` de prod (`0x4CC1…3185` es owner + governor del vault
de Celo y es la key del incidente 7702). Se genera en el momento, se fondea del
faucet y se descarta. Nunca se imprime en un log ni en un commit.

## Por qué esto no es un salto al vacío

Los scripts ya corrieron en **dos** cadenas: hay `_input_base.txt` y
`_input_celo.txt` con sus `_output_` al lado. Los inputs de Arc ya están creados
(`*_input_arc.txt`). Y las dependencias **no son externas**:
`01_Integrations.s.sol:51-54` despliega EVC, ProtocolConfig, SequenceRegistry y
BalanceTracker desde cero, y `:58` **despliega Permit2 solo** si no se le pasa uno.
Permit2 además sólo lo usan los contratos *Lens* (lectura), no el flujo de
pedir/pagar. `LoanManagerV3.sol` no tiene direcciones horneadas ni `block.chainid`.

## La secuencia

Cada paso escribe su `_output_arc.txt`; el siguiente lo lee. **Copiar la dirección
del output al input del paso siguiente** (los `0xTODO_…` están marcados).

```bash
export ARC_RPC=https://rpc.testnet.arc.io
export PRIVATE_KEY=<la key de prueba>        # nunca la de prod
cd evk-periphery
```

| # | script | lee | produce |
|---|---|---|---|
| 1 | `01_Integrations.s.sol` | `01_Integrations_input_arc.txt` | evc, protocolConfig, sequenceRegistry, balanceTracker, permit2 |
| 2 | `05_EVaultImplementationUncollat.s.sol` | los 5 de arriba | eVaultImplementation + módulos |
| 3 | `06_EVaultFactory.s.sol` | eVaultImplementation | eVaultFactory |
| 4 | `07_EVault.s.sol` | eVaultFactory + USDC | **eVault** |
| 5 | `DeployLoanManager.s.sol` | `LOAN_MANAGER_VAULT=<eVault>` | **LoanManagerV3** |

`DeployLoanManager.s.sol:11-18` toma `PRIVATE_KEY`, `LOAN_MANAGER_VAULT`
(obligatorio) y `LOAN_MANAGER_OWNER` (opcional, default = deployer).

**IRM: no hace falta.** En Celo está en cero — el interés lo cobra
LoanManagerV3 al repagar (`previewLoanWithLate`), no el IRM del vault.

## El cableado y el flujo que se demuestra

```
vault.setLoanManager(<LoanManagerV3>)      # onlyGovCLM
<LM>.setUserRisk(<prueba>, score, limit)   # darle linea a la wallet de prueba
USDC.approve(<vault>, 5e6) && vault.deposit(5e6, <prueba>)
vault.borrow(1e6, <prueba>)                # abre el prestamo via openLoan
USDC.approve(<vault>, …) && vault.repay(…) # cierra via closeLoan
```

Montos chicos a propósito: con 10 USDC por pedido alcanza para gas + depósito de
5 + préstamo de 1. Si falta, se pide de nuevo o con otra wallet.

**El entregable son los hashes de esas transacciones en el explorer**, no un
sistema completo. El Entregable 1 pide "funcionando de punta a punta para el flujo
central", explícitamente "no tiene que estar completo".

## Qué NO se hace acá

- Nada de mainnet (eso es semanas 4-5, y el microgrant del 14/10).
- Nada de backend multi-cadena.
- Nada de write-off. **Y ojo con los hitos del programa: no prometer
  "recuperación de incumplidos"** — `markDefault` nunca pone `L.active = false`
  y `openLoan` exige `!active`, así que ese ciclo hoy no cierra ni en Celo.
