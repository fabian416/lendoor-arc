# Lendoor — Arc Acceleration Season: milestones and evidence

Public evidence doc for Deliverable 3 (Crecimiento × Circle, season Sep 28 – Nov 13, 2026). Milestones as set in
Week 2 (Deliverable 1, Oct 9), Circle's success metric for each, our result as of **Nov 20, 2026**, and the
evidence behind it. Anyone with the link can view; all links are public.

**Summary: 3 of 5 milestones hit (M1, M4, M5), 1 partially (M2), 1 changed in scope and not yet shipped (M3).**

| # | Milestone (Week 2) | Target date | Circle's success metric | Result | Status |
|---|---|---|---|---|---|
| M1 | Core credit flow on Arc testnet | Oct 9 | Transactions visible on the explorer | 14 of 14 planned txs on testnet; later 30 of 30 on mainnet | **Hit** |
| M2 | Risk readable on-chain | Oct 16 | AccountLens returns the correct credit line; 10 test loans opened and repaid by script | Credit line and loan state readable on-chain (`creditLimit`, `loans`, `debtOf`, `accountLiquidity`); AccountLens not deployed; 2 of 10 scripted loans (1 testnet, 1 mainnet) | **Partial** |
| M3 | Loss layer (first-loss) | Oct 23 | A default does not move the senior share price until the first-loss layer is exhausted | Scope changed from a separate junior tranche to a reserve inside the LoanManager fee split; not shipped on Arc yet | **Changed, not hit** |
| M4 | Vault on Arc mainnet | Oct 30 (done Nov 9) | Vault deployed and verified on mainnet; share price equal to its real value | Vault live on Arc mainnet since Nov 9; 5 USDC deposited, 5,000,000 shares, total assets 5.016 USDC → share price 1.0032, equal to deposits plus collected interest | **Hit (late)** |
| M5 | A real loan funded from Arc | Demo Day (Nov 13) | A loan funded from the Arc vault, repaid and visible end to end | 1 USDC borrowed for 7 days from a second wallet and repaid 1.016 USDC on mainnet on Nov 9, by the team; no external-user loan yet | **Hit (team loan)** |

## Where everything lives

- Repo (contracts, scripts, runbooks, all hashes): https://github.com/fabian416/lendoor-arc
- Summary page: https://arc.lendoor.xyz/deliverable-1 (English) · https://arc.lendoor.xyz/entregable-1 (Spanish)
- Mainnet addresses and the 30 transaction hashes: https://github.com/fabian416/lendoor-arc/blob/main/deployments/arc-mainnet-5042/addresses-and-txs.json
- Testnet addresses and hashes: https://github.com/fabian416/lendoor-arc/blob/main/deployments/arc-testnet-5042002/addresses-and-txs.json
- Production on Celo (live stats read from the contracts): https://lendoor.xyz/stats

## M1 — Core credit flow on Arc testnet (hit)

Deployed Oct 9, 2026 on Arc testnet (chain 5042002) with Foundry: EVC, protocol config, the EVault implementation
with our uncollateralized risk module, the factory, the USDC vault and LoanManagerV3. Then a full cycle: 5 USDC
deposited, a 5 USDC credit line and a 7-day / 160 bps offer set for a second wallet, 1 USDC borrowed, 1.016 USDC
repaid. Later a second deposit of 8 USDC and a LoanManagerV3 v2 with owner setters for testing.

- Vault: https://explorer.testnet.arc.io/address/0xc90F69f03B0f50ECfFE84ded906be678111Afc0c
- LoanManagerV3 v2 (used by the vault since Oct 9): https://explorer.testnet.arc.io/address/0xe38594e3173c33bA78BEc2AcF3E424045D3A27d0
- Deposit: https://explorer.testnet.arc.io/tx/0x50ba01ad6c48ca02c0f383dcfc0b472c1389d6db1d4232d39a39ec18e08ee39d
- Loan: https://explorer.testnet.arc.io/tx/0xcda56af9f84347171e5e8e777695380228c93bc33800f7314e3bdaca0700ba6d
- Repayment: https://explorer.testnet.arc.io/tx/0xfa623a79722718233dcc01d64c31677c7808ad59e8c3c450aa4dad4639da623f
- State after: total assets 13.016 USDC, debt 0.

## M2 — Risk readable on-chain (partial)

What is done: a third party can read a wallet's credit line and loan state directly from the contracts on both
networks: `LoanManagerV3.creditLimit(address)`, `loans(address)`, `EVault.debtOf(address)` and
`EVault.accountLiquidity(address)` (the last one works on these deployments thanks to a storage-slot fix we
shipped in October; it reverts on our older Celo deployment).

What is not done: the Euler `AccountLens` periphery contract was not deployed, and only 2 of the 10 scripted
test loans were run (one per network). The scripts exist (`scripts/arc-deploy.sh flow`) and each extra loan costs
cents of gas; this is a matter of hours, not a blocker.

- Mainnet LoanManagerV3: https://explorer.arc.io/address/0xa82A34E560FCdFE27988C68f877a92825D5f2D0E
- Read example (mainnet, Nov 20): `creditLimit(0xC5a1…249f)` = 5,000,000 (5 USDC), `debtOf` = 0.

## M3 — Loss layer / first-loss (changed, not hit)

The Week 2 plan was a separate junior tranche (a second vault) that absorbs losses before the senior share price
moves. We changed the design: a second vault doubled the audit surface for a program-sized deployment, so the
first-loss layer becomes a reserve inside the LoanManager fee split (a share of every fee accrues to an on-contract
reserve that absorbs late losses first). It is designed, not deployed. On the current deployments a default is
written off against the vault directly, so this metric is **not met**.

## M4 — Vault on Arc mainnet (hit, Nov 9 instead of Oct 30)

Deployed Nov 9, 2026 on Arc mainnet (chain 5042) with the same scripts, rehearsed on a mainnet fork on Oct 25.
30 transactions, all successful: 18 deploy, 5 wiring, 7 flow. Gas 20–21 gwei; deploy plus wiring ≈ 0.84 USDC.
The slip from Oct 30 was the funding path (our production chain, Celo, is not on CCTP) and the team being at
HackMeridian the week of the deadline.

- Vault: https://explorer.arc.io/address/0xF29C85A434Ec303789002E0710001589C313e132
- LoanManagerV3 proxy: https://explorer.arc.io/address/0xa82A34E560FCdFE27988C68f877a92825D5f2D0E
- EVC: https://explorer.arc.io/address/0x4D8218092EE4D292bfC6C980f9B68A86A9C4B1b5
- Share price check (Nov 20): `totalAssets` 5,016,000 / `totalSupply` 5,000,000 = 1.0032 per share, which is
  exactly the 5 USDC deposited plus the 0.016 USDC of interest collected. No inflation, no unbacked shares.

## M5 — A real loan funded from Arc (hit as a team loan)

On Nov 9 on mainnet: 0.5 USDC sent to a second wallet, 5 USDC deposited into the vault, the second wallet enabled
the vault as controller in the EVC, borrowed 1 USDC for 7 days at 160 bps and repaid 1.016 USDC. Everything is
on the explorer. What is **not** done yet: a loan from an external user wallet through the app (arc.lendoor.xyz
still runs against testnet).

- Deposit: https://explorer.arc.io/tx/0xd35c10aee676c1031bacc788edd6178d74afbe10b4801b4bd91bace8b94a3820
- Enable controller: https://explorer.arc.io/tx/0xafa64026bdd7670cad32b02caf9654c097f18b6286b848c6ae8c31a08510397d
- Loan: https://explorer.arc.io/tx/0x9a04915ddfdb16443128ac29480daf19df71768646a2cacff7996485243dbff3
- Repayment: https://explorer.arc.io/tx/0xe1a5c2a6cbf2a957135d3fa405445a08674bf28d85082b10192c43b34c6bb918

## Usage on Arc (external vs team)

- External: 0 wallets, 0 customers, 0 USDC. The Arc app has not been opened to users yet.
- Team / test: mainnet 2 wallets, 30 txs, 5 USDC in the vault, 1 loan repaid; testnet 2 wallets, 14 txs, 13 USDC, 1 loan repaid.

## Context off-Arc (production on Celo, read from the contracts)

Nov 9, 2026 (lendoor.xyz/stats): 6,231 loans originated, 1,601 unique borrowers, 67,489 USDC of principal,
4,442 USDC of interest, 8,458 USDC of total assets, 7.9x capital turnover. Updated numbers are always live at
https://lendoor.xyz/stats.
