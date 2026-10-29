from pathlib import Path
from PIL import Image
import json,hashlib
P=Path(__file__).resolve().parent;R=P.parent;B=R.parents[2]
m=json.loads((R/'manifest.json').read_text());assert len(m['assets'])==18,len(m['assets']);checks=[];frames={}
for e in m['assets']:
 im=Image.open(R/e['file']).convert('RGBA');w,h=e['frame_size'];assert list(im.size)==[w*max(e['rows']),h*len(e['rows'])]
 assert hashlib.sha256((R/e['file']).read_bytes()).hexdigest()==e['sha256'];assert set(im.getchannel('A').get_flattened_data())<={0,255}
 assert all(a or (r,g,b)==(0,0,0) for r,g,b,a in im.get_flattened_data());colours=len({c[:3] for c in im.get_flattened_data() if c[3]});assert colours<=32
 fs=[im.crop((i*w,j*h,i*w+w,j*h+h)) for j,n in enumerate(e['rows']) for i in range(n)];assert all(f.getbbox() for f in fs)
 assert len({f.tobytes() for f in fs})==len(fs),(e['file'],'duplicate frame')
 for f in fs:
  x0,y0,x1,y1=f.getchannel('A').getbbox();assert x0>=1 and y0>=1 and x1<=w-1 and y1<=h-1,(e['file'],'clipped silhouette')
 frames[e['file']]=fs;checks.append({'file':e['file'],'size':list(im.size),'frame_size':[w,h],'row_counts':e['rows'],'opaque_colours':colours,'distinct_frames':len(fs),'binary_alpha':True,'cleared_transparent_rgb':True})
assert sum(len(v) for v in frames.values())==30
for prefix in ['bones','debris']:
 assert len({frames[f'{prefix}_{i}.png'][0].tobytes() for i in [1,2,3]})==3
clearance={}
for name in ['grate_ns','grate_ew']:
 fs=frames[name+'.png'];coverage=[];runs=[]
 for f in fs:
  if name=='grate_ns':box=(8,8,56,24);line=[f.getpixel((x,16))[3] for x in range(64)]
  else:box=(8,8,24,56);line=[f.getpixel((16,y))[3] for y in range(64)]
  a=f.crop(box).getchannel('A');coverage.append(sum(v>0 for v in a.get_flattened_data())/(a.width*a.height));longest=current=0
  for v in line:
   current=current+1 if v==0 else 0;longest=max(longest,current)
  runs.append(longest)
 assert min(coverage[:2])>max(coverage[2:])+.15,(name,coverage)
 assert min(runs[2:])>=40,(name,runs)
 clearance[name]={'interior_opaque_fraction':coverage,'centreline_clear_run_px':runs,'rows':'two shut, then two open, confirmed by Julian'}
# Review animations. Games should hold final states as described in README.
for name in ['crate','barrel','satchel_body','valve','grate_ns','grate_ew']:
 fs=frames[name+'.png'];seq=[]
 for f in fs:
  c=Image.new('RGBA',f.size,(70,72,74,255));c.alpha_composite(f);seq.append(c.resize((f.width*4,f.height*4),Image.Resampling.NEAREST).convert('RGB'))
 seq[0].save(R/'previews'/(name+'.gif'),save_all=True,append_images=seq[1:],duration=300 if name!='valve' else 150,loop=0)
# Full gallery, fixed frames/row, true nearest 4x, no labels.
g=Image.new('RGBA',(1024,128*len(m['assets'])),(42,45,47,255))
for row,e in enumerate(m['assets']):
 for col,f in enumerate(frames[e['file']]):
  factor=min(4,128/f.height);f=f.resize((round(f.width*factor),round(f.height*factor)),Image.Resampling.NEAREST);g.alpha_composite(f,(col*256,row*128))
g.save(R/'previews/contact-4x.png')
# A transparent-sprite placement review over actual shipped room art, not an engine screenshot.
room=Image.open(B/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA');placements=[('crate.png',0,2,4),('barrel.png',0,9,4),('satchel_body.png',0,2,6),('miner_tag_body.png',0,7,9),('letter.png',0,8,6),('hymn_sheet.png',0,4,9),('valve.png',0,6,3),('bones_1.png',0,2,10),('bones_2.png',0,9,10),('bones_3.png',0,4,4),('debris_1.png',0,6,7),('debris_2.png',0,9,2),('debris_3.png',0,2,2)]
for file,index,x,y in placements:
 f=frames[file][index];room.alpha_composite(f,(x*32,y*32))
room.resize((768,768),Image.Resampling.NEAREST).save(R/'previews/room-placement-2x.png')
report={'runtime_pngs':18,'frames_total':30,'assets':checks,'grate_clearance':clearance,'three_distinct_bone_variants':True,'three_distinct_debris_variants':True,'native_visual_review':'Icons, paired caches, valve and both grate rows reviewed at nearest enlargement. Placement preview uses actual exported sprites.','limit':'Art checks only. Collision, interaction states, actual game lighting and animation timing require Claude integration.'}
(R/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS: 18 PNGs, 30 distinct frames, sizes/alpha/palettes/margins, three clutter variants, open grate clearance.')
