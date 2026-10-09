# Lendoor en Arc

Deploy de los contratos de Lendoor (EVault uncollateralized + LoanManagerV3, base
Euler EVK) en **Arc** (la cadena de Circle). Separado a propósito del monorepo de
producción de Celo (`LenDoor`) y del track de Stellar (`lendoor-stellar`): acá vive
SOLO lo de Arc.

- **El runbook es la fuente de verdad:** [`docs/arc-testnet-runbook.md`](docs/arc-testnet-runbook.md)
  — la secuencia completa del Entregable 1 (Arc Acceleration Season), con el gotcha
  de 18-vs-6 decimales y el pre-flight obligatorio.
- `evk-periphery/` — contratos y scripts de deploy (ya corridos en Base y Celo;
  los inputs de Arc son los `*_input_arc.txt`).
- Incluye el fix de la colisión de storage del CLM (slot fijo
  `keccak256("lendoor.evault.creditLimitManager")`) + su suite de tests
  (`test/RiskManagerUncollat/CreditLimitManagerSlot.t.sol`). En el bytecode viejo de
  prod Celo la colisión no existe; este fix importa para TODO deploy nuevo desde
  este fuente.

## Reglas de la casa

1. **Jamás** usar claves del `.env` de prod. Wallet descartable nueva por corrida,
   fondeada de `faucet.circle.com` (el gas se paga en USDC).
2. Pre-flight antes de firmar: imprimir `DEPLOYMENT_RPC_URL` y `DEPLOYER` y PARAR
   si dicen `forno.celo.org` o `0x4CC1…3185`.
3. El saldo nativo usa 18 decimales y la interfaz ERC-20 del mismo USDC usa 6:
   todo va por la interfaz ERC-20.

## Desplegado en Arc testnet (09/10/2026, chain 5042002)

Entregable 1 de Arc Acceleration Season: deploy completo + un depósito, un préstamo y un repago,
12 transacciones exitosas, sin backend. Direcciones y hashes en
[`deployments/arc-testnet-5042002/addresses-and-txs.json`](deployments/arc-testnet-5042002/addresses-and-txs.json);
los registros de `forge script --broadcast` en `deployments/arc-testnet-5042002/broadcast/`.

| Contrato | Dirección |
|---|---|
| EVault USDC (ERC-4626) | [`0xc90F69f03B0f50ECfFE84ded906be678111Afc0c`](https://explorer.testnet.arc.io/address/0xc90F69f03B0f50ECfFE84ded906be678111Afc0c) |
| LoanManagerV3 (proxy ERC-1967) | [`0x42C61140c0c2f0eb85f73DB66c730F48000ce1C9`](https://explorer.testnet.arc.io/address/0x42C61140c0c2f0eb85f73DB66c730F48000ce1C9) |
| EVC | `0x50c3a68Ab605dfC9561DF580b3195DA6e735Ba2C` |
| EVaultFactory | `0x158F751c4042EA3CEEd9585827c3c3759ac8fa99` |
| EVault implementación (módulo sin colateral) | `0x80E8D4444d5Cf3e7A8D54e921c552478C65e20d1` |
| USDC nativo de Arc | `0x3600000000000000000000000000000000000000` |

Flujo demostrado: `deposit` 5 USDC → `setUserRisk` + `setLoanOffer` (7 días, 160 bps) →
`enableController` → `borrowWithTerm` 1 USDC → `repay` 1,016 USDC. Estado final: `totalAssets`
5,016 USDC, deuda 0, `accountLiquidity` responde (el fix del slot del CLM funciona en deploy nuevo).

Reproducir: `scripts/arc-deploy.sh {preflight|sim01|deploy|wire|all}` desde la raíz del repo, con
`ARC_WORKDIR` apuntando a una carpeta privada que tenga `wallets.env` (wallets descartables, fondeadas
en `faucet.circle.com`). El script exporta el bloque anti-prod del runbook antes de firmar nada.

## Página pública

`https://arc.lendoor.xyz` sirve `site/index.html` (estática, desde el Caddy de staging): contratos, transacciones, flujo e hitos.
