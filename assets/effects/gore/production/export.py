from PIL import Image
from pathlib import Path
import json,sys

def spans(v,gap=3):
 pts=[i for i,x in enumerate(v) if x];out=[]
 for i in pts:
  if not out or i-out[-1][-1]>gap:out.append([i])
  else:out[-1].append(i)
 return [(x[0],x[-1]+1) for x in out]

def loadrows(p,ys=None,counts=None,equal=False):
 im=Image.open(p).convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));a=im.getchannel('A')
 yy=list(zip(ys,ys[1:])) if ys else spans([a.crop((0,y,im.width,y+1)).getbbox() is not None for y in range(im.height)],4)
 rows=[]
 for ri,(y0,y1) in enumerate(yy):
  band=im.crop((0,y0,im.width,y1));ba=band.getchannel('A')
  xx=[(round(i*im.width/counts[ri]),round((i+1)*im.width/counts[ri])) for i in range(counts[ri])] if equal else spans([ba.crop((x,0,x+1,ba.height)).getbbox() is not None for x in range(ba.width)],3)
  xx=[(x0,x1) for x0,x1 in xx if x1-x0>=20]
  row=[]
  for x0,x1 in xx:
   f=band.crop((x0,0,x1,band.height));b=f.getbbox()
   if b:row.append(f.crop(b))
  if counts:assert len(row)==counts[ri],(str(p),ri,len(row),counts[ri])
  rows.append(row)
 return rows

def export(rows,target,size=64,scales=None,counts=None,root=None):
 root=root or(size//2,size//2 if size!=64 else 56)
 out=Image.new('RGBA',(max(map(len,rows))*size,len(rows)*size))
 for r,row in enumerate(rows):
  sc=scales[r] if scales else min((size-4)/max(f.width for f in row),(size-4)/max(f.height for f in row))
  for c,f in enumerate(row):
   f=f.resize((max(1,round(f.width*sc)),max(1,round(f.height*sc))),Image.Resampling.NEAREST)
   x=root[0]-f.width//2;y=root[1]-f.height if size==64 and root[1]==56 else root[1]-f.height//2
   assert x>=0 and y>=0 and x+f.width<=size and y+f.height<=size,(r,c,f.size,(x,y))
   out.paste(f,(c*size+x,r*size+y))
 a=out.getchannel('A');out=out.convert('RGB').quantize(colors=47,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(a)
 clear=Image.new('RGBA',out.size);clear.paste(out,mask=a);out=clear
 out.save(target);return out
p=Path('assets/effects/gore');im=Image.open(p/'production/blood-master.png').convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
rows=[]
for (y0,y1),xs in zip([(0,320),(320,690),(690,1024)],[[0,450,900,1536],[0,500,1000,1536],[0,555,990,1536]]):
 row=[]
 for x0,x1 in zip(xs,xs[1:]):
  f=im.crop((x0,y0,x1,y1));row.append(f.crop(f.getbbox()))
 rows.append(row)
scale=28/max(f.width for row in rows for f in row)
atlas=export(rows,p/'blood_decals.png',size=32,scales=[scale]*3)
names=['pool_small','pool_medium','pool_large','splatter_1','splatter_2','splatter_3','splatter_4','drag_smear_1','drag_smear_2']
for i,n in enumerate(names):atlas.crop(((i%3)*32,(i//3)*32,(i%3+1)*32,(i//3+1)*32)).save(p/(n+'.png'))
atlas.resize((576,576),Image.Resampling.NEAREST).save(p/'production/decals-6x.png')
print('Nine32×32 blood decals exported')
