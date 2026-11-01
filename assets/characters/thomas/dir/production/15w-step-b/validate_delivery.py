"""Content/provenance checks; run after the unchanged Godot shrink/check tools."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import math
import subprocess

P = Path(__file__).resolve().parent
ROOT = P.parents[5]
A = P.parent / '15w-step-a'
approval = json.loads((P / 'approval.json').read_text())
load = lambda p: Image.open(p).convert('RGBA')
pixels = lambda im: list(im.get_flattened_data())
mask = lambda im: {(x, y) for y in range(im.height) for x in range(im.width) if im.getpixel((x, y))[3]}
near = lambda p, m: any((p[0]+dx, p[1]+dy) in m for dx in (-1, 0, 1) for dy in (-1, 0, 1))
sheet = load(P.parent.parent / 's.png')
normal = load(P.parent.parent / 's_n.png')
assert sheet.size == normal.size == (640, 160)
assert sheet.getchannel('A').tobytes() == normal.getchannel('A').tobytes()
assert set(sheet.getchannel('A').get_flattened_data()) == {0, 255}
for suffix, runtime in [('', sheet), ('_n', normal)]:
    model = load(ROOT / f'assets/characters/thomas/rig/production/model-s{suffix}.png')
    palette = {c[:3] for c in pixels(model) if c[3]}
    assert all(c[:3] in palette for c in pixels(runtime) if c[3])
    for i in range(6):
        assert runtime.crop((i*80, 0, (i+1)*80, 80)).tobytes() == model.tobytes()
    assert not runtime.crop((480, 0, 640, 80)).getbbox()
    assert load(P.parent / f'walk_s{suffix}_4x.png').size == (2560, 320)
    row = load(P.parent / f'walk_s{suffix}.png')
    assert row.size == (640, 80)
    assert runtime.crop((0, 80, 640, 160)).tobytes() == row.tobytes()

records = []
guides = load(ROOT / 'design/art-briefs/animation/walk-s/guide_walk_s.png')
for i in range(8):
    n = i + 1
    frame = sheet.crop((i*80, 80, (i+1)*80, 160))
    guide = guides.crop((i*80, 0, (i+1)*80, 80))
    if n % 2:
        key = A / f'key-{n:02d}-1x.png'
        assert hashlib.sha256(key.read_bytes()).hexdigest() == approval['key_sha256'][str(n)]
        assert frame.tobytes() == load(key).tobytes()
    assert frame.crop((0, 0, 80, 32)).tobytes() == guide.crop((0, 0, 80, 32)).tobytes()
    assert frame.crop((0, 67, 80, 80)).tobytes() == guide.crop((0, 67, 80, 80)).tobytes()
    a, b = mask(frame), mask(guide)
    assert all(near(p, b) for p in a) and all(near(p, a) for p in b)
    todo, components = set(a), []
    while todo:
        stack = [todo.pop()]
        component = []
        while stack:
            x, y = stack.pop()
            component.append((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x+dx, y+dy)
                    if q in todo:
                        todo.remove(q)
                        stack.append(q)
        components.append(component)
    components.sort(key=len, reverse=True)
    records.append({'frame': n, 'outline_iou': len(a & b)/len(a | b),
                    'guide_envelope_px': 1, 'head_and_boot_regions': 'exact own guide',
                    'approved_key_unchanged': n % 2 == 1,
                    'connected_component_sizes': [len(c) for c in components],
                    'minor_components': components[1:]})
lengths = []
for c in pixels(normal):
    if c[3]:
        v = [2*x/255-1 for x in c[:3]]
        assert v[2] > 0
        lengths.append(math.sqrt(sum(x*x for x in v)))
assert max(abs(x-1) for x in lengths) < 0.012
protected = ['assets/characters/thomas/rig/production/model-s.png',
             'assets/characters/thomas/rig/production/model-s_n.png',
             'assets/characters/thomas/rig/s.png', 'assets/characters/thomas/rig/s_n.png',
             'assets/characters/thomas/production/sprites/standing-candidate.png',
             'assets/characters/thomas/production/sprites/steady-portrait-candidate.png',
             'assets/characters/thomas/production/concepts/canonical-reference-v1.png']
for path in protected:
    assert (ROOT/path).read_bytes() == subprocess.check_output(['git', 'show', 'origin/main:'+path], cwd=ROOT)
check = (P/'guide-check.txt').read_text()
assert check.strip().endswith('PASS') and check.count('head 100% his own') == 8
report = {'job': '15-W', 'status': 'DELIVERED; IN-GAME REVIEW PENDING',
          'step_a_approval': approval, 'runtime_size': [640,160], 'painting_row_size': [2560,320],
          'idle': '6 exact model copies + 2 transparent cells', 'walk': '8 frames, 10fps',
          'alpha': 'binary, diffuse and normal identical', 'palette': 'approved model diffuse/normal only',
          'normal_vector_length_range': [min(lengths),max(lengths)],
          'frames': records, 'upstream_checker': 'PASS, all 8 actual delivered frames',
          'protected_files_unchanged': protected,
          'wiring': 'Claude: prefer painted south idle/walk over rig; do not use missing rows 3-5'}
(P/'validation.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps({'checker': 'PASS', 'approved_keys': 'unchanged',
                  'alpha_and_palettes': 'PASS', 'normal_lengths': report['normal_vector_length_range'],
                  'component_sizes': [r['connected_component_sizes'] for r in records]}))
