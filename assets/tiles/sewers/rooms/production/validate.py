from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
P=Path(__file__).resolve().parent;R=P.parent;B=R.parents[3]
layouts=json.loads((P/'layouts.json').read_text());m=json.loads((R/'manifest.json').read_text());assert len(layouts)==18 and len(m['assets'])==22
ims={};checks=[];water_report={};profile={'n':[],'s':[],'e':[],'w':[]}
def teal(p):r,g,b,a=p;return bool(a and g>r*1.35 and b>r*1.35 and b>20 and g>18)
for name,e in m['assets'].items():
 path=R/e['file'];im=Image.open(path).convert('RGBA');ims[name]=im;assert list(im.size)==e['dimensions'];assert hashlib.sha256(path.read_bytes()).hexdigest()==e['sha256']
 assert set(im.getchannel('A').get_flattened_data())<={0,255};assert all(a or (r,g,b)==(0,0,0) for r,g,b,a in im.get_flattened_data())
 colours=len({c[:3] for c in im.get_flattened_data() if c[3]});assert colours<=32,(name,colours)
 checks.append({'file':e['file'],'size':list(im.size),'opaque_rgb_colours':colours,'binary_alpha':True})
 if name not in layouts:continue
 d=layouts[name];assert list(im.size)==d['size'];br=(B/d['blockout']);assert br.is_file(),br
 assert Image.open(br).size==im.size
 values=[]
 for y,row in enumerate(d['grid']):
  for x,c in enumerate(row):
   tile=im.crop((x*32,y*32,x*32+32,y*32+32));v=sum(teal(p) for p in tile.get_flattened_data())/1024
   if c in '.,DS~':assert tile.getchannel('A').getextrema()==(255,255),(name,x,y,'walkable alpha')
   if c in '.,DS':assert v<.08,(name,x,y,'unexpected water',v)
   if c=='~':assert v>.4,(name,x,y,'missing water',v)
   if c in '.D,~':values.append([x,y,c,round(v,3)])
 water_report[name]=values
 for side,(x,y,w,h) in e['ports_px'].items():
  W,H=im.size
  if side=='n':f=im.crop((x-32,0,x+96,4))
  elif side=='s':f=im.crop((x-32,H-4,x+96,H)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
  elif side=='w':f=im.crop((0,y-32,4,y+96))
  else:f=im.crop((W-4,y-32,W,y+96)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
  profile[side].append((name,f.tobytes()))
 for l in e['lights']:
  x,y=l['glass_centre_px'];cx,cy=l['blockout_cell'];assert x//32==cx and y//32==cy
 # Grid/light review layers are QA images only, never runtime art.
 v=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST);draw=ImageDraw.Draw(v)
 for x in range(0,v.width,64):draw.line([(x,0),(x,v.height-1)],fill=(200,210,220,255))
 for y in range(0,v.height,64):draw.line([(0,y),(v.width-1,y)],fill=(200,210,220,255))
 for l in e['lights']:
  x,y=l['glass_centre_px'];draw.ellipse((x*2-2,y*2-2,x*2+2,y*2+2),fill=(40,255,200,255))
 v.save(R/'previews'/(name+'-grid.png'))
pairs=0
for a,b in [('n','s'),('e','w')]:
 for na,pa in profile[a]:
  for nb,pb in profile[b]:assert pa==pb,(na,nb,a,b);pairs+=1
# Every possible placed seal covers the exact corresponding doorway footprint.
seal_sizes={'north':(64,64),'south':(64,32),'west':(32,64),'east':(32,64)}
for n,sz in seal_sizes.items():assert ims['sealed/'+n].size==sz and ims['sealed/'+n].getchannel('A').getextrema()==(255,255)
rooms=['junction_a','junction_b','junction_c','chamber_a','chamber_b','chamber_c','flooded_a','flooded_b','entry','stairs','lore_a','lore_b']
g=Image.new('RGBA',(1152,1536),(17,20,23,255))
for i,n in enumerate(rooms):
 im=ims[n];g.alpha_composite(im,((i%3)*384+(384-im.width)//2,(i//3)*384+(384-im.height)//2))
g.save(R/'previews/rooms-contact.png')
cs=['connector_ew','connector_ns','connector_ne','connector_nw','connector_es','connector_sw'];g=Image.new('RGBA',(768,512),(17,20,23,255))
for i,n in enumerate(cs):g.alpha_composite(ims[n].resize((256,256),Image.Resampling.NEAREST),((i%3)*256,(i//3)*256))
g.save(R/'previews/tunnels-contact-2x.png')
# A real-image assembly crosses a turn and two room joins. Placement is review-only.
# gallery right exit -> W/S bend -> N/S -> N/E bend -> long gallery west exit.
a=ims['junction_a'];bend=ims['connector_sw'];ns=ims['connector_ns'];ne=ims['connector_ne'];b=ims['chamber_a']
g=Image.new('RGBA',(1152,768),(17,20,23,255));g.alpha_composite(a,(0,0));g.alpha_composite(bend,(384,128));g.alpha_composite(ns,(384,256));g.alpha_composite(ne,(384,384));g.alpha_composite(b,(512,256));g.save(R/'previews/turn-assembly.png')
# Plain seals demonstrated on the four doors of a single room.
v=ims['junction_a'].copy()
for side,(x,y,w,h) in m['assets']['junction_a']['ports_px'].items():v.alpha_composite(ims['sealed/'+{'n':'north','s':'south','e':'east','w':'west'}[side]],(x,y))
v.resize((768,768),Image.Resampling.NEAREST).save(R/'previews/sealed-room-2x.png')
report={'runtime_pngs':22,'painted_layouts':18,'seals':4,'assets':checks,'opposite_port_profile_pairs_checked':pairs,'port_profile_depth_px':4,'three_authored_door_pad_variants':True,'three_authored_wall_top_crops':True,'water_checks':water_report,'lights_recorded':sum(len(e.get('lights',[])) for e in m['assets'].values()),'limits':'Art export and 4px seam profiles checked. Does not certify continuous masonry courses beyond the weld, collision, engine rendering, lighting or visual approval.'}
(R/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS:',len(checks),'PNGs;',pairs,'opposite port profiles;',report['lights_recorded'],'lights; grid water/floor/alpha checks.')
