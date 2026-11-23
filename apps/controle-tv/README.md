# Controle TV (modo Smart TV da giratina)

PWA de controle remoto pro modo TV (`~/.config/sway/scripts/modo-tv.sh`): YouTube na
interface de TV, YouTube Music, HBO Max, touchpad, setas/OK/voltar, digitar, mídia e volume.

- Endereço: `https://shadowtec-giratina.local:8443` (mDNS pelo avahi; não depende do IP).
- Servidor: `server.py` (Python puro), sobe com o Sway (`hosts/shadowtec-giratina/sway.conf`).
  Injeta no Sway com `wlrctl` (ponteiro) e `wtype` (teclado); mídia `playerctl`; volume `swayosd-client`.
- HTTPS com CA local: `./gerar-certs.sh` → `~/.local/share/controle-tv/certs/`. O celular instala
  só a `ca.crt` (Configurações → Segurança → Criptografia e credenciais → Instalar certificado → CA).
  Se o IP mudar, nada a fazer (o nome .local vale); rodar o script de novo só se trocar o hostname.
- Token: `~/.config/controle-tv/token` (fora do git). Link pra 1ª abertura: `https://shadowtec-giratina.local:8443/?k=<token>`.
- Precisa: `wtype`, `wlrctl` (AUR), `avahi` ativo e, no firewalld, mdns + 8443/tcp só da rede de casa.
- Atalho no PC: `Super+t` liga/desliga o modo TV.
