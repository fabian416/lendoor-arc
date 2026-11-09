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

## 3. Demo Day — viernes 13/11, 16:00 UTC

### Logística (de la guía oficial de Crecimiento)

| Qué | Cuándo / cómo |
|---|---|
| Mentoría grupal con detalles del Demo Day | **lun 9/11, 18:00 UTC** (Meet en el Notion de la semana 7). Ahí pedir de palabra el slot temprano |
| 1:1 de pitch con Laín Calvo o Crecimiento | mar 10 y jue 12; se pide en el grupo de Telegram |
| **Práctica obligatoria en StreamYard** | **mié 11/11, 18:00 UTC**, 1 hora. Entrar con la misma laptop, cámara y deck que el viernes; compartir las slides para probar |
| Link de StreamYard | lo mandan el **jue 12/11** |
| Demo Day | **vie 13/11**: backstage **15:45 UTC**, apertura 16:00, charla con Circle 16:10, **pitches 16:21–17:24** (16 slots de 4 min: 1 de subir + 3 de pitch), cierre 17:24–17:34 |
| Formato | **3 min máximo, inglés, sin Q&A, cámara encendida**. Aviso a los 30 s finales; cortan a los 3:00. Practicar a **2:45** en voz alta, al menos 3 veces |
| Deck | **≥5 slides, 16:9**, presentado por nosotros desde StreamYard ("Present" → subir PDF o compartir Google Slides). **PDF descargado en la compu** como respaldo |
| Nombre en StreamYard | "Fabián \| Lendoor" o "Lucho \| Lendoor" |
| Video opcional | 30–60 s, sin audio, embebido en una slide; cuenta dentro de los 3 min. La guía recomienda **solo slides** (menos riesgo). Si se usa, probarlo en la práctica del miércoles |
| Stream público | youtu.be/iS0-MCrVUGI (compartirlo con la comunidad) |
| Deliverable 3 | form de cierre, abre después del Demo Day, **vence 17/11** |

### El problema del vuelo y cómo lo resolvemos

TP87 Lisboa → São Paulo sale jue 12/11 23:25 y llega vie 06:50 (hora de São Paulo = hora argentina). TP5786 São Paulo → Buenos Aires sale 14:15, embarque ~13:30–13:45 BRT = **16:30–16:45 UTC**. Los pitches van de 16:21 a 17:24 UTC: **sólo los slots 1 y 2 (16:21–16:28 UTC) son seguros**. Por eso el pedido a Tomi.
Plan: (1) pedir slot 1 o 2 hoy en la mentoría y por escrito; (2) en GRU, sala VIP o zona tranquila con wifi + eSIM de respaldo, laptop cargada, auriculares con micrófono; (3) entrar al backstage 15:45 UTC y compartir el deck apenas se entra; (4) presenta el que tenga mejor señal, el otro queda de respaldo con el mismo PDF; (5) si el embarque se adelanta, avisar por el chat privado del backstage.

### Estructura del deck (5 slides, la que pide la guía)

1. **Qué hacemos y para quién** (una frase): crédito en USDC sin garantía para gente sin historial crediticio en Latinoamérica, dentro de la billetera que ya usa.
2. **Qué construimos**: el stack (vault ERC-4626 + módulo de riesgo sin colateral + LoanManager), vivo en Celo dentro de Lemon y, desde el 9/11, en **Arc mainnet**. Diagrama simple: fondeador → vault → deudor; Lendoor fija línea y oferta.
3. **Tracción y prueba** (números reales del 9/11): 6.231 préstamos, 1.601 prestatarios, 67.489 USDC prestados, 4.442 USDC de interés, 8.458 USDC de activos, rotación 7,9×. Repago a tiempo subió de 65 % a 89 % con la escalera `[verificar el número exacto antes de poner la slide]`. En Arc: 30 txs, depósito, préstamo y repago on-chain.
4. **El pedido** (la slide más importante): liquidez USDC para el vault de Arc, wallets/fintechs de LatAm que quieran embeber crédito, y la cohorte 2 de Circle Grants. Si están levantando ronda, va acá: `<monto, etapa, qué destraba>`.
5. **Contacto**: lendoor.xyz · arc.lendoor.xyz · X @LendoorProtocol · Telegram @LuchoLeonel · mails.

### Guion de 3 minutos (inglés, ~2:45 leído a ritmo normal; ajustar números el jueves)

> Hi, I'm Fabián, co-founder of Lendoor. **Lendoor gives unsecured USDC credit to people with no credit history in Latin America, inside the wallets they already use.**
>
> Here's the problem. In Argentina and Peru, tens of millions of people have a smartphone and a stablecoin wallet, but no credit score, so no one will lend them even ten dollars. Banks can't underwrite them and crypto lending only works if you already have collateral.
>
> We built the underwriting layer that makes small, unsecured loans work. A user asks for a loan inside their wallet, we decide in seconds using identity, on-chain wallet signals and in-app behavior, and the loan is funded from an ERC-4626 vault on chain. Pay on time and your limit climbs one step. Pay late and the limit drops. That ladder is our real risk engine: repayment behavior predicts default far better than any admission score.
>
> It's live. Inside the Lemon wallet, on Celo, we've originated more than **6,200 loans to 1,600 borrowers**, about **67,000 dollars** in principal and **4,400 dollars** in interest, with the capital turning over almost **eight times**. As the ladder kicked in, on-time repayment went from the mid-sixties to **near ninety percent** `[verificar]`.
>
> During this program we brought the exact same stack to Arc. It's been on testnet since October 9 and **since yesterday it's live on Arc mainnet**: the vault, the loan manager, and a full cycle on chain, a deposit, a seven-day loan and its repayment. Thirty transactions, all on the explorer. Same contracts that run our production, now on Circle's chain, with USDC as the asset and the gas.
>
> Why Arc matters for us: it's where institutional USDC lives. Our model is simple: senior capital earns a stable yield from short-term consumer credit, and we take the credit risk with a first-loss reserve.
>
> So here's the ask. One, **USDC liquidity for the Arc vault**, starting small: curators, treasuries or funds that want senior yield from real repayments. Two, **wallets and fintechs in LatAm** that want to offer credit to their users without building a risk team. Three, a conversation with **Circle about the Grants program**, now that we're on mainnet.
>
> We're Fabián and Lucho. lendoor.xyz, arc.lendoor.xyz, and you can find us on Telegram. Thank you.

### Checklist antes del viernes

- [ ] Deck en Google Slides, 16:9, 5 slides, con los números del jueves; PDF descargado en las dos laptops.
- [ ] Guion practicado a 2:45 en voz alta, tres veces, por quien presenta; el otro lo tiene también.
- [ ] Mié 11, 18:00 UTC: práctica en StreamYard con la laptop del viernes; probar compartir el deck.
- [ ] Jue 12: guardar el link de StreamYard; eSIM o roaming activo para GRU; cargadores.
- [ ] Vie 13, 15:45 UTC (12:45 hora São Paulo): en el backstage con el deck ya compartido.
- [ ] Después del Demo Day: Deliverable 3 antes del 17/11.

## 4. Datos a mano

- Vault mainnet: `0xF29C85A434Ec303789002E0710001589C313e132` · LoanManagerV3: `0xa82A34E560FCdFE27988C68f877a92825D5f2D0E` · EVC: `0x4D8218092EE4D292bfC6C980f9B68A86A9C4B1b5`
- Txs: deposit `0xd35c10ae…a3820`, loan `0x9a04915d…dbff3`, repay `0xe1a5c2a6…6bb918` (completos en `deployments/arc-mainnet-5042/addresses-and-txs.json`)
- Celo hoy (lendoor.xyz/stats, 09/11): 6.231 préstamos, 1.601 prestatarios únicos, 67.489 USDC prestados, 4.442 de interés, 8.458 de activos.
- Demo Day: vie 13/11 16:00 UTC, StreamYard, backstage 15:45 UTC, pitch 3 min en inglés, deck ≥5 slides 16:9 + PDF. Práctica obligatoria mié 11/11 18:00 UTC. Deliverable 3 (form de cierre) vence 17/11.
