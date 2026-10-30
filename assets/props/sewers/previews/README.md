# Sewer contents previews

Review artifacts only; `.gdignore` keeps them out of imports. Every PNG is one static review image, one row/one frame, except the grate enlargements which visibly retain the runtime sheet’s two rows. No preview background is baked into runtime sprites.

| File | Canvas / frames | Purpose |
| --- | --- | --- |
| `all-assets.png` | 512×2304, 1 frame(s) | Nearest-sampled art review |
| `body-before-after-room.png` | 1536×768, 1 frame | Same room and placements; original left, revised right |
| `body-before-after-closeup.png` | 768×512, 1 frame | Before left, revised right; satchel top, tally body bottom |
| `barrel.gif` | 128×128, 2 frame(s) | State/turn animation preview |
| `contact-4x.png` | 1024×4608, 1 frame(s) | Nearest-sampled art review |
| `crate.gif` | 128×128, 2 frame(s) | State/turn animation preview |
| `grate_ew-6x.png` | 384×768, 1 frame(s) | Nearest-sampled art review |
| `grate_ew.gif` | 128×256, 4 frame(s) | State/turn animation preview |
| `grate_ns-6x.png` | 768×384, 1 frame(s) | Nearest-sampled art review |
| `grate_ns.gif` | 256×128, 4 frame(s) | State/turn animation preview |
| `icons-6x.png` | 576×192, 1 frame(s) | Nearest-sampled art review |
| `room-placement-2x.png` | 768×768, 1 frame(s) | Nearest-sampled art review |
| `satchel_body.gif` | 256×128, 2 frame(s) | State/turn animation preview |
| `valve.gif` | 128×128, 4 frame(s) | State/turn animation preview |

`contact-4x.png` uses one file per row, flattening its frames left to right in manifest order. Tall grate frames are shown at 2× to fit their review row; other frames are 4×. `all-assets.png` is the smaller initial gallery. `gallery-order.json` lists the same order.

`room-placement-2x.png` composites actual exported props over the approved crossing for size/readability review. It is not gameplay placement logic, collision or an engine-lighting test. Caches and grates repeat in the GIFs only to make their states easy to inspect.

Job15a updates the native diffuse contact sheets and icon/grate enlargements here. Its current room before/after and light response reviews are in `assets/characters/thomas/production/room-fit/` and `../production/house-style/`. Earlier body-before/after images and GIFs here remain historical job14 state reviews. `all-assets.png` and `contact-4x.png` now reserve128 native review pixels per file row, so tall grate frames are not clipped.
