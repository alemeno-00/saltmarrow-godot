#!/bin/bash
set -eu
project_dir="$(cd "$(dirname "$0")" && pwd)"
for engine_path in "${GODOT_BIN:-}" "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" "/Applications/Godot.app/Contents/MacOS/Godot"; do
  if [ -n "$engine_path" ] && [ -x "$engine_path" ]; then
    exec "$engine_path" --path "$project_dir" res://scenes/sewer_fight.tscn --resolution 1280x720
  fi
done
echo "Godot was not found. Install Godot, or set GODOT_BIN to its executable path."
read -r -p "Press Return to close. "
