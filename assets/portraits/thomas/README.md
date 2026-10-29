# Thomas health portraits

All files are single-frame transparent128×128 PNGs, chest up, three-quarters right. Each has one row and one frame. Hard pixel edges, binary alpha, no smoothing. The game should select a state, not animate between files.

| File | State |
| --- | --- |
| steady.png | Exact byte-for-byte copy of the approved steady-portrait-candidate.png |
| hurt.png | Cut lower lip, bruised cheek, watchful pain |
| badly_hurt.png | Brow wound, dark-red blood, bruising, pale face and tense jaw |
| dying.png | Grey ashen skin, half-shut eyes, slack mouth, dark-red wounds |

The three injury states were edited separately from the same approved steady portrait with the built-in imagegen tool; nearest-neighbour128×128 export and31-colour reduction without dithering. The original approved files are unchanged. Face, hair, scarf and greatcoat match the same man; expression and wounds change with health. Claude can switch to these paths by health state; no code changes included.

`production/` retains generated source canvases, a comparison preview and the exact prompt set description.
