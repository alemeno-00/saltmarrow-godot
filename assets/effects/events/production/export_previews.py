"""Review composites only, using exported runtime pixels and existing room pixels."""
from pathlib import Path
from PIL import Image
P=Path(__file__).resolve().parent;R=P.parent;ROOT=P.parents[3];O=P/'previews';N=Image.Resampling.NEAREST
watcher=Image.open(R/'watcher.png').convert('RGBA');normal=Image.open(R/'watcher_n.png').convert('RGBA');frost=Image.open(R/'star_frost.png').convert('RGBA');fn=Image.open(R/'star_frost_n.png').convert('RGBA')
watcher.resize((640,640),N).save(O/'watcher-8x.png');normal.resize((640,640),N).save(O/'watcher-normal-8x.png');frost.resize((1536,256),N).save(O/'frost-strip-8x.png');fn.resize((1536,256),N).save(O/'frost-normal-strip-8x.png')
thomas=Image.open(ROOT/'assets/characters/thomas/rig/production/model-s.png').convert('RGBA');pair=Image.new('RGBA',(160,80),(94,97,96,255));pair.alpha_composite(thomas,(0,0));pair.alpha_composite(watcher,(80,0));pair.save(O/'scale-1x.png');pair.resize((960,480),N).save(O/'scale-6x.png')
room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
def composite(opacity):
 scene=room.copy();scene.alpha_composite(thomas,(80,152));ghost=watcher.copy();ghost.putalpha(ghost.getchannel('A').point(lambda a:round(a*opacity)));scene.alpha_composite(ghost,(208,144))
 for i in range(6):scene.alpha_composite(frost.crop((i*32,0,(i+1)*32,32)),(144+(i%3)*32,256+(i//3)*32))
 return scene
full=composite(1);subtle=composite(.42);full.save(O/'room-full-1x.png');subtle.save(O/'room-subtle-1x.png');subtle.resize((1152,1152),N).save(O/'room-subtle-3x.png')
# Repeated patches sit on a real96x96 floor crop; each panel repeats only its own patch3x3.
floor=room.crop((144,128,240,224));repeat=Image.new('RGBA',(288,192))
for i in range(6):
 panel=floor.copy();tile=frost.crop((i*32,0,(i+1)*32,32))
 for y in range(3):
  for x in range(3):panel.alpha_composite(tile,(x*32,y*32))
 repeat.paste(panel,((i%3)*96,(i//3)*96))
repeat.resize((1152,768),N).save(O/'frost-repeat-4x.png')
# Mechanical watcher fade only; existing code's timing and42% maximum opacity, not in-game rendering.
frames=[]
for i in range(30):
 t=i*.05;a=min(t/.35,1) if t<=1.25 else max(0,1-(t-1.25)/.25)
 frames.append(composite(.42*a).convert('RGB'))
frames[0].save(O/'watcher-fade-1x.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2)
print('Exported native room, scale comparison, fade and six3x3 repetition panels.')
