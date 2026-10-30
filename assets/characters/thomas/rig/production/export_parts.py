"""Mechanical extraction, palette conversion and pivot registration of painted parts."""
from pathlib import Path
from PIL import Image
from collections import deque
import json,math
P=Path(__file__).resolve().parent;R=P.parent;ROOT=P.parents[4]
MASTER=P/'polish-v2/south-parts-master-v2.png'
NORMAL_MASTER=P/'polish-v2/south-parts-normal-master-v2.png'
N=Image.Resampling.NEAREST
NAMES=['head','torso','skirt','upper_arm_l','forearm_l','upper_arm_r','forearm_r','thigh_l','shin_l','thigh_r','shin_r']
SIZES=[(9,9),(13,18),(15,17),(4,12),(4,12),(4,12),(4,12),(5,14),(5,14),(5,14),(5,14)]
PIVOTS=[(12,22),(12,22)]+[(12,2)]*9
REDS=[(41,16,19),(69,27,29),(94,39,37),(122,52,45)]
ROOM=[tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())]
PALETTE=[c for c in ROOM if max(c)>18 and max(c)-min(c)<70]

def extract(im,i,trim_skirt=True):
    w,h=im.size;col,row=i%4,i//4
    f=im.crop((round(w*col/4),round(h*row/3),round(w*(col+1)/4),round(h*(row+1)/3))).convert('RGBA')
    f.putalpha(f.getchannel('A').point(lambda a:255 if a>=128 else 0))
    # Alpha cleanup removes isolated generator specks, never paints a new shape.
    mask={(x,y) for y in range(f.height) for x in range(f.width) if f.getpixel((x,y))[3]};groups=[]
    while mask:
        seed=mask.pop();q=deque([seed]);group={seed}
        while q:
            x,y=q.popleft()
            for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
                pt=x+dx,y+dy
                if pt in mask:mask.remove(pt);q.append(pt);group.add(pt)
        groups.append(group)
    largest=max(map(len,groups))
    keep=set().union(*(g for g in groups if len(g)>=largest*.02)) if i==1 else max(groups,key=len)
    for y in range(f.height):
        for x in range(f.width):
            if (x,y) not in keep:f.putpixel((x,y),(0,0,0,0))
    box=f.getbbox();f=f.crop(box)
    if i>=3:
        counts=[sum(1 for x in range(f.width) if f.getpixel((x,y))[3]) for y in range(f.height)]
        # Thin stray cap tips must not push the actual joint several pixels down.
        top=next(y for y,count in enumerate(counts) if count>=max(counts)*.55)
        f=f.crop((0,top,f.width,f.height))
    if i==2 and trim_skirt:
        # The torso owns the belt; remove the duplicate belt above the coat skirt.
        trim=round(f.height*.10);f=f.crop((0,trim,f.width,f.height))
    return f,box

def export():
    source=Image.open(MASTER).convert('RGBA')
    sheet=Image.new('RGBA',(264,24));packed=Image.new('RGBA',(96,72));records=[]
    for i,name in enumerate(NAMES):
        head_path=P/'polish-v2/head-master-v2.png'
        if i==0 and head_path.exists():
            head=Image.open(head_path).convert('RGBA');head_pack=Image.new('RGBA',(head.width*4,head.height*3));head_pack.paste(head,(0,0))
            f,box=extract(head_pack,0,False)
        else:f,box=extract(source,i,False)
        f=f.resize(SIZES[i],N)
        pixels=[]
        for r,g,b,a in f.get_flattened_data():
            if not a:pixels.append((0,0,0,0));continue
            ramp=REDS if r>g*1.8 and r>b*1.4 else PALETTE
            c=min(ramp,key=lambda c:sum((c[k]-[r,g,b][k])**2 for k in range(3)))
            pixels.append((*c,255))
        f.putdata(pixels)
        x=12-f.width//2;y=23-f.height if i<2 else 0
        if i<2 and not f.getpixel((12-x,22-y))[3]:
            occupied=[xx for xx in range(f.width) if f.getpixel((xx,22-y))[3]]
            x=12-min(occupied,key=lambda xx:abs((x+xx)-12))
        if i>=3:
            # Centre actual material at the joint, not the asymmetric cuff's bounds.
            row=min(range(min(5,f.height)),key=lambda yy:abs(yy-2) if any(f.getpixel((xx,yy))[3] for xx in range(f.width)) else 100)
            occupied=[xx for xx in range(f.width) if f.getpixel((xx,row))[3]]
            joint_x=min(occupied,key=lambda xx:abs((x+xx)-12))
            x=12-joint_x;y=2-row
        cell=Image.new('RGBA',(24,24));cell.paste(f,(x,y))
        if i in [8,10]:
            for xx in range(24):
                yy=y+f.height-1;c=cell.getpixel((xx,yy))
                if c[3]:cell.putpixel((xx,yy),(*min(PALETTE,key=lambda d:sum((d[k]-max(20,c[k]-10))**2 for k in range(3))),255))
        sheet.paste(cell,(24*i,0));packed.paste(cell,(i%4*24,i//4*24))
        records.append({'cell':i,'part':name,'pivot':PIVOTS[i],'source':str(head_path.relative_to(P)) if i==0 else str(MASTER.relative_to(P)),'source_box':box,'painted_size':SIZES[i],'paste':[x,y],'alpha_bounds':cell.getbbox()})
    sheet.save(R/'s.png');packed.resize((1152,864),N).save(P/'south-parts-registered-packed.png')
    normal_path=NORMAL_MASTER
    if normal_path.exists():
        normal_source=Image.open(normal_path).convert('RGBA');normals=Image.new('RGBA',sheet.size)
        for i in range(11):
            f,box=extract(normal_source,i,False);f=f.resize(SIZES[i],N)
            x,y=records[i]['paste']
            cell=Image.new('RGBA',(24,24));cell.paste(f,(x,y))
            diffuse=sheet.crop((i*24,0,i*24+24,24));valid=[(xx,yy,cell.getpixel((xx,yy))) for yy in range(24) for xx in range(24) if cell.getpixel((xx,yy))[3]>=128]
            pixels=[]
            for yy in range(24):
                for xx in range(24):
                    if not diffuse.getpixel((xx,yy))[3]:pixels.append((0,0,0,0));continue
                    c=cell.getpixel((xx,yy))
                    if c[3]<128:c=min(valid,key=lambda v:(v[0]-xx)**2+(v[1]-yy)**2)[2]
                    v=[c[0]/127.5-1,c[1]/127.5-1,max(.15,c[2]/127.5-1)];length=math.sqrt(sum(z*z for z in v))
                    pixels.append(tuple(round(127.5*(z/length+1)) for z in v)+(255,))
            cell.putdata(pixels);normals.paste(cell,(i*24,0))
        normals.save(R/'s_n.png')
    (P/'registration.json').write_text(json.dumps({'source':str(MASTER.relative_to(P)),'sheet_size':[264,24],'cell_size':[24,24],'parts':records},indent=2)+'\n')
    preview=R/'previews';preview.mkdir(exist_ok=True);(preview/'.gdignore').touch()
    sheet.resize((2112,192),N).save(preview/'south-parts-8x.png')
    print('Exported11 parts at fixed pivots.')

if __name__=='__main__':export()
