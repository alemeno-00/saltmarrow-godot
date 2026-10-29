from PIL import Image
from pathlib import Path
import json
P=Path(__file__).parent

def crop_rows(fn,ys,xrows):
 im=Image.open(P/fn).convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
 result=[]
 for (y0,y1),xs in zip(zip(ys,ys[1:]),xrows):
  row=[]
  for x0,x1 in zip(xs,xs[1:]):
   f=im.crop((x0,y0,x1,y1));b=f.getbbox();assert b;f=f.crop(b);row.append(f)
  result.append(row)
 return result

def sheet(rows,name):
 scale=min(55/max(f.height for row in rows for f in row),62/max(f.width for row in rows for f in row))
 out=Image.new('RGBA',(max(map(len,rows))*64,len(rows)*64))
 for r,row in enumerate(rows):
  for c,f in enumerate(row):
   f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST)
   out.paste(f,(c*64+32-f.width//2,r*64+56-f.height))
 alpha=out.getchannel('A');out=out.convert('RGB').quantize(colors=31,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(alpha)
 clean=Image.new('RGBA',out.size);clean.paste(out,mask=alpha);out=clean
 out.save((P/(name+'-candidate.png')) if name=='mace_abilities' else (P.parent.parent/(name+'.png')));out.resize((out.width*3,out.height*3),Image.Resampling.NEAREST).save(P/(name+'-3x.png'))
 (P/(name+'-validation.json')).write_text(json.dumps({'size':out.size,'frame':[64,64],'root':[32,56],'counts':list(map(len,rows)),'scale':scale,'alpha':sorted(set(alpha.get_flattened_data()))},indent=2)+'\n')
 print(name,out.size,list(map(len,rows)),scale)

attack=crop_rows('attack-master.png',[0,270,550,758,1024],[[0,245,465,800],[0,240,508,800],[0,290,540,800],[0,232,397,550,717,881,1052,1298,1536]])
sheet(attack,'attack_mace')
ability=crop_rows('abilities-master.png',[0,260,460,665,850,1024],[[0,226,387,543,715,891,1145,1323,1536],[0,245,427,658,899,1105,1300,1536],[0,221,365,503,666,902,1037,1200,1336,1536],[0,168,325,455,596,725,861,1010,1210,1361,1536],[0,170,270,386,492,608,723,832,941,1052,1228,1400,1536]])
# One deliberately held anticipation frame before the low sweep.
ability[1].insert(1,ability[1][0].copy())
sheet(ability,'mace_abilities')
