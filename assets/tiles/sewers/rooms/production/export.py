"""Register generated room paintings; crop-only shared masonry/door edge profiles.
No procedural room textures or painted stand-ins are generated here.
"""
from pathlib import Path
from PIL import Image
import json,hashlib
P=Path(__file__).resolve().parent;R=P.parent
layouts=json.loads((P/'layouts.json').read_text());regs=json.loads((P/'registration.json').read_text());N=Image.Resampling.NEAREST

def segment(src,out,sx,dx,sy,dy):
 assert len(sx)==len(dx) and len(sy)==len(dy)
 for j in range(len(sy)-1):
  for i in range(len(sx)-1):
   w,h=dx[i+1]-dx[i],dy[j+1]-dy[j]
   if w<=0 or h<=0:continue
   out.paste(src.crop((sx[i],sy[j],sx[i+1],sy[j+1])).resize((w,h),N),(dx[i],dy[j]))

raw={};details={}
cap_src=Image.open(P/'junction_c-master.png').convert('RGBA')
caps=[cap_src.crop((4,y,100,y+96)).resize((32,32),N) for y in [214,318,422]]
for name,reg in regs.items():
 path=P/reg.get('source_file',name+'-master.png')
 if not path.exists():continue
 d=layouts[name];W,H=d['size'];s=Image.open(path).convert('RGBA');out=Image.new('RGBA',(W,H))
 segment(s,out,reg['x_source'],reg['x_target'],reg['y_source'],reg['y_target'])
 if reg.get('connector'):
  if reg.get('replace_wall_tops'):
   for y,row in enumerate(d['grid']):
    for x,c in enumerate(row):
     if c=='#':out.paste(caps[(x+y)%3],(x*32,y*32))
  raw[name]=out;details[name]={'registration':reg,'source_dimensions':list(s.size)};continue
 # Complete original painted north band registered around its dry doorway.
 a,b=reg['north_door_x'];segment(s,out,[0,a,b,s.width],[0,160,224,W],[0,reg['north_bottom']],[0,64])
 # Plain common wall-top crops remove wrongly generated vertical side/south faces.
 for y,row in enumerate(d['grid']):
  for x,c in enumerate(row):
   if c=='#':out.paste(caps[(x+y)%len(caps)],(x*32,y*32))
 # Register each original dry passage separately to the blockout, with a tiny edge inset.
 ix0,iy0,ix1,iy1=reg['core_source'];lo,hi=reg['side_door_y'];sa,sb=reg['south_door_x']
 for side,box,dest in [
  ('n',(a+3,3,b-3,reg['north_bottom']),(160,0,64,64)),
  ('s',(sa+3,reg['south_top'],sb-3,s.height-3),(160,H-32,64,32)),
  ('w',(3,lo,ix0,hi),(0,160,32,64)),
  ('e',(ix1,lo,s.width-3,hi),(W-32,160,32,64))]:
  x,y,w,h=dest;out.paste(s.crop(box).resize((w,h),N),(x,y))
 raw[name]=out;details[name]={'registration':reg,'source_dimensions':list(s.size)}

def ports(d):
 g=d['grid'];w,h=len(g[0]),len(g);p={}
 if 'D' in g[0]:
  x=g[0].index('D');depth=0
  while depth<h and g[depth][x]=='D':depth+=1
  p['n']=[x*32,0,64,depth*32]
 if 'D' in g[-1]:p['s']=[g[-1].index('D')*32,(h-1)*32,64,32]
 for side,x in [('w',0),('e',w-1)]:
  ys=[y for y,r in enumerate(g) if r[x]=='D']
  if ys:p[side]=[x*32,min(ys)*32,32,len(ys)*32]
 return p
# Three crops of the authored chamber floor supply dry doorway pads, removing guide-colour residue.
if 'chamber_b' in raw:
 donor=raw['chamber_b'];pads=[donor.crop((x,160,x+64,224)) for x in [32,96,160]]
 for j,(name,im) in enumerate(raw.items()):
  for i,(side,(x,y,w,h)) in enumerate(ports(layouts[name]).items()):
   im.paste(pads[(j+i)%3].crop((0,0,w,h)),(x,y))

# All images share one palette to keep related materials and joins consistent.
if raw:
 total=sum(im.width for im in raw.values());strip=Image.new('RGB',(total,max(im.height for im in raw.values())))
 x=0
 for im in raw.values():strip.paste(im.convert('RGB'),(x,0));x+=im.width
 pal=strip.quantize(colors=28,dither=Image.Dither.NONE).getpalette()[:84]
 for rgb in [(90,59,30),(134,83,31),(174,115,48),(199,148,76)]:pal.extend(rgb)
 palette=Image.new('P',(1,1));palette.putpalette(pal+pal[:3]*((768-len(pal))//3))
 basepalette=Image.new('P',(1,1));basepalette.putpalette(pal[:84]+pal[:3]*228)
 neutral=[pal[i:i+3] for i in range(0,84,3) if pal[i]>=pal[i+1]*.9 and pal[i]>=pal[i+2]*.9];np=[v for rgb in neutral for v in rgb];floorpalette=Image.new('P',(1,1));floorpalette.putpalette(np+np[:3]*((768-len(np))//3))
 def finish(im,d=None):
  a=im.getchannel('A').point(lambda v:255 if v>=128 else 0);rgb=im.convert('RGB');q=rgb.quantize(palette=basepalette,dither=Image.Dither.NONE).convert('RGBA')
  if d:
   # Semantic palette restriction removes coloured blockout residue on dry stone only.
   for yy,row in enumerate(d['grid']):
    for xx,c in enumerate(row):
     if c in '.,D':
      box=(xx*32,yy*32,xx*32+32,yy*32+32);q.paste(rgb.crop(box).quantize(palette=floorpalette,dither=Image.Dither.NONE).convert('RGBA'),box[:2])
   enriched=rgb.quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');mask=Image.new('L',im.size);mp=mask.load()
   for l in d['lights']:
    cx,cy=l['cell']
    for y in range(cy*32,(cy+1)*32):
     for x in range(cx*32,(cx+1)*32):
      r,g,b=rgb.getpixel((x,y))
      if r>150 and r>g*1.18 and g>b*1.3:mp[x,y]=255
   q.paste(enriched,mask=mask)
  q.putalpha(a);clean=Image.new('RGBA',im.size);clean.paste(q,mask=a);return clean
 finals={k:finish(v,layouts[k]) for k,v in raw.items()}
 # Shared 4px port edge strips come from actual generated plain dry floor.
 # Only the outer edge is welded; complete room interiors remain original paintings.
 donor=finals.get('chamber_b',next(iter(finals.values())))
 horizontal=donor.crop((160,176,224,180));vertical=donor.crop((178,160,182,224))
 wall=finish(caps[0]);wh=wall.crop((0,12,32,16));wv=wall.crop((12,0,16,32));corner=Image.new('RGBA',(4,4));q=wall.crop((12,12,14,14));corner.paste(q,(0,0));corner.paste(q.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(2,0));corner.paste(q.transpose(Image.Transpose.FLIP_TOP_BOTTOM),(0,2));corner.paste(q.transpose(Image.Transpose.ROTATE_180),(2,2))
 wh.paste(corner,(0,0));wh.paste(corner,(28,0));wv.paste(corner,(0,0));wv.paste(corner,(0,28))
 for name,im in finals.items():
  W,H=im.size
  for side,(x,y,w,h) in ports(layouts[name]).items():
   if side in 'ns':
    yy=0 if side=='n' else H-4;hh=horizontal if side=='n' else horizontal.transpose(Image.Transpose.FLIP_TOP_BOTTOM);ww=wh if side=='n' else wh.transpose(Image.Transpose.FLIP_TOP_BOTTOM);im.paste(hh,(x,yy));im.paste(ww,(x-32,yy));im.paste(ww,(x+64,yy))
   else:
    xx=0 if side=='w' else W-4;vv=vertical if side=='w' else vertical.transpose(Image.Transpose.FLIP_LEFT_RIGHT);ww=wv if side=='w' else wv.transpose(Image.Transpose.FLIP_LEFT_RIGHT);im.paste(vv,(xx,y));im.paste(ww,(xx,y-32));im.paste(ww,(xx,y+64))
  folder=R/name;folder.mkdir(exist_ok=True);im.save(folder/'1.png');im.resize((W*2,H*2),N).save(R/'previews'/(name+'-2x.png'))
  d=layouts[name];lights=[]
  for l in d['lights']:
   cx,cy=l['cell'];pts=[]
   for yy in range(cy*32,(cy+1)*32):
    for xx in range(cx*32,(cx+1)*32):
     r,g,b,a=im.getpixel((xx,yy))
     if a and r>135 and r>g*1.18 and g>b*1.3:pts.append((xx,yy,r))
   assert pts,(name,l)
   lum=sum(v[2] for v in pts);centre=[round(sum(v[i]*v[2] for v in pts)/lum) for i in [0,1]]
   lights.append({'glass_centre_px':centre,'blockout_cell':l['cell'],'kind':l['kind']})
  details[name].update({'file':name+'/1.png','dimensions':[W,H],'frame_size':[W,H],'rows':[1],'origin_px':[0,0],'mirrorable':d['mirrorable'],'blockout':d['blockout'],'ports_px':ports(d),'lights':lights,'sha256':hashlib.sha256((folder/'1.png').read_bytes()).hexdigest()})
 seal_folder=R/'sealed';seal_folder.mkdir(exist_ok=True)
 seals={'north':finals['junction_b'].crop((32,0,96,64)),'south':finish(cap_src.crop((104,1140,312,1244)).resize((64,32),N)),'west':finish(cap_src.crop((4,214,100,422)).resize((32,64),N)),'east':finish(cap_src.crop((1153,214,1250,422)).resize((32,64),N))}
 for name,im in seals.items():
  im.save(seal_folder/(name+'.png'));details['sealed/'+name]={'file':'sealed/'+name+'.png','dimensions':list(im.size),'frame_size':list(im.size),'rows':[1],'origin_px':[0,0],'sha256':hashlib.sha256((seal_folder/(name+'.png')).read_bytes()).hexdigest()}
 (P/'palette.json').write_text(json.dumps([pal[i:i+3] for i in range(0,96,3)],indent=2)+'\n')
 (R/'manifest.json').write_text(json.dumps({'grid_px':32,'assets':details,'port_edge_width_px':4,'wall_top_provenance':'Three direct crops of generated junction_c masonry; not fabricated geometry.','status':'Art review; game lighting and visual acceptance belong to Claude/Julian.'},indent=2)+'\n')
 print('Exported',len(finals),'registered paintings.')
