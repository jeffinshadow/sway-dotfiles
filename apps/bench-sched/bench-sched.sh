#!/usr/bin/env bash
# bench-sched.sh — compara escalonadores (EEVDF do kernel x sched_ext LAVD/bpfland) na giratina.
#
#   sintetico                 automático (~3 min): pra cada escalonador, satura os 28 threads
#                             (stress-ng --cpu, simulando build da homologação) e mede a latência
#                             de acordar uma tarefa periódica de 1 ms (loop de jogo/áudio) +
#                             a vazão da carga. Resultado em ~/bench-sched/sintetico-<data>.txt
#   jogo <sched> [carga]      prepara uma rodada no jogo: troca o escalonador (eevdf|lavd|bpfland),
#                             liga carga de fundo se pedir, e arma o log do MangoHud. Depois:
#                             abre o Cyberpunk → Configurações → Benchmark e aperta Shift+F2
#                             quando o benchmark começar (grava 65 s sozinho).
#   fim                       termina a rodada (para a carga, volta pro EEVDF)
#   relatorio                 tabela de todas as rodadas do jogo (FPS médio, 1% e 0,1% low, travadas)
#
# Jogo: na opção de inicialização do Steam, troque %command% por ~/.local/bin/bench-jogo %command%
# (fora de uma rodada armada ele não faz nada: só executa o jogo).
set -uo pipefail
DIR="$HOME/bench-sched"; mkdir -p "$DIR"
ARMADO="${XDG_RUNTIME_DIR:-/tmp}/bench-sched-rodada"
CARGA_PID="${XDG_RUNTIME_DIR:-/tmp}/bench-sched-carga.pid"

sched() {   # troca o escalonador e espera entrar
    case "$1" in
        eevdf) scxctl stop >/dev/null 2>&1 ;;
        lavd) scxctl get 2>/dev/null | grep -q Lavd && scxctl switch --sched lavd --mode gaming >/dev/null 2>&1 \
                 || scxctl start --sched lavd --mode gaming >/dev/null 2>&1 ;;
        bpfland) scxctl get 2>/dev/null | grep -q -i bpfland && return 0
                 scxctl get 2>/dev/null | grep -q running && scxctl switch --sched bpfland --mode gaming >/dev/null 2>&1 \
                 || scxctl start --sched bpfland --mode gaming >/dev/null 2>&1 ;;
        *) echo "escalonador: eevdf|lavd|bpfland" >&2; exit 2 ;;
    esac
    for _ in $(seq 1 15); do
        st=$(cat /sys/kernel/sched_ext/state)
        [[ "$1" == eevdf && "$st" == disabled ]] && return 0
        [[ "$1" != eevdf && "$st" == enabled ]] && return 0
        sleep 1
    done
    echo "aviso: escalonador $1 não confirmou (state=$st)" >&2
}

sintetico() {
    out="$DIR/sintetico-$(date +%F_%H%M).txt"
    printf '%-8s %9s %9s %9s %10s %12s\n' sched "p50(µs)" "p99(µs)" "p99.9" "max(µs)" "carga(ops/s)" | tee "$out"
    for s in eevdf lavd bpfland; do
        sched "$s"; sleep 2
        stress-ng --cpu 28 --cpu-method matrixprod -t 40 --metrics-brief > "$DIR/.carga.log" 2>&1 &
        cp=$!; sleep 5
        stress-ng --cyclic 4 --cyclic-policy other --cyclic-method clock_ns --cyclic-sleep 1000000 \
                  -t 30 > "$DIR/.cyc.log" 2>&1
        wait "$cp"
        p() { grep -E "cyclic: +$1%" "$DIR/.cyc.log" | awk '{print $(NF-1)}' | sort -n | tail -1; }   # pior dos 4
        mx=$(grep -E "cyclic: +min:" "$DIR/.cyc.log" | sed -E 's/.*max: ([0-9]+).*/\1/' | sort -n | tail -1)
        ops=$(awk '/ cpu / && /bogo/ {next} / cpu +[0-9]/ {print $(NF-1)}' "$DIR/.carga.log" | tail -1)
        [[ -z "$ops" ]] && ops=$(grep -E "metrc:.* cpu " "$DIR/.carga.log" | awk '{print $(NF-2)}' | tail -1)
        awk -v s="$s" -v a="$(p 50.00)" -v b="$(p 99.00)" -v c="$(p 99.90)" -v m="$mx" -v o="$ops" \
            'BEGIN {printf "%-8s %9.1f %9.1f %9.1f %10.1f %12s\n", s, a/1000, b/1000, c/1000, m/1000, o}' | tee -a "$out"
    done
    sched eevdf
    echo "(latência = atraso pra acordar uma tarefa de 1 ms com a CPU saturada; menor é melhor."
    echo " carga = vazão dos 28 workers; maior é melhor)" | tee -a "$out"
}

jogo() {
    s="${1:?escalonador: eevdf|lavd|bpfland}"; carga="${2:-sem-carga}"
    sched "$s"
    if [[ "$carga" == carga ]]; then
        setsid stress-ng --cpu 20 --cpu-method matrixprod -t 1800 >/dev/null 2>&1 &
        echo $! > "$CARGA_PID"
    fi
    rodada="$(date +%H%M%S)_${s}_${carga}"
    mkdir -p "$DIR/jogo/$rodada"; echo "$DIR/jogo/$rodada" > "$ARMADO"
    echo "Rodada $rodada armada. Abra o jogo, vá no Benchmark e aperte Shift+F2 quando começar."
    echo "Ao terminar: bench-sched fim"
}

fim() {
    [[ -f "$CARGA_PID" ]] && { pkill -P "$(cat "$CARGA_PID")" 2>/dev/null; kill "$(cat "$CARGA_PID")" 2>/dev/null; rm -f "$CARGA_PID"; }
    pkill -x stress-ng 2>/dev/null
    rm -f "$ARMADO"; sched eevdf; echo "rodada encerrada, de volta ao EEVDF."
}

relatorio() {
    python3 - "$DIR/jogo" <<'PY'
import csv, glob, os, statistics as st, sys
base = sys.argv[1]
rows = []
for d in sorted(glob.glob(os.path.join(base, "*"))):
    for f in sorted(glob.glob(os.path.join(d, "*.csv"))):
        if f.endswith("_summary.csv"): continue
        lines = open(f, errors="ignore").read().splitlines()
        try: h = next(i for i, l in enumerate(lines) if l.startswith("fps,"))
        except StopIteration: continue
        rd = csv.DictReader(lines[h:])
        ft = [float(r["frametime"]) for r in rd if r.get("frametime")]
        if len(ft) < 200: continue
        ft.sort(); n = len(ft); med = ft[n // 2]
        pct = lambda q: ft[min(n - 1, int(q * n))]
        rows.append((os.path.basename(d), n, 1000 / st.mean(ft), 1000 / pct(.99), 1000 / pct(.999),
                     sum(x > 2 * med for x in ft), st.pstdev(ft)))
if not rows: print("nenhuma rodada com log ainda"); sys.exit()
print(f"{'rodada':34} {'quadros':>7} {'FPS médio':>9} {'1% low':>7} {'0,1% low':>8} {'travadas':>8} {'desvio(ms)':>10}")
for r in rows:
    print(f"{r[0]:34} {r[1]:7d} {r[2]:9.1f} {r[3]:7.1f} {r[4]:8.1f} {r[5]:8d} {r[6]:10.2f}")
PY
}

case "${1:-}" in
    sintetico) sintetico ;;
    jogo) shift; jogo "$@" ;;
    fim) fim ;;
    relatorio) relatorio ;;
    *) sed -n '2,19p' "$0"; exit 2 ;;
esac
