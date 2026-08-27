#!/usr/bin/env bash
# Render the Nth <svg> in index.html to a PNG, resolving CSS custom properties.
# usage: scripts/svg.sh <index> [width] [dark]
set -euo pipefail
N="${1:?svg index required}"; W="${2:-480}"; MODE="${3:-light}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/shots"; mkdir -p "$OUT"
python3 - "$ROOT/index.html" "$N" "$MODE" > "$OUT/svg-$N.svg" <<'PY'
import sys,re
src,n,mode=sys.argv[1],int(sys.argv[2]),sys.argv[3]
h=open(src,encoding='utf-8').read()
svgs=re.findall(r'<svg\b.*?</svg>',h,re.S)
if n>=len(svgs): sys.exit(f"only {len(svgs)} svgs")
s=svgs[n]
# pull the palette out of :root (light) or the [data-theme=dark] block
block=re.search(r':root\{(.*?)\}',h,re.S).group(1) if mode=='light' else \
      re.search(r':root\[data-theme="dark"\]\{(.*?)\}',h,re.S).group(1)
var=dict(re.findall(r'--([a-z0-9-]+)\s*:\s*([^;]+);',block))
def sub(m):
    name=m.group(1).strip()
    return var.get(name,m.group(2).strip() if m.group(2) else '#888')
s=re.sub(r'var\(\s*--([a-z0-9-]+)\s*(?:,\s*([^)]+))?\)',sub,s)
bg=var.get('paper','#fff')
if not s.startswith('<svg'): sys.exit('parse fail')
s=s.replace('<svg','<svg xmlns="http://www.w3.org/2000/svg"',1) if 'xmlns' not in s.split('>')[0] else s
print(f'<?xml version="1.0"?>')
# wrap so the artwork sits on the real panel background
vb=re.search(r'viewBox="([\d.\s-]+)"',s)
print(s.replace('<svg',f'<svg style="background:{bg}"',1))
PY
rsvg-convert -w "$W" -b none "$OUT/svg-$N.svg" -o "$OUT/svg-$N.png"
echo "$OUT/svg-$N.png"
