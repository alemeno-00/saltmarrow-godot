"""Nearest-neighbour review layouts of the final eight runtime walk frames."""
from pathlib import Path
from PIL import Image

P = Path(__file__).resolve().parent
ROOT = P.parents[5]
OUT = P / 'previews'
OUT.mkdir(exist_ok=True)
N = Image.Resampling.NEAREST
row = Image.open(P.parent / 'walk_s.png').convert('RGBA')
normal = Image.open(P.parent / 'walk_s_n.png').convert('RGBA')
guide = Image.open(ROOT / 'design/art-briefs/animation/walk-s/guide_walk_s.png').convert('RGBA')
for name, source in [('walk', row), ('normal', normal)]:
    board = Image.new('RGBA', (320, 160), (94, 97, 96, 255))
    for i in range(8):
        board.alpha_composite(source.crop((i*80, 0, (i+1)*80, 80)), ((i%4)*80, (i//4)*80))
    board.save(OUT / f'{name}-board-1x.png')
    board.resize((1280, 640), N).save(OUT / f'{name}-board-4x.png')
pair = Image.new('RGBA', (640, 160), (94, 97, 96, 255))
pair.alpha_composite(guide)
pair.alpha_composite(row, (0, 80))
pair.resize((1920, 480), N).save(OUT / 'guide-and-walk-3x.png')
room = Image.open(ROOT / 'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA')
native, crop, neutral = [], [], []
for i in range(8):
    frame = row.crop((i*80, 0, (i+1)*80, 80))
    floor = room.copy()
    floor.alpha_composite(frame, (152, 168))
    native.append(floor.convert('RGB'))
    crop.append(floor.crop((112, 144, 272, 272)).resize((640, 512), N).convert('RGB'))
    plain = Image.new('RGBA', (80, 80), (94, 97, 96, 255))
    plain.alpha_composite(frame)
    neutral.append(plain.resize((320, 320), N).convert('RGB'))
for name, frames in [('room-loop-1x', native), ('room-loop-4x-crop', crop), ('walk-loop-4x', neutral)]:
    # Global GIF palette keeps the room stable; no inter-frame colour drift.
    atlas = Image.new('RGB', (frames[0].width * 8, frames[0].height))
    for i, frame in enumerate(frames):
        atlas.paste(frame, (i * frame.width, 0))
    palette = atlas.quantize(colors=256, dither=Image.Dither.NONE)
    indexed = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    indexed[0].save(OUT / f'{name}.gif', save_all=True, append_images=indexed[1:], duration=100, loop=0, disposal=2, optimize=False)
native[0].save(OUT / 'room-first-frame-1x.png')
crop[0].save(OUT / 'room-first-frame-4x-crop.png')
print('Eight-frame boards and 10fps mechanical room composites exported.')
