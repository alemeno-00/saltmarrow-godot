"""Mechanical registration and nearest-sampled exports of generated masters."""
from PIL import Image
from pathlib import Path
from collections import deque
import json,hashlib
P=Path(__file__).resolve().parent;R=P.parent
NEAR=Image.Resampling.NEAREST

def pixel(im,size,preserve_warm=False):
 im=im.convert('RGBA').resize(size,NEAR);a=im.getchannel('A').point(lambda x:255 if x>=128 else 0)
 rgb=im.convert('RGB')
 if preserve_warm:
  pal=rgb.quantize(colors=28,dither=Image.Dither.NONE).getpalette()[:84]
  warm=sorted({v for v in rgb.get_flattened_data() if v[0]>140 and v[0]>v[1]*1.25 and v[1]>v[2]*1.15},key=sum)
  assert warm
  for q in [0,.33,.66,1]:pal.extend(warm[round(q*(len(warm)-1))])
  palette=Image.new('P',(1,1));palette.putpalette(pal+pal[:3]*((768-len(pal))//3))
  im=rgb.quantize(colors=28,dither=Image.Dither.NONE).convert('RGBA')
  # Preserve muted amber only in the three original lantern-glass regions.
  for x in [48,241,400]:
   b=(x-4,9,x+5,21);im.paste(rgb.crop(b).quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA'),b[:2])
 else:im=rgb.quantize(colors=32,dither=Image.Dither.NONE).convert('RGBA')
 im.putalpha(a)
 out=Image.new('RGBA',size);out.paste(im,mask=a);return out

def components(im):
 w,h=im.size;a=bytearray(im.getchannel('A').point(lambda x:255 if x>=128 else 0).tobytes());cs=[]
 for start in range(w*h):
  if not a[start]:continue
  a[start]=0;q=deque([start]);pts=[];x0=w;y0=h;x1=y1=0
  while q:
   v=q.popleft();y,x=divmod(v,w);pts.append(v);x0=min(x0,x);y0=min(y0,y);x1=max(x1,x);y1=max(y1,y)
   for ny in range(max(0,y-1),min(h,y+2)):
    for nx in range(max(0,x-1),min(w,x+2)):
     n=ny*w+nx
     if a[n]:a[n]=0;q.append(n)
  if len(pts)<2000:continue
  mask=Image.new('L',(x1-x0+1,y1-y0+1));p=mask.load()
  for v in pts:
   y,x=divmod(v,w);p[x-x0,y-y0]=255
  f=im.crop((x0,y0,x1+1,y1+1));f.putalpha(mask);cs.append((f,[x0,y0,x1+1,y1+1],len(pts)))
 return cs

src=Image.open(P/'room-master.png').convert('RGBA');assert src.size==(1415,1112)
# Register the generated painting's observed physical boundaries to blockout boundaries.
# No geometry, texture or shading is painted by the exporter.
sx=[0,103,1312,1415];dx=[0,32,416,448]
sy=[0,112,212,420,524,624,1001,1112];dy=[0,32,64,128,160,192,320,352]
room=Image.new('RGBA',(448,352))
for yi in range(len(sy)-1):
 for xi in range(len(sx)-1):
  crop=src.crop(((4 if xi==0 and yi==2 else sx[xi]),sy[yi],sx[xi+1],sy[yi+1])).resize((dx[xi+1]-dx[xi],dy[yi+1]-dy[yi]),NEAR)
  room.paste(crop,(dx[xi],dy[yi]))
# Narrow sluice frames to their exact wall cells; locate middle lantern inside tile7.
nx=[0,103,205,304,443,650,799,974,1112,1312,1415]
nd=[0,32,64,96,128,208,272,320,352,416,448]
for i in range(len(nx)-1):room.paste(src.crop((nx[i],0,nx[i+1],112)).resize((nd[i+1]-nd[i],32),NEAR),(nd[i],0))
room=pixel(room,(448,352),True);room.save(R/'outflow_room.png')
room.resize((896,704),NEAR).save(R/'previews/outflow_room-2x.png')
registry=[{'file':'outflow_room.png','frame_size':[448,352],'rows':[1],'origin_px':[0,0]}]

def sheet(name,frames):
 out=Image.new('RGBA',(32*len(frames),32))
 for i,f in enumerate(frames):out.paste(f,(32*i,0))
 out=pixel(out,out.size);out.save(R/(name+'.png'));registry.append({'file':name+'.png','frame_size':[32,32],'rows':[len(frames)],'origin_px':[16,16]})
 return out

if (P/'gates-master.png').exists():
 im=Image.open(P/'gates-master.png').convert('RGBA');cs=components(im);assert len(cs)==9,len(cs)
 cs.sort(key=lambda c:(min(2,int((c[1][1]+c[1][3])/2/im.height*3)),c[1][0]))
 fs=[]
 for f,b,a in cs:
  cell=Image.new('RGBA',(32,32));cell.paste(pixel(f,(20,22)),(6,10));fs.append(cell)
 sheet('sluice_open',fs[:4]);closing=sheet('sluice_shutting',fs[4:8]);sheet('sluice_shut',[closing.crop((96,0,128,32))])
 (P/'gate-source-crops.json').write_text(json.dumps([b for f,b,a in cs],indent=2)+'\n')
if (P/'flood-master.png').exists():
 im=Image.open(P/'flood-master.png').convert('RGBA');cs=sorted(components(im),key=lambda c:c[1][0]);assert len(cs)==4,len(cs)
 sheet('floor_flooding',[pixel(f,(32,32)) for f,b,a in cs]);(P/'flood-source-crops.json').write_text(json.dumps([b for f,b,a in cs],indent=2)+'\n')
if (P/'tag-master.png').exists():
 im=Image.open(P/'tag-master.png').convert('RGBA');cs=sorted(components(im),key=lambda c:c[1][0]);assert len(cs)==2,len(cs)
 for name,(f,b,a),target in zip(['tally_tag_floor','tally_tag_icon'],cs,[(20,12),(26,26)]):
  ratio=min(target[0]/f.width,target[1]/f.height);sz=(round(f.width*ratio),round(f.height*ratio));cell=Image.new('RGBA',(32,32));cell.paste(pixel(f,sz),((32-sz[0])//2,(32-sz[1])//2));sheet(name,[cell])
 (P/'tag-source-crops.json').write_text(json.dumps([b for f,b,a in cs],indent=2)+'\n')
for e in registry:e['sha256']=hashlib.sha256((R/e['file']).read_bytes()).hexdigest()
(R/'manifest.json').write_text(json.dumps({'grid_px':32,'assets':registry,'room_gates_px':[[96,0],[320,0]],'lantern_glass_px':[[48,15],[241,15],[400,15]],'room_registration':{'x_source':sx,'x_target':dx,'y_source':sy,'y_target':dy,'north_x_source':nx,'north_x_target':nd}},indent=2)+'\n')
print('Exported:',[e['file'] for e in registry])
