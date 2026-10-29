"""Extract disjoint alpha silhouettes; no rectangular slicing through neighbours."""
from pathlib import Path
from PIL import Image
from collections import deque
import json,hashlib
P=Path(__file__).parent
specs=[('skull_crack',8,2),('knee_breaker',8,2),('shatter',9,3),('wide_arc',10,2),('execution',12,3)]
def components(im):
 w,h=im.size;a=bytearray(im.getchannel('A').point(lambda v:255 if v>=128 else 0).tobytes());found=[]
 for start in range(w*h):
  if not a[start]:continue
  a[start]=0;q=deque([start]);pts=[];x0=w;y0=h;x1=y1=0
  while q:
   v=q.popleft();pts.append(v);y,x=divmod(v,w);x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
   for ny in range(max(0,y-1),min(h,y+2)):
    for nx in range(max(0,x-1),min(w,x+2)):
     n=ny*w+nx
     if a[n]:a[n]=0;q.append(n)
  if len(pts)<2000:continue
  mask=Image.new('L',(x1-x0+1,y1-y0+1));mp=mask.load()
  for v in pts:
   y,x=divmod(v,w);mp[x-x0,y-y0]=255
  f=im.crop((x0,y0,x1+1,y1+1));f.putalpha(mask);found.append((f,[x0,y0,x1+1,y1+1],len(pts)))
 return found
src=Image.open(P/'parts-master.png').convert('RGBA');cs=components(src);print([(b,n) for f,b,n in cs]);cs=sorted(cs,key=lambda c:c[2],reverse=True)[:6];assert len(cs)==6;cs.sort(key=lambda c:(int(((c[1][1]+c[1][3])/2)/src.height*2),c[1][0]))
names=['severed_arm','severed_head','flesh_chunk_1','flesh_chunk_2','flesh_chunk_3','flesh_chunk_4'];limits=[22,14,10,12,11,10]
atlas=Image.new('RGBA',(96,64));records=[]
for i,((f,b,n),name,limit) in enumerate(zip(cs,names,limits)):
 scale=limit/max(f.size);f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST);cell=Image.new('RGBA',(32,32));cell.paste(f,(16-f.width//2,16-f.height//2));a=cell.getchannel('A');cell=cell.convert('RGB').quantize(colors=31,dither=Image.Dither.NONE).convert('RGBA');cell.putalpha(a);clean=Image.new('RGBA',cell.size);clean.paste(cell,mask=a);cell=clean
 cell.save(P.parent/(name+'.png'));atlas.paste(cell,((i%3)*32,(i//3)*32));records.append({'file':name+'.png','frame':[32,32],'rows':1,'frames':1,'source_bounds':b,'occupied_max_dimension':limit})
atlas.save(P.parent/'gore_parts.png');atlas.resize((576,384),Image.Resampling.NEAREST).save(P/'parts-6x.png');(P/'parts-validation.json').write_text(json.dumps(records,indent=2)+'\n')
print('Six floor parts exported, 32×32 each, static atlas96×64')
