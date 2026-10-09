# La app de Lendoor contra Arc testnet, en el server de staging

Código: rama `arc-app` del repo privado `fabian416/lendoor` (frontend con la cadena por env; backend sin cambios).
Lo que cambió en el frontend: `src/lib/chain.ts` (Celo o Arc según `VITE_EXPECTED_CHAIN_ID`), los dos
WagmiProvider, el chequeo de cadena de `ContractsProvider.tsx`, los RPC de respaldo de Celo sólo en Celo,
y el `Dockerfile` que ahora recibe direcciones/RPC/chain id por `--build-arg`.

## Pasos (todo en el EC2 de staging, como ec2-user)

```bash
# 1) stack aparte
sudo mkdir -p /opt/docker/lendoor-arc && cd /opt/docker/lendoor-arc
sudo cp /opt/docker/lendoor/.env .env && sudo chmod 600 .env
#    editar .env con las líneas de env.arc.example (clave = owner del LoanManager de Arc)
sudo cp <este repo>/deploy/arc/compose.yml compose.yml
sudo docker network ls | grep lendoor-internal     # ajustar el nombre en compose.yml si difiere

# 2) código: rama arc-app (el server NO tiene auth de GitHub: se manda un tar desde la Mac)
#    en la Mac:  cd ~/personal-repos/lendoor-arc-app && git archive --format=tar.gz -o /tmp/arc-src.tar.gz arc-app \
#                && scp -i ~/.ssh/lendoor_keys /tmp/arc-src.tar.gz ec2-user@54.80.67.249:~/
rm -rf ~/arc-build && mkdir ~/arc-build && tar -xzf ~/arc-src.tar.gz -C ~/arc-build && cd ~/arc-build

# 3) imágenes (build nativo x86, ~3 min cada una)
sudo docker build -t lendoor/backend:arc-local -f backend/Dockerfile .
sudo docker build \
  --build-arg VITE_APP_BASE_URL=https://arc.lendoor.xyz \
  --build-arg VITE_PUBLIC_BACKEND_URL=https://arc.lendoor.xyz/api \
  --build-arg VITE_EVAULT=0xc90F69f03B0f50ECfFE84ded906be678111Afc0c \
  --build-arg VITE_EVAULT_CONTROLLER=0x50c3a68Ab605dfC9561DF580b3195DA6e735Ba2C \
  --build-arg VITE_LOAN_MANAGER_ADDRESS=0x42C61140c0c2f0eb85f73DB66c730F48000ce1C9 \
  --build-arg VITE_USDC=0x3600000000000000000000000000000000000000 \
  --build-arg VITE_RPC_URL=https://rpc.testnet.arc.io \
  --build-arg VITE_EXPECTED_CHAIN_ID=5042002 \
  --build-arg VITE_INCOME_VERIFY=0 \
  -t lendoor/frontend:arc-local -f frontend/Dockerfile .

# 4) arrancar y mirar
cd /opt/docker/lendoor-arc && sudo docker compose up -d
sudo docker logs backend-arc --tail 50      # esperar "Nest application successfully started"
curl -s localhost:5001/health ; curl -s -o /dev/null -w "%{http_code}\n" localhost:3001/

# 5) Caddy: reemplazar el bloque arc.lendoor.xyz por Caddyfile.arc.snippet y recargar
cd /opt/docker/lendoor && sudo docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Qué probar después, con MetaMask en Arc Testnet (chain 5042002, RPC https://rpc.testnet.arc.io)

1. Entrar a https://arc.lendoor.xyz, conectar MetaMask, firmar el SIWE.
2. Onboarding: teléfono (el código sale en `docker logs backend-arc`), encuesta, Self en modo mock.
3. Lend: depositar USDC de testnet en el vault.
4. Borrow: pedir; el backend firma la oferta con la wallet owner y la UI manda `borrowWithTerm`.
5. Repay.

Sin probar todavía: fees del backend con gas en USDC, SIWE por ECDSA, que el ABI del LoanManager
coincida con el topic `LoanOpened` del chain-sync.
