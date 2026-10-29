"""Assemble review scenes only from exported PNGs; no painted stand-ins."""
from PIL import Image
from pathlib import Path
import json
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text())
lookup={e['id']:e for e in m['new_assets']+m['reference_assets']}
S=32;M=64;canvas=Image.new('RGBA',(704,544),(13,18,21,255));objects=[]
def place(i,x,y):
 e=lookup[i];im=Image.open(R/e['file']).convert('RGBA');ox,oy=e['origin_px'];px=M+x*S+16-ox;py=M+y*S+(16 if e['kind']=='terrain' or e['kind']=='stairs' else 32)-oy
 canvas.alpha_composite(im,(px,py));objects.append({'id':i,'cell':[x,y]})
# Deliberately expose repeated joins, corners and doorway scale at native size.
for y in range(2,12):
 for x in range(2,18):
  place('v1.'+['floor_dry','floor_dry','floor_dry','floor_wet'][(x*7+y*11)%4],x,y)
for y in [6,7]:
 for x in range(2,18):place('v1.bank_'+('01' if y==6 else '04'),x,y)
place('v1.bridge_v',8,7)
for x in range(2,18):
 if x!=9:place('wall_n',x,1)
 place('wall_s',x,12)
for y in range(2,12):
 place('wall_w',1,y);place('wall_e',18,y)
for i,x,y in [('corner_outer_se',1,1),('corner_outer_sw',18,1),('corner_outer_ne',1,12),('corner_outer_nw',18,12)]:place(i,x,y)
place('door_n_open',9,1)
for i,x,y in [('v1.barrel',3,3),('v1.crate',16,3),('v1.rubble',3,10),('v1.pipe_h',5,2),('stairs_down_n',15,10),('pillar',12,4)]:place(i,x,y)
# Approved Thomas still, unchanged, used only for scale review.
hero=Image.open(R.parents[2]/'characters/thomas/production/sprites/standing-candidate.png').convert('RGBA')
canvas.alpha_composite(hero,(M+9*S+16-32,M+3*S+32-56))
(R/'previews').mkdir(exist_ok=True)
canvas.save(R/'previews/assembly.png');canvas.resize((1408,1088),Image.Resampling.NEAREST).save(R/'previews/assembly-2x.png')
(R/'previews/assembly.json').write_text(json.dumps({'purpose':'Art review only; exposes unresolved wall joins. Not a generated level or collision test.','grid_px':32,'margin_px':64,'placements':objects},indent=2)+'\n')
print('Wrote native and 2x assemblies.')
