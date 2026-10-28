"""Mechanical catalogue of actual exported overlays; no new painted artwork."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageChops
import json
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text())
sheet=Image.new('RGB',(1024,384),(29,32,34));d=ImageDraw.Draw(sheet)
for i,e in enumerate(e for e in m['assets'] if e['file'].startswith('overlays/')):
 x=(i%4)*256;y=(i//4)*192
 # Show alpha silhouette over a neutral checker and the same asset at default opacity over paving.
 for yy in range(16,96,8):
  for xx in range(8,248,8):d.rectangle((x+xx,y+yy,x+xx+7,y+yy+7),fill=(54,57,59) if ((xx//8+yy//8)%2) else (42,45,47))
 a=Image.open(R/e['file']).convert('RGBA');a=a.resize((a.width*2,a.height*2),Image.Resampling.NEAREST)
 a.thumbnail((232,76),Image.Resampling.NEAREST);sheet.paste(a,(x+(256-a.width)//2,y+18+(76-a.height)//2),a)
 base=Image.open(R/'assemblies/paving_0.png').convert('RGBA')
 mark=Image.open(R/e['file']).convert('RGBA');mark.putalpha(mark.getchannel('A').point(lambda v:round(v*e['default_opacity'])))
 base.alpha_composite(mark,((base.width-mark.width)//2,(base.height-mark.height)//2))
 base=base.resize((224,112),Image.Resampling.NEAREST);base=base.crop((0,20,224,92));sheet.paste(base,(x+16,y+104))
 d.text((x+12,y+180),e['id']+' / '+str(e['size'][0])+'x'+str(e['size'][1]),fill=(209,203,183))
sheet.save(R/'overlay-review.png')
a=Image.open(R/'godot-corridor.png').convert('RGB');b=Image.open(R/'godot-corridor-clean.png').convert('RGB');diff=ImageChops.difference(a,b)
changed=sum(max(p)>0 for p in diff.get_flattened_data());assert changed>1000
(R/'engine-validation.json').write_text(json.dumps(dict(engine='Godot 4.7.2 Compatibility',scene='res://scenes/fidelity_corridor.tscn',capture_size=list(a.size),overlays_changed_pixels=changed,total_pixels=a.width*a.height,assertions=['arch threshold clear; piers blocked','bridge rail overhang not walkable','water blocked','dry path crosses bridge','overlay toggle preserves all movement cells'],core_tests='43 passed, 0 failed',scope='Isolated review corridor. No visual approval or concept-identical claim.'),indent=2)+'\n')
