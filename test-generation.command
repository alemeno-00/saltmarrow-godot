#!/bin/bash
set -eu
project_dir="$(cd "$(dirname "$0")" && pwd)"
for engine_path in "${GODOT_BIN:-}" "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" "/Applications/Godot.app/Contents/MacOS/Godot"; do
  if [ -n "$engine_path" ] && [ -x "$engine_path" ]; then
    exec "$engine_path" --path "$project_dir" res://scenes/generation_lab.tscn --resolution 1280x800
  fi
done
echo "Godot was not found. Set GODOT_BIN to its executable path."
read -r -p "Press Return to close. "
