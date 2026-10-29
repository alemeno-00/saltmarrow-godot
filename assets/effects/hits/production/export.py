from PIL import Image
from pathlib import Path
import json,sys

def spans(v,gap=3):
 pts=[i for i,x in enumerate(v) if x];out=[]
 for i in pts:
  if not out or i-out[-1][-1]>gap:out.append([i])
  else:out[-1].append(i)
 return [(x[0],x[-1]+1) for x in out]

def loadrows(p,ys=None,counts=None,equal=False):
 im=Image.open(p).convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));a=im.getchannel('A')
 yy=list(zip(ys,ys[1:])) if ys else spans([a.crop((0,y,im.width,y+1)).getbbox() is not None for y in range(im.height)],4)
 rows=[]
 for ri,(y0,y1) in enumerate(yy):
  band=im.crop((0,y0,im.width,y1));ba=band.getchannel('A')
  xx=[(round(i*im.width/counts[ri]),round((i+1)*im.width/counts[ri])) for i in range(counts[ri])] if equal else spans([ba.crop((x,0,x+1,ba.height)).getbbox() is not None for x in range(ba.width)],3)
  xx=[(x0,x1) for x0,x1 in xx if x1-x0>=20]
  row=[]
  for x0,x1 in xx:
   f=band.crop((x0,0,x1,band.height));b=f.getbbox()
   if b:row.append(f.crop(b))
  if counts:assert len(row)==counts[ri],(str(p),ri,len(row),counts[ri])
  rows.append(row)
 return rows

def export(rows,target,size=64,scales=None,counts=None,root=None):
 root=root or(size//2,size//2 if size!=64 else 56)
 out=Image.new('RGBA',(max(map(len,rows))*size,len(rows)*size))
 for r,row in enumerate(rows):
  sc=scales[r] if scales else min((size-4)/max(f.width for f in row),(size-4)/max(f.height for f in row))
  for c,f in enumerate(row):
   f=f.resize((max(1,round(f.width*sc)),max(1,round(f.height*sc))),Image.Resampling.NEAREST)
   x=root[0]-f.width//2;y=root[1]-f.height if size==64 and root[1]==56 else root[1]-f.height//2
   assert x>=0 and y>=0 and x+f.width<=size and y+f.height<=size,(r,c,f.size,(x,y))
   out.paste(f,(c*size+x,r*size+y))
 a=out.getchannel('A');out=out.convert('RGB').quantize(colors=47,dither=Image.Dither.NONE).convert('RGBA');out.putalpha(a)
 clear=Image.new('RGBA',out.size);clear.paste(out,mask=a);out=clear
 out.save(target);return out
def crops(file,ys,xrows):
 im=Image.open(file).convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));rows=[]
 for (y0,y1),xs in zip(zip(ys,ys[1:]),xrows):
  row=[]
  for x0,x1 in zip(xs,xs[1:]):
   f=im.crop((x0,y0,x1,y1));b=f.getbbox();assert b,(str(file),y0,x0);row.append(f.crop(b))
  rows.append(row)
 return rows
p=Path('assets/effects/hits');rows=crops(p/'production/hits-master.png',[0,270,525,735,1024],[[0,405,720,1090,1536]]*3+[[0,180,470,775,1030,1290,1536]])
for name,row in zip(['crushing','slashing','piercing','tier_3'],rows):
 im=export([row],p/(name+'.png'),size=64,root=(32,32));im.resize((im.width*3,192),Image.Resampling.NEAREST).save(p/'production'/(name+'-3x.png'))
p=Path('assets/effects/mace');rows=crops(p/'production/effects-master.png',[0,225,460,725,1024],[[0,300,590,815,1040,1285,1536],[0,470,770,1100,1536],[0,250,550,930,1210,1536],[0,345,800,1180,1536]])
for name,row,size in zip(['dazed','fracture','wall_slam','wide_arc'],rows,[32,32,64,96]):
 im=export([row],p/(name+'.png'),size=size,root=(size//2,size//2));im.resize((im.width*3,im.height*3),Image.Resampling.NEAREST).save(p/'production'/(name+'-3x.png'))
arm=Image.open(p/'production/armour-master.png');w,h=arm.size;rows=crops(p/'production/armour-master.png',[0,round(h/3),round(2*h/3),h],[[round(i*w/7) for i in range(8)]]*3)
for name,row in zip(['helm','pauldron','breastplate'],rows):
 full=export([row],p/'production'/(name+'-strip.png'),size=32)
 full.crop((0,0,192,32)).save(p/(name+'_break.png'));full.crop((192,0,224,32)).save(p/(name+'_rest.png'))
p=Path('assets/characters/thomas/production/careful-step');rows=loadrows(p/'master.png',counts=[4]);sc=min(44/max(f.height for f in rows[0]),60/max(f.width for f in rows[0]));step=export(rows,p/'row.png',scales=[sc]);step.resize((1024,256),Image.Resampling.NEAREST).save(p/'row-4x.png')
target=p.parent.parent/'body.png';old=Image.open(target).convert('RGBA');assert old.size in [(384,448),(384,512)]
new=Image.new('RGBA',(384,512));new.paste(old.crop((0,0,384,448)),(0,0));new.paste(step,(0,448));assert new.crop((0,0,384,448)).tobytes()==old.crop((0,0,384,448)).tobytes();new.save(target)
print('Exported hit effects, mace effects, armour debris and careful-step row')
