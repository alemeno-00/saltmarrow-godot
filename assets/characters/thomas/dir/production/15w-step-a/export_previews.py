"""Review layouts of only keys1,3,5,7; no in-betweens or animation synthesis."""
from pathlib import Path
from PIL import Image
P=Path(__file__).resolve().parent;ROOT=P.parents[5];N=Image.Resampling.NEAREST;O=P/'previews'
row=Image.open(P/'keys-1x.png').convert('RGBA');guide=Image.open(ROOT/'design/art-briefs/animation/walk-s/guide_walk_s.png').convert('RGBA');model=Image.open(ROOT/'assets/characters/thomas/rig/production/model-s.png').convert('RGBA')
board=Image.new('RGBA',row.size,(94,97,96,255));board.alpha_composite(row);board.save(O/'keys-1x.png');board.resize((1280,320),N).save(O/'keys-4x.png');board.resize((1920,480),N).save(O/'keys-6x.png')
pair=Image.new('RGBA',(320,160),(94,97,96,255))
for j,n in enumerate((1,3,5,7)):pair.alpha_composite(guide.crop(((n-1)*80,0,n*80,80)),(j*80,0))
pair.alpha_composite(row,(0,80));pair.resize((1280,640),N).save(O/'guide-and-keys-4x.png')
room=Image.open(ROOT/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
for j,n in enumerate((1,3,5,7)):room.alpha_composite(row.crop((j*80,0,(j+1)*80,80)),(56+j*64,160))
room.save(O/'room-keys-1x.png');room.resize((1152,1152),N).save(O/'room-keys-3x.png')
for j,n in enumerate((1,3,5,7)):
 Image.open(P/f'key-{n:02d}-1x.png').resize((320,320),N).save(P/f'key-{n:02d}-palette-4x.png')
square=Image.new('RGBA',(160,160),(94,97,96,255))
for j in range(4):square.alpha_composite(row.crop((j*80,0,(j+1)*80,80)),((j%2)*80,(j//2)*80))
square.resize((960,960),N).save(O/'keys-2x2-6x.png')
print('Four-key static review exported; no complete walk loop or runtime sheet created.')
