# Deliverable 2 — respuestas finales para pegar en el form (09/11/2026)

Form: `https://docs.google.com/forms/d/e/1FAIpQLSfspPAxAw4pIcymDgnnvEuAipm54eoTIrRyzAMnNYOxApvk3Q/viewform`
(verificado abierto el 09/11). Camino **"Yes"**: mainnet deployado y corrido el 09/11/2026.
Lo que está entre `<…>` lo completa Fabián antes de enviar. Nada se envía sin su OK.

---

**Startup Name** → `Lendoor`

**Founder filling out the form** → `Fabián Díaz`

**Is your integration live on Arc Mainnet?** → `Yes`

**Link to your mainnet deployment (URL required)** →
`https://explorer.arc.io/address/0xF29C85A434Ec303789002E0710001589C313e132`
(segundo link, si el campo acepta más de uno: `https://arc.lendoor.xyz`)

**How did the mainnet deployment go? What took longer than expected, what broke, what changed between testnet and mainnet?**

> Deployed on Nov 9 with the same Foundry scripts we used on testnet on Oct 9, rehearsed on a local fork of Arc mainnet on Oct 25. 30 transactions in total, all successful: 18 for the deployment (EVC, protocol config, the 8 EVault modules and implementation, the factory, the vault proxy, LoanManagerV3 implementation and proxy; 41.5M gas), 5 to wire the vault (hook config, loan manager, credit limit manager, a 5 USDC credit line, a 7-day / 160 bps loan offer) and 7 for the end-to-end flow: 5 USDC deposited into the vault, 1 USDC borrowed for 7 days from a second wallet, 1.016 USDC repaid. Vault after the flow: 5.016 USDC of total assets, zero debt. Gas was 20–21 gwei, below the 25 we measured in October; deploy plus wiring cost about 0.84 USDC.
> What took longer than expected: getting USDC onto Arc, not the contracts. Our production runs on Celo, which is not on CCTP, so the USDC had to travel Celo → exchange → Arbitrum → CCTP → Arc, and the first attempt landed on the wrong chain and had to be sent back. That, plus the team being at HackMeridian in Lisbon the week of the Oct 30 deadline, is why we are late.
> What broke: nothing in the contracts. The only differences between testnet and mainnet were the chain id (5042 vs 5042002), the explicit mainnet gate we added to the deploy script, and the funding path. Caveat for other teams: `transfer` on the USDC predeploy reverts on a local anvil fork of Arc, so the money flow can only be rehearsed on the real network; and the mainnet RPC returns 403 to clients without a User-Agent header.

**Link to your updated documentation (URL required)** →
`https://github.com/fabian416/lendoor-arc`
(README with the mainnet table, `docs/arc-mainnet-runbook.md`, `deployments/arc-mainnet-5042/addresses-and-txs.json` with all 30 hashes)

**Where did the docs or the tooling fall short?**

> The mainnet RPC rejects requests without a User-Agent with a 403 (undocumented). There is no public gas/fee documentation for mainnet (we measured 20–25 gwei). Arc Studio does not deploy to mainnet. There is no documented path to list a non-Morpho ERC-4626 vault (Euler-based) in the Earn Kit; we asked in Deliverable 1 and did not get an answer. And for teams whose production chain is outside CCTP (Celo), getting the first USDC onto Arc is the hardest step of the whole program.

**Milestone Status**

| Form row | Our milestone (Deliverable 1) | Status |
|---|---|---|
| Milestone 1 | Core flow on Arc testnet (Oct 9) | Done |
| Milestone 2 | Risk readable on-chain (Oct 16): credit line and loan state readable via `creditLimit` / `loans` / `debtOf`; 10 test loans by script | In progress |
| Milestone 3 | Loss layer / first-loss (Oct 23) | Changed |
| Milestone 4 | Vault on Arc mainnet (Oct 30) | Done (Nov 9) |

**Progress on each success metric**

> M1 — "Transactions visible on the explorer": done. 14 of 14 planned txs on testnet (Oct 9) and 30 of 30 on mainnet (Nov 9), all on explorer.arc.io.
> M2 — "AccountLens returns the correct credit line; 10 test loans opened and repaid by script": the credit line and loan state are readable on-chain (`creditLimit`, `loans`, `debtOf`, `accountLiquidity`), done. AccountLens not deployed (0 of 1). Scripted loans opened and repaid: 1 on testnet and 1 on mainnet (2 of 10).
> M3 — "A default does not move the senior share price until the first-loss tranche is exhausted": changed, 0 of 1. We moved first-loss from a separate tranche contract to a reserve inside the LoanManager fee split (part of each fee goes to an on-contract reserve that absorbs late losses first). Target: after Demo Day.
> M4 — "Vault deployed and verified on mainnet, share price equal to its real value": 1 of 1. Vault `0xF29C…e132` on mainnet, 5 USDC deposited, 1 loan repaid, total assets 5.016 USDC, share price 1.0032.
> M5 — "A real loan funded from Arc, repaid and visible end to end": 1 of 1 by the team (1 USDC, 7 days, repaid 1.016). The Demo Day loan will come from a user wallet, not the deployer.

**Usage so far**

> External: 0 wallets, 0 customers, 0 USDC on Arc. We have not opened the Arc app to users yet.
> Team/test, mainnet: 2 wallets, 30 txs, 5 USDC deposited, 1 loan of 1 USDC (7 days, 160 bps) repaid. Testnet: 2 wallets, 14 txs, 13 USDC deposited, 1 loan repaid.
> Context off-Arc, read from the Celo contracts on Nov 9 (lendoor.xyz/stats): 6,231 loans originated, 1,601 unique borrowers, 67,489 USDC of principal originated, 4,442 USDC of interest generated, 8,458 USDC of total assets, 7.9x capital turnover. Loans and repayments are happening every hour.

**Evidence (URL required)**

> Mainnet vault: https://explorer.arc.io/address/0xF29C85A434Ec303789002E0710001589C313e132
> Mainnet LoanManagerV3: https://explorer.arc.io/address/0xa82A34E560FCdFE27988C68f877a92825D5f2D0E
> Deposit: https://explorer.arc.io/tx/0xd35c10aee676c1031bacc788edd6178d74afbe10b4801b4bd91bace8b94a3820
> Loan: https://explorer.arc.io/tx/0x9a04915ddfdb16443128ac29480daf19df71768646a2cacff7996485243dbff3
> Repayment: https://explorer.arc.io/tx/0xe1a5c2a6cbf2a957135d3fa405445a08674bf28d85082b10192c43b34c6bb918
> All 30 hashes: https://github.com/fabian416/lendoor-arc/blob/main/deployments/arc-mainnet-5042/addresses-and-txs.json
> Testnet vault: https://explorer.testnet.arc.io/address/0xc90F69f03B0f50ECfFE84ded906be678111Afc0c
> App (testnet today, mainnet next): https://arc.lendoor.xyz · Product in production on Celo: https://lendoor.xyz/panel

**Changes to your milestones**

> M3 (first-loss) changed scope: instead of a separate junior tranche we are building a reserve inside the LoanManager fee split, because a second vault doubled the audit surface for a program-sized deployment. M4 (mainnet) slipped from Oct 30 to Nov 9 because of the funding path (Celo is not on CCTP) and HackMeridian; same scripts, rehearsed on a fork, no contract changes. M5 moves with Demo Day to Nov 13.

**What would you need from Arc or the Circle stack that does not exist yet?**

> (1) A USDC path onto Arc for teams whose production runs on a chain outside CCTP: a Gateway or faucet-like route for program teams would have removed our main blocker. (2) A documented way to list a non-Morpho ERC-4626 vault (Euler-based) in the Earn Kit. (3) Mainnet gas/fee documentation. (4) Document that the mainnet RPC requires a User-Agent. (5) Arc Studio deploying to mainnet. For benchmarking: on Celo we use Alchemy for signer txs and forno for reads; on Arc the public RPC was enough for the whole deployment.

**Which of the following did you attend?** → lo tilda Fabián.

**Your greatest constraint or blocker right now**

> Capital and logistics, not tech: funding the Arc deployer and the pool from outside CCTP, and a two-person team that was at a hackathon the week of the deadline. The stack is the same one that runs our Celo production and is now live on Arc mainnet.

**Demo Day**

> We will pitch on Nov 13 and plan to show the mainnet vault and a loan from a user wallet. One logistics note: we will be on a layover in São Paulo that day and board a flight around 16:30 UTC, so an early slot in the pitch order would help us a lot. Also: can this Deliverable 2 be updated if we add the user-wallet loan before Friday?
