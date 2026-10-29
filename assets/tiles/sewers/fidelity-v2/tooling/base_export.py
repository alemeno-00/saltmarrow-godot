from PIL import Image, ImageChops
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent.parent
entries=[]
def clean(im):
    im=im.copy().convert('RGBA'); p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y];p[x,y]=(r,g,b,255) if a>=160 else (0,0,0,0)
    return im
def save(name,im,group):
    im=clean(im);path=ROOT/group/(name+'.png');im.save(path)
    entries.append(dict(id=name,file=f'{group}/{name}.png',size=list(im.size),origin=[im.width//2,im.height] if group=='masonry' else [im.width//2,im.height//2],sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    return im
def seam(im,reference=None):
    im=im.copy();p=im.load();c=(reference or im).load();w,h=im.size
    for y in range(h):
        color=c[0,y] if reference else tuple((c[0,y][k]+c[w-1,y][k])//2 for k in range(3))+(255,)
        p[0,y]=p[w-1,y]=color
    for x in range(w):
        color=c[x,0] if reference else tuple((p[x,0][k]+p[x,h-1][k])//2 for k in range(3))+(255,)
        p[x,0]=p[x,h-1]=color
    p[w-1,0]=p[0,h-1]=p[w-1,h-1]=p[0,0]
    return im
source=Image.open(ROOT/'source/surfaces.png').convert('RGBA')
canonical={}
for y in range(4):
    for x in range(4):
        w,h=source.size
        tile=source.crop((round(x*w/4)+3,round(y*h/4)+3,round((x+1)*w/4)-3,round((y+1)*h/4)-3)).resize((32,32),Image.Resampling.NEAREST)
        tile=clean(tile);bg=Image.new('RGBA',(32,32),(22,27,29,255));bg.alpha_composite(tile);tile=bg
        family='water' if y==3 else 'floor';index=x if y==3 else y*4+x
        tile=seam(tile,canonical.get(family));canonical.setdefault(family,tile)
        save(f'{family}_{index:02d}',tile,'terrain')
source=Image.open(ROOT/'source/masonry.png').convert('RGBA')
for i in range(4):
    w,h=source.size
    piece=source.crop((round(i*w/4),0,round((i+1)*w/4),round(h/2)))
    bounds=piece.getchannel('A').point(lambda a:255 if a>160 else 0).getbbox()
    piece=piece.crop(bounds)
    # Remove the source's rounded isolated side silhouette, preserving front material.
    piece=piece.crop((5,0,piece.width-5,piece.height)).resize((64,64),Image.Resampling.NEAREST)
    piece=clean(piece)
    if i==0:edge=piece.crop((0,0,1,64))
    piece.paste(edge,(0,0));piece.paste(edge,(63,0))
    save(f'wall_{i}',piece,'masonry')
for name,box,size in [('arch_wall',(25,450,495,812),(96,96)),('arch',(505,455,881,810),(96,96)),('pipe_wall',(900,450,1323,815),(64,64)),('pier',(1430,425,1655,815),(32,64))]:
    a=source.crop(box);bbox=a.getchannel('A').point(lambda a:255 if a>160 else 0).getbbox();a=a.crop(bbox).resize(size,Image.Resampling.NEAREST)
    save(name,a,'masonry')
(ROOT/'manifest.json').write_text(json.dumps(dict(status='unapproved visual revision',grid=32,provenance='New built-in-generated source families; nearest-neighbour mechanical registration, binary-alpha cleanup and edge normalization. Not concept cutouts.',assets=entries),indent=2)+'\n')
print('Exported',len(entries),'assets')
