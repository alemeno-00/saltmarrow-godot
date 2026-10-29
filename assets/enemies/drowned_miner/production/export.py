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
   x=root[0]-f.width//2;y=root[1]-f.height if size==64 else root[1]-f.height//2
   assert x>=0 and y>=0 and x+f.width<=size and y+f.height<=size,(r,c,f.size,(x,y))
   out.paste(f,(c*size+x,r*size+y))
 a=out.getchannel('A');out=out.convert('RGB').quantize(colors=47,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(a)
 clear=Image.new('RGBA',out.size);clear.paste(out,mask=a);out=clear
 out.save(target);return out
p=Path('assets/enemies/drowned_miner')
a=loadrows(p/'production/standing-master.png');b=loadrows(p/'production/prone-master.png',ys=[0,350,625,885,1020,1278],counts=[3,3,4,2,4]);c=loadrows(p/'production/death-master.png',ys=[0,240,450,650,860,1035,1230],counts=[6]*6,equal=True)
rows=[a[0],a[1],b[0],b[1],a[3],a[4],a[5],a[6],b[2],b[3],b[4],c[0],c[1],c[2],c[3],c[4]]
counts=[4,6,3,3,3,3,3,4,4,2,4,6,6,6,6,6]
assert list(map(len,rows))==counts,list(map(len,rows))
sa=46/max(f.height for f in a[0]);sb=min(55/max(f.height for row in b for f in row),61/max(f.width for row in b for f in row));sc=min(46/max(f.height for f in c[0]),61/max(f.width for row in c for f in row))
scales=[sa,sa,sb,sb,sa,sa,sa,sa,sb,sb,sb,sc,sc,sc,sc,sc]
im=export(rows,p/'body.png',scales=scales);im.resize((768,2048),Image.Resampling.NEAREST).save(p/'production/body-2x.png')
(p/'production/validation.json').write_text(json.dumps({'frame':[64,64],'root':[32,56],'counts':counts,'canvas':im.size,'alpha':sorted(set(im.getchannel('A').get_flattened_data()))},indent=2)+'\n')
p=Path('assets/enemies/faithful');a=loadrows(p/'production/standing-master.png',counts=[4,6,4,4]);b=loadrows(p/'production/reactions-master.png',ys=[0,270],counts=[3])
source=Image.open(p/'production/reactions-master.png').convert('RGBA');source.putalpha(source.getchannel('A').point(lambda a:255 if a>=128 else 0))
for y0,y1,xs in [(270,510,[0,355,700,1100,1536]),(510,755,[0,215,430,670,938,1207,1536]),(755,1024,[0,220,448,687,940,1225,1536])]:
 row=[]
 for x0,x1 in zip(xs,xs[1:]):
  f=source.crop((x0,y0,x1,y1));row.append(f.crop(f.getbbox()))
 b.append(row)
rows=a+b
sa=44/max(f.height for f in a[0]);sb=min(44/max(f.height for f in b[0]),61/max(f.width for row in b for f in row));scales=[sa]*4+[sb]*4
im=export(rows,p/'body.png',scales=scales);im.resize((768,1024),Image.Resampling.NEAREST).save(p/'production/body-2x.png')
(p/'production/validation.json').write_text(json.dumps({'frame':[64,64],'root':[32,56],'counts':list(map(len,rows)),'canvas':im.size,'alpha':sorted(set(im.getchannel('A').get_flattened_data()))},indent=2)+'\n')
print('Exported both enemy sheets')
