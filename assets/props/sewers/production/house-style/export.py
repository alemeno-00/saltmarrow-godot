"""Palette-register existing generated props and their generated normal studies."""
from pathlib import Path
from PIL import Image
import json,sys,math,hashlib
P=Path(__file__).resolve().parent;R=P.parents[1];ROOT=P.parents[4]
sys.path.insert(0,str(ROOT/'assets/characters/thomas/production/room-fit'))
from registration import fit
ROOM=[tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text()) if max(c)>15]
def lum(c):return .2126*c[0]+.7152*c[1]+.0722*c[2]
def nearest(c):return min(ROOM,key=lambda p:sum((p[i]-c[i])**2 for i in range(3)))
m=json.loads((R/'manifest.json').read_text());entries=[]
for e in m['assets']:
 name=Path(e['file']).stem;before=Image.open(P/(name+'-before.png')).convert('RGBA');colour=before.copy();pixels=[]
 for c in before.get_flattened_data():pixels.append((*nearest(c),255) if c[3] else (0,0,0,0))
 colour.putdata(pixels);fw,fh=e['frame_size'];counts=e['rows']
 # Replace residual nearly black contour with its adjacent material's darker room tone.
 for y in range(before.height):
  for x in range(before.width):
   c=before.getpixel((x,y))
   if not c[3] or max(c[:3])>=20:continue
   near=[]
   for dy,dx in [(0,-1),(0,1),(-1,0),(1,0),(0,-2),(0,2),(-2,0),(2,0)]:
    xx,yy=x+dx,y+dy
    if 0<=xx<before.width and 0<=yy<before.height and xx//fw==x//fw and yy//fh==y//fh:
     v=before.getpixel((xx,yy))
     if v[3] and max(v[:3])>35:near.append(v)
   if near:
    material=nearest(near[0]);options=[p for p in ROOM if 15<lum(p)<=max(25,lum(material)-10)]
    if options:colour.putpixel((x,y),(*min(options,key=lambda p:sum((p[i]-material[i]*.8)**2 for i in range(3))),255))
 for row,count in enumerate(counts):
  for col in range(count):
   frame=colour.crop((col*fw,row*fh,(col+1)*fw,(row+1)*fh));b=frame.getchannel('A').getbbox()
   if name not in ['salve','bandage','grate_key','letter','hymn_sheet']:
    for x in range(b[0],b[2]):
     c=frame.getpixel((x,b[3]-1))
     if c[3]:
      choices=[p for p in ROOM if 15<lum(p)<=max(22,lum(c)-10)]
      if choices:frame.putpixel((x,b[3]-1),(*min(choices,key=lambda p:abs(lum(p)-(lum(c)-12))),255))
   colour.paste(frame,(col*fw,row*fh))
 colour.save(R/e['file']);e['sha256']=hashlib.sha256((R/e['file']).read_bytes()).hexdigest();normal_path=P/(name+'-normal-master.png')
 if normal_path.exists():
  # Character helper uses 64px cells; props are temporarily registered at 64px
  # nearest scale, then reduced back to their exact original per-axis frame size.
  cols=max(counts);scaled=Image.new('RGBA',(cols*64,len(counts)*64))
  for row,count in enumerate(counts):
   for col in range(count):scaled.paste(before.crop((col*fw,row*fh,(col+1)*fw,(row+1)*fh)).resize((64,64),Image.Resampling.NEAREST),(col*64,row*64))
  normal,registration=fit(Image.open(normal_path),scaled,counts);normal=normal.resize(before.size,Image.Resampling.NEAREST);normal.putalpha(before.getchannel('A'));out=[]
  for r,g,b,a in normal.get_flattened_data():
   if not a:out.append((0,0,0,0));continue
   v=[r/127.5-1,g/127.5-1,max(.05,b/127.5-1)];length=math.sqrt(sum(x*x for x in v));out.append(tuple(round(127.5*(x/length+1)) for x in v)+(255,))
  normal.putdata(out);normal.save(R/(name+'_n.png'));e['normal_map']=name+'_n.png'
  entries.append({'file':e['file'],'normal':e['normal_map'],'frame_size':[fw,fh],'rows':counts,'registration_at_64px_cells':registration})
 e['house_style']='room palette/grain, local contour, neutral ambient albedo, contact-dark base; original shape and states'
(R/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');(P/'registration.json').write_text(json.dumps(entries,indent=2)+'\n');print('House-style props:',len(m['assets']),'normal maps:',len(entries))
