#!/usr/bin/env bash
# Entregable 1 Arc testnet (Arc Acceleration Season). Uso: arc-deploy.sh {preflight|sim01|deploy|wire|all}
set -euo pipefail
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
S=${ARC_WORKDIR:-$HOME/.lendoor-arc}   # carpeta PRIVADA con wallets.env (export DEPLOYER/DEPLOYER_KEY/BORROWER/BORROWER_KEY); nunca en el repo
cd "$(dirname "$0")/../evk-periphery"
source $S/wallets.env
export ARC_RPC=https://rpc.testnet.arc.io
export DEPLOYMENT_RPC_URL=$ARC_RPC
export PRIVATE_KEY=$DEPLOYER_KEY
export LOAN_MANAGER_OWNER=$DEPLOYER
export SAFE_ADDRESS=""
export SAFE_KEY=0
export USDC=0x3600000000000000000000000000000000000000
export LOAN_MANAGER=""; export VAULT_BASE=""; export VAULT_NEW=""; export ME=$DEPLOYER; export OWNER=$DEPLOYER
RES=$S/result.json; [ -f $RES ] || echo '{}' > $RES
setres(){ tmp=$(mktemp); jq --arg k "$1" --arg v "$2" '.[$k]=$v' $RES > $tmp && mv $tmp $RES; }
getres(){ jq -r --arg k "$1" '.[$k] // empty' $RES; }
send(){ # send <label> <signer G|B> <to> <sig> args...
  local label=$1 who=$2 to=$3 sig=$4; shift 4
  local key=$DEPLOYER_KEY; [ "$who" = "B" ] && key=$BORROWER_KEY
  local out; out=$(cast send "$to" "$sig" "$@" --rpc-url $ARC_RPC --private-key $key --json)
  local h; h=$(echo "$out" | jq -r .transactionHash); local st; st=$(echo "$out" | jq -r .status)
  echo "  [$label] tx=$h status=$st"
  [ "$st" = "0x1" ] || { echo "  !! $label FALLÓ"; echo "$out"; exit 1; }
  setres "tx_$label" "$h"
}
preflight(){
  echo "== preflight =="
  echo "chain-id: $(cast chain-id --rpc-url $ARC_RPC) (esperado 5042002)"
  echo "DEPLOYMENT_RPC_URL=$DEPLOYMENT_RPC_URL"
  echo "deployer=$(cast wallet address --private-key $DEPLOYER_KEY) (esperado $DEPLOYER)"
  echo "borrower=$(cast wallet address --private-key $BORROWER_KEY) (esperado $BORROWER)"
  echo "usdc decimals: $(cast call $USDC 'decimals()(uint8)' --rpc-url $ARC_RPC)"
  DB=$(cast call $USDC 'balanceOf(address)(uint256)' $DEPLOYER --rpc-url $ARC_RPC | awk '{print $1}')
  echo "deployer USDC (6dp): $DB"
  [ "$DB" -ge 2500000 ] || { echo "!! FALTA FONDEAR: $DEPLOYER necesita >= 2.5 USDC del faucet (tiene $DB)"; return 1; }
}
runscript(){ # runscript <script:contract> <broadcast 0|1>
  local bc=""; [ "$2" = "1" ] && bc="--broadcast --slow"
  forge script "$1" --rpc-url $ARC_RPC $bc -vv 2>&1 | tee -a $S/log-forge.txt | grep -vE "^\s*$" | tail -25
}
sim01(){ echo "== simulación 01 (sin broadcast) =="; cp script/01_Integrations_input_arc.txt script/01_Integrations_input.json; runscript script/01_Integrations.s.sol:Integrations 0; }
deploy(){
  preflight
  echo "== 01 Integrations =="; cp script/01_Integrations_input_arc.txt script/01_Integrations_input.json
  runscript script/01_Integrations.s.sol:Integrations 1
  cat script/01_Integrations_output.json; cp script/01_Integrations_output.json $S/01_output_arc.json
  echo "== 05 EVaultImplementationUncollat =="
  jq '{evc, protocolConfig, sequenceRegistry, balanceTracker, permit2}' script/01_Integrations_output.json > script/05_EVaultImplementation_input.json
  runscript script/05_EVaultImplementationUncollat.s.sol:EVaultImplementationUncollat 1
  cat script/05_EVaultImplementation_output.json; cp script/05_EVaultImplementation_output.json $S/05_output_arc.json
  echo "== 06 EVaultFactory =="
  jq '{eVaultImplementation}' script/05_EVaultImplementation_output.json > script/06_EVaultFactory_input.json
  runscript script/06_EVaultFactory.s.sol:EVaultFactory 1
  cat script/06_EVaultFactory_output.json; cp script/06_EVaultFactory_output.json $S/06_output_arc.json
  echo "== 07 EVault =="
  jq --arg f "$(jq -r .eVaultFactory script/06_EVaultFactory_output.json)" --arg u "$USDC" \
    '{oracleRouterFactory:"0x0000000000000000000000000000000000000000",deployRouterForOracle:false,eVaultFactory:$f,upgradable:true,asset:$u,oracle:"0x0000000000000000000000000000000000000000",unitOfAccount:$u}' -n > script/07_EVault_input.json
  runscript script/07_EVault.s.sol:EVaultDeployer 1
  cat script/07_EVault_output.json; cp script/07_EVault_output.json $S/07_output_arc.json
  VAULT=$(jq -r .eVault script/07_EVault_output.json); setres vault "$VAULT"
  echo "== LoanManagerV3 (impl + proxy) =="
  LOAN_MANAGER_VAULT=$VAULT forge script script/DeployLoanManager.s.sol:DeployLoanManagerProxy --rpc-url $ARC_RPC --broadcast -vv 2>&1 | tee -a $S/log-forge.txt | grep -E "deployed at|Deployer|Owner|Vault|ONCHAIN|Error|error" || true
  LM=$(grep -E "Proxy deployed at:" $S/log-forge.txt | tail -1 | awk '{print $NF}'); setres loanManager "$LM"
  IMPL=$(grep -E "Implementation deployed at:" $S/log-forge.txt | tail -1 | awk '{print $NF}'); setres loanManagerImpl "$IMPL"
  echo "VAULT=$VAULT  LM=$LM"
  jq -s '.[0] + {integrations: .[1], implementation: .[2], factory: .[3]}' $RES $S/01_output_arc.json $S/05_output_arc.json $S/06_output_arc.json > $RES.tmp && mv $RES.tmp $RES
}
wire(){
  VAULT=$(getres vault); LM=$(getres loanManager); [ -n "$VAULT" ] && [ -n "$LM" ] || { echo "faltan vault/LM en result.json"; exit 1; }
  EVC=$(cast call $VAULT 'EVC()(address)' --rpc-url $ARC_RPC); setres evc "$EVC"
  echo "== cableado == VAULT=$VAULT LM=$LM EVC=$EVC"
  send hookConfig G $VAULT 'setHookConfig(address,uint32)' 0x0000000000000000000000000000000000000000 0
  send setLoanManager G $VAULT 'setLoanManager(address)' $LM
  send setCreditLimitManager G $VAULT 'setCreditLimitManager(address)' $LM
  VU=$(( $(date +%s) + 7*86400 ))
  send setUserRisk G $LM 'setUserRisk(address,uint16,bool,uint64,uint256)' $BORROWER 700 true $VU 5000000
  echo "  creditLimit(borrower)=$(cast call $LM 'creditLimit(address)(uint256)' $BORROWER --rpc-url $ARC_RPC)"
  send setLoanOffer G $LM 'setLoanOffer(address,uint16,uint16,uint64,uint256)' $BORROWER 7 160 $VU 5000000
  send fundBorrower G $USDC 'transfer(address,uint256)' $BORROWER 500000
  echo "== flujo =="
  send approveDeposit G $USDC 'approve(address,uint256)' $VAULT 5000000
  send deposit G $VAULT 'deposit(uint256,address)' 5000000 $DEPLOYER
  send enableController B $EVC 'enableController(address,address)' $BORROWER $VAULT
  send borrowWithTerm B $VAULT 'borrowWithTerm(uint256,address,uint16,uint16)' 1000000 $BORROWER 7 160
  echo "  debtOf(borrower)=$(cast call $VAULT 'debtOf(address)(uint256)' $BORROWER --rpc-url $ARC_RPC)"
  DUE=1016000
  send approveRepay B $USDC 'approve(address,uint256)' $VAULT $DUE
  send repay B $VAULT 'repay(uint256,address)' $DUE $BORROWER
  echo "== estado final =="
  echo "  totalAssets=$(cast call $VAULT 'totalAssets()(uint256)' --rpc-url $ARC_RPC)"
  echo "  debtOf(borrower)=$(cast call $VAULT 'debtOf(address)(uint256)' $BORROWER --rpc-url $ARC_RPC)"
  echo "  loans(borrower)=$(cast call $LM 'loans(address)' $BORROWER --rpc-url $ARC_RPC | head -c 400)"
  echo "  accountLiquidity=$(cast call $VAULT 'accountLiquidity(address,bool)(uint256,uint256)' $BORROWER false --rpc-url $ARC_RPC 2>&1 | head -2 | tr '\n' ' ')"
  echo "  shares(deployer)=$(cast call $VAULT 'balanceOf(address)(uint256)' $DEPLOYER --rpc-url $ARC_RPC)"
  echo; echo "RESULTADO:"; cat $RES
}
case "${1:-}" in preflight) preflight;; sim01) sim01;; deploy) deploy;; wire) wire;; all) deploy; wire;; *) echo "uso: $0 {preflight|sim01|deploy|wire|all}"; exit 2;; esac
