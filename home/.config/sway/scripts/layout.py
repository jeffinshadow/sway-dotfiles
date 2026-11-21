#!/usr/bin/env python3
"""Layout automático do sway (no lugar do autotiling-rs).

Em qualquer tela, a divisão alterna como no autotiling: janela mais larga
que alta divide lado a lado; mais alta que larga divide em cima/embaixo.

Em tela larga (>= LARGA_MIN px, o 32" QHD), as três primeiras janelas viram
três colunas iguais; em tela em pé (mais alta que larga, o 24" em retrato),
três linhas iguais, uma embaixo da outra. Da quarta em diante, a coluna (ou
linha) em foco é dividida no meio (e segue alternando).

Fala direto com o IPC do sway, só com a biblioteca padrão.
"""
import json
import os
import socket
import struct
import sys

LARGA_MIN = int(os.environ.get("LAYOUT_LARGA_MIN", "2400"))
COLUNAS = 3  # máximo de colunas (tela larga) ou linhas (tela em pé)
MAGIC = b"i3-ipc"
RUN_COMMAND, SUBSCRIBE, GET_TREE = 0, 2, 4


def conecta():
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(os.environ["SWAYSOCK"])
    return s


def envia(s, tipo, texto=""):
    dados = texto.encode()
    s.sendall(MAGIC + struct.pack("=II", len(dados), tipo) + dados)


def recebe(s):
    def le(n):
        buf = b""
        while len(buf) < n:
            parte = s.recv(n - len(buf))
            if not parte:
                raise ConnectionError("sway fechou o IPC")
            buf += parte
        return buf

    tamanho, tipo = struct.unpack("=II", le(14)[6:])
    return tipo, json.loads(le(tamanho))


def pede(s, tipo, texto=""):
    envia(s, tipo, texto)
    return recebe(s)[1]


def folhas(no):
    """Janelas no mosaico (sem flutuantes) abaixo de um nó."""
    filhos = no.get("nodes", [])
    if not filhos:
        return [no] if no.get("type") == "con" else []
    return [f for filho in filhos for f in folhas(filho)]


def caminho_do_foco(no, caminho=()):
    """Do nó raiz até a janela em foco no mosaico; None se o foco é flutuante."""
    if no.get("focused") and no.get("type") == "con" and not no.get("nodes"):
        return caminho + (no,)
    for filho in no.get("nodes", []):
        achou = caminho_do_foco(filho, caminho + (no,))
        if achou:
            return achou
    return None


def divisao(cmd, arvore):
    """Prepara onde a próxima janela vai abrir, a partir da janela em foco."""
    caminho = caminho_do_foco(arvore)
    if not caminho:
        return
    janela, pai = caminho[-1], caminho[-2]
    if janela.get("fullscreen_mode") or pai.get("layout") in ("tabbed", "stacked"):
        return
    saida = next(n for n in caminho if n.get("type") == "output")
    ws = next(n for n in caminho if n.get("type") == "workspace")
    avo = caminho[-3] if len(caminho) >= 3 else None

    # "Embrulho": contêiner de um filho só, criado por um split anterior.
    embrulho = pai if pai.get("type") == "con" and len(pai["nodes"]) == 1 else None
    no_topo = pai is ws or (embrulho is not None and avo is ws)

    quer = None
    largura, altura = saida["rect"]["width"], saida["rect"]["height"]
    eixo = "splith" if largura >= LARGA_MIN else "splitv" if altura > largura else None
    if no_topo and eixo:
        faixas = len(ws["nodes"])
        if faixas == 1 or (ws.get("layout") == eixo and faixas < COLUNAS):
            quer = "faixa"  # a próxima janela abre como coluna/linha nova
    if quer is None:
        r = janela["rect"]
        quer = "splitv" if r["height"] > r["width"] else "splith"

    alvo = f'[con_id={janela["id"]}] '
    if quer == "faixa":
        if embrulho is not None:
            cmd(alvo + "split none")
        elif ws.get("layout") != eixo:
            cmd(alvo + eixo)  # filha única: só troca o layout da workspace
        return
    sozinha = len(pai["nodes"]) == 1
    if sozinha and pai.get("layout") == quer:
        return
    cmd(alvo + quer)


def main():
    eventos, comandos = conecta(), conecta()

    def cmd(texto):
        pede(comandos, RUN_COMMAND, texto)

    def aplica():
        divisao(cmd, pede(comandos, GET_TREE))

    pede(eventos, SUBSCRIBE, '["window", "workspace", "output"]')
    aplica()
    ignora = {"title", "urgent", "mark"}
    while True:
        _, evento = recebe(eventos)
        if evento.get("change") in ignora:
            continue
        aplica()


if __name__ == "__main__":
    try:
        main()
    except (ConnectionError, BrokenPipeError, KeyboardInterrupt):
        sys.exit(0)
