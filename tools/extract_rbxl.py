import struct, sys, os, lz4.block, zstandard
data=open(sys.argv[1],'rb').read()
out=sys.argv[2]
p=32
classes={}; names={}; src={}; parent={}; cls_of={}
def deint(b,n):
    return [int.from_bytes(bytes(b[j*n+i] for j in range(4)),'big') for i in range(n)]
def zz(v): return (v>>1)^-(v&1)
def refs(b,n):
    r=[];a=0
    for v in deint(b,n):
        a+=zz(v); r.append(a)
    return r
while p<len(data):
    name=data[p:p+4]; cl,ul=struct.unpack('<II',data[p+4:p+12]); p+=16
    if cl:
        raw=data[p:p+cl]
        body=zstandard.ZstdDecompressor().decompress(raw,max_output_size=ul) if raw[:4]==b'\x28\xb5\x2f\xfd' else lz4.block.decompress(raw,uncompressed_size=ul)
        p+=cl
    else: body=data[p:p+ul]; p+=ul
    if name==b'INST':
        cid,=struct.unpack('<I',body[:4]); l,=struct.unpack('<I',body[4:8]); cn=body[8:8+l].decode()
        q=8+l+1; n,=struct.unpack('<I',body[q:q+4]); q+=4
        classes[cid]=(cn,refs(body[q:q+4*n],n))
        for r in classes[cid][1]: cls_of[r]=cn
    elif name==b'PROP':
        cid,=struct.unpack('<I',body[:4]); l,=struct.unpack('<I',body[4:8]); pn=body[8:8+l].decode()
        t=body[8+l]; q=9+l
        if t==1 and pn in('Name','Source'):
            vals=[]
            for r in classes[cid][1]:
                L,=struct.unpack('<I',body[q:q+4]); q+=4
                vals.append(body[q:q+L].decode('utf8','replace')); q+=L
            d=names if pn=='Name' else src
            for r,v in zip(classes[cid][1],vals): d[r]=v
    elif name==b'PRNT':
        n,=struct.unpack('<I',body[1:5])
        c=refs(body[5:5+4*n],n); pr=refs(body[5+4*n:5+8*n],n)
        parent=dict(zip(c,pr))
def path(r):
    s=[]
    while r in names and r!=-1:
        s.append(names[r]); r=parent.get(r,-1)
    return '/'.join(reversed(s))
for r,s in src.items():
    ph=os.path.join(out,path(r)+'.'+cls_of[r]+'.lua')
    os.makedirs(os.path.dirname(ph),exist_ok=True); open(ph,'w').write(s)
    print(len(s),ph)
print('classes',{v[0]:len(v[1]) for v in classes.values()})
