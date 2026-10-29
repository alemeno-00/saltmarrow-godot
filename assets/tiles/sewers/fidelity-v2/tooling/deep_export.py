from pathlib import Path
exec((Path(__file__).resolve().parent / 'base_export.py').read_text())
from PIL import ImageDraw
source=clean(Image.open(ROOT/'source/deep-masonry.png'))
strip=source.crop((30,110,1505,365)).resize((384,66),Image.Resampling.NEAREST)
deep=[]
for i in range(3):
    wall=Image.new('RGBA',(128,128))
    wall.alpha_composite(strip.crop((i*128,0,i*128+128,18)),(0,0))
    for course in range(3):
        other=(i+course)%3
        wall.alpha_composite(strip.crop((other*128,19,other*128+128,43)),(0,18+course*24))
    wall.alpha_composite(strip.crop((i*128,28,i*128+128,66)),(0,90))
    # Shared vertical profile maintains matching cap and mortar endpoints.
    if i==0:edge=wall.crop((1,0,2,128))
    wall.paste(edge,(0,0));wall.paste(edge,(127,0))
    deep.append(save(f'deep_wall_{i}',wall,'masonry'))
old=clean(Image.open(ROOT/'source/masonry.png'))
pillar=Image.open(ROOT/'masonry/pier.png').convert('RGBA')
tall=Image.new('RGBA',(32,128));tall.alpha_composite(pillar.crop((0,0,32,16)))
for row in range(4):tall.alpha_composite(pillar.crop((0,16,32,40)),(0,16+row*24))
tall.alpha_composite(pillar.crop((0,48,32,64)),(0,112))
save('deep_pier',tall,'masonry')
bank=Image.new('RGBA',(32,16))
bank.alpha_composite(Image.open(ROOT/'masonry/wall_0.png').convert('RGBA').crop((0,0,64,20)).resize((32,8),Image.Resampling.NEAREST))
bank.alpha_composite(deep[0].crop((0,24,32,32)),(0,8))
save('bank_n',bank,'masonry')
pipe=source.crop((878,465,977,869)).resize((32,128),Image.Resampling.NEAREST)
save('deep_pipe',pipe,'masonry')
surface=Image.open(ROOT/'source/surfaces.png').convert('RGBA')
common=None
for i in range(4):
    w,h=surface.size
    a=surface.crop((round(i*w/4)+3,round(3*h/4)+3,round((i+1)*w/4)-3,h-3)).resize((64,64),Image.Resampling.NEAREST)
    a=seam(clean(a),common);common=common or a
    save(f'water_big_{i}',a,'terrain')
arch=old.crop((505,455,881,810));arch=arch.crop(arch.getbbox()).resize((96,128),Image.Resampling.NEAREST)
integrated=deep[1].copy();integrated.alpha_composite(arch,(32,0))
cut=ImageDraw.Draw(integrated)
cut.polygon([(56,128),(56,65),(61,48),(70,36),(80,32),(90,36),(99,48),(104,65),(104,128)],fill=(0,0,0,0))
save('deep_arch',integrated,'masonry')
actor_source=clean(Image.open(ROOT/'source/actors.png'))
w,h=actor_source.size
for name,left,right in [('thomas',0,0.395),('miner',0.40,0.69),('faithful',0.72,1.0)]:
    ob=actor_source.crop((round(w*left),0,round(w*right),h));ob=ob.crop(ob.getbbox())
    height=48;width=round(ob.width*height/ob.height)
    ob=ob.resize((width,height),Image.Resampling.NEAREST)
    feet=ob.getchannel('A').crop((0,45,width,48)).getbbox()
    foot_center=(feet[0]+feet[2])/2
    left=round(32-foot_center)
    assert 0<=left and left+width<=64,(name,'weapon exceeds frame after feet registration')
    canvas=Image.new('RGBA',(64,64));canvas.alpha_composite(ob,(left,8))
    path=ROOT/'actors'/(name+'.png');canvas=clean(canvas);canvas.save(path)
    entries.append(dict(id=name,file='actors/'+name+'.png',size=[64,64],origin=[32,56],frames=1,facing='right',status='static review pose, not animation',sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
props=clean(Image.open(ROOT/'source/props.png'))
w,h=props.size
for name,left,right,canvas,height in [('bridge',0,0.39,(64,160),142),('drain',0.40,0.69,(64,64),64),('torch',0.73,1.0,(32,48),32)]:
    ob=props.crop((round(left*w),0,round(right*w),h));ob=ob.crop(ob.getbbox())
    width=round(ob.width*height/ob.height)
    if width>canvas[0]:width=canvas[0];height=round(ob.height*width/ob.width)
    ob=ob.resize((width,height),Image.Resampling.NEAREST)
    im=Image.new('RGBA',canvas);im.alpha_composite(ob,((canvas[0]-width)//2,(canvas[1]-height)//2 if name!='torch' else canvas[1]-height))
    path=ROOT/'props'/(name+'.png');im=clean(im);im.save(path)
    entries.append(dict(id=name,file='props/'+name+'.png',size=list(canvas),origin=[canvas[0]//2,canvas[1]],sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(ROOT/'manifest.json').write_text(json.dumps(dict(status='unapproved visual revision',grid=32,provenance='New generated families, mechanical nearest-neighbour registration and hard-alpha cleanup; tall walls assembled from generated brick courses without vertically stretching their pixels; not original concept cutouts.',assets=entries),indent=2)+'\n')
print('Exported',len(entries),'assets, including deep walls and static figures')
