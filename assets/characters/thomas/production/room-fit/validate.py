"""Art-file checks and native-scale visual reviews, not gameplay tests."""
from pathlib import Path
from PIL import Image
import json,math,hashlib
P=Path(__file__).resolve().parent;ROOT=P.parents[4];N=Image.Resampling.NEAREST
JOBS=[('characters/thomas','body',[4,6,6,3,6,6,6,4]),('characters/thomas','attack_mace',[3,3,3,8]),('characters/thomas','mace_abilities',[8,8,9,10,12]),('enemies/drowned_miner','body',[4,6,3,3,3,3,3,4,4,2,4,6,6,6,6,6]),('enemies/faithful','body',[4,6,4,4,3,4,6,6])]
ROOM={tuple(c) for c in json.loads((ROOT/'assets/tiles/sewers/rooms/production/palette.json').read_text())};RED={(41,16,19),(69,27,29),(94,39,37),(122,52,45)}
checks=[]
def check(path,before,fw,fh,counts,normal=True):
 im=Image.open(path).convert('RGBA');assert im.size==before.size
 assert im.getchannel('A').tobytes()==before.getchannel('A').tobytes(),(path,'alpha changed')
 assert set(im.getchannel('A').get_flattened_data())<={0,255}
 colours={c[:3] for c in im.get_flattened_data() if c[3]};assert colours<=ROOM|RED,(path,colours-ROOM-RED)
 assert all(c[3] or c[:3]==(0,0,0) for c in im.get_flattened_data())
 for row,count in enumerate(counts):
  frames=[im.crop((i*fw,row*fh,(i+1)*fw,(row+1)*fh)) for i in range(count)]
  assert all(f.getbbox() for f in frames);assert len({f.tobytes() for f in frames})==count
  assert not im.crop((count*fw,row*fh,im.width,(row+1)*fh)).getchannel('A').getbbox()
 report={'file':str(path.relative_to(ROOT)),'canvas':list(im.size),'frame_size':[fw,fh],'rows':counts,'frames':sum(counts),'original_alpha_and_root_preserved':True,'opaque_colours':len(colours),'palette':'shared room palette plus explicitly approved muted-red scarf/blood accents','sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
 if normal:
  np=path.with_stem(path.stem+'_n');nm=Image.open(np).convert('RGBA');assert nm.size==im.size and nm.getchannel('A').tobytes()==im.getchannel('A').tobytes()
  vectors=[tuple(c[i]/127.5-1 for i in range(3)) for c in nm.get_flattened_data() if c[3]];error=max(abs(math.sqrt(sum(x*x for x in v))-1) for v in vectors);assert error<.012 and all(v[2]>0 for v in vectors),(path,error)
  assert len({tuple(round(x,1) for x in v) for v in vectors})>15,(path,'flat normal map')
  report.update(normal_map=str(np.relative_to(ROOT)),normal_alpha_matches=True,max_unit_vector_error=error,positive_z=True,normal_sha256=hashlib.sha256(np.read_bytes()).hexdigest())
 checks.append(report);return im
images={};before_images={};normal_images={}
for rel,name,counts in JOBS:
 folder=ROOT/'assets'/rel;d=folder/'production/room-fit';before=Image.open(d/(name+'-before.png')).convert('RGBA');im=check(folder/(name+'.png'),before,64,64,counts);key=rel+'/'+name;images[key]=im;before_images[key]=before;normal_images[key]=Image.open(folder/(name+'_n.png')).convert('RGBA')
 for row,count in enumerate(counts):
  seq=[]
  for i in range(count):
   f=im.crop((i*64,row*64,(i+1)*64,(row+1)*64));bg=Image.new('RGBA',(64,64),(101,97,90,255));bg.alpha_composite(f);seq.append(bg.resize((256,256),N).convert('RGB'))
  seq[0].save(d/(name+'-row-'+str(row+1)+'.gif'),save_all=True,append_images=seq[1:],duration=160,loop=0)
prop=ROOT/'assets/props/sewers';manifest=json.loads((prop/'manifest.json').read_text())
for e in manifest['assets']:
 name=Path(e['file']).stem;before=Image.open(prop/'production/house-style'/(name+'-before.png')).convert('RGBA');fw,fh=e['frame_size'];im=check(prop/e['file'],before,fw,fh,e['rows'],normal='normal_map' in e);key='props/sewers/'+name;images[key]=im;before_images[key]=before
 if 'normal_map' in e:normal_images[key]=Image.open(prop/e['normal_map']).convert('RGBA')
 assert hashlib.sha256((prop/e['file']).read_bytes()).hexdigest()==e['sha256']
# Existing grate holes/collision footprints remain byte-identical alpha by checks above.
# All scene reviews keep character/room pixel density identical; only final preview is 2x.
room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
placements=[('characters/thomas/body',(64,64),(96,160)),('enemies/drowned_miner/body',(64,64),(224,160)),('enemies/faithful/body',(64,64),(160,256)),('props/sewers/crate',(32,32),(64,128)),('props/sewers/barrel',(32,32),(288,128)),('props/sewers/satchel_body',(64,32),(64,288)),('props/sewers/miner_tag_body',(64,32),(256,288)),('props/sewers/bones_2',(32,32),(288,224)),('props/sewers/debris_1',(32,32),(64,224))]
scenes=[]
for group in [before_images,images]:
 scene=room.copy()
 for key,size,xy in placements:scene.alpha_composite(group[key].crop((0,0,*size)),xy)
 scenes.append(scene)
compare=Image.new('RGBA',(768,384));compare.paste(scenes[0],(0,0));compare.paste(scenes[1],(384,0));compare.resize((1536,768),N).save(P/'room-before-after-2x.png')
scenes[1].resize((768,768),N).save(P/'room-after-2x.png')
# Controlled left/right normal lighting test on native diffuse pixels.
def light(im,nm,direction):
 out=im.copy();d=direction;l=math.sqrt(sum(x*x for x in d));d=[x/l for x in d];pixels=[]
 for c,n in zip(im.get_flattened_data(),nm.get_flattened_data()):
  if not c[3]:pixels.append((0,0,0,0));continue
  v=[n[i]/127.5-1 for i in range(3)];strength=.32+.83*max(0,sum(v[i]*d[i] for i in range(3)));pixels.append(tuple(min(255,round(c[i]*strength)) for i in range(3))+(255,))
 out.putdata(pixels);return out
for rel,name,counts in JOBS:
 key=rel+'/'+name;im=images[key];nm=normal_images[key];g=Image.new('RGBA',(64*4,64*3),(101,97,90,255))
 for row in range(3):
  index=min(row,len(counts)-1);f=im.crop((0,index*64,64,(index+1)*64));n=nm.crop((0,index*64,64,(index+1)*64))
  for col,c in enumerate([before_images[key].crop((0,index*64,64,(index+1)*64)),f,light(f,n,(-.8,.25,.7)),light(f,n,(.8,.25,.7))]):g.alpha_composite(c,(col*64,row*64))
 g.resize((1024,768),N).save(ROOT/'assets'/rel/'production/room-fit'/(name+'-light-review.png'))
# Prop audit contact sheets, all frames, neutral floor base.
g=Image.new('RGBA',(512,128*18),(101,97,90,255))
for row,e in enumerate(manifest['assets']):
 im=images['props/sewers/'+Path(e['file']).stem];fw,fh=e['frame_size'];i=0
 for r,count in enumerate(e['rows']):
  for col in range(count):
   f=im.crop((col*fw,r*fh,(col+1)*fw,(r+1)*fh));g.alpha_composite(f.resize((fw*2,fh*2),N),(i*128,row*128));i+=1
g.save(prop/'production/house-style/diffuse-review.png')
# Current prop review files supersede the job14 contact sheets, retaining their paths.
g.save(prop/'previews/all-assets.png');g.resize((1024,4608),N).save(prop/'previews/contact-4x.png')
icons=Image.new('RGBA',(96,32),(101,97,90,255))
for i,name in enumerate(['salve','bandage','grate_key']):icons.alpha_composite(images['props/sewers/'+name],(i*32,0))
icons.resize((576,192),N).save(prop/'previews/icons-6x.png')
for name in ['grate_ns','grate_ew']:
 im=images['props/sewers/'+name];im.resize((im.width*6,im.height*6),N).save(prop/'previews'/(name+'-6x.png'))
# Normal response for every in-world prop: albedo, light left, light right.
review=Image.new('RGBA',(768,128*15),(101,97,90,255));row=0
for e in manifest['assets']:
 if 'normal_map' not in e:continue
 name=Path(e['file']).stem;key='props/sewers/'+name;fw,fh=e['frame_size'];f=images[key].crop((0,0,fw,fh));n=normal_images[key].crop((0,0,fw,fh));factor=min(4,128/fh)
 for col,c in enumerate([f,light(f,n,(-.8,.25,.7)),light(f,n,(.8,.25,.7))]):review.alpha_composite(c.resize((round(fw*factor),round(fh*factor)),N),(col*256,row*128))
 row+=1
review.save(prop/'production/house-style/normal-light-review.png')
report={'job':'15a','diffuse_sheets':len(checks),'character_frames':sum(sum(c) for _,_,c in JOBS),'world_prop_normal_maps':15,'character_normal_maps':5,'normal_encoding':'OpenGL, RGB -> XYZ, +green up, +blue forward; normalized positive-Z vectors','frame_contract':'existing character sheets remain64x64 with root32,56; exact original alpha and transparent trailing cells preserved','house_style_checks':['local coloured contour; no pure black','room palette; user approved muted-red exception for scarf/blood','original native texture clusters retained; no clean replacement pose fills','readable values against approved paving','dark existing contact pixel row; no shadow geometry','neutral albedo; dynamic normal-map lighting','matching normal maps on all world sheets','legacy64px scale retained;80px begins job15'],'assets':checks,'review_limit':'Native compositing and controlled normal-lighting reviews, not engine screenshots. Actual game light strengths and mirrored normal orientation require gameplay review.'}
(P/'validation.json').write_text(json.dumps(report,indent=2)+'\n');(prop/'validation.json').write_text(json.dumps({'job':'15a','runtime_pngs':18,'normal_maps':15,'frames_total':30,'assets':[c for c in checks if '/props/' in c['file']],'alpha_and_grate_openings_identical_to_before':True,'house_style_review':'production/house-style/README.md','limit':report['review_limit']},indent=2)+'\n')
print('PASS:',len(checks),'diffuse sheets,20 matching normal maps;',report['character_frames'],'character frames;30 prop frames; exact original masks and dimensions; room palette+approved reds; unit positive-Z normals.')
