#!/usr/bin/env bash
# Screenshot one section of index.html with everything else hidden.
# usage: scripts/shot.sh <section-id> [width]   ->  shots/<section-id>.png
set -euo pipefail
ID="${1:?section id required}"; W="${2:-820}"; H="${3:-2600}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="$ROOT/shots"; mkdir -p "$OUT"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Inject a stylesheet that isolates the target section and defeats reveal animations.
python3 - "$ROOT/index.html" "$ID" > "$TMP/page.html" <<'PY'
import sys,re
src,sid=sys.argv[1],sys.argv[2]
h=open(src,encoding='utf-8').read()
css=f"""<style id="shot">
  header.bar{{display:none!important}}
  main>section,footer{{display:none!important}}
  main>section#{sid}{{display:block!important;border-top:0!important;padding-top:1.5rem!important}}
  .reveal{{opacity:1!important;transform:none!important;transition:none!important}}
  html{{scroll-behavior:auto!important}}
</style></head>"""
h=h.replace('</head>',css,1)
sys.stdout.write(h)
PY

"$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --window-size="$W,$H" --default-background-color=00000000 \
  --virtual-time-budget=3000 \
  --screenshot="$OUT/$ID.png" "file://$TMP/page.html" 2>/dev/null
# trim uniform rows off the bottom so the shot is tight to the content
python3 - "$OUT/$ID.png" <<'PY'
import sys,zlib,struct
p=sys.argv[1];d=open(p,'rb').read();i=8;idat=b'';w=h=0
while i<len(d):
    ln=struct.unpack('>I',d[i:i+4])[0];tp=d[i+4:i+8]
    if tp==b'IHDR':w,h,bd,ct=struct.unpack('>IIBB',d[i+8:i+18])
    elif tp==b'IDAT':idat+=d[i+8:i+8+ln]
    i+=12+ln
nch={0:1,2:3,3:1,4:2,6:4}[ct];bpp=nch*bd//8;st=w*bpp
raw=zlib.decompress(idat);rows=[];prev=bytearray(st);o=0
for y in range(h):
    f=raw[o];o+=1;ln2=bytearray(raw[o:o+st]);o+=st
    for x in range(st):
        a=ln2[x-bpp] if x>=bpp else 0;b=prev[x];c=prev[x-bpp] if x>=bpp else 0
        if f==1:ln2[x]=(ln2[x]+a)&255
        elif f==2:ln2[x]=(ln2[x]+b)&255
        elif f==3:ln2[x]=(ln2[x]+(a+b)//2)&255
        elif f==4:
            pa,pb,pc=abs(b-c),abs(a-c),abs(a+b-2*c)
            pr=a if(pa<=pb and pa<=pc)else(b if pb<=pc else c)
            ln2[x]=(ln2[x]+pr)&255
    rows.append(bytes(ln2));prev=ln2
last=h-1
while last>0 and len(set(rows[last][k:k+bpp] for k in range(0,st,bpp)))==1: last-=1
last=min(h-1,last+12)
out=b''.join(b'\x00'+r for r in rows[:last+1])
def chunk(t,dd):
    c=struct.pack('>I',len(dd))+t+dd
    return c+struct.pack('>I',zlib.crc32(t+dd)&0xffffffff)
png=b'\x89PNG\r\n\x1a\x0a'[:8]
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,last+1,bd,ct,0,0,0))+chunk(b'IDAT',zlib.compress(out))+chunk(b'IEND',b'')
open(p,'wb').write(png)
print(f"{p}  {w}x{last+1}")
PY
