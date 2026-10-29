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
target=P.parent.parent
report=[]
preview=Image.new('RGBA',(480,192))
for ni,name in enumerate(['bone','slate']):
 strips=[]
 for mode,count in [('tumble',8),('rest',10)]:
  src=Image.open(P/(name+'-'+mode+'-master.png')).convert('RGBA');cs=components(src);assert len(cs)==count,(name,mode,len(cs))
  cs.sort(key=lambda c:(int(((c[1][1]+c[1][3])/2)/src.height*2),c[1][0]))
  if name=='bone' and mode=='rest':
   ten=components(Image.open(P/'bone-ten-master.png').convert('RGBA'));assert len(ten)==1
   # Match the other nine resting silhouettes' height before shared sampling.
   tf,tb,tn=ten[0];th=max(f.height for f,_,_ in cs);tf=tf.resize((round(tf.width*th/tf.height),th),Image.Resampling.NEAREST);cs[-1]=(tf,tb,tn)
  scale=min(44/max(f.width for f,_,_ in cs),44/max(f.height for f,_,_ in cs));strip=Image.new('RGBA',(48*count,48))
  for i,(f,b,n) in enumerate(cs):
   f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST);strip.paste(f,(i*48+24-f.width//2,24-f.height//2))
  strips.append(strip)
 atlas=Image.new('RGBA',(480,96));atlas.paste(strips[0],(0,0));atlas.paste(strips[1],(0,48))
 a=atlas.getchannel('A');atlas=atlas.convert('RGB').quantize(colors=31,dither=Image.Dither.NONE).convert('RGBA');atlas.putalpha(a);clean=Image.new('RGBA',atlas.size);clean.paste(atlas,mask=a);atlas=clean
 tumble=atlas.crop((0,0,384,48));rest=atlas.crop((0,48,480,96));tumble.save(target/(name+'_tumble.png'));rest.save(target/(name+'_faces.png'))
 for face in range(10):rest.crop((face*48,0,(face+1)*48,48)).save(target/(name+'_'+str(face+1)+'.png'))
 preview.paste(atlas,(0,ni*96))
 cells=[tumble.crop((i*48,0,(i+1)*48,48)).resize((240,240),Image.Resampling.NEAREST) for i in range(8)]
 cells[0].save(P/(name+'-tumble.gif'),save_all=True,append_images=cells[1:],duration=90,loop=0,disposal=2)
 counts=[]
 for face in range(10):
  cell=rest.crop((face*48,0,(face+1)*48,48));mask=Image.new('L',(48,48));mp=mask.load()
  for y in range(14,34):
   for x in range(17,31):
    r,g,b,a=cell.getpixel((x,y));is_pip=(max(r,g,b)<70) if name=='bone' else (r>150 and g>130 and b>95 and r-g<55)
    if a and is_pip:mp[x,y]=255
  px=bytearray(mask.tobytes());ncomp=0
  for st in range(2304):
   if not px[st]:continue
   q=deque([st]);px[st]=0;area=0
   while q:
    v=q.popleft();area+=1;y,x=divmod(v,48)
    for ny in range(max(0,y-1),min(48,y+2)):
     for nx in range(max(0,x-1),min(48,x+2)):
      v2=ny*48+nx
      if px[v2]:px[v2]=0;q.append(v2)
   if area>=2:ncomp+=1
  counts.append(ncomp)
 assert counts==list(range(1,11)),(name,counts)
 report.append({'die':name,'tumble_frames':8,'face_frames':10,'frame_size':[48,48],'native_pip_components':counts})
 print(name,'native pip counts',counts)
preview.resize((1440,576),Image.Resampling.NEAREST).save(P/'comparison-3x.png')
(P/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
