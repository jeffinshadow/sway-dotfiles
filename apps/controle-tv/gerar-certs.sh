#!/usr/bin/env bash
# gerar-certs.sh — autoridade certificadora local + certificado do controle-tv.
# O celular instala só a ca.crt (uma vez); o servidor usa server.{crt,key}.
# Válido pra shadowtec-giratina.local e pro IP atual. Rodar de novo só refaz o
# certificado do servidor (a CA fica, então o celular não precisa reinstalar).
set -euo pipefail
d="$HOME/.local/share/controle-tv/certs"; mkdir -p "$d"; chmod 700 "$d"; cd "$d"
host="$(cat /etc/hostname).local"
ip="$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')"
if [[ ! -f ca.key ]]; then
  openssl req -x509 -newkey rsa:3072 -nodes -keyout ca.key -out ca.crt -days 3650 \
    -subj "/CN=Shadowtec Casa CA" \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
fi
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/CN=$host"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 825 \
  -extfile <(printf 'subjectAltName=DNS:%s,DNS:localhost,IP:%s,IP:127.0.0.1\nbasicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n' "$host" "$ip")
rm -f server.csr; chmod 600 ./*.key
echo "certificados em $d (host $host, IP $ip)"
