"""Mechanical sprite export: isolate transparent gutters, nearest sampling, fixed scale."""
from pathlib import Path
from PIL import Image
import json
P=Path(__file__).parent

def spans(values,gap=12):
 pts=[i for i,v in enumerate(values) if v]
 groups=[]
 for i in pts:
  if not groups or i-groups[-1][-1]>gap:groups.append([i])
  else:groups[-1].append(i)
 return [(g[0],g[-1]+1) for g in groups]

def isolate(name,counts):
 im=Image.open(P/name).convert('RGBA')
 im.putalpha(im.getchannel('A').point(lambda a:255 if a>=(250 if name=='injury-master.png' else 128) else 0))
 a=im.getchannel('A')
 ys=spans([a.crop((0,y,im.width,y+1)).getbbox() is not None for y in range(im.height)],20)
 assert len(ys)==len(counts),(name,ys)
 rows=[]
 for (y0,y1),n in zip(ys,counts):
  band=im.crop((0,y0,im.width,y1));ba=band.getchannel('A')
  xs=spans([ba.crop((x,0,x+1,band.height)).getbbox() is not None for x in range(band.width)],12)
  assert len(xs)==n,(name,n,xs)
  rows.append([band.crop((x0,0,x1,band.height)).crop(band.crop((x0,0,x1,band.height)).getbbox()) for x0,x1 in xs])
 return rows

def main():
 move=isolate('locomotion-master.png',[4,6]);inj=isolate('injury-master.png',[6,3,6]);ground=isolate('ground-master.png',[6,6])
 # One scale per master, based on its most upright pose; no per-frame fit/stretch.
 scales=[46/max(f.height for f in move[0]),46/max(f.height for f in inj[1]),44/ground[1][0].height]
 rows=[(move[0],scales[0]),(move[1],scales[0]),(inj[0],scales[1]),(inj[1],scales[1]),(inj[2],scales[1]),(ground[0],scales[2]),(ground[1],scales[2])]
 out=Image.new('RGBA',(384,448));meta=[]
 for r,(frames,scale) in enumerate(rows):
  for c,f in enumerate(frames):
   f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST)
   assert f.width<=62 and f.height<=52,(r,c,f.size)
   x=32-f.width//2;y=56-f.height
   out.paste(f,(c*64+x,r*64+y));meta.append({'row':r+1,'frame':c+1,'bounds':[x,y,x+f.width,56]})
 # Shared 31 colour palette avoids colour flicker between independently generated rows.
 alpha=out.getchannel('A');out=out.convert('RGB').quantize(colors=31,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(alpha)
 clean=Image.new('RGBA',out.size);clean.paste(out,mask=alpha);out=clean
 out.save(P.parent.parent/'body.png')
 out.resize((1536,1792),Image.Resampling.NEAREST).save(P/'body-4x.png')
 names=['idle','walk','sneak','hurt','wounded_walk','dying_crawl','death']
 for r,(frames,_) in enumerate(rows):
  cells=[out.crop((c*64,r*64,(c+1)*64,(r+1)*64)).resize((256,256),Image.Resampling.NEAREST) for c in range(len(frames))]
  cells[0].save(P/(names[r]+'.gif'),save_all=True,append_images=cells[1:],duration=180 if r!=0 else 300,loop=0,disposal=2)
 counts=[4,6,6,3,6,6,6]
 for r,n in enumerate(counts):
  for c in range(6):assert bool(out.crop((c*64,r*64,(c+1)*64,(r+1)*64)).getbbox())==(c<n)
 assert set(alpha.get_flattened_data())=={0,255}
 (P/'validation.json').write_text(json.dumps({'canvas':[384,448],'frame_size':[64,64],'root':[32,56],'counts':counts,'alpha':[0,255],'scales':scales,'frames':meta},indent=2)+'\n')
 print('Exported 37 frames; binary alpha; empty trailing cells; fixed scale per source pass.')
if __name__=='__main__':main()
