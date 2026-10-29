# Thomas Wren

| File | Frame / canvas | Rows and frame counts | Facing |
| --- | --- | --- | --- |
| body.png | 64×64 / 384×512 | idle4; walk6; sneak6; hurt3; wounded walk6; dying crawl6; death6; careful step4 | Right |
| attack_mace.png | 64×64 / 512×256 | wind-up3; strike3; recovery3; critical overhead8 | Right |
| mace_abilities.png | 64×64 / 768×320 | Skull Crack8; Knee Breaker8; Shatter9; Wide Arc10; Execution12 | Right at start/end; full rotation during Wide Arc |

Root is (32,56) in every character frame; ground contact ends at pixel row y55. Frames run left to right, no gaps. Shorter rows have transparent trailing cells. Use only the listed populated counts, not the full sheet width. All PNGs have hard pixel edges and binary transparency; use nearest filtering and no mipmaps.

Body rows1–7 are unarmed. Row8 is a guarded careful step with the maul held across Thomas's body,4 frames,non-looping. Death is non-looping and holds its final frame. Suggested fps: idle4,walk8,sneak6,hurt10,wounded walk6,dying crawl5,death7,careful step6.

Both mace sheets contain the complete body and weapon; replace the body during an attack rather than overlaying a second Thomas. The maul is a heavy iron block head on a wooden haft,held in both hands. Suggested ordinary attack timing: wind-up6fps,strike12fps,recovery7fps,critical6fps. Each ability includes wind-up,strike and recovery. Execution frames5–7 are the raised hold for slow motion; exact phase splits are in production/abilities-v2/README.md.

Source art,export and review files:

- production/body-v2/: first seven body rows,generated masters,export source,validation and per-row GIF previews.
- production/careful-step/: eighth row,source and enlarged preview. Appending it leaves the first seven rows unchanged.
- production/mace-v1/: mace attack master,export,preview and validation; older rejected ability studies are retained for provenance.
- production/abilities-v2/: final47-frame ability sheet sources,export,validation,phase splits and GIF previews. This supersedes the mace-v1 ability candidate.
- production/animation-review/: rejected original body study; use body-v2 instead.

Approved standing-candidate.png and steady-portrait-candidate.png stay at their original production/sprites/ paths. No code changes are included. Claude owns animation selection,timing and contact placement in gameplay. The current contract remains right-facing; the eight-direction proposal is separate and delivers no runtime frames here.
