"""Register generated room paintings, extract foregrounds, and author navigation.
No generated character art. Pillow required. All coordinates are reviewed source landmarks.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import hashlib,json,itertools,collections
R=Path(__file__).resolve().parent.parent
H=896
spec={
'corridor':dict(width=1024,source_size=(1536,1024),crop=(20,0,1516,1024),anchors=[(0,0),(124,128),(350,320),(427,384),(492,416),(642,512),(677,528),(744,576),(796,608),(913,736),(1024,768)]),
'junction':dict(width=768,source_size=(1280,1280),crop=(0,0,1280,1280),anchors=[(0,0),(64,24),(255,128),(475,320),(553,384),(641,416),(823,512),(862,528),(955,576),(1020,608),(1204,744),(1280,768)]),
'cistern':dict(width=1024,source_size=(1280,1280),crop=(0,0,1280,1280),anchors=[(0,0),(85,32),(320,128),(512,320),(553,384),(624,416),(725,512),(763,528),(800,576),(900,640),(980,736),(1010,768),(1190,880),(1280,896)])}
def hard(a):
 a=a.convert('RGBA');return Image.frombytes('RGBA',a.size,bytes(v for p in a.get_flattened_data() for v in (p[:3]+(255,) if p[3]>=160 else (0,0,0,0))))
def yy(y,s):
 for (a,b),(c,d) in zip(s['anchors'],s['anchors'][1:]):
  if a<=y<=c:return round(b+(y-a)*(d-b)/(c-a))
 return 0 if y<0 else s['anchors'][-1][1]
def xy(point,s):
 return (round((point[0]-s['crop'][0])*s['width']/(s['crop'][2]-s['crop'][0])),yy(point[1],s))
def register(a,s):
 a=hard(a.resize(s['source_size'],Image.Resampling.NEAREST));out=Image.new('RGBA',(s['width'],H))
 for (a0,b0),(a1,b1) in zip(s['anchors'],s['anchors'][1:]):
  stripe=a.crop((s['crop'][0],a0,s['crop'][2],a1)).resize((s['width'],b1-b0),Image.Resampling.NEAREST);out.alpha_composite(stripe,(0,b0))
 return out
art={k:register(Image.open(R/'source'/(k+'.png')),s) for k,s in spec.items()}
port=art['corridor'].crop((0,0,64,H))
# Common native connector, including shared pixel boundary. No feathering or resampling at runtime.
for y in range(H):port.putpixel((0,y),port.getpixel((32,y)));port.putpixel((63,y),port.getpixel((32,y)))
port.save(R/'connector.png')
for id,a in art.items():a.paste(port,(0,0));a.paste(port,(a.width-64,0))
# Transparent prop reused from the previous environment family, never painted character art.
bridge=hard(Image.open(R.parent/'fidelity-v2/props/bridge.png')).resize((64,224),Image.Resampling.NEAREST)
for col in [5,26]:art['cistern'].alpha_composite(bridge,(round((col-.5)*32),352))
sections={}
for id,a in art.items():
 s=spec[id];W=a.width;cols=W//32;path=R/id;path.mkdir(exist_ok=True)
 floor=Image.new('L',(W,H));fd=ImageDraw.Draw(floor)
 water=Image.new('L',(W,H));wd=ImageDraw.Draw(water)
 if id in ['corridor','junction']:
  fd.rectangle((0,320,W-1,383),fill=255);fd.rectangle((0,512,W-1,575),fill=255)
  wd.rectangle((0,384,W-1,511),fill=255)
  if id=='corridor':
   fd.rectangle((15*32,352,16*32-1,575),fill=255)
   for col in [5,9,12]:fd.rectangle((col*32,320,(col+1)*32-1,351),fill=0)
  else:
   # The arch is a closed service passage, with a short reachable dry recess.
   fd.polygon([xy(p,s) for p in [(550,470),(550,380),(700,380),(700,470)]],fill=255)
   # Barrel footprint on the upper walk: cell centre is visibly inside the barrel.
   fd.rectangle((15*32,320,16*32-1,351),fill=0)
   fd.rectangle((21*32,320,22*32-1,351),fill=0)
 else:
  upperleft=[(0,512),(190,512),(250,470),(330,402),(425,350),(525,350),(525,405),(445,440),(385,490),(375,553),(0,553)]
  upperright=[(1280-x,y) for x,y in upperleft]
  lower=[(0,763),(210,763),(280,850),(400,925),(525,945),(750,945),(870,925),(1000,848),(1080,763),(1280,763),(1280,800),(1090,800),(1000,905),(870,975),(750,995),(525,995),(400,976),(278,910),(190,800),(0,800)]
  for poly in [upperleft,upperright,lower]:fd.polygon([xy(p,s) for p in poly],fill=255)
  wd.polygon([xy(p,s) for p in [(0,553),(375,553),(385,490),(445,440),(525,405),(525,350),(750,350),(750,405),(835,440),(895,490),(905,553),(1280,553),(1280,725),(1090,725),(1000,848),(870,915),(750,945),(525,945),(400,915),(280,850),(190,725),(0,725)]],fill=255)
  for col in [5,26]:fd.rectangle((col*32,352,(col+1)*32-1,575),fill=255)
  # Registered throat zones, identical to other modules and wide enough for bridges.
  for x0,x1 in [(0,191),(832,1023)]:
   fd.rectangle((x0,320,x1,383),fill=255);fd.rectangle((x0,512,x1,575),fill=255)
   wd.rectangle((x0,384,x1,511),fill=255)
 rows=[]
 for cy in range(H//32):
  row=''
  for cx in range(cols):
   px=cx*32+16;py=cy*32+16
   # Authored source polygon, centre sample. Debug preview exposes this approximation.
   row+='.' if floor.getpixel((px,py)) else '~' if water.getpixel((px,py)) else '#'
  rows.append(row)
 # Connector pixels and collision agree at both module edges.
 for y in range(10,18):
  fill='.' if y in [10,11,16,17] else '~'
  for x in [0,1,cols-2,cols-1]:rows[y]=rows[y][:x]+fill+rows[y][x+1:]
 fgmask=Image.new('L',(W,H));d=ImageDraw.Draw(fgmask)
 if id=='cistern':
  poly=[(0,800),(190,800),(220,835),(320,920),(440,976),(570,1005),(740,1005),(860,972),(980,907),(1070,800),(1280,800),(1280,1280),(0,1280)]
  d.polygon([xy(p,s) for p in poly],fill=255)
 else:d.rectangle((0,576,W-1,H-1),fill=255)
 # Shared connector foreground begins at exactly the same height at every port.
 for box in [(0,576,63,H-1),(W-64,576,W-1,H-1)]:d.rectangle(box,fill=255)
 for box in [(0,0,63,575),(W-64,0,W-1,575)]:d.rectangle(box,fill=0)
 foreground=Image.new('RGBA',a.size);foreground.paste(a,(0,0),fgmask)
 ground=a.copy();ground.paste((0,0,0,0),(0,0,W,H),fgmask)
 ground=hard(ground);foreground=hard(foreground)
 ground.save(path/'ground.png');foreground.save(path/'foreground.png');a.save(path/'assembled.png')
 collision=Image.new('RGBA',(cols,H//32));cd=collision.load()
 for y,row in enumerate(rows):
  for x,c in enumerate(row):cd[x,y]={'#':(180,45,45,160),'.':(45,220,100,160),'~':(35,110,240,160)}[c]
 preview=a.copy();preview.alpha_composite(collision.resize(a.size,Image.Resampling.NEAREST));preview.save(R/'previews'/(id+'-mask.png'))
 sections[id]=dict(size=list(a.size),cells=[cols,H//32],origin=[0,0],ground=rows,layers=['ground.png','foreground.png'],ports={'west':dict(x=0,rows=[10,11,12,13,14,15,16,17]),'east':dict(x=cols-1,rows=[10,11,12,13,14,15,16,17])},closed_branch=id=='junction',bridges=[15] if id=='corridor' else [5,26] if id=='cistern' else [],source_registration=s)
m=dict(status='unapproved large-section prototype',grid=32,height_cells=H//32,start_row=11,sections=sections,arrangements=[['corridor','junction','cistern'],['cistern','corridor','junction']],provenance='New built-in-generated room paintings referencing approved v0.2. Nearest-neighbour registration to authored y landmarks, hard-alpha cleanup and shared 64px throat strips. No original concept cutouts. Cistern bridges reuse generated fidelity-v2 prop.',collision_legend={'#':'wall or void, blocked','.':'dry floor or supported bridge, walkable','~':'deep water, blocked'},restrictions=['no rotation or mirroring','north service gate closed','static water and baked environment light','only 2 selected orders, not 30 archetypes','ground includes fixed rear walls and fixed props; foreground is separately extracted'],character_art='No new character art; review reuses existing temporary figure until other workflow supplies sprites')
(R/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
print('Exported three section paintings and registered foregrounds')
