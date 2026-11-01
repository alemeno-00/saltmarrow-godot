"""Register the eight independent normal edits; retain the approved head/boot regions.
Normal vectors are normalized and exact diffuse alpha is enforced, then upstream shrink snaps the palette.
"""
from pathlib import Path
from PIL import Image
import json,math
P=Path(__file__).resolve().parent;N=Image.Resampling.NEAREST;row=Image.new('RGBA',(2560,320));records=[]
for n in range(1,9):
 src=Image.open(P/f'normal-{n:02d}-source.png').convert('RGBA');mask=src.getchannel('A').point(lambda a:255 if a>=128 else 0);box=mask.getbbox();assert box
 guide=Image.open(P/f'normal-guide-{n:02d}-4x.png').convert('RGBA');target=guide.getbbox();fit=Image.new('RGBA',(320,320));fit.paste(src.crop(box).resize((target[2]-target[0],target[3]-target[1]),N),(target[0],target[1]))
 fit.paste(guide.crop((0,0,320,128)),(0,0));fit.paste(guide.crop((0,268,320,320)),(0,268))
 diffuse=Image.open(P/f'painted-{n:02d}-palette-4x.png').convert('RGBA');valid=[(x,y,fit.getpixel((x,y))) for y in range(320) for x in range(320) if fit.getpixel((x,y))[3]>=128 and fit.getpixel((x,y))[2]>110];assert valid
 out=Image.new('RGBA',(320,320));data=[];extended=0
 for idx,(d,c) in enumerate(zip(diffuse.get_flattened_data(),fit.get_flattened_data())):
  if not d[3]:data.append((0,0,0,0));continue
  x,y=idx%320,idx//320
  if y<128 or y>=268:
   g=guide.getpixel((x,y));assert g[3];data.append(g);continue
  if c[3]<128 or c[2]<=110:c=min(valid,key=lambda p:(p[0]-x)**2+(p[1]-y)**2)[2];extended+=1
  v=[c[0]/127.5-1,c[1]/127.5-1,max(.15,c[2]/127.5-1)];length=math.sqrt(sum(a*a for a in v));data.append(tuple(round(127.5*(a/length+1)) for a in v)+(255,))
 out.putdata(data);assert out.getchannel('A').tobytes()==diffuse.getchannel('A').tobytes();out.save(P/f'normal-{n:02d}-4x.png');row.paste(out,((n-1)*320,0));records.append({'frame':n,'source_bounds':box,'guide_bounds':target,'alpha':'exact final diffuse','preserved_guide_regions_4x':[[0,0,320,128],[0,268,320,320]],'normal_extension_pixels_4x':extended,'extension':'nearest existing normal colour within the same frame only; positive-z normalization'})
row.save(P.parent/'walk_s_n_4x.png');(P/'normal-registration.json').write_text(json.dumps(records,indent=2)+'\n');print('Registered eight normal maps; 4x alpha matches every diffuse frame.')
