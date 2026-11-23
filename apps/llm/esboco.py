#!/usr/bin/env python3
"""esboco ARQUIVO|PASTA... — mapa compacto de código/config com números de linha, pro agente local ler só o
trecho que importa (read com offset/limit) em vez do arquivo inteiro.

  arquivo: definições com faixa de linhas (Python: def/class início-fim via ast; sh, js/ts, css, ini/conf,
           markdown, svelte/vue: por padrão de linha)
  pasta:   arquivos de código/config com nº de linhas (sem .git, node_modules, venv, build...), maiores primeiro
"""
import ast, os, re, sys
from pathlib import Path

PADROES = {
    ".sh": r"^\s*(?:function\s+)?([A-Za-z_][\w:-]*)\s*\(\)\s*\{?|^\s*function\s+[\w:-]+|^\s*case\s+.*\s+in\s*$" r'|^\s{2,8}[\w|*\-" ]+\)\s',
    ".js": r"^\s*(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s*\*?\s*\w+|^\s*(?:export\s+)?(?:default\s+)?class\s+\w+"
           r"|^\s*(?:export\s+)?(?:const|let|var)\s+\w+\s*=\s*(?:async\s*)?(?:\([^)]*\)|\w+)\s*=>"
           r"|^\s{2,4}(?:static\s+)?(?:async\s+)?(?!if\b|for\b|while\b|switch\b|catch\b|return\b)\w+\s*\([^)]*\)\s*\{"
           r"|^\s*(?:export\s+)?(?:interface|type|enum)\s+\w+",
    ".css": r"^([^\s{}/@][^{]*|@media[^{]*)\{",
    ".ini": r"^\s*\[([^\]]+)\]|^#::",          # [seção] e os separadores "#::" das configs do Sway
    ".md": r"^#{1,4}\s",
    ".toml": r"^\s*\[\[?[^\]]+\]\]?",
    ".yaml": r"^[A-Za-z_][\w-]*:",
}
for a, b in {".ts": ".js", ".mjs": ".js", ".cjs": ".js", ".jsx": ".js", ".tsx": ".js", ".svelte": ".js", ".vue": ".js",
             ".bash": ".sh", ".zsh": ".sh", ".cfg": ".ini", ".conf": ".ini", ".service": ".ini", ".timer": ".ini",
             ".desktop": ".ini", ".scss": ".css", ".yml": ".yaml"}.items():
    PADROES[a] = PADROES[b]
CODIGO = set(PADROES) | {".py", ".json", ".jsonc", ".html", ".lua", ".go", ".rs", ".c", ".h", ".cpp", ".sql", ".txt"}
IGNORAR = {".git", "node_modules", "venv", ".venv", "__pycache__", "build", "dist", ".cache", ".next", "target", "vendor"}


def linhas(p):
    with open(p, "rb") as f:
        return sum(1 for _ in f)


def py(p):
    arvore = ast.parse(p.read_text(errors="replace"))
    def anda(n, nivel):
        for c in ast.iter_child_nodes(n):
            if isinstance(c, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                tipo = "class" if isinstance(c, ast.ClassDef) else "def"
                print(f"{c.lineno}-{c.end_lineno}: {'  ' * nivel}{tipo} {c.name}")
                if nivel < 1:
                    anda(c, nivel + 1)
    anda(arvore, 0)


def arquivo(p):
    print(f"## {p} ({linhas(p)} linhas)")
    if p.suffix == ".py":
        try:
            return py(p)
        except SyntaxError:
            pass
    padrao = PADROES.get(p.suffix) or (PADROES[".ini"] if p.name in ("config", "conf") else None)
    if not padrao:
        print("(sem padrão pra esse tipo: use rg -n 'termo' ou read por faixa)")
        return
    rx = re.compile(padrao)
    for i, l in enumerate(open(p, errors="replace"), 1):
        if rx.search(l):
            print(f"{i}: {l.rstrip()[:110]}")


def pasta(d):
    itens = []
    for raiz, dirs, nomes in os.walk(d):
        dirs[:] = [x for x in dirs if x not in IGNORAR and not x.startswith(".")]
        for n in nomes:
            p = Path(raiz, n)
            if p.suffix in CODIGO or n in ("Makefile", "Dockerfile", "config"):
                try:
                    itens.append((linhas(p), p))
                except OSError:
                    pass
    itens.sort(key=lambda x: (-x[0], str(x[1])))
    print(f"## {d}/ ({len(itens)} arquivos de código/config; maiores primeiro)")
    for n, p in itens[:60]:
        print(f"{n:6} {p.relative_to(d)}")
    if len(itens) > 60:
        print(f"... +{len(itens) - 60} arquivos (rg --files {d} pra ver todos)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for a in sys.argv[1:]:
        p = Path(a).expanduser()
        if p.is_dir():
            pasta(p)
        elif p.is_file():
            arquivo(p)
        else:
            print(f"## {a}: não existe")
