"""Rebuild generated-source exports, manifests and native atlases. Requires Pillow."""
from pathlib import Path
import subprocess,sys
folder=Path(__file__).resolve().parent
for name in ['deep_export.py','layers_export.py','verify.py']:
 subprocess.run([sys.executable,str(folder/name)],check=True)
