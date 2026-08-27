#!/usr/bin/env bash
# Pixel probe: print the RGBA of given x,y coords in a PNG.
# usage: scripts/probe.sh shots/year.png 100,200 140,200
set -euo pipefail
PNG="${1:?png required}"; shift
python3 - "$PNG" "$@" <<'PY'
import sys,zlib,struct
p=open(sys.argv[1],'rb').read()
assert p[:8]==b'\x89PNG\r\n\x1a\n'
i=8;w=h=bd=ct=None;idat=b''
while i<len(p):
    ln=struct.unpack('>I',p[i:i+4])[0];tp=p[i+4:i+8];dt=p[i+8:i+8+ln]
    if tp==b'IHDR': w,h,bd,ct=struct.unpack('>IIBB',dt[:10])
    elif tp==b'IDAT': idat+=dt
    i+=12+ln
raw=zlib.decompress(idat)
nch={0:1,2:3,3:1,4:2,6:4}[ct]; bpp=nch*bd//8; stride=w*bpp
out=bytearray();prev=bytearray(stride);o=0
for y in range(h):
    f=raw[o];o+=1;line=bytearray(raw[o:o+stride]);o+=stride
    for x in range(stride):
        a=line[x-bpp] if x>=bpp else 0;b=prev[x];c=prev[x-bpp] if x>=bpp else 0
        if f==1:line[x]=(line[x]+a)&255
        elif f==2:line[x]=(line[x]+b)&255
        elif f==3:line[x]=(line[x]+(a+b)//2)&255
        elif f==4:
            pa,pb,pc=abs(b-c),abs(a-c),abs(a+b-2*c)
            pr=a if(pa<=pb and pa<=pc)else(b if pb<=pc else c)
            line[x]=(line[x]+pr)&255
    out+=line;prev=line
for spec in sys.argv[2:]:
    x,y=(int(v) for v in spec.split(','))
    off=y*stride+x*bpp
    px=tuple(out[off:off+bpp])
    print(f"{x},{y} -> {px}  #{''.join('%02X'%v for v in px[:3])}")
PY
