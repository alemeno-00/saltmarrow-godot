"""Register generated colour/normal passes to the live frame masks.
No poses or volume fields are drawn here: sources come from image generation.
"""
from pathlib import Path
from PIL import Image
import json, math, hashlib
P=Path(__file__).resolve().parent;ROOT=P.parents[4];N=Image.Resampling.NEAREST
JOBS=[('characters/thomas','body',[4,6,6,3,6,6,6,4]),('characters/thomas','attack_mace',[3,3,3,8]),('characters/thomas','mace_abilities',[8,8,9,10,12]),('enemies/drowned_miner','body',[4,6,3,3,3,3,3,4,4,2,4,6,6,6,6,6]),('enemies/faithful','body',[4,6,4,4,3,4,6,6])]
ROOM=json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())
from registration import fit
thomas_curve=None
for rel,name,counts in JOBS:
 folder=ROOT/'assets'/rel;d=folder/'production/room-fit';before=Image.open(d/(name+'-before.png')).convert('RGBA');colour_path=d/(name+'-colour-master.png')
 if not colour_path.exists():continue
 guide,registration=fit(Image.open(colour_path),before,counts)
 # Transfer the generated study's value distribution to the ORIGINAL pixels.
 # The guide is not a replacement pose: this preserves every existing internal
 # texture cluster, hand, face, maul angle, and transparent leg gap.
 def lum(c):return round(.2126*c[0]+.7152*c[1]+.0722*c[2])
 old_levels=sorted(lum(c) for c in before.get_flattened_data() if c[3]);new_levels=sorted(lum(c) for c in guide.get_flattened_data() if c[3]);cdf={}
 from bisect import bisect_right
 for value in range(256):
  fraction=bisect_right(old_levels,value)/len(old_levels);cdf[value]=new_levels[min(len(new_levels)-1,round(fraction*(len(new_levels)-1)))]
 if rel=='characters/thomas':
  if thomas_curve is None:thomas_curve=cdf.copy()
  else:cdf=thomas_curve
 # Signature red is an explicit user-approved exception to the room palette.
 red_ramp=[(41,16,19),(69,27,29),(94,39,37),(122,52,45)]
 neutral=[tuple(c) for c in ROOM if max(c)>15 and max(c)-min(c)<45]
 def recolour(c):
  if not c[3]:return (0,0,0,0)
  l=cdf[lum(c)]
  if c[0]>c[1]*3 and c[2]>=c[1]*.75 and c[0]>30:
   target=min(red_ramp,key=lambda p:abs(lum(p)-l))
  else:
   # Slate charcoal at low values; paving's grey-beige ramp for skin,
   # ivory smock, wear and salt. All actual colours are room entries.
   tone=(l*.96,l,l*1.02) if l<80 else (l*1.035,l,l*.91)
   target=min(neutral,key=lambda p:sum((p[i]-tone[i])**2 for i in range(3)))
  return (*target,255)
 colour=Image.new('RGBA',before.size);pixels=[recolour(c) for c in before.get_flattened_data()]
 # Grade the existing contact pixels only; add no shadow or geometry.
 for y in range(55,before.height,64):
  for x in range(before.width):
   i=y*before.width+x;c=pixels[i]
   if c[3]:
    darker=[tuple(p) for p in ROOM if 15<lum(p)<=max(22,lum(c)-12) and max(p)-min(p)<45]
    if darker:pixels[i]=(*min(darker,key=lambda p:abs(lum(p)-(lum(c)-15))),255)
 colour.putdata(pixels);colour.save(folder/(name+'.png'));colour.resize((colour.width*2,colour.height*2),N).save(d/(name+'-fitted-2x.png'));accent=red_ramp
 normal_path=d/(name+'-normal-master.png');norm_report=None
 if normal_path.exists():
  normal,norm_report=fit(Image.open(normal_path),before,counts,True);pixels=[]
  for r,g,b,a in normal.get_flattened_data():
   if not a:pixels.append((0,0,0,0));continue
   v=[r/127.5-1,g/127.5-1,max(.05,b/127.5-1)];length=math.sqrt(sum(x*x for x in v));pixels.append(tuple(round(127.5*(x/length+1)) for x in v)+(255,))
  normal.putdata(pixels);normal.save(folder/(name+'_n.png'))
 (d/(name+'-registration.json')).write_text(json.dumps({'runtime':str((folder/(name+'.png')).relative_to(ROOT)),'canvas':list(before.size),'frame_size':[64,64],'row_counts':counts,'root':[32,56],'palette_source':'assets/tiles/sewers/rooms/production/palette.json','preserved_red_accents':accent,'alpha':'exact original binary mask','colour_transfer':'generated value distribution applied to original pixel clusters; all poses and alpha retained','colour_guide_registration':registration,'normal_registration':norm_report},indent=2)+'\n')
 print(rel,name,'colour fitted; normal',bool(norm_report))
