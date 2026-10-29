"""Extract disjoint alpha silhouettes; no rectangular slicing through neighbours."""
from pathlib import Path
from PIL import Image
from collections import deque
import json,hashlib
P=Path(__file__).parent
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
ROOT=P.parent
entries=[];renders=[]
def ordered(name,count,rows):
 im=Image.open(P/(name+'-master.png')).convert('RGBA');cs=components(im);assert len(cs)==count,(name,len(cs),count)
 cs.sort(key=lambda c:(min(rows-1,int(((c[1][1]+c[1][3])/2)/im.height*rows)),c[1][0]));return cs

def add(name,folder,cell,origin,footprint,source=None,**extra):
 entries.append({'id':name,'file':folder+'/'+name+'.png','dimensions':list(cell.size),'origin_px':origin,'footprint_cells':footprint,'kind':folder,'rows':1,'frames':1,'source_bounds':source,**extra});renders.append(cell)

wall_ids=['wall_n','wall_e','wall_s','wall_w']+['corner_outer_'+d for d in ['ne','se','sw','nw']]+['corner_inner_'+d for d in ['ne','se','sw','nw']]
for name,(im,b,area) in zip(wall_ids,ordered('walls',12,3)):
 add(name,'walls',im.resize((32,64),Image.Resampling.NEAREST),[16,64],[1,1],b)
js=ordered('junctions',10,3)
for name,(im,b,area) in zip(['endcap_n','endcap_e','endcap_s','endcap_w'],js[:4]):
 add(name,'walls',im.resize((32,64),Image.Resampling.NEAREST),[16,64],[1,1],b)
im,b,area=js[9];add('pillar','walls',im.resize((32,64),Image.Resampling.NEAREST),[16,64],[1,1],b)
for name,(im,b,area) in zip(['cap_t_n','cap_t_e','cap_t_s','cap_t_w','cap_cross'],js[4:9]):
 scale=min(32/im.width,32/im.height);im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST);cell=Image.new('RGBA',(32,32));cell.paste(im,((32-im.width)//2,(32-im.height)//2));add(name,'caps',cell,[16,32],[1,1],b,layer='optional_plan_cap',placement_note='Plan-view junction cap; not a substitute for an upright wall face.')

ds=ordered('doors',8,2)
# Shared masonry-pier registration, NOT independent bounding-box centring.
# Closed/open source pier baselines are410/817. The open leaf may hang below the pier.
roots_x=[254.5,647,1122,1572];scale=60/343
for i,(im,b,area) in enumerate(ds):
 d=['n','e','s','w'][i%4];state='closed' if i<4 else 'open';root_y=410 if i<4 else 817
 f=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST);x=round(32+(b[0]-roots_x[i%4])*scale);y=round(72+(b[1]-root_y)*scale)
 assert x>=0 and y>=0 and x+f.width<=64 and y+f.height<=80,(i,(x,y),f.size)
 cell=Image.new('RGBA',(64,80));cell.paste(f,(x,y));add('door_'+d+'_'+state,'doors',cell,[32,72],[1,1],b,state=state,pair='door_'+d,registration={'source_root':[roots_x[i%4],root_y],'source_scale':scale},visual_overhang='Frame may extend into neighbouring solid-wall cells; open leaf is decorative, not collision.')
for d,(im,b,area) in zip(['n','e','s','w'],ordered('stairs',4,2)):
 add('stairs_down_'+d,'stairs',im.resize((32,32),Image.Resampling.NEAREST),[16,16],[1,1],b,descends_toward=d)

# One shared palette across all new art; clear hidden RGB outside alpha.
strip=Image.new('RGBA',(64*len(renders),80))
for i,im in enumerate(renders):strip.paste(im,(64*i,0))
a=strip.getchannel('A');strip=strip.convert('RGB').quantize(colors=63,dither=Image.Dither.NONE).convert('RGBA');strip.putalpha(a);clean=Image.new('RGBA',strip.size);clean.paste(strip,mask=a);strip=clean
final={}
for i,e in enumerate(entries):
 w,h=e['dimensions'];im=strip.crop((i*64,0,i*64+w,h));dest=ROOT/e['file'];dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest);e['sha256']=hashlib.sha256(dest.read_bytes()).hexdigest();final[e['id']]=im

def atlas(folder,size,cols,file):
 group=[e for e in entries if e['kind']==folder];w,h=size;rows=(len(group)+cols-1)//cols;sheet=Image.new('RGBA',(cols*w,rows*h))
 for i,e in enumerate(group):
  x=(i%cols)*w;y=(i//cols)*h;sheet.paste(final[e['id']],(x,y));e['atlas']=file;e['atlas_region_px']=[x,y,*e['dimensions']]
 sheet.save(ROOT/file);sheet.resize((sheet.width*3,sheet.height*3),Image.Resampling.NEAREST).save(P/(folder+'-3x.png'))
atlas('walls',(32,64),8,'walls_atlas.png');atlas('caps',(32,32),5,'caps_atlas.png');atlas('doors',(64,80),4,'doors_atlas.png');atlas('stairs',(32,32),4,'stairs_atlas.png')
base=ROOT.parent/'v1_0';old=json.loads((base/'manifest.json').read_text());refs=[]
for item in old['assets']:
 e=dict(item);e['id']='v1.'+item['id'];e['file']='../v1_0/'+item['file'];e['read_only_reference']=True
 if e.get('atlas'):e['atlas']='../v1_0/'+e['atlas']
 assert hashlib.sha256((base/item['file']).read_bytes()).hexdigest()==item['sha256'],item['id']
 refs.append(e)
manifest={'version':'sewer-generation-1','base_grid_px':[32,32],'pixel_origin':'Top left; +x right,+y down; anchors are pixel boundaries.','base_pack':'../v1_0/manifest.json','new_assets':entries,'reference_assets':refs,'wall_boundary_directions':{'n':'north room boundary; floor to south','e':'east boundary; floor to west','s':'south foreground boundary; floor to north','w':'west boundary; floor to east'},'corners':'Suffix is the pair of map-axis branches meeting at the corner; outer is convex, inner recessed. Choose from room geometry, not texture rotation.','cap_suffix':'cap_t_n is missing its north branch; analogous E/S/W. Caps are optional plan-view overlays, not upright wall substitutes.','collision_handoff':'Code owner assigns collision/navigation and door state. Never infer collision from alpha or animate atlas storage rows.','art_only':True}
manifest['status']='draft study; not integration-ready'
manifest['known_gaps']=['Repeated side-wall caps and corner geometry do not join seamlessly.','North/south directional walls currently both show faces; camera convention needs revision.','North doorway minimum lower aperture is 17px, narrower than 18px approved Thomas silhouette.','T/cross caps are plan-view overlays, not complete upright wall junctions.']
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

def normalize(m):
 c=m&15
 for bit,a,b in [(16,1,2),(32,2,4),(64,4,8),(128,8,1)]:
  if m&bit and not c&(a|b):c|=bit
 return c
masks=sorted({normalize(m) for m in range(256)});assert len(masks)==47
assert all((base/'tiles'/('bank_'+format(m,'02x')+'.png')).is_file() for m in masks)
for im in final.values():assert set(im.getchannel('A').get_flattened_data()).issubset({0,255})
# Front-facing open apertures are measured in the lower walking band, not above the arch.
clearances={}
for d in ['n','s']:
 im=final['door_'+d+'_open'];a=im.getchannel('A');widths=[]
 for y in range(55,70):
  if a.getpixel((32,y)):widths.append(0);continue
  x0=x1=32
  while x0>0 and not a.getpixel((x0-1,y)):x0-=1
  while x1<63 and not a.getpixel((x1+1,y)):x1+=1
  widths.append(x1-x0+1)
 clearances[d]={'walking_band_y':[55,69],'minimum_clear_width_px':min(widths),'row_widths':widths}
report={'new_png_assets':len(entries),'reference_assets_unchanged':len(refs),'all_reference_hashes_match':True,'all_256_bank_inputs_covered':True,'normalized_bank_masks':len(masks),'binary_alpha':True,'front_door_clearance':clearances,'new_asset_frames':'Each file is a single static image; no animation frames in atlas storage rows.','engine_import_collision_and_occlusion':'Claude integration required; not tested by this exporter.'}
(ROOT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
