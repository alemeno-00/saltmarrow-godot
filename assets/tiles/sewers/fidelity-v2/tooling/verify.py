from pathlib import Path
from PIL import Image
import json,hashlib,math,itertools
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text());checks=[]
images={e['id']:Image.open(R/e['file']).convert('RGBA') for e in m['assets']}
for e in m['assets']:
 a=images[e['id']]
 assert list(a.size)==e['size']
 assert set(a.getchannel('A').get_flattened_data())<={0,255}
 assert all(p[:3]==(0,0,0) for p in a.get_flattened_data() if p[3]==0)
 assert hashlib.sha256((R/e['file']).read_bytes()).hexdigest()==e['sha256']
checks.append(f'{len(m["assets"])} exports: dimensions, binary alpha, transparent RGB and hashes pass')
for family in [[images[f'floor_{i:02d}'] for i in range(12)],[images[f'water_big_{i}'] for i in range(4)]]:
 for a,b in itertools.product(family,repeat=2):
  w,h=a.size
  assert a.crop((w-1,0,w,h)).tobytes()==b.crop((0,0,1,h)).tobytes()
  assert a.crop((0,h-1,w,h)).tobytes()==b.crop((0,0,w,1)).tobytes()
checks.append('320 ordered surface-edge comparisons pass (12 floor variants and four 64px water substrates)')
for a,b in itertools.product([images[f'deep_wall_{i}'] for i in range(3)],repeat=2):
 assert a.crop((127,0,128,128)).tobytes()==b.crop((0,0,1,128)).tobytes()
checks.append('9 ordered tall-wall joins match exactly')
assemblies=[images[e['id']] for e in m['assets'] if e['file'].startswith('assemblies/')]
for a,b in itertools.product(assemblies,repeat=2):
 assert a.crop((a.width-1,0,a.width,a.height)).tobytes()==b.crop((0,0,1,b.height)).tobytes()
checks.append('64 ordered multi-cell paving side joins share the same mortar boundary; no claim of arbitrary internal stone continuity')
for e in m['assets']:
 if e['file'].startswith('overlays/'):
  a=images[e['id']];coverage=sum(p[3]>0 for p in a.get_flattened_data())/(a.width*a.height)
  assert 0.02<coverage<.55
  assert abs(coverage-e['alpha_coverage'])<.0001
checks.append('8 irregular overlays have real transparent surrounds and measured sparse alpha coverage')
for name in ['thomas','miner','faithful']:
 a=images[name];feet=a.getchannel('A').crop((0,53,64,56)).getbbox()
 assert abs((feet[0]+feet[2])/2-32)<=0.5
 assert a.getchannel('A').getbbox()[3]==56
checks.append('static character feet centres x32 ±0.5px, ground boundary y56; full silhouettes fit 64px frames')
assert images['deep_arch'].getpixel((80,110))[3]==0
checks.append('arch aperture is transparent')
# Shelf-packed source regions remain native pixels; allocated storage is grid-aligned.
for kind,filename in [('terrain','terrain-atlas.png'),('sprites','sprite-atlas.png')]:
 selected=[e for e in m['assets'] if (e['file'].startswith('terrain/'))==(kind=='terrain')]
 x=y=rowh=0;placements=[]
 for e in selected:
  a=images[e['id']];sw=math.ceil(a.width/32)*32;sh=math.ceil(a.height/32)*32
  if x+sw>512:x=0;y+=rowh;rowh=0
  placements.append((e,x,y));x+=sw;rowh=max(rowh,sh)
 out=Image.new('RGBA',(512,y+rowh))
 for e,x,y in placements:
  a=images[e['id']];out.alpha_composite(a,(x,y));e['atlas']=filename;e['region']=[x,y,a.width,a.height]
 out.save(R/filename)
 for e,x,y in placements:
  a=images[e['id']];assert out.crop((x,y,x+a.width,y+a.height)).tobytes()==a.tobytes()
checks.append('both native-size atlases have grid-aligned storage and byte-identical export regions')
m['water_binding']='64px substrates are sampled in four fixed 32px quadrants per 2x2 block; choose variation per block, not per quadrant'
m['collision']='Use the authored ground mask; masonry overhang is not its ground footprint. The review arch has a 48px-wide visual aperture aligned with one clear ground cell (26,7). Bridge has one clear ground column (19) with rail overhang outside it.'
for e in m['assets']:
 e['selected_for_corridor']=e['file'].startswith(('assemblies/','overlays/')) or e['id'].startswith(('floor_','water_big_','deep_')) or e['id'] in ['thomas','miner','faithful','bridge','drain','torch','pier','bank_n']
 e['status']='unapproved visual candidate' if e['selected_for_corridor'] else 'unselected initial proportion study'
(R/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
(R/'validation.json').write_text(json.dumps(dict(technical_checks=checks,visual_acceptance='NOT APPROVED; no pixel-identical or concept-fidelity certification',engine='Godot 4.7.2 Compatibility'),indent=2)+'\n')
print('\n'.join(checks))
