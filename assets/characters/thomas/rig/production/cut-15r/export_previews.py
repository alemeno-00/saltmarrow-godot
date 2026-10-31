"""Nearest-neighbour review layouts from Godot-rendered frames; no painting."""
from pathlib import Path
from PIL import Image
P=Path(__file__).resolve().parent;O=P/'previews';ROOT=P.parents[5];N=Image.Resampling.NEAREST
bind=Image.open(O/'bind.png').convert('RGBA');model=Image.open(P.parent/'model-s.png').convert('RGBA');assert bind.tobytes()==model.tobytes()
bind.resize((640,640),N).save(O/'bind-8x.png')
pair=Image.new('RGBA',(160,80),(94,97,96,255));pair.alpha_composite(model,(0,0));pair.alpha_composite(bind,(80,0));pair.resize((960,480),N).save(O/'model-and-bind-6x.png')
room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
for mode in ('idle','walk','sneak','limp'):
 strip=Image.open(O/(mode+'-16.png')).convert('RGBA');frames=[strip.crop((i*80,0,(i+1)*80,80)) for i in range(16)]
 board=Image.new('RGBA',(320,160),(94,97,96,255))
 for j in range(8):board.alpha_composite(frames[j*2],((j%4)*80,(j//4)*80))
 board.resize((1280,640),N).save(O/(mode+'-8frames-4x.png'))
 scenes=[]
 for frame in frames:
  floor=room.copy();floor.alpha_composite(frame,(112,152));scenes.append(floor.crop((64,96,256,288)).resize((576,576),N).convert('RGB'))
 scenes[0].save(O/(mode+'-floor-3x.gif'),save_all=True,append_images=scenes[1:],loop=0,duration=150 if mode=='idle' else 50 if mode=='walk' else [60,70]*8 if mode=='limp' else 80,disposal=2)
print('Exported exact bind comparison, eight-frame boards and four16-sample floor loops.')
transition=Image.open(O/'start-walk-stop-60.png').convert('RGBA');scenes=[]
for i in range(60):
 frame=transition.crop((i*80,0,(i+1)*80,80));floor=room.copy();floor.alpha_composite(frame,(112,152));scenes.append(floor.crop((64,96,256,288)).resize((576,576),N).convert('RGB'))
scenes[0].save(O/'start-walk-stop-floor-3x.gif',save_all=True,append_images=scenes[1:],loop=0,duration=[60,70,70]*20,disposal=2)
