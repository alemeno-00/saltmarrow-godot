# Blood decal production

blood-master.png:1536×1024 variable-gutter source,three rows of three abstract stains. decals-6x.png:576×576 preview,192×192 cells,same static layout as blood_decals.png. export.py:mechanical export source; run from repository root. .gdignore excludes sources from runtime import.

Built-in imagegen prompt: nine non-graphic dark oxblood liquid stains,three pool sizes,four distinct splash shapes,two drag streaks,top-down floor perspective,transparent isolated32px pixel art,no text/grid/smoothing. Export:nearest sampling,shared palette,binary alpha and cleared hidden RGB. Dimensions/alpha and enlarged silhouettes checked. The full gore-set generation was rejected; a separate stylized prop pass now completes the remaining files,as described below.


parts-master.png:1536×1024 source,two rows of three complete floor parts. parts-6x.png:576×384 enlarged preview,192×192 cells. export_parts.py:reproducible alpha-silhouette export. parts-validation.json:frame sizes,source bounds and occupied dimensions. All sources remain excluded by .gdignore.

Built-in imagegen prompt: six stylized non-graphic game props,a sleeved/gloved detached arm,a closed-eyed dark-haired head,and four abstract dark-maroon debris lumps,no exposed anatomy,32px target,hard pixel outlines,cold wet palette and transparency. A targeted orientation edit turns head and arm right. Export isolates the six principal silhouettes,omits a loose source fleck,uses nearest sampling and31-colour palettes,normalizes alpha0/255,and centres in32×32 cells. Arm occupies22px maximum dimension,head14px,chunks10/12/11/10px. All15 individual files and two atlases passed size/transparency checks and enlarged visual inspection.
