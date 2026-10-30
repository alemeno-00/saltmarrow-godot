"""Mechanical palette conversion, shared registration, assembly and review exports."""
from pathlib import Path
from collections import deque
from PIL import Image
import json, hashlib, math

P=Path(__file__).resolve().parent
R=P.parent.parent
ROOT=P.parents[6]
N=Image.Resampling.NEAREST
SPECS=[('idle_s',6),('walk_s',8),('walk_e',8)]
ROOM=[tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())]
REDS=[(41,16,19),(69,27,29),(94,39,37),(122,52,45)]
PALETTE=[c for c in ROOM if max(c)>18 and max(c)-min(c)<65]

def crown_y(crop):
    width=crop.width
    for y in range(round(crop.height*.3)):
        count=0
        for x in range(round(width*.2),round(width*.85)):
            r,g,b,a=crop.getpixel((x,y))
            if a>=128 and 15<r<180 and r>g*1.08 and g>b*1.08:count+=1
        if count>=max(3,width*.12):return y
    return 0

def clean(im):
    im=im.convert('RGBA').resize((80,80),N)
    mask={(x,y) for y in range(80) for x in range(80) if im.getpixel((x,y))[3]>=128}
    components=[]
    while mask:
        seed=mask.pop(); component={seed}; queue=deque([seed])
        while queue:
            x,y=queue.popleft()
            for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
                point=x+dx,y+dy
                if point in mask:
                    mask.remove(point); component.add(point); queue.append(point)
        components.append(component)
    keep=max(components,key=len)
    for y in range(80):
        for x in range(80):
            r,g,b,a=im.getpixel((x,y))
            if (x,y) not in keep:
                im.putpixel((x,y),(0,0,0,0)); continue
            im.putpixel((x,y),(r,g,b,255))
    return im

def register(frame,guide):
    # A common guide-space calibration keeps the guide root fixed at (40,72).
    # The upstream guides measure about55px, rather than the specified48-52.
    head=[(x,y) for y in range(80) for x in range(80) if guide.getpixel((x,y))[:3]==(225,212,190) and guide.getpixel((x,y))[3]]
    legs=[(x,y) for y in range(80) for x in range(80) if guide.getpixel((x,y))[3] and ((guide.getpixel((x,y))[0]>guide.getpixel((x,y))[2]*1.6 and guide.getpixel((x,y))[0]>60) or (guide.getpixel((x,y))[2]>guide.getpixel((x,y))[0]*1.6 and guide.getpixel((x,y))[2]>60))]
    head_y=min(y for x,y in head)
    heel=max(y for x,y in legs)+1
    target_crown=round(72+(head_y-72)*.9)
    target_heel=round(72+(heel-72)*.9)
    target_crown=target_heel-max(48,min(52,target_heel-target_crown))
    bounds=frame.getbbox(); crown=bounds[1]+crown_y(frame.crop(bounds))
    scale=(target_heel-target_crown)/(bounds[3]-crown)
    tx=40-40*scale;ty=target_heel-bounds[3]*scale
    out=frame.transform((80,80),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),resample=N)
    pixels=[]
    for r,g,b,a in out.get_flattened_data():
        if not a: pixels.append((0,0,0,0));continue
        ramp=REDS if r>g*1.8 and r>b*1.4 else PALETTE
        c=min(ramp,key=lambda c:sum((c[k]-[r,g,b][k])**2 for k in range(3)))
        pixels.append((*c,255))
    out.putdata(pixels)
    dark=[c for c in PALETTE if max(c)-min(c)<20 and max(c)<55]
    for y in range(max(0,target_heel-7),79):
        for x in range(80):
            c=out.getpixel((x,y))
            if c[3] and not out.getpixel((x,y+1))[3] and dark:
                shade=min(dark,key=lambda d:sum((d[k]-c[k])**2 for k in range(3)))
                out.putpixel((x,y),(*shade,255))
    return out,{'source_crown':crown,'source_heel':bounds[3],'target_crown':target_crown,'target_heel':target_heel,'height':target_heel-target_crown,'uniform_scale':scale,'translation':[tx,ty]}

def export():
    sheet=Image.new('RGBA',(640,240)); records=[]; complete=True
    previews=R/'previews'; previews.mkdir(exist_ok=True)
    for row,(name,count) in enumerate(SPECS):
        frames=[]; guide=Image.open(P/(name+'-guide.png')).convert('RGBA')
        comparison=Image.new('RGBA',(count*80,240),(80,80,80,255))
        for i in range(count):
            source=P/(name+f'-{i+1:02}-paint.png')
            if not source.exists(): complete=False; continue
            gf=guide.crop((i*80,0,i*80+80,80))
            frame,registration=register(clean(Image.open(source)),gf)
            sheet.paste(frame,(i*80,row*80)); frames.append(frame)
            gf=gf.transform((80,80),Image.Transform.AFFINE,(1/.9,0,40-40/.9,0,1/.9,72-72/.9),resample=N)
            comparison.alpha_composite(frame,(i*80,0))
            comparison.alpha_composite(gf,(i*80,80))
            comparison.alpha_composite(frame,(i*80,160))
            gf.putalpha(gf.getchannel('A').point(lambda a:round(a*.55)))
            comparison.alpha_composite(gf,(i*80,160))
            records.append({'animation':name,'frame':i+1,'source':source.name,'alpha_bounds':frame.getbbox(),'registration':registration,'sha256':hashlib.sha256(frame.tobytes()).hexdigest()})
        comparison.resize((comparison.width*3,720),N).save(previews/(name+'-guide-review.png'))
        if frames:
            loop=[]
            for f in frames:
                bg=Image.new('RGBA',(80,80),(96,97,92,255)); bg.alpha_composite(f)
                loop.append(bg.convert('RGB').resize((320,320),N))
            loop[0].save(previews/(name+'-guided.gif'),save_all=True,append_images=loop[1:],duration=140 if name.startswith('idle') else 100,loop=0)
    sheet.resize((1920,720),N).save(previews/'guided-contact-sheet.png')
    sheet.save(P/'camera-test-unscaled.png')
    if complete:
        sheet.save(R/'camera_test.png')
        normal_source=P/'camera-test-normal-master.png'
        if normal_source.exists():
            normals=Image.open(normal_source).convert('RGB').resize(sheet.size,N)
            normal_pixels=[]
            for c,d in zip(normals.get_flattened_data(),sheet.get_flattened_data()):
                if not d[3]:normal_pixels.append((0,0,0,0));continue
                v=[c[0]/127.5-1,c[1]/127.5-1,max(.15,c[2]/127.5-1)]
                length=math.sqrt(sum(a*a for a in v))
                normal_pixels.append(tuple(round(127.5*(a/length+1)) for a in v)+(255,))
            normal_map=Image.new('RGBA',sheet.size);normal_map.putdata(normal_pixels)
            normal_map.save(R/'camera_test_n.png')
    room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
    room_views=Image.new('RGBA',(576,192))
    for row in range(3):
        view=room.copy();view.alpha_composite(sheet.crop((0,row*80,80,row*80+80)),(112,152))
        room_views.paste(view.crop((64,96,256,288)),(row*192,0))
    room_views.resize((1152,384),N).save(previews/'guided-room-comparison.png')
    (P/'export-report.json').write_text(json.dumps({'complete':complete,'frame_count':len(records),'root':[40,72],'frame_size':[80,80],'records':records},indent=2)+'\n')
    print(json.dumps({'complete':complete,'frames':len(records)}))

if __name__=='__main__': export()
