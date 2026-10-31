"""Format, palette, silhouette, density, alpha and transparent-wrap checks."""
from pathlib import Path
from PIL import Image
import json,math,hashlib,subprocess
P=Path(__file__).resolve().parent;R=P.parent;ROOT=P.parents[3]
reg=json.loads((P/'registration.json').read_text());room={tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())};accents={tuple(c) for c in reg['approved_star_accents']};records=[]
for name,size in [('watcher',(80,80)),('star_frost',(192,32))]:
 path=R/(name+'.png');npath=R/(name+'_n.png');im=Image.open(path).convert('RGBA');nm=Image.open(npath).convert('RGBA');assert im.size==nm.size==size;assert set(im.getchannel('A').get_flattened_data())=={0,255};assert im.getchannel('A').tobytes()==nm.getchannel('A').tobytes();colours={c[:3] for c in im.get_flattened_data() if c[3]};assert colours<=room|accents
 lengths=[]
 for r,g,b,a in nm.get_flattened_data():
  if a:
   v=[r/127.5-1,g/127.5-1,b/127.5-1];length=math.sqrt(sum(c*c for c in v));assert abs(length-1)<.012 and v[2]>0;lengths.append(length)
 assert all(c==(0,0,0,0) for c in im.get_flattened_data() if not c[3]);assert all(c==(0,0,0,0) for c in nm.get_flattened_data() if not c[3])
 records.append({'file':path.name,'normal':npath.name,'size':size,'colours':sorted(colours),'normal_length_range':[min(lengths),max(lengths)],'alpha_matches':True,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'normal_sha256':hashlib.sha256(npath.read_bytes()).hexdigest()})
w=Image.open(R/'watcher.png').convert('RGBA');bounds=w.getbbox();assert bounds[1]==14 and bounds[3]==72 and bounds[3]-bounds[1]==58
pinpoints=[(x,y) for y in range(80) for x in range(80) if w.getpixel((x,y))==(*reg['approved_star_accents'][-1],255)];assert len(pinpoints)==2;assert sorted(map(list,pinpoints))==sorted(reg['watcher']['eyes'])
assert all(w.getpixel((x,71))[:3]==tuple(reg['room_greys'][0]) for x in range(80) if w.getpixel((x,71))[3])
f=Image.open(R/'star_frost.png').convert('RGBA');fn=Image.open(R/'star_frost_n.png').convert('RGBA');counts=[];signatures=[]
for i in range(6):
 tile=f.crop((i*32,0,(i+1)*32,32));n=fn.crop((i*32,0,(i+1)*32,32));count=sum(c[3]>0 for c in tile.get_flattened_data());counts.append(count);signatures.append(tile.tobytes())
 for t in (tile,n):
  assert all(t.getpixel((x,y))==(0,0,0,0) for y in range(32) for x in range(32) if x in (0,31) or y in (0,31))
 assert count==reg['frost'][i]['opaque_pixels']
assert counts==sorted(counts) and len(set(counts))==6 and len(set(signatures))==6
protected=['assets/characters/thomas/rig/production/model-s.png','assets/characters/thomas/rig/production/model-s_n.png','assets/characters/thomas/rig/s.png','assets/characters/thomas/rig/s_n.png','assets/characters/thomas/production/sprites/standing-candidate.png','assets/characters/thomas/production/sprites/steady-portrait-candidate.png','assets/characters/thomas/production/concepts/canonical-reference-v1.png']
for p in protected:assert (ROOT/p).read_bytes()==subprocess.check_output(['git','show','origin/main:'+p],cwd=ROOT)
v={'job':'14b','date':'2026-10-31','assets':records,'watcher_bounds':bounds,'watcher_height':58,'feet_root':[40,72],'pearl_eye_pixels':pinpoints,'frost_frames':6,'frame_size':[32,32],'rows':1,'frost_opaque_pixels':counts,'frost_coverage_percent':[round(c/1024*100,2) for c in counts],'tileability':'exactly transparent1px wrap boundary in diffuse and normal; repeatable isolated patches','pearl_palette_approval':'Julian: Add small pearly-blue accents','new_pearl_colours':reg['approved_star_accents'],'body_palette':'shared room greys only','protected_files_unchanged':protected,'checks':'format, registration, declared palette, exact alpha, positive-z unit normals, unique increasing-density patches, transparent wrap boundary, protected file equality','limits':'Visual camera/readability reviewed in native room composites. Real game activation, lighting, blend and effect pacing require Claude wiring and in-game review.'}
(P/'validation.json').write_text(json.dumps(v,indent=2)+'\n');print(json.dumps({'watcher':w.size,'height':58,'eye_pixels':pinpoints,'frost':f.size,'counts':counts,'normal_alpha':'exact','wrap':'transparent and matching on every edge','protected':'unchanged'}))
