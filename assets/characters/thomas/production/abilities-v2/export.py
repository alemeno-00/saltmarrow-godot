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
rows=[];records=[]
for name,count,nr in specs:
 im=Image.open(P/(name+'-master.png')).convert('RGBA');cs=components(im);print(name,len(cs),[(b,n) for _,b,n in cs]);assert len(cs)==count,(name,len(cs),count)
 cs.sort(key=lambda c:(min(nr-1,int(((c[1][1]+c[1][3])/2)/im.height*nr)),c[1][0]))
 scale=min(55/max(f.height for f,_,_ in cs),61/max(f.width for f,_,_ in cs))
 row=[]
 for f,b,n in cs:
  f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST);row.append(f)
 records.append({'name':name,'count':count,'source_scale':scale,'source_bounds':[b for _,b,_ in cs]});rows.append(row)
out=Image.new('RGBA',(768,320))
for r,row in enumerate(rows):
 for c,f in enumerate(row):out.paste(f,(c*64+32-f.width//2,r*64+56-f.height))
a=out.getchannel('A');out=out.convert('RGB').quantize(colors=31,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(a);clean=Image.new('RGBA',out.size);clean.paste(out,mask=a);out=clean
out.save(P.parent.parent/'mace_abilities.png');out.resize((2304,960),Image.Resampling.NEAREST).save(P/'sheet-3x.png')
for r,(name,count,_) in enumerate(specs):
 cells=[out.crop((c*64,r*64,(c+1)*64,(r+1)*64)).resize((256,256),Image.Resampling.NEAREST) for c in range(count)]
 cells[0].save(P/(name+'.gif'),save_all=True,append_images=cells[1:],duration=160 if name!='execution' else 220,loop=0,disposal=2)
 for c in range(12):assert bool(out.crop((c*64,r*64,(c+1)*64,(r+1)*64)).getbbox())==(c<count)
assert set(a.get_flattened_data())=={0,255}
(P/'validation.json').write_text(json.dumps({'size':out.size,'frame':[64,64],'root':[32,56],'counts':[s[1] for s in specs],'alpha':[0,255],'rows':records},indent=2)+'\n')
