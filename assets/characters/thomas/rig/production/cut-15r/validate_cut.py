"""Verify the cut's provenance, format, ownership and sampled alpha connectivity."""
from pathlib import Path
from PIL import Image
from collections import deque
import subprocess,json,hashlib
P=Path(__file__).resolve().parent;ROOT=P.parents[5];R=P.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
model=P.parent/'model-s.png';normal=P.parent/'model-s_n.png';assert sha(model)=='93617715b316bc3a816a5c89f3ccfa24c88bc0a4a58e2342461656d183a64564'
im=Image.open(R/'s.png').convert('RGBA');nm=Image.open(R/'s_n.png').convert('RGBA');assert im.size==nm.size==(264,24);assert im.getchannel('A').tobytes()==nm.getchannel('A').tobytes();assert set(im.getchannel('A').get_flattened_data())=={0,255}
bind=Image.open(P/'previews/bind.png').convert('RGBA');bind_n=Image.open(P/'previews/bind_n.png').convert('RGBA');assert bind.tobytes()==Image.open(model).convert('RGBA').tobytes();assert bind_n.tobytes()==Image.open(normal).convert('RGBA').tobytes()
B=json.loads((ROOT/'design/art-briefs/animation/rig/bind_s.json').read_text())['parts'];own=Image.open(P/'ownership.png');o=json.loads((P/'ownership.json').read_text());diffuse=Image.open(model).convert('RGBA');norm=Image.open(normal).convert('RGBA');ids=Image.open(P.parent/'model-15r/material-ids.png');kit=0
for y in range(80):
 for x in range(80):
  label=own.getpixel((x,y));assert bool(label)==bool(diffuse.getpixel((x,y))[3])
  if not label:continue
  d=next(d for d in B.values() if d['cell']+1==label);bx,by,_,_=d['model_square'];at=x-bx+d['cell_x'],y-by
  assert im.getpixel(at)==diffuse.getpixel((x,y));assert nm.getpixel(at)==norm.getpixel((x,y))
  if ids.getpixel((x,y)) in (4,6,7):assert label==2;kit+=1
rank={d['part']:i for i,d in enumerate(json.loads((P/'bind-placements.json').read_text()))}
for entry in o['overlaps']:
 assert rank[entry['covered_by']]>rank[entry['part']]
 assert own.getpixel(tuple(entry['model']))!=B[entry['part']]['cell']+1
 d=B[entry['part']];x,y=entry['model'];bx,by,_,_=d['model_square'];at=x-bx+d['cell_x'],y-by;src=tuple(entry['source'])
 assert im.getpixel(at)==diffuse.getpixel(src);assert nm.getpixel(at)==norm.getpixel(src)
connectivity={}
for mode,count in [('idle',16),('walk',16),('sneak',16),('limp',16),('start-walk-stop',60)]:
 strip=Image.open(P/'previews'/f'{mode}-{count}.png').convert('RGBA');groups_per_frame=[]
 for i in range(count):
  frame=strip.crop((i*80,0,(i+1)*80,80));mask={(x,y) for y in range(80) for x in range(80) if frame.getpixel((x,y))[3]};sizes=[]
  assert all(0<x<79 and 0<y<79 for x,y in mask),'frame boundary clipping'
  while mask:
   seed=mask.pop();q=deque([seed]);size=1
   while q:
    x,y=q.popleft()
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
     pt=x+dx,y+dy
     if pt in mask:mask.remove(pt);q.append(pt);size+=1
   sizes.append(size)
  groups_per_frame.append(sorted(sizes,reverse=True))
 connectivity[mode]=groups_per_frame
protected=['assets/characters/thomas/rig/production/model-s.png','assets/characters/thomas/rig/production/model-s_n.png','assets/characters/thomas/production/sprites/standing-candidate.png','assets/characters/thomas/production/sprites/steady-portrait-candidate.png','assets/characters/thomas/production/concepts/canonical-reference-v1.png']
for path in protected:assert (ROOT/path).read_bytes()==subprocess.check_output(['git','show','origin/main:'+path],cwd=ROOT)
v={'job':'15-R step2','rig_source_revision':'9536fb8461d3d6770ec74a839e35c9dd5501713a','runtime_size':[264,24],'cell_size':[24,24],'rows':1,'cells':11,'facing':'south','visible_model_pixels':o['model_pixel_count'],'hidden_overlap_pixels':len(o['overlaps']),'kit_pixels_on_torso':kit,'repainted_visible_pixels':0,'diffuse_bind_differences':0,'normal_bind_differences':0,'alpha_matches':True,'protected_files_unchanged':protected,'model_sha256':sha(model),'model_normal_sha256':sha(normal),'parts_sha256':sha(R/'s.png'),'parts_normal_sha256':sha(R/'s_n.png'),'connectivity_8_neighbour_component_sizes':connectivity,'in_game_approval':'PENDING CLAUDE WIRING AND JULIAN REVIEW'}
(P/'validation.json').write_text(json.dumps(v,indent=2)+'\n')
print(json.dumps({'kit':kit,'visible_pixels':o['model_pixel_count'],'hidden_overlap_pixels':len(o['overlaps']),'base_pose_single_component':all(len(g)==1 for m in ('idle','walk','sneak','limp') for g in connectivity[m]),'spring_max_components':max(map(len,connectivity['start-walk-stop'])),'spring_detached_components':[(i,g) for i,g in enumerate(connectivity['start-walk-stop']) if len(g)>1]}))
