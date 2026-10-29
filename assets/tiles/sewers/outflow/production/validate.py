from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parent.parent
m=json.loads((R/'manifest.json').read_text());checks=[]
for e in m['assets']:
 im=Image.open(R/e['file']).convert('RGBA');fw,fh=e['frame_size'];assert im.size==(fw*max(e['rows']),fh*len(e['rows']))
 a=set(im.getchannel('A').get_flattened_data());assert a<={0,255}
 c=len({p[:3] for p in im.get_flattened_data() if p[3]});assert c<=32,(e['file'],c)
 for f in range(e['rows'][0]):assert im.crop((f*fw,0,(f+1)*fw,fh)).getbbox()
 checks.append({'file':e['file'],'size':list(im.size),'alpha_values':sorted(a),'rgb_colours':c})
room=Image.open(R/'outflow_room.png').convert('RGBA');grid=[]
def water(p):r,g,b,a=p;return a and g>r*1.7 and b>r*1.7 and g>20
for y in range(11):
 row=[]
 for x in range(14):
  cell=room.crop((x*32,y*32,(x+1)*32,(y+1)*32));ratio=sum(bool(water(p)) for p in cell.get_flattened_data())/1024;row.append(round(ratio,3))
  if y==5 and 1<=x<=12:assert ratio>.7,(x,y,ratio)
  else:assert ratio<.025,(x,y,ratio)
 grid.append(row)
# Floor and entrance are opaque, including the full two-square west passage.
for y in range(1,10):
 for x in range(1,13):assert room.crop((x*32,y*32,(x+1)*32,(y+1)*32)).getchannel('A').getextrema()==(255,255),(x,y)
assert room.crop((0,64,32,128)).getchannel('A').getextrema()==(255,255)
closing=Image.open(R/'sluice_shutting.png');assert closing.crop((96,0,128,32)).tobytes()==Image.open(R/'sluice_shut.png').tobytes()
for name,n in [('sluice_open',4),('sluice_shutting',4),('floor_flooding',4)]:
 im=Image.open(R/(name+'.png')).convert('RGBA');frames=[im.crop((i*32,0,(i+1)*32,32)) for i in range(n)];assert len({f.tobytes() for f in frames})==n
 bg=[]
 for f in frames:
  c=Image.new('RGBA',(32,32),(50,50,54,255));c.alpha_composite(f);bg.append(c.resize((192,192),Image.Resampling.NEAREST).convert('RGB'))
 bg[0].save(R/'previews'/f'{name}.gif',save_all=True,append_images=bg[1:],duration=180 if 'open' in name else 220,loop=0)
flood=Image.open(R/'floor_flooding.png').convert('RGBA');coverage=[sum(bool(water(p)) for p in flood.crop((i*32,0,(i+1)*32,32)).get_flattened_data())/1024 for i in range(4)];assert coverage==sorted(coverage) and coverage[0]<.05 and coverage[-1]>.95,coverage
review=room.resize((896,704),Image.Resampling.NEAREST);d=ImageDraw.Draw(review)
for x in range(0,897,64):d.line([(x,0),(x,703)],fill=(255,255,255,110))
for y in range(0,705,64):d.line([(0,y),(895,y)],fill=(255,255,255,110))
review.save(R/'previews/blockout-grid-review.png')
composite=room.copy()
for x in [96,320]:composite.alpha_composite(Image.open(R/'sluice_open.png').crop((0,0,32,32)),(x,0))
composite.resize((896,704),Image.Resampling.NEAREST).save(R/'previews/gates-in-room-2x.png')
# Gallery of actual delivered 32px pieces, no labels in image.
g=Image.new('RGBA',(128,128));y=0
for name in ['sluice_open','sluice_shutting','floor_flooding']:
 g.paste(Image.open(R/(name+'.png')),(0,y));y+=32
for x,name in zip([0,32,64],['sluice_shut','tally_tag_floor','tally_tag_icon']):g.paste(Image.open(R/(name+'.png')),(x,96))
g.resize((768,768),Image.Resampling.NEAREST).save(R/'previews/pieces-6x.png')
(R/'validation.json').write_text(json.dumps({'assets':checks,'room_teal_fraction_per_blockout_cell':grid,'flood_water_coverage':coverage,'entrance_opaque_px':[0,64,32,64],'floor_and_water_cells_opaque':True,'closing_last_frame_equals_shut':True,'unique_frames_each_animation':4,'review_limit':'Pixel/grid export checks only. Claude still needs to test real game lighting and overlay placement; Julian approves appearance.'},indent=2)+'\n');print('PASS: 7 PNGs, exact sizes, binary alpha, ≤32 colours each, grid/channel/entrance, 3 animations, shut match; flood coverage',coverage)
