# Portrait source record

| File | Frame / canvas | Rows and counts |
| --- | --- | --- |
| hurt-master.png | 1280×1280 generated source | 1 portrait |
| badly_hurt-master.png | 1280×1280 generated source | 1 portrait |
| dying-master.png | 1280×1280 generated source | 1 portrait |
| comparison-3x.png | 384×384 preview cells,1536×384 canvas | 1 row: steady,hurt,badly hurt,dying |

Built-in imagegen identity-preserving edits. Every edit uses assets/characters/thomas/production/sprites/steady-portrait-candidate.png as its target. Prompt common constraints: preserve long hollow face, head silhouette,nose,old cheek scar,short brown hair,stubble,red scarf,greatcoat,chest-up three-quarter right pose; same dark hard pixel art lighting; no text/frame/new objects; transparent silhouette. Change only injury state.

Hurt prompt: small dark-red lower-lip cut, visible cheek bruise, slightly pained watchful brow. Badly hurt: drained pale face,clenched jaw,brow cut bleeding dark red down temple,split lip,bruising,still conscious. Dying: ashen grey skin,half-shut eyes,slack mouth,dark-red dried brow and lip blood,exhaustion,no scream.

Final files: nearest128×128,31-colour quantization without dithering,alpha threshold128,clear hidden RGB. Checks: all four128×128,binary alpha0/255; steady identical to approved source; side-by-side enlarged visual review. All face right.
