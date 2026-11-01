"""Register independent image-tool edits. Preserve unchanged head/boot regions from each own guide.
No limbs are generated from another frame, reflected, moved separately or rotated here.
"""
from pathlib import Path
from PIL import Image
from collections import deque
import json
P=Path(__file__).resolve().parent;N=Image.Resampling.NEAREST
selected={n:f'frame-{n:02d}-source-v1.png' for n in (2,4,6,8)}
records=[];row=Image.new('RGBA',(1280,320))
for j,n in enumerate((2,4,6,8)):
 src=Image.open(P/selected[n]).convert('RGBA');src.putalpha(src.getchannel('A').point(lambda a:255 if a>=128 else 0))
 mask={(x,y) for y in range(src.height) for x in range(src.width) if src.getpixel((x,y))[3]};groups=[]
 while mask:
  seed=mask.pop();q=deque([seed]);g={seed}
  while q:
   x,y=q.popleft()
   for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
    p=x+dx,y+dy
    if p in mask:mask.remove(p);q.append(p);g.add(p)
  groups.append(g)
 main=max(groups,key=len);box=min(x for x,y in main),min(y for x,y in main),max(x for x,y in main)+1,max(y for x,y in main)+1
 for y in range(src.height):
  for x in range(src.width):
   if (x,y) not in main:src.putpixel((x,y),(0,0,0,0))
 guide=Image.open(P/f'guide-{n:02d}-4x.png').convert('RGBA');target=guide.getbbox();fit=Image.new('RGBA',(320,320));fit.paste(src.crop(box).resize((target[2]-target[0],target[3]-target[1]),N),(target[0],target[1]));fit.save(P/f'frame-{n:02d}-registered-edit-4x.png')
 # The guide's head and foot placement are already approved and are invariants of this cleanup.
 # Masked editing preserves these areas rather than accepting the generator's redesign/pose drift.
 fit.paste(guide.crop((0,0,320,128)),(0,0));fit.paste(guide.crop((0,268,320,320)),(0,268))
 # Constrain the edit to the brief's one-game-pixel silhouette envelope.
 guide1=guide.resize((80,80),N);gm={(x,y) for y in range(80) for x in range(80) if guide1.getpixel((x,y))[3]}
 fm={(x,y) for y in range(80) for x in range(80) if sum(fit.getpixel((x*4+dx,y*4+dy))[3]>=128 for dy in range(4) for dx in range(4))>8}
 near=lambda pt,mask:any((pt[0]+dx,pt[1]+dy) in mask for dy in (-1,0,1) for dx in (-1,0,1))
 clipped=[pt for pt in fm if not near(pt,gm)];restored=[pt for pt in gm if not near(pt,fm)]
 for x,y in clipped:fit.paste((0,0,0,0),(x*4,y*4,x*4+4,y*4+4))
 for x,y in restored:fit.paste(guide.crop((x*4,y*4,x*4+4,y*4+4)),(x*4,y*4))
 # Retain short original guide connections where the edit detached a wrist/fringe cluster.
 def components(mask):
  todo=set(mask);out=[]
  while todo:
   seed=todo.pop();q=deque([seed]);g={seed}
   while q:
    xx,yy=q.popleft()
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
     pt=xx+dx,yy+dy
     if pt in todo:todo.remove(pt);q.append(pt);g.add(pt)
   out.append(g)
  return sorted(out,key=len,reverse=True)
 repairs=[]
 for _ in range(8):
  post={(x,y) for y in range(80) for x in range(80) if sum(fit.getpixel((x*4+dx,y*4+dy))[3]>=128 for dy in range(4) for dx in range(4))>8};groups=components(post)
  if len(groups)==1:break
  main=groups[0];joined=False
  for cluster in groups[1:]:
   queue=deque((pt,[]) for pt in cluster);seen=set(cluster);path=None
   while queue:
    pt,missing=queue.popleft()
    if pt in main:path=missing;break
    if len(missing)>3:continue
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
     nxt=pt[0]+dx,pt[1]+dy
     if nxt in seen or nxt not in (gm|post):continue
     seen.add(nxt);queue.append((nxt,missing+([nxt] if nxt not in post else [])))
   if path is not None and len(path)<=3:
    for x,y in path:fit.paste(guide.crop((x*4,y*4,x*4+4,y*4+4)),(x*4,y*4));repairs.append([x,y])
    joined=True;break
  if not joined:break
 fit.save(P/f'frame-{n:02d}-4x.png');row.paste(fit,(j*320,0))
 records.append({'frame':n,'source':selected[n],'source_bounds':box,'guide_bounds':target,'whole_figure_registration':'nearest-neighbour source bbox to guide bbox','preserved_guide_regions_4x':[[0,0,320,128],[0,268,320,320]],'clipped_blocks_outside_guide_envelope':[list(pt) for pt in clipped],'restored_original_guide_blocks':[list(pt) for pt in restored],'restored_guide_connection_blocks':repairs,'preservation_reason':'keep approved head and original boots/sole placement unchanged; only middle painting region accepts the independent edit'})
row.save(P/'inbetweens-4x.png');(P/'registration.json').write_text(json.dumps(records,indent=2)+'\n');print('Registered four independent in-betweens with the approved guide-preservation method.')
