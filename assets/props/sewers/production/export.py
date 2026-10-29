"""Nearest-sample generated isolated art into registered runtime frames.
No procedural sprites are painted. Sources and crop/scale data are retained.
"""
from pathlib import Path
from PIL import Image
import json,hashlib
P=Path(__file__).resolve().parent;R=P.parent;N=Image.Resampling.NEAREST
specs={}
def add(name,fw=32,fh=32,n=1,target=(26,26),align='centre',states=None,rows=None):specs[name]={'frame_size':[fw,fh],'frames':n,'target':list(target),'align':align,'states':states or ['static'],'rows':rows or [n]}
for name in ['salve','bandage','grate_key']:add(name,target=(26,26) if name=='salve' else (26,22))
for name,target in [('crate',(28,28)),('barrel',(26,28))]:add(name,n=2,target=target,align='base',states=['closed','opened'])
add('satchel_body',64,32,2,(56,24),'centre',['closed satchel','searched satchel'])
add('letter',target=(22,16));add('hymn_sheet',target=(24,22));add('miner_tag_body',64,32,1,(56,24))
add('valve',n=4,target=(26,28),align='base',states=['turn 0','turn 1','turn 2','turn 3'])
for name in ['bones_1','bones_2','bones_3','debris_1','debris_2','debris_3']:add(name,target=(24,20))
# Grate layout is explicit in grate-format.json once clarified.
if (P/'grate-format.json').exists():
 d=json.loads((P/'grate-format.json').read_text())
 for name,fw,fh,target in [('grate_ns',64,32,(62,30)),('grate_ew',32,64,(30,62))]:add(name,fw,fh,d['total_frames'],target,'centre',d['states'],d['rows']);specs[name]['source_grid']=d['source_grid']
entries=[];images={}
for name,spec in specs.items():
 path=P/(name+'-master.png')
 if not path.exists():continue
 source=Image.open(path).convert('RGBA');a=source.getchannel('A').point(lambda v:255 if v>=128 else 0);source.putalpha(a);fw,fh=spec['frame_size'];n=spec['frames'];pieces=[];bounds=[]
 sc,sr=spec.get('source_grid',[n,1])
 for i in range(n):
  col,row=i%sc,i//sc;x0=round(source.width*col/sc);x1=round(source.width*(col+1)/sc);y0=round(source.height*row/sr);y1=round(source.height*(row+1)/sr)
  if col:assert not a.crop((max(0,x0-2),y0,min(source.width,x0+2),y1)).getbbox(),(name,'sprite crosses column cut',i)
  if row:assert not a.crop((x0,max(0,y0-2),x1,min(source.height,y0+2))).getbbox(),(name,'sprite crosses row cut',i)
  f=source.crop((x0,y0,x1,y1));b=f.getchannel('A').getbbox();assert b,(name,i)
  pieces.append(f.crop(b));bounds.append([b[0]+x0,b[1]+y0,b[2]+x0,b[3]+y0])
 tw,th=spec['target'];scale=min(tw/max(f.width for f in pieces),th/max(f.height for f in pieces));frames=[]
 for f in pieces:
  size=tuple(spec['target']) if name.startswith('grate_') else (max(1,round(f.width*scale)),max(1,round(f.height*scale)));f=f.resize(size,N);frame=Image.new('RGBA',(fw,fh));x=(fw-f.width)//2;y=(fh-f.height)//2 if spec['align']=='centre' else fh-2-f.height
  assert min(x,y)>=0 and x+f.width<=fw and y+f.height<=fh;frame.paste(f,(x,y));frames.append(frame)
 cols=max(spec['rows']);sheet=Image.new('RGBA',(fw*cols,fh*len(spec['rows'])))
 for i,f in enumerate(frames):sheet.paste(f,((i%cols)*fw,(i//cols)*fh))
 # One palette per whole sheet; preserve binary alpha and clear hidden RGB.
 a=sheet.getchannel('A');q=sheet.convert('RGB').quantize(colors=32,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(a);sheet=Image.new('RGBA',q.size);sheet.paste(q,mask=a);sheet.save(R/(name+'.png'));images[name]=sheet
 entry={'file':name+'.png','frame_size':[fw,fh],'canvas':list(sheet.size),'rows':spec['rows'],'states':spec['states'],'origin_px':[fw//2,fh//2],'source_canvas':list(source.size),'source_bounds':bounds,'shared_scale':None if name.startswith('grate_') else scale,'source_grid':spec.get('source_grid',[n,1]),'resampling':'fixed per-axis plane fit' if name.startswith('grate_') else 'shared uniform nearest scale','alignment':spec['align'],'frame_alpha_boxes':[f.getchannel('A').getbbox() for f in frames],'sha256':hashlib.sha256((R/(name+'.png')).read_bytes()).hexdigest()};entries.append(entry)
(R/'manifest.json').write_text(json.dumps({'job':14,'grid_px':32,'pixel_origin':'upper left,+x right,+y down; sprite origins centre of frame','assets':entries},indent=2)+'\n')
# Review gallery: one row per file; no labels inside game images.
g=Image.new('RGBA',(512,64*len(entries)),(25,28,31,255))
for i,e in enumerate(entries):
 im=images[Path(e['file']).stem];factor=min(2,512/im.width,64/im.height);g.alpha_composite(im.resize((round(im.width*factor),round(im.height*factor)),N),(0,i*64))
g.save(R/'previews/all-assets.png');(R/'previews/gallery-order.json').write_text(json.dumps([e['file'] for e in entries],indent=2)+'\n')
print('Exported',len(entries),'runtime PNGs,',sum(sum(e['rows']) for e in entries),'frames.')
