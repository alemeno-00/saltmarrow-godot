from pathlib import Path
from PIL import Image
import json,hashlib
P=Path(__file__).resolve().parent;A=P.parent/'15w-step-a';row=Image.new('RGBA',(2560,320));approval=json.loads((P/'approval.json').read_text())
for n in range(1,9):
 if n%2:
  f=A/f'key-{n:02d}-1x.png';assert hashlib.sha256(f.read_bytes()).hexdigest()==approval['key_sha256'][str(n)];frame=Image.open(f).convert('RGBA').resize((320,320),Image.Resampling.NEAREST)
 else:frame=Image.open(P/f'frame-{n:02d}-4x.png').convert('RGBA')
 row.paste(frame,((n-1)*320,0))
row.save(P.parent/'walk_s_4x.png')
