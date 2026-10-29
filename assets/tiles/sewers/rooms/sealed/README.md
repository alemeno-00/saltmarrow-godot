# Unused doorway seals

Plain masonry overlays. Each is one static frame, one row; PNG RGBA, binary alpha, at most 32 colours. Top-left origin (0,0). No animation.

| File | Frame/canvas | Appearance |
| --- | --- | --- |
| `north.png` | 64×64 | Two-square-tall north brick face |
| `south.png` | 64×32 | Wall top |
| `west.png` | 32×64 | Wall top |
| `east.png` | 32×64 | Wall top |

Place exactly over the corresponding unused room doorway rectangle listed in each layout README. Use authored direction, nearest filtering. These are plain crops of generated masonry from the room kit, using its shared palette, not newly invented game geometry. Claude should review wall courses in gameplay; the sealed-room preview shows the visual result on the crossing. Gameplay already decides which doors are blocked.
