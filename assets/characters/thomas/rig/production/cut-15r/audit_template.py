"""Read-only fit audit of the approved whole model against current torso cell.
No part art is painted, cut, or substituted by this diagnostic.
Run with Godot placements JSON captured from Rig.placements(idle(0), south, (40,72)).
"""
from pathlib import Path
from PIL import Image
import json, math, hashlib
P=Path(__file__).resolve().parent
model=Image.open(P.parent/'model-s.png').convert('RGBA')
placements=json.loads((P/'current-idle-placements.json').read_text())
torso=next(p for p in placements if p['part']=='torso')
assert torso['angle']==0
at,pivot=torso['at'],torso['pivot']
def local(x,y):return [math.floor(x+.5-at[0]+pivot[0]),math.floor(y+.5-at[1]+pivot[1])]
scarf=[]
reds={(41,16,19),(69,27,29),(94,39,37),(122,52,45)}
for y in range(80):
 for x in range(80):
  c=model.getpixel((x,y));q=local(x,y)
  if c[3] and c[:3] in reds and not(0<=q[0]<24 and 0<=q[1]<24):scarf.append({'model':[x,y],'cell':q})
assert scarf
report={'status':'STEP 1 APPROVED; STEP 2 TEMPLATE FIT INCOMPATIBILITY',
 'model_sha256':hashlib.sha256((P.parent/'model-s.png').read_bytes()).hexdigest(),
 'rig_revision':'9765aee', 'pose':'RigPose.idle(0), south, root (40,72)',
 'torso':torso,'cell_size':[24,24],
 'sampling':'q=floor((pixel + 0.5) - at + pivot); torso rotation is zero',
 'last_representable_model_row':47,
 'scarf_pixels_outside_torso':scarf,
 'handoff':'Calibrate the rig/template to this approved whole model before cutting. Do not crop kit/scarf, move it to another part, or change approved proportions to make the current anchors fit.',
 'runtime_parts_changed':False,'job_complete':False}
(P/'template-fit.json').write_text(json.dumps(report,indent=2)+'\n')
print('Fit audit: '+str(len(scarf))+' approved scarf pixels outside current torso cell. No runtime parts changed.')
