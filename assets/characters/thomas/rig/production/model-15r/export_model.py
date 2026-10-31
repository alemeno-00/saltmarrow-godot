"""Mechanical alpha cleanup, nearest pixel registration, palette export and review layout.
No rig parts are cut or repainted here. This is job15-R step1 only.
"""
from pathlib import Path
from PIL import Image
from collections import deque
import json,math
P=Path(__file__).resolve().parent;R=P.parent;ROOT=P.parents[5];N=Image.Resampling.NEAREST
RED=[(41,16,19),(69,27,29),(94,39,37),(122,52,45)]
ROOM=[tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())]
TARGETS=[(21,19,19),(33,33,34),(46,46,49),(64,63,64),(59,57,61),(63,50,44),(90,59,30),(118,109,97),(135,126,111),(154,145,130),(125,119,106),(97,94,90),(134,83,31),(179,129,55)]
PAL=list(dict.fromkeys(min(ROOM,key=lambda c:sum((c[k]-t[k])**2 for k in range(3))) for t in TARGETS))
def ramp(targets):return list(dict.fromkeys(min(ROOM,key=lambda c:sum((c[k]-t[k])**2 for k in range(3))) for t in targets))
COAT=ramp([(21,19,19),(33,33,34),(46,46,49),(64,63,64)])
canonical=Image.open(ROOT/'assets/characters/thomas/production/concepts/canonical-reference-v1.png').convert('RGB').crop((690,82,770,170))
flesh=list({c for c in canonical.get_flattened_data() if 75<=c[0]<=190 and 45<=c[1]<=155 and 30<=c[2]<=130 and c[0]>c[1]*1.1 and c[1]>c[2]*1.1})
# Proposed approval-only skin exception: the room palette lacks these warm mid-tones.
SKIN=[min(flesh,key=lambda c:sum((c[k]-t[k])**2 for k in range(3))) for t in [(83,60,48),(112,80,61),(145,105,79),(164,128,98)]]
HAIR=ramp([(21,19,19),(33,33,34),(63,50,44),(90,59,30)])
CANVAS=ramp([(63,50,44),(90,59,30),(118,109,97),(135,126,111)])
WRAP=ramp([(64,63,64),(97,94,90),(125,119,106),(154,145,130)])
BRASS=ramp([(63,50,44),(90,59,30),(134,83,31),(179,129,55)])

def material_ramp(c,nx,ny):
    # Colour ramps classify existing painted material; no silhouette pixels are added.
    r,g,b=c
    face=35<=nx<=44 and 24<=ny<=29
    hand=47<=ny<=52 and (29<=nx<=32 or 47<=nx<=51)
    # At this resolution the painted eye whites represent the whole eye, not a glow.
    if face and ny==26 and max(c)>140 and g>=r*.8:return [(63,50,44)]
    if (face or hand) and r>=85 and r>g*1.12:return SKIN
    if ny<30:return HAIR
    if r>g*2.2 and b>=g*.8 and 30<=ny<=52:return RED
    if 41<=nx<=44 and 47<=ny<=52 and r>g*1.35 and g>b*1.4:return BRASS
    strap=32<=ny<=45 and abs(nx-ny)<=1.6
    bag=43<=nx<=49 and 43<=ny<=49
    if (strap or bag) and r>g*1.12 and g>b*1.08 and r>75:return CANVAS
    if 61<=ny<=66 and max(c)>75 and abs(r-g)<20 and abs(g-b)<20:return WRAP
    if ny>=67:return HAIR
    if 35<=nx<=45 and 49<=ny<=62 and r>g*1.12:return HAIR
    return COAT

def cleanup(source):
    im=source.convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
    mask={(x,y) for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]};groups=[]
    while mask:
        seed=mask.pop();group={seed};queue=deque([seed])
        while queue:
            x,y=queue.popleft()
            for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
                pt=x+dx,y+dy
                if pt in mask:mask.remove(pt);group.add(pt);queue.append(pt)
        groups.append(group)
    keep=max(groups,key=len)
    for y in range(im.height):
        for x in range(im.width):
            if (x,y) not in keep:im.putpixel((x,y),(0,0,0,0))
    box=im.getbbox();return im.crop(box),box

def export():
    source=Image.open(P/'model-refined-source.png');crop,box=cleanup(source)
    scale=52/crop.height;size=(round(crop.width*scale),52);small=crop.resize(size,N)
    feet=crop.getchannel('A').crop((0,round(crop.height*.90),crop.width,crop.height)).getbbox()
    anchor=(feet[0]+feet[2])/2;x=40-round(anchor*scale);y=20
    data=[]
    for index,(r,g,b,a) in enumerate(small.get_flattened_data()):
        if not a:data.append((0,0,0,0));continue
        colours=material_ramp((r,g,b),x+index%size[0],y+index//size[0])
        if colours==SKIN:
            light=.2126*r+.7152*g+.0722*b
            c=SKIN[3] if light>=175 else SKIN[2] if light>=125 else SKIN[1] if light>=85 else SKIN[0]
        else:c=min(colours,key=lambda c:sum((c[k]-[r,g,b][k])**2 for k in range(3)))
        data.append((*c,255))
    small.putdata(data);frame=Image.new('RGBA',(80,80));frame.paste(small,(x,y))
    for xx in range(80):
        c=frame.getpixel((xx,71))
        if c[3]:frame.putpixel((xx,71),(33,33,34,255))
    frame.save(R/'model-s.png')
    normal_path=P/'model-normal-source.png'
    if normal_path.exists():
        ncrop,nbox=cleanup(Image.open(normal_path));nb=frame.getbbox()
        fitted=ncrop.resize((nb[2]-nb[0],nb[3]-nb[1]),N);nm=Image.new('RGBA',(80,80));nm.paste(fitted,(nb[0],nb[1]))
        valid=[(xx,yy,nm.getpixel((xx,yy))) for yy in range(80) for xx in range(80) if nm.getpixel((xx,yy))[3]]
        pixels=[]
        for index,(c,d) in enumerate(zip(nm.get_flattened_data(),frame.get_flattened_data())):
            if not d[3]:pixels.append((0,0,0,0));continue
            if not c[3]:c=min(valid,key=lambda p:(p[0]-index%80)**2+(p[1]-index//80)**2)[2]
            v=[c[0]/127.5-1,c[1]/127.5-1,max(.15,c[2]/127.5-1)];length=math.sqrt(sum(z*z for z in v))
            pixels.append(tuple(round(127.5*(z/length+1)) for z in v)+(255,))
        nm.putdata(pixels);nm.save(R/'model-s_n.png')
    preview=P/'previews';preview.mkdir(exist_ok=True);(preview/'.gdignore').touch()
    frame.resize((640,640),N).save(preview/'model-s-8x.png')
    concept=Image.open(ROOT/'assets/characters/thomas/production/concepts/canonical-reference-v1.png').convert('RGBA')
    pair=Image.new('RGBA',(1600,640),(74,77,78,255));pair.alpha_composite(concept.resize((960,640),N),(0,0));pair.alpha_composite(frame.resize((640,640),N),(960,0));pair.save(preview/'concept-and-model-8x.png')
    room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA');room.alpha_composite(frame,(112,152));room.save(preview/'room-1x.png')
    room.crop((64,96,256,288)).resize((768,768),N).save(preview/'room-4x.png')
    # Existing cast shown at their actual exported scale, without repainting them.
    faithful=Image.open(ROOT/'assets/enemies/faithful/body.png').convert('RGBA').crop((0,0,64,64))
    miner=Image.open(ROOT/'assets/enemies/drowned_miner/body.png').convert('RGBA').crop((0,0,64,64))
    cast=Image.new('RGBA',(240,80),(90,93,92,255));cast.alpha_composite(frame,(0,0));cast.alpha_composite(faithful,(88,16));cast.alpha_composite(miner,(168,16));cast.save(preview/'cast-1x.png');cast.resize((1440,480),N).save(preview/'cast-6x.png')
    (P/'registration.json').write_text(json.dumps({'source_size':source.size,'source_bounds':box,'export_size':[80,80],'body_height':52,'feet_root':[40,72],'uniform_scale':scale,'paste':[x,y],'body_size':size,'material_ramps':{'coat':COAT,'skin':SKIN,'hair_boots':HAIR,'canvas_trousers':CANVAS,'wraps':WRAP,'brass':BRASS,'scarf':RED},'step2':'NOT STARTED; requires Julian approval'},indent=2)+'\n')
    print('Exported whole52px model only. Bounds:',frame.getbbox())

if __name__=='__main__':export()
