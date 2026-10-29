from PIL import Image
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text());m['assets']=[e for e in m['assets'] if e['file'].split('/')[0] not in ['assemblies','overlays']]
def hard(a):
 return Image.frombytes('RGBA',a.size,bytes(v for p in a.convert('RGBA').get_flattened_data() for v in (p[:3]+(255,) if p[3]>=160 else (0,0,0,0))))
def save(name,a,group,**kw):
 a=hard(a);p=R/group/(name+'.png');a.save(p)
 m['assets'].append(dict(id=name,file=f'{group}/{name}.png',size=list(a.size),origin=[0,0],collision='none: cosmetic surface only',sha256=hashlib.sha256(p.read_bytes()).hexdigest(),**kw))
s=Image.open(R/'source/floor-modules.png').convert('RGBA');modules=[]
for i,(x,y) in enumerate([(70,44),(805,44),(70,361),(805,361),(70,681),(805,681)]):
 a=hard(s.crop((x,y,x+662,y+278)).resize((128,64),Image.Resampling.NEAREST))
 bg=Image.new('RGBA',a.size,(20,23,22,255));bg.alpha_composite(a);a=bg
 # Shared dark mortar perimeter supports abutment without imposing equal slab shapes.
 px=a.load()
 for xx in range(128):px[xx,0]=px[xx,63]=(20,23,22,255)
 for yy in range(64):px[0,yy]=px[127,yy]=(20,23,22,255)
 modules.append(a);save(f'paving_{i}',a,'assemblies',footprint=[4,2],join='dark mortar perimeter; finite assembly, not a Wang autotile')
for name,src,box in [('paving_small',0,(32,0,96,64)),('paving_medium',5,(0,0,96,64))]:
 a=modules[src].crop(box);px=a.load()
 for yy in range(a.height):px[0,yy]=px[a.width-1,yy]=(20,23,22,255)
 save(name,a,'assemblies',footprint=[a.width//32,2],join='cropped assembly with common mortar edge')
s=Image.open(R/'source/overlays.png').convert('RGBA');w,h=s.size
spec=[('cracks',(128,64),(108,50),.45),('damp',(96,64),(78,50),.48),('salt',(64,64),(42,52),.28),('moss',(96,64),(72,48),.40),('chips',(64,64),(48,48),.65),('silt',(64,64),(34,52),.45),('repair',(96,64),(64,48),.65),('seep',(128,32),(112,24),.50)]
for i,(name,size,fit,opacity) in enumerate(spec):
 x=i%4;y=i//4;a=hard(s.crop((round(x*w/4),round(y*h/2),round((x+1)*w/4),round((y+1)*h/2))))
 a=a.crop(a.getbbox());a.thumbnail(fit,Image.Resampling.NEAREST)
 canvas=Image.new('RGBA',size);canvas.alpha_composite(a,((size[0]-a.width)//2,(size[1]-a.height)//2));canvas=hard(canvas)
 coverage=sum(p[3]>0 for p in canvas.get_flattened_data())/(size[0]*size[1]);assert 0.02<coverage<.55,(name,coverage)
 save(name,canvas,'overlays',default_opacity=opacity,alpha_coverage=round(coverage,4),repeat='sparse purposeful placement; not a full-surface texture')
m['layer_order']=['floor assemblies','sparse wear overlays','raised banks and walls','bridge and props','actors and effects']
(R/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');print('Added eight multi-cell paving assemblies and eight transparent overlays')
