# Para Lucho — pestaña de Lendoor en el directorio + mensaje a Tomi (09/11/2026)

## 1. Pestaña de Lendoor en el Startup Directory

Doc (lo edita cualquiera de la cohorte; cada equipo su pestaña):
https://docs.google.com/document/d/1_PmZLKMHwVLFQc2D8VCe-pyzV_Tk9Qx2n94p2lX4ypU/edit

Buscá la pestaña **Lendoor**. Hay tres secciones que dicen "To be completed by the team". Pegá esto, en inglés como el resto del doc.
Si querés tocar algo, tocalo; lo único que conviene no cambiar son las direcciones y los números.

### Building on Arc

> The same uncollateralized USDC credit stack that runs our production on Celo, redeployed on Arc: an Euler EVK vault (ERC-4626, USDC), an uncollateralized risk module and LoanManagerV3, which sets the credit line, the offer (term and fee) and the default rules per wallet. Live on Arc testnet since Oct 9 and on **Arc mainnet since Nov 9**: vault `0xF29C85A434Ec303789002E0710001589C313e132`, LoanManagerV3 `0xa82A34E560FCdFE27988C68f877a92825D5f2D0E`, 30 transactions, full deposit → 7-day loan → repayment flow on chain. Repo and runbooks: github.com/fabian416/lendoor-arc · summary: arc.lendoor.xyz. Next: pointing the app to mainnet, the first loan from a user wallet (Demo Day), a first-loss reserve inside the LoanManager, and listing the vault for USDC depositors.

### Looking for

> (1) USDC liquidity for the Arc vault: curators, treasuries or funds that want senior yield from short-term consumer credit, starting small (hundreds to a few thousand USDC). (2) Wallets and fintechs in Latin America that want to embed credit for users with no credit history (B2B2C), the way we do inside Lemon. (3) A path to list the vault in Circle's Earn Kit or with Arc curators. (4) An intro or a 1:1 with Jenna and the Circle team for the Circle Grants cohort 2 (lending is a priority area). (5) Design partners for the first-loss layer.

### Can offer

> Credit underwriting for thin-file users as a service for wallets: risk scoring built on 6,000+ real loans in Argentina and Peru (1,600+ borrowers), repayment-behavior data, and a 7-day micro-loan flow (credit line, offer, borrow, repay, default) that runs on any EVM chain with USDC. Hands-on experience deploying Euler EVK on Arc, with public runbooks for testnet and mainnet. And the lessons of funding an Arc deployer from a chain outside CCTP (Celo), for any team in the same situation.

## 2. Mensaje a Tomi (grupo de Telegram o DM), después de que el form esté enviado

```
Hi Tomi! Update from Lendoor: Deliverable 2 is submitted. We're live on Arc mainnet since today: vault, loan manager and a full deposit → loan → repayment flow, 30 transactions, all on explorer.arc.io. Docs and all hashes at github.com/fabian416/lendoor-arc, summary at arc.lendoor.xyz. Sorry for the delay: we were at HackMeridian in Lisbon that week and getting USDC onto Arc from Celo took a few hops.

Two asks: (1) for Demo Day on Nov 13 we'll be on a layover in São Paulo and board around 16:30 UTC, so one of the first two pitch slots would help us a lot; (2) we'd love a 1:1 this week to review the deck, and if possible an intro or a short call with Jenna / the Circle team about the Circle Grants cohort 2 now that we're on mainnet. Thanks!
```

## 3. Datos a mano

- Vault mainnet: `0xF29C85A434Ec303789002E0710001589C313e132` · LoanManagerV3: `0xa82A34E560FCdFE27988C68f877a92825D5f2D0E` · EVC: `0x4D8218092EE4D292bfC6C980f9B68A86A9C4B1b5`
- Txs: deposit `0xd35c10ae…a3820`, loan `0x9a04915d…dbff3`, repay `0xe1a5c2a6…6bb918` (completos en `deployments/arc-mainnet-5042/addresses-and-txs.json`)
- Celo hoy (lendoor.xyz/stats, 09/11): 6.231 préstamos, 1.601 prestatarios únicos, 67.489 USDC prestados, 4.442 de interés, 8.458 de activos.
- Demo Day: vie 13/11 16:00 UTC, StreamYard, backstage 15:45 UTC, pitch 3 min en inglés, deck ≥5 slides 16:9 + PDF. Práctica obligatoria mié 11/11 18:00 UTC. Deliverable 3 (form de cierre) vence 17/11.
