"""Assemble supplied-tool-shrunk rows; no painting or pose changes."""
from pathlib import Path
from PIL import Image

P = Path(__file__).resolve().parent
ROOT = P.parents[5]
for suffix in ('', '_n'):
    model = Image.open(ROOT / f'assets/characters/thomas/rig/production/model-s{suffix}.png').convert('RGBA')
    walk = Image.open(P.parent / f'walk_s{suffix}.png').convert('RGBA')
    assert model.size == (80, 80) and walk.size == (640, 80)
    sheet = Image.new('RGBA', (640, 160))
    for i in range(6):
        sheet.paste(model, (i * 80, 0))
    sheet.paste(walk, (0, 80))
    sheet.save(P.parent.parent / f's{suffix}.png')
print('Runtime diffuse and normal sheets assembled, 640x160.')
