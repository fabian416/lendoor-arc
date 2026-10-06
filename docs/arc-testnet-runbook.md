# Runbook — Lendoor en Arc testnet (Entregable 1 de la aceleradora)

**Fecha límite: viernes 09/10/2026 19:00 UTC.** Meta interna: jueves 08/10 con los
hashes en el explorer. Alcance acordado: EVault + LoanManagerV3 en Arc **testnet**,
un depósito y **un préstamo abierto y repagado** con una wallet de prueba. Sólo
scripts de foundry: **sin backend, sin mainnet, sin write-off**.

> **Estado al 05/10/2026.** Toda la secuencia de abajo se ensayó de punta a punta
> contra un **anvil forkeado de Arc testnet** (bloque 65.652.766) y, para la parte
> de movimiento de plata, contra un USDC mock de 6 decimales. Los 5 pasos de deploy
> corrieron verdes sobre el fork de Arc, y el flujo depósito → préstamo → repago
> corrió verde con el mock. Lo único que falta es una wallet de prueba fondeada.
> Lo que sigue es la secuencia **corregida**: la versión anterior de este runbook
> tenía 6 pasos que revertían (ver "Lo que estaba mal", al final).

## La red

| | |
|---|---|
| Chain ID | **5042002** (`0x4CF372`) · mainnet 5042 |
| RPC | `https://rpc.testnet.arc.io` |
| Explorer | `https://explorer.testnet.arc.io` |
| Faucet | `https://faucet.circle.com` → Arc Testnet · **10 USDC por pedido** |
| USDC | `0x3600000000000000000000000000000000000000` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` (ya deployado, ~18 KB de code) |

**UN SOLO faucet: el gas se paga en USDC.** No hay USDC envuelto.

**Cuánto cuesta:** el deploy completo son **41.372.739 de gas**. A los 25 gwei que
cobraba la red el 05/10, eso es **≈ 1,03 USDC**. Un solo pedido de faucet (10 USDC)
paga el deploy, el depósito de 5 y el préstamo de 1 con margen. Si el borrower es
una wallet distinta del governor, necesita su propio gas: alcanza con mandarle
~0,3 USDC desde la primera.

### 🔴 El gotcha de los decimales — verificado, es real

El saldo **nativo** (gas, `msg.value`, `eth_getBalance`) usa **18 decimales**. La
interfaz **ERC-20** del mismo token en `0x3600…` usa **6**. **Comparten el mismo
saldo**, medido en vivo:

```
cast balance $D                       -> 10000000000000000000000   (10.000e18)
cast call $USDC "balanceOf(address)"  ->          10000000000      (10.000e6)
```

Exactamente 10¹² de diferencia, sobre la misma plata. El EVault y el LoanManager van
por la interfaz ERC-20 (6 dp), igual que en Celo — eso ya está bien, el vault
reporta `decimals() = 6`. Cualquier cálculo que use el balance **nativo** queda
10¹² corrido. Antes de mover un peso:

```bash
cast call 0x3600000000000000000000000000000000000000 "decimals()(uint8)" \
  --rpc-url https://rpc.testnet.arc.io          # da 6
```

**Ojo aparte:** `totalSupply()` del predeploy devuelve un número que **no** está en
la misma escala que `balanceOf`. No lo uses para derivar escalas ni para calcular
precio de share.

### 🔴 No se puede ensayar el movimiento de plata sobre un fork de anvil

El predeploy `0x3600…` necesita un hook del host que anvil no implementa. Sobre un
fork de Arc, `transfer` y `transferFrom` **revierten con data vacía** (y
`totalSupply()` también), mientras `balanceOf`, `approve`, `decimals` y `allowance`
funcionan. En la red real los mismos `transfer` dan `true` (verificado con
`eth_call` desde una cuenta fondeada). O sea: es una limitación de anvil, **no** de
Arc.

Consecuencia práctica: sobre el fork se puede ensayar **todo el deploy y todo el
cableado de gobernanza**, pero el depósito/préstamo/repago hay que ensayarlo con un
**USDC mock de 6 decimales** (`script/MockUSDC.s.sol`) o directo en la testnet real.

## La clave

**Una wallet nueva, generada para esto y nada más.** No se usa `ETH_PRIVATE_KEY`
ni `PRIVATE_KEY` del `.env` de prod (`0x4CC1…3185` es owner + governor del vault
de Celo y es la key del incidente 7702). Se genera en el momento, se fondea del
faucet y se descarta. Nunca se imprime en un log ni en un commit.

### 🔴🔴 `evk-periphery/.env` se auto-carga y apunta a PROD

Foundry levanta `evk-periphery/.env` solo, sin que se lo pidas. Ese archivo tiene:

```
DEPLOYMENT_RPC_URL=https://forno.celo.org        <- CELO MAINNET
LOAN_MANAGER_OWNER=0x4CC122dFB13bA7888363C964dc0e53cb7153e185   <- la key del 7702
LOAN_MANAGER_VAULT=0xe7ba4Ea0aD3902E8eeD8626506Bc9f0A205e5663   <- un vault viejo de Celo
DEPLOYER_KEY / PRIVATE_KEY / PK / PK_OWNER / SAFE_KEY / DEPOSITOR_PK  <- claves reales
```

Las variables que ya existen en el shell ganan sobre el `.env`, las que no, **se
cuelan**. Esto no es teórico: en el primer ensayo el LoanManagerV3 quedó con
`owner() = 0x4CC1…3185` porque no exporté `LOAN_MANAGER_OWNER`. El síntoma después
es `OwnableUnauthorizedAccount` al llamar `setUserRisk` con la wallet de prueba.

**Por eso el bloque de `export` de abajo exporta TODAS las variables peligrosas,
incluso las que parecen no hacer falta.**

## Por qué esto no es un salto al vacío

Los scripts ya corrieron en **dos** cadenas (hay `_input_base.txt` y
`_input_celo.txt` con sus `_output_` al lado), y ahora también en un fork de Arc.
Las dependencias **no son externas**: `01_Integrations.s.sol:51-54` despliega EVC,
ProtocolConfig, SequenceRegistry y BalanceTracker desde cero.
`LoanManagerV3.sol` no tiene direcciones horneadas ni `block.chainid`.

**Permit2 sí es externo, y sí entra en el camino caliente.** La corrección: no lo
usan "sólo los Lens". `SafeERC20Lib.safeTransferFrom` intenta **Permit2 primero** y
recién después cae a `transferFrom`. En Arc no molesta porque Permit2 ya está
deployado en la dirección canónica y el fallback funciona. Pero `01_Integrations`
**revierte** si le pasás `permit2: 0x0` en una red que no sea el anvil local
(`:56-63` sólo auto-despliega Permit2 cuando `DEPLOYMENT_RPC_URL` es
`http://127.0.0.1:8545`). El input de Arc ya quedó corregido con la dirección
canónica.

## El entorno

```bash
cd evk-periphery

export ARC_RPC=https://rpc.testnet.arc.io
export DEPLOYMENT_RPC_URL=$ARC_RPC     # los scripts 01/05/06/07 forkean de aca
export DEPLOYER_KEY=<la key de prueba> # <- 01/05/06/07 usan ESTA, no PRIVATE_KEY
export PRIVATE_KEY=$DEPLOYER_KEY       # <- DeployLoanManager usa ESTA
export DEPLOYER=<la address de prueba>
export LOAN_MANAGER_OWNER=$DEPLOYER    # obligatorio: si no, se cuela la de prod
export SAFE_ADDRESS=                   # vaciar lo que venga del .env
export SAFE_KEY=
export USDC=0x3600000000000000000000000000000000000000

# chequeo de que no se colo nada de prod
echo $DEPLOYMENT_RPC_URL   # tiene que decir rpc.testnet.arc.io, NO forno.celo.org
cast wallet address --private-key $DEPLOYER_KEY   # tiene que ser la de prueba
```

## La secuencia

**Los scripts leen `*_input.json`, no los `_arc.txt`.** Los `.txt` son las copias
durables (los `.json` están en `.gitignore`); hay que copiarlos a mano en cada paso
y pegar las direcciones del output anterior donde dice `0xTODO_…`.

```bash
cp script/01_Integrations_input_arc.txt script/01_Integrations_input.json
forge script script/01_Integrations.s.sol:Integrations \
  --rpc-url $ARC_RPC --broadcast --slow -vv
cat script/01_Integrations_output.json          # evc, protocolConfig, sequenceRegistry, balanceTracker, permit2
```

| # | script : contrato | lee | produce |
|---|---|---|---|
| 1 | `01_Integrations.s.sol:Integrations` | `01_Integrations_input.json` | evc, protocolConfig, sequenceRegistry, balanceTracker, permit2 |
| 2 | `05_EVaultImplementationUncollat.s.sol:EVaultImplementationUncollat` | `05_EVaultImplementation_input.json` (los 5 de arriba) | eVaultImplementation + 8 módulos |
| 3 | `06_EVaultFactory.s.sol:EVaultFactory` | `06_EVaultFactory_input.json` | eVaultFactory |
| 4 | `07_EVault.s.sol:EVaultDeployer` | `07_EVault_input.json` (factory + USDC) | **eVault** |
| 5 | `DeployLoanManager.s.sol:DeployLoanManagerProxy` | `LOAN_MANAGER_VAULT=<eVault>` por env | **LoanManagerV3** (impl + proxy ERC1967) |

El paso 5 toma `PRIVATE_KEY`, `LOAN_MANAGER_VAULT` (obligatorio) y
`LOAN_MANAGER_OWNER` (opcional, default = deployer, **pero el `.env` lo sobreescribe**).

**IRM: no hace falta.** En Celo está en cero — el interés lo cobra
LoanManagerV3 al repagar (`previewLoanWithLate`), no el IRM del vault. Verificado:
el flujo completo corre con `interestRateModel = address(0)`.

## El cableado y el flujo que se demuestra

Esta es la parte que estaba mal en la versión anterior. La secuencia verificada:

```bash
export VAULT=<eVault>
export LM=<LoanManagerV3 proxy>
export EVC=$(cast call $VAULT 'EVC()(address)' --rpc-url $ARC_RPC)
export BORROWER=<wallet de prueba 2>
G="--rpc-url $ARC_RPC --private-key $DEPLOYER_KEY"
B="--rpc-url $ARC_RPC --private-key $BORROWER_KEY"

# 1) 🔴 OBLIGATORIO Y FACIL DE OLVIDAR: el initialize() del EVK deja las 15 ops
#    hookeadas con target 0, o sea TODAS deshabilitadas. Sin esto, deposit
#    revierte con E_OperationDisabled (0x750f8817).
cast send $VAULT 'setHookConfig(address,uint32)' 0x0000000000000000000000000000000000000000 0 $G

# 2) el LoanManager, de los dos lados
cast send $VAULT 'setLoanManager(address)'        $LM $G    # onlyGovCLM
cast send $VAULT 'setCreditLimitManager(address)' $LM $G    # onlyGov

# 3) riesgo. OJO: setUserRisk tiene CINCO argumentos, y kycOk=false hace que
#    creditLimit() devuelva 0 sin decir nada.
VU=$(( $(date +%s) + 86400 ))
cast send $LM 'setUserRisk(address,uint16,bool,uint64,uint256)' \
  $BORROWER 700 true $VU 5000000 $G
cast call  $LM 'creditLimit(address)(uint256)' $BORROWER --rpc-url $ARC_RPC   # 5000000

# 4) 🔴 LA OFERTA ES OBLIGATORIA: openLoan hace require(o.exists, "no offer").
#    tenorDays y feeBps del borrow tienen que coincidir EXACTO con la oferta.
cast send $LM 'setLoanOffer(address,uint16,uint16,uint64,uint256)' \
  $BORROWER 7 160 $VU 5000000 $G

# 5) depósito de 5 USDC
cast send $USDC  'approve(address,uint256)' $VAULT 5000000 $G
cast send $VAULT 'deposit(uint256,address)' 5000000 $DEPLOYER $G

# 6) 🔴 el borrower tiene que habilitar el vault como controller en la EVC.
#    Sin esto, accountLiquidity revierte con E_NoLiability (0x43855d0f).
#    Y la EVC admite UN SOLO controller por cuenta: si reusás una wallet que ya
#    tenía uno, da EVC_ControllerViolation (0xf1be4519).
cast send $EVC 'enableController(address,address)' $BORROWER $VAULT $B

# 7) 🔴 vault.borrow() NO SIRVE: revierte con BorrowDisabled().
#    El entry point es borrowWithTerm(amount, receiver, tenorDays, feeBps).
cast send $VAULT 'borrowWithTerm(uint256,address,uint16,uint16)' \
  1000000 $BORROWER 7 160 $B

# 8) repago. repay() NO acepta pagos parciales: exige EXACTAMENTE amountDue
#    (= principal * (10000 + feeBps) / 10000 = 1.016.000 para 1 USDC a 160 bps).
DUE=1016000
cast send $USDC  'approve(address,uint256)' $VAULT $DUE $B
cast send $VAULT 'repay(uint256,address)'   $DUE $BORROWER $B
```

Estado esperado al final (medido en el ensayo):

```
totalAssets        5016000      (5 del depósito + 16000 de interés)
debtOf(BORROWER)   0
loans(BORROWER)    active = false
accountLiquidity   (5000000, 0) <- sólo si está aplicado el fix de la colisión
```

Montos chicos a propósito: con 10 USDC por pedido alcanza para gas + depósito de
5 + préstamo de 1.

**El entregable son los hashes de esas transacciones en el explorer**, no un
sistema completo. El Entregable 1 pide "funcionando de punta a punta para el flujo
central", explícitamente "no tiene que estar completo".

## La colisión de storage del CLM

Confirmada por inspección de layout **y por ejecución**. Está arreglada en
`src/RiskManagerUncollat.sol` y trabada por
`test/RiskManagerUncollat/CreditLimitManagerSlot.t.sol` (5 tests).

El módulo corre de dos formas sobre el mismo storage del vault, y el primer slot
libre no coincide:

| | slot de `_creditLimitManager` | qué hay en ese slot en el EVault |
|---|---|---|
| compilado dentro de `EVault`/`Dispatch` | **25** | nada, era suyo |
| por `delegatecall` al módulo suelto | **22** | `BorrowingModule.totalWriteOffs` |

Qué funciones van por cada camino (`EVault.sol`):
- `creditLimitManager()`, `setCreditLimitManager()`, `checkAccountStatus()` **no**
  están declaradas con `use(MODULE_RISKMANAGER)` → corren en el contexto del EVault
  → slot 25 → **correcto**.
- `accountLiquidity()` y `accountLiquidityFull()` sí lo están (`EVault.sol:158,160`)
  → delegatecall al módulo → slot 22 → **roto**.

**Por eso el Entregable 1 no depende del fix:** el camino que valida el préstamo es
`checkAccountStatus`, que corre en el contexto del EVault. En el ensayo, el test del
flujo completo pasa igual **con** el bug reintroducido; los que fallan son los dos
de `accountLiquidity`, con `E_InvalidAddress()` (`0x7669014e`).

Lo que sí rompe, y es lo que importa para la tesis de "protección de riesgo
legible": `AccountLens` llama `accountLiquidity` por `staticcall` y ante el fallo
marca `queryFailure = true` dejando los valores en **cero**
(`src/Lens/AccountLens.sol:162-197`). Un tercero que lea el vault —un curador, un
dashboard de riesgo— ve "sin deuda y sin línea de crédito" en lugar de un error.

**En prod Celo** (`0x31BF6609DC9AefcaFB5D6e5FA4773E0b1bF61a01`, leído el 05/10) el
slot 22 tiene `4358000000` (4.358 USDC de write-offs) y el slot 25 tiene el CLM. O
sea que ahí `accountLiquidity` tampoco anda: el módulo lee 4358000000, lo
interpreta como la address `0x…0103c1cD80`, que no tiene código, y la llamada falla
al decodificar.

**El fix** mueve el CLM a un slot fijo
(`keccak256("lendoor.evault.creditLimitManager")`), que los dos contextos leen
igual, y deja `totalWriteOffs` en el 22 intacto.

🔴 **Para Arc no hace falta nada extra.** Para **Celo sí**: el valor que hoy vive en
el slot 25 deja de leerse, así que después de cambiar la implementación hay que
**volver a llamar `setCreditLimitManager`**, idealmente en el mismo batch. Si se
olvida, `checkAccountStatus` lee cero y **todo borrow y todo repay revierten**.
Eso es un paso de prod: lo decide y lo ejecuta Fabián.

## Qué NO se hace acá

- Nada de mainnet (eso es semanas 4-5, y el microgrant del 14/10).
- Nada de backend multi-cadena.
- Nada de write-off. **Y ojo con los hitos del programa: no prometer
  "recuperación de incumplidos"** — `markDefault` (`LoanManagerV3.sol:236-251`)
  pone `L.defaulted = true` pero nunca `L.active = false`, y `openLoan` exige
  `!L.active`, así que ese ciclo hoy no cierra ni en Celo.

## Lo que estaba mal en la versión anterior de este runbook

Para que no vuelva a pasar. Cada uno de estos reventaba el ensayo:

1. `permit2: 0x0` en el input de Arc → `01_Integrations` revierte. Permit2 ya está
   en Arc; el script sólo lo auto-despliega sobre el anvil local.
2. "Permit2 sólo lo usan los Lens" → falso, se intenta **primero** en cada
   `transferFrom` del vault.
3. Faltaba `cp *_input_arc.txt *_input.json`: los scripts leen `.json`.
4. Faltaba el contrato en el `forge script` y los nombres de las env vars:
   01/05/06/07 usan `DEPLOYER_KEY` + `DEPLOYMENT_RPC_URL`, DeployLoanManager usa
   `PRIVATE_KEY`.
5. Faltaba la advertencia del `.env` auto-cargado con RPC y claves de prod.
6. Faltaba `setHookConfig(0, 0)` → `deposit` revierte con `E_OperationDisabled`.
7. `vault.borrow(1e6, …)` → revierte con `BorrowDisabled()`. Es `borrowWithTerm`.
8. `setUserRisk(<prueba>, score, limit)` → son 5 argumentos, con `kycOk` y
   `validUntil`.
9. Faltaba `setLoanOffer` → `openLoan` revierte con `"no offer"`.
10. Faltaba `evc.enableController` → `E_NoLiability`.
11. `repay` no acepta montos libres: exige exactamente `amountDue`.
