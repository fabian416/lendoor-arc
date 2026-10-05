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
