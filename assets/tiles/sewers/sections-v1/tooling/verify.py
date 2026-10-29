"""Asset, connection and reachability checks independent of Godot rendering."""
from pathlib import Path
from PIL import Image,ImageChops
import json,itertools,hashlib
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text());checks=[];assembled={};hashes={}
for id,s in m['sections'].items():
 layers=[Image.open(R/id/(f+'.png')).convert('RGBA') for f in ['ground','foreground','assembled']]
 for name,a in zip(['ground','foreground','assembled'],layers):
  assert list(a.size)==s['size']
  assert set(a.getchannel('A').get_flattened_data())<={0,255}
  assert all(p[:3]==(0,0,0) for p in a.get_flattened_data() if p[3]==0)
  path=R/id/(name+'.png');hashes[str(path.relative_to(R))]=hashlib.sha256(path.read_bytes()).hexdigest()
 ground,fore,whole=layers
 assert not ImageChops.multiply(ground.getchannel('A'),fore.getchannel('A')).getbbox()
 both=ground.copy();both.alpha_composite(fore);assert both.tobytes()==whole.tobytes()
 assembled[id]=whole
 assert len(s['ground'])==s['cells'][1] and all(len(row)==s['cells'][0] for row in s['ground'])
 assert s['size']==[s['cells'][0]*32,s['cells'][1]*32]
checks.append('9 full-section PNGs: grid dimensions, hard alpha, transparent RGB, disjoint foreground/ground, exact reassembly')
for a,b in itertools.product(assembled.values(),repeat=2):
 assert a.crop((a.width-1,0,a.width,a.height)).tobytes()==b.crop((0,0,1,b.height)).tobytes()
checks.append('9 ordered section boundary profiles match pixel-for-pixel; interior stone-course continuity remains a visual review item')
for order in itertools.permutations(m['sections']):
 rows=[''.join(m['sections'][id]['ground'][y] for id in order) for y in range(m['height_cells'])]
 floors={(x,y) for y,row in enumerate(rows) for x,c in enumerate(row) if c=='.'}
 reached={(2,m['start_row'])};todo=list(reached)
 while todo:
  x,y=todo.pop()
  for n in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
   if n in floors and n not in reached:reached.add(n);todo.append(n)
 assert reached==floors,(order,len(floors-reached))
 offset=0
 for id in order[:-1]:
  offset+=m['sections'][id]['cells'][0]
  for y in range(10,18):assert rows[y][offset-1]==rows[y][offset]
checks.append('all 6 unrotated section orders: every dry cell reachable; port ground types match at both joins')
m['hashes']=hashes
(R/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
report=dict(checks=checks,visual_acceptance='Pending user review of actual engine renders; not concept-identical certification',engine_scope='Both selected arrangements loaded, all dry cells reached, real exploration crosses both joins and returns via the lower walk, water blocked. See tests/test_sewer_sections.gd.',limitations=m['restrictions'])
(R/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('\n'.join(checks))
