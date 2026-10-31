"""Mechanical registration, palette export, alpha cleanup and preview layouts.
Painted sources and normal sources come from the built-in image tool; no art is drawn here.
"""
from pathlib import Path
from PIL import Image
from collections import deque
import json,math
P=Path(__file__).resolve().parent;R=P.parent;ROOT=P.parents[3];N=Image.Resampling.NEAREST
ROOM=[tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())]
GREY=[(64,63,64),(101,97,90),(125,119,106),(154,145,130)]
ACCENTS=[(125,151,159),(178,201,210),(209,224,235)]
FROST=[(57,78,80)]+ACCENTS
assert all(c in ROOM for c in GREY+[FROST[0]])
def nearest(c,pal):return min(pal,key=lambda p:sum((p[k]-c[k])**2 for k in range(3)))
def groups(points):
 points=set(points);out=[]
 while points:
  seed=points.pop();group={seed};q=deque([seed])
  while q:
   x,y=q.popleft()
   for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
    pt=x+dx,y+dy
    if pt in points:points.remove(pt);group.add(pt);q.append(pt)
  out.append(group)
 return sorted(out,key=len,reverse=True)
def binary(im):
 im=im.convert('RGBA');return Image.frombytes('RGBA',im.size,bytes(v for c in im.get_flattened_data() for v in ((*c[:3],255) if c[3]>=128 else (0,0,0,0))))
def watcher():
 source=binary(Image.open(P/'watcher-source.png'));mask={(x,y) for y in range(source.height) for x in range(source.width) if source.getpixel((x,y))[3]};keep=groups(mask)[0]
 box=(min(x for x,y in keep),min(y for x,y in keep),max(x for x,y in keep)+1,max(y for x,y in keep)+1)
 for xy in mask-keep:source.putpixel(xy,(0,0,0,0))
 crop=source.crop(box);scale=58/crop.height;small=crop.resize((round(crop.width*scale),58),N)
 foot=crop.getchannel('A').crop((0,round(crop.height*.90),crop.width,crop.height)).getbbox();footmid=(foot[0]+foot[2])/2
 paste=(40-round(footmid*scale),14);frame=Image.new('RGBA',(80,80));frame.paste(small,paste)
 mask={(x,y) for y in range(80) for x in range(80) if frame.getpixel((x,y))[3]};main=groups(mask)[0]
 for xy in mask-main:frame.putpixel(xy,(0,0,0,0))
 # Map the generated eye components to single logical pixels rather than lose them to undersampling.
 blue={(x,y) for x,y in keep if source.getpixel((x,y))[2]>source.getpixel((x,y))[0]+12 and source.getpixel((x,y))[1]>source.getpixel((x,y))[0]+8 and source.getpixel((x,y))[0]>110 and y<box[1]+crop.height*.25}
 eyes=groups(blue)[:2];assert len(eyes)==2
 eye_xy=[]
 for group in eyes:
  cx=sum(x for x,y in group)/len(group);cy=sum(y for x,y in group)/len(group)
  xy=paste[0]+round((cx-box[0])*scale),paste[1]+round((cy-box[1])*scale)
  assert frame.getpixel(xy)[3];eye_xy.append(xy)
 data=[(*nearest(c,GREY),255) if c[3] else (0,0,0,0) for c in frame.get_flattened_data()];frame.putdata(data)
 for xy in eye_xy:frame.putpixel(xy,(*ACCENTS[-1],255))
 for x in range(80):
  if frame.getpixel((x,71))[3]:frame.putpixel((x,71),(*GREY[0],255))
 frame.save(R/'watcher.png');frame.resize((640,640),N).save(P/'watcher-registration-8x.png')
 return {'source_bounds':box,'uniform_scale':scale,'paste':paste,'size':[80,80],'body_height':58,'feet_root':[40,72],'eyes':[list(xy) for xy in eye_xy]}
def frost():
 source=Image.open(P/'frost-source-v1.png').convert('RGBA');tiles=[];records=[]
 for i in range(6):
  cx=i%3;cy=i//3;box=(cx*512,cy*512,(cx+1)*512,(cy+1)*512)
  # The whole source square fits inside a30x30 patch, preserving all features and a transparent wrap boundary.
  small=binary(source.crop(box).resize((30,30),N));mask={(x,y) for y in range(30) for x in range(30) if small.getpixel((x,y))[3]};parts=groups(mask);keep=set().union(*(g for g in parts if len(g)>=2))
  for xy in mask-keep:small.putpixel(xy,(0,0,0,0))
  small.putdata([(*nearest(c,FROST),255) if c[3] else (0,0,0,0) for c in small.get_flattened_data()]);tile=Image.new('RGBA',(32,32));tile.paste(small,(1,1));tiles.append((len(keep),i,tile,box))
 tiles.sort(key=lambda t:t[0]);strip=Image.new('RGBA',(192,32));grid=Image.new('RGBA',(96,64))
 for j,(count,i,tile,box) in enumerate(tiles):
  strip.paste(tile,(j*32,0));grid.paste(tile,((j%3)*32,(j//3)*32));records.append({'frame':j,'source_cell':i,'source_bounds':box,'opaque_pixels':count,'coverage':count/1024})
 strip.save(R/'star_frost.png');grid.resize((768,512),N).save(P/'frost-registration-8x.png');return records

def normal_for(image_name,source_name,watcher_registration=None):
 path=P/source_name
 if not path.exists():return
 diffuse=Image.open(R/image_name).convert('RGBA');src=Image.open(path).convert('RGBA')
 if watcher_registration is not None:
  # Generated normal body is fitted to the exact diffuse body bounds; alpha remains the diffuse's.
  b=binary(src).getbbox();target=diffuse.getbbox();crop=src.crop(b).resize((target[2]-target[0],target[3]-target[1]),N);nm=Image.new('RGBA',diffuse.size);nm.paste(crop,(target[0],target[1]))
 else:
  nm=Image.new('RGBA',(192,32))
  for i in range(6):
   w=src.width//3;h=src.height//2;crop=src.crop(((i%3)*w,(i//3)*h,(i%3+1)*w,(i//3+1)*h)).resize((32,32),N);nm.paste(crop,(i*32,0))
 valid=[(x,y,nm.getpixel((x,y))) for y in range(nm.height) for x in range(nm.width) if nm.getpixel((x,y))[3]>=128 and nm.getpixel((x,y))[2]>110]
 assert valid
 pixels=[]
 for idx,(d,c) in enumerate(zip(diffuse.get_flattened_data(),nm.get_flattened_data())):
  if not d[3]:pixels.append((0,0,0,0));continue
  if c[3]<128 or c[2]<110:
   # Restrict extension within this frost frame, avoiding colour borrowed from a neighbouring tile.
   candidates=valid if watcher_registration else [p for p in valid if p[0]//32==(idx%nm.width)//32]
   if not candidates:candidates=valid
   c=min(candidates,key=lambda p:(p[0]-idx%nm.width)**2+(p[1]-idx//nm.width)**2)[2]
  v=[c[0]/127.5-1,c[1]/127.5-1,max(.15,c[2]/127.5-1)];length=math.sqrt(sum(a*a for a in v));pixels.append(tuple(round(127.5*(a/length+1)) for a in v)+(255,))
 nm.putdata(pixels);nm.save(R/(Path(image_name).stem+'_n.png'))

w=watcher();f=frost();normal_for('watcher.png','watcher-normal-source.png',w);normal_for('star_frost.png','frost-normal-source.png')
(P/'registration.json').write_text(json.dumps({'watcher':w,'frost':f,'room_greys':GREY,'frost_ramp':FROST,'approved_star_accents':ACCENTS,'approval':'Julian: Add small pearly-blue accents','date':'2026-10-31','sources':'built-in image_gen; export uses nearest-neighbour registration and palette conversion'},indent=2)+'\n')
print(json.dumps({'watcher':w,'frost_counts':[r['opaque_pixels'] for r in f]}))
