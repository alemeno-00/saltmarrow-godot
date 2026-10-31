"""Cut approved model pixels by ownership; no repainting, scaling or palette changes.
The explicit masks below distinguish coat panels from limbs, in the supplied bind coordinates.
"""
from pathlib import Path
from PIL import Image
from collections import Counter
import hashlib,json
P=Path(__file__).resolve().parent;R=P.parents[1];ROOT=P.parents[5]
B=json.loads((ROOT/'design/art-briefs/animation/rig/bind_s.json').read_text())['parts']
model=Image.open(P.parent/'model-s.png').convert('RGBA');normal=Image.open(P.parent/'model-s_n.png').convert('RGBA')
ids=Image.open(P.parent/'model-15r/material-ids.png')
assert hashlib.sha256((P.parent/'model-s.png').read_bytes()).hexdigest()=='93617715b316bc3a816a5c89f3ccfa24c88bc0a4a58e2342461656d183a64564'
assert model.getchannel('A').tobytes()==normal.getchannel('A').tobytes()
names=[k for k in sorted(B,key=lambda k:B[k]['cell'])];owners={}
def owner(x,y):
 if y<30:return 'head'
 # Every scarf, strap, satchel and lantern pixel stays on the torso.
 if ids.getpixel((x,y)) in (4,6,7):return 'torso'
 if 32<=y<=50 and x<=33:return 'upper_arm_r' if y<40 else 'forearm_r'
 if 32<=y<=50 and x>=46:return 'upper_arm_l' if y<40 else 'forearm_l'
 if y<50:return 'torso'
 # Coat panels stay on the skirt; the narrow trouser columns are separate legs.
 if y>=63:return 'shin_r' if x<40 else 'shin_l'
 if y>=52 and 35<=x<=37:return 'thigh_r' if y<59 else 'shin_r'
 if y>=52 and 41<=x<=43:return 'thigh_l' if y<59 else 'shin_l'
 return 'skirt'
for y in range(80):
 for x in range(80):
  if model.getpixel((x,y))[3]:owners[x,y]=owner(x,y)
sheet=Image.new('RGBA',(264,24));nsheet=Image.new('RGBA',(264,24));ownership=Image.new('L',(80,80))
def paste_pixel(part,xy,source=None):
 x,y=xy;sx,sy=(source or xy);d=B[part];bx,by,w,h=d['model_square'];q=x-bx+d['cell_x'],y-by
 assert 0<=x-bx<24 and 0<=y-by<24,(part,xy,q)
 assert model.getpixel((sx,sy))[3]
 sheet.putpixel(q,model.getpixel((sx,sy)));nsheet.putpixel(q,normal.getpixel((sx,sy)))
for xy,part in owners.items():paste_pixel(part,xy);ownership.putpixel(xy,B[part]['cell']+1)
# Joint overlap only beneath later-drawn opaque parts in the bind pose.
# Existing joint pixels are copied; hip extensions borrow the same leg two rows below.
order=json.loads((P/'bind-placements.json').read_text());rank={p['part']:i for i,p in enumerate(order)}
overlaps=[]
def overlap(part,coords):
 for xy in coords:
  occluder=owners.get(xy)
  if occluder and occluder!=part and rank[occluder]>rank[part]:
   source=(xy[0],xy[1]+2) if part.startswith('thigh_') and xy[1] in (50,51) else xy
   paste_pixel(part,xy,source);overlaps.append({'part':part,'model':list(xy),'covered_by':occluder,'source':list(source)})
for side,xs in [('r',range(35,38)),('l',range(41,44))]:
 # Two hidden rows at the hips; two rows through the knee join beneath the shin.
 overlap('thigh_'+side,[(x,y) for y in (50,51,59,60) for x in xs])
for side,xs in [('r',range(30,34)),('l',range(46,50))]:
 overlap('upper_arm_'+side,[(x,y) for y in (40,41) for x in xs])
 overlap('torso',[(x,y) for y in (32,33) for x in xs])
# One row of torso beneath the neck/head, where it is covered in the bind pose.
overlap('torso',[(x,29) for x in range(37,44)])
sheet.save(R/'s.png');nsheet.save(R/'s_n.png');ownership.save(P/'ownership.png')
(P/'ownership.json').write_text(json.dumps({'part_ids':{n:B[n]['cell']+1 for n in names},'counts':dict(Counter(owners.values())),'model_pixel_count':len(owners),'overlaps':overlaps,'added_overlap_pixels':len(overlaps),'repainted_pixels':0,'all_overlap_colours':'existing approved diffuse/normal copies;12 hidden hip pixels extend the same leg two rows upward,42 duplicate the same coordinate'},indent=2)+'\n')
preview=P/'previews';preview.mkdir(exist_ok=True);(preview/'.gdignore').touch()
# Repack solely for inspection; runtime remains a single row of 11 cells.
board=Image.new('RGBA',(96,72),(94,97,96,255));nboard=board.copy()
for i in range(11):
 box=(i*24,0,(i+1)*24,24);at=((i%4)*24,(i//4)*24)
 board.alpha_composite(sheet.crop(box),at);nboard.alpha_composite(nsheet.crop(box),at)
board.resize((768,576),Image.Resampling.NEAREST).save(preview/'parts-8x.png');nboard.resize((768,576),Image.Resampling.NEAREST).save(preview/'parts-normal-8x.png')
assert sheet.getchannel('A').tobytes()==nsheet.getchannel('A').tobytes()
print(json.dumps({'model_pixels':len(owners),'counts':dict(Counter(owners.values())),'hidden_duplicate_pixels':len(overlaps),'normal_alpha_match':True}))
