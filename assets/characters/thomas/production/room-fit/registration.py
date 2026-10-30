"""Nearest registration of generated normal studies to original frame masks."""
from PIL import Image
N=Image.Resampling.NEAREST
def fit(source,original,counts,normal=False):
 source=source.convert('RGBA');out=Image.new('RGBA',original.size);cols=original.width//64;rows=len(counts);report=[]
 for row,count in enumerate(counts):
  for col in range(count):
   box=(col*64,row*64,(col+1)*64,(row+1)*64);old=original.crop(box);ob=old.getchannel('A').getbbox();assert ob
   sb=(round(col*source.width/cols),round(row*source.height/rows),round((col+1)*source.width/cols),round((row+1)*source.height/rows));cell=source.crop(sb);a=cell.getchannel('A').point(lambda v:255 if v>=128 else 0);cell.putalpha(a);b=a.getbbox();assert b,(row,col,'empty generated cell')
   tile=cell.crop(b).resize((ob[2]-ob[0],ob[3]-ob[1]),N)
   # Extend nearest valid colour at small silhouette differences before locking alpha.
   from collections import deque
   q=deque((x,y) for y in range(tile.height) for x in range(tile.width) if tile.getpixel((x,y))[3]>=128);assert q
   seen=set(q)
   while q:
    x,y=q.popleft();c=tile.getpixel((x,y))
    for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
     if 0<=nx<tile.width and 0<=ny<tile.height and (nx,ny) not in seen:seen.add((nx,ny));tile.putpixel((nx,ny),c);q.append((nx,ny))
   frame=Image.new('RGBA',(64,64));frame.paste(tile,(ob[0],ob[1]));frame.putalpha(old.getchannel('A'));out.paste(frame,(box[0],box[1]));report.append({'row':row+1,'frame':col+1,'source_cell':list(sb),'source_alpha_bounds':list(b),'target_alpha_bounds':list(ob)})
 return out,report
