# Saltmarrow Deep — biome and layout art-design guide

Status: central art-design specification for review, not an implemented generator or delivered tileset.
Scope: Ruins, Sewers, Mines, Fortress, Caves and Sunken.

## Authority, sources and ownership

Read alongside [AGENTS.md](../../AGENTS.md), [ART_JOBS.md](../../ART_JOBS.md), [story](../../docs/story.md) and [characters for art](../../docs/characters.md). Those repository sources govern ownership, delivery format and story. ChatGPT owns assets; Claude owns scripts, scenes, tests, project settings and workflows. This guide lives under assets/docs and makes no Godot changes. The user's explicit documentation request is separate from the art-job queue; no sprite job is completed or checked off by this PR.

Sources: the user's seven core principles and five supplied Saltmarrow Deep reference sheets, provided 28 October 2026, continuing the Saltmarrow Overhaul Plan conversation. The sewer list below is transcribed from supplied Image 5, not reconstructed from the inaccessible assistant replies. Other biome lists are proposed specifications extending those principles, not recovered historical lists. Images 2 and 3 duplicate the general layout sheet and contain a numbering typo around Study/Well Room; their numbering does not override the sewer list.

Concept sheets communicate shapes, materials, functional relationships and mood. Their claims of being “procedural generation ready” are conceptual: flattened boards are not production-ready tile assets, registered sprites, collision maps or proof of implementation. Do not crop them into a shipping tileset. General sheets saying “same layout, different theme” illustrate material comparison, not permission to reskin identical geometry across all six biomes.

## Core principles

1. Each biome has distinct architecture, room shapes, corridors, hazards and assembly grammar.
2. Share the technical grid, socket and collision contracts without forcing identical geometry.
3. Design 30 handcrafted modular archetypes per biome, built from reusable walls, floors, thresholds, supports and props. Variants do not count as additional archetypes.
4. Establish original purpose and believable structure first; apply damage, flooding, occupation or corruption afterwards.
5. Vary approved modules and states within limits that preserve navigation and structural logic.
6. Use dedicated transition modules with a reason for the environmental change.
7. Sewers use long drainage spines, rounded brick tunnels, curved junctions, circular cisterns, maintenance passages, sluices and variable water levels.

## Approved dungeon visual art standard

Approved by the user for future dungeon designs on 28 October 2026. Apply this visual standard across the six biome grammars below, while retaining each biome’s architecture and materials. [Camera-perspective concept reference](references/README.md) includes the user-supplied board and its provenance and limitations.

- **Perspective:** slightly angled top-down 2D pixel art, with visible wall faces, wall tops and readable prop depth. Keep the gameplay grid square and axis-aligned; this is not an isometric diamond grid or a pure overhead view that hides wall faces. Use a consistent drawn angle and wall-face depth across adjoining modules; no numerical camera angle is established by the concept.
- **Base resolution:** one map tile is 32 × 32 pixels. This defines tile resolution and grid registration, not a universal sprite canvas. Characters retain the 64 × 64px frames, bottom-centre placement and feet anchor at x32/y56 required by ART_JOBS. The concept’s roughly 48px visible character height is illustrative. Larger doorways, tall props, effects and assembled modules may span multiple cells where the job permits; declare canvas size, ground footprint, anchor and visual overhang separately. Single-tile exports explicitly required by ART_JOBS remain 32 × 32px.
- **Consistent scale:** review a character, open and closed doorway, wall section and representative barrel/support together at native pixel size before extending a kit. Keep body proportions, doorway clear aperture, wall height and prop size consistent between rooms and biomes. Preserve character clearance at thresholds; use authored multi-tile assemblies where appropriate rather than resizing sprites arbitrarily. A sprite’s visible height is distinct from its frame and collision footprint.
- **Palette and tone:** muted, gritty, low-fantasy coastal materials: cold slate blues, charcoal, wet browns, weathered stone, damp timber, salt and restrained oxidized metal. Use small warm amber accents and dark red blood. Preserve the shared pearly eyes, faint inner light and salt-crystal edges for star influence; avoid broad neon colour washes. No guns or modern equipment.
- **Biome materials:** ruins use weathered broken masonry and exposed growth; sewers use damp brick, arches, drains and corroded fantasy fittings; mines use rough ore-bearing rock, salt and timber supports; fortress spaces use dressed defensive masonry and disciplined fittings; caves use geological rock, mineral deposits and pools; sunken spaces use ancient masonry, silt, tidal marks and marine growth. Materials reinforce each biome’s assembly grammar rather than reskinning identical rooms.
- **Restrained lighting:** local lanterns, torches and subtle environmental or star light support atmosphere without hiding routes or washing out silhouettes. Keep shadow direction and baked highlights consistent across joins; identify any intended runtime light separately in the handoff. Check unlit and low-light appearances as well as lit presentation. Art documents do not implement engine lighting.
- **Gameplay readability:** quiet walkable surfaces, distinct wall faces and clear doorway thresholds remain readable at gameplay scale. Mark pits, deep water, unsafe edges and attack/hazard areas through shape, edge contrast and material cues as well as colour. Props, highlights and foreground walls must not conceal mandatory paths, character feet or hazard boundaries; describe required occlusion handling for Claude’s review.
- **Modular production:** author reusable floors, wall tops/faces, straight runs, inner/outer corners, endcaps, thresholds, door states, supports, props, water/hazard edges and biome transition pieces. Register seams and anchors to the base grid; supply each approved orientation rather than rotating directional lighting blindly. Export separate transparent PNG assets with hard pixel edges, no smoothing, anti-aliasing or image text. For each folder, document files, pixel/frame dimensions, rows/counts, facing or “not applicable”, footprint, anchor, overhang/occlusion intent, states and compatible joins. Keep decoration separate where reuse requires it; provide footprint plans for gameplay integration.

The reference is **concept illustration**, not **game-ready sprites**. Its captions, approximate grid, detailed lighting and composed rooms establish direction, not pixel-perfect measurements or production compliance. Production delivery requires native-resolution seam, scale, transparency, state and readability checks on actual exported assets, plus separate gameplay review. This documentation and reference do not complete any ART_JOBS item.

## Shared grid, connection and collision contracts

The map square is 32 × 32 pixels, as specified by ART_JOBS. Use an axis-aligned square gameplay footprint with the approved slightly angled top-down architectural cutaway and visible wall faces; curves are stepped footprints on that grid, not a rotated diamond grid. Wall silhouettes and tall decorations may extend visually beyond a cell; their ground footprint remains explicit.

The following module metadata is a design handoff contract, not a claim about current engine fields. Each archetype must have an ID, biome, purpose, footprint in grid cells, anchor/origin, occupied and clear cells, supports, entrances, elevation, water state, allowed transformations, variant slots, hazard exclusions and a small plan diagram. Record dimensions before production; illustrative concept-board room sizes are not engine requirements.

Each socket records its boundary cell coordinates, outward cardinal direction, clear width in cells, floor elevation, connection class (walkway, channel, door, stair, shaft or sealed), threshold material and state. Pair only opposite directions with equal width, elevation and compatible class/state. Never attach a dry walk socket directly to a deep-water channel. Use an adapter when widths, heights or materials change. Stair/shaft endpoints need explicit paired destinations; a drawn ladder does not grant traversal.

Reserve a continuous clear route at least two cells wide on ordinary circulation paths; a deliberately narrow one-cell segment must be marked as such for gameplay review. These are proposed art planning clearances, subject to Claude's movement constraints. Door art must show the full agreed clear aperture. Keep socket landing strips free of props and hazards; seal unused sockets with complete wall/endcap modules rather than invisible barriers.

Supply a semantic footprint plan: walkable floor; solid wall/support; blocking prop; nonblocking decoration; shallow water; deep water; void/pit; transition; conditional door/gate. Separate movement, sight-blocking and hazard intent: a grate can be see-through yet block movement; a low rail need not block sight. Claude confirms actual collision, sight and movement behavior. Paint must agree with the eventual collision plan; no apparently open floor with hidden blockers, and no solid-looking wall that can be walked through.

Bridge decks and their water/pit below need distinct layers and unambiguous edges. Water surface appearance does not establish depth: use rims, steps, visible submerged floor for shallow water, dark depth and clear boundaries for deep water. Never infer collision from image alpha or ornament. Water-level variants each need their own footprint review; connectivity must remain valid in every enabled state.

## Functional design and controlled variation

Design sequence: original plan and use → circulation/service networks → structure and supports → sockets and routes → damage/flooding → later occupation → sparse corruption → prop and lighting pass → navigation review. A ruin must still reveal the building it was; a mine must reveal what was extracted.

Select an archetype and compatible footprint before decorating. Keep socket locations, primary routes and structural anchors fixed unless choosing a separately reviewed footprint variant. Weight ordinary circulation and working spaces more heavily than landmarks. Reserve rare arenas and major landmarks by role, avoiding adjacent repetition. Exact weights and encounter pacing belong to the future implementation.

Allow bounded swaps of floor patches, wall repairs, peripheral props, supported alcoves, rubble pockets, water states and secondary obstacles. Declare mutually exclusive slots, density limits and hazard budgets per archetype. No random props on every square; keep at least half the usable floor visually quiet in ordinary rooms. Do not rotate asymmetric water flow, stairs, directional light or architectural facades blindly; redraw or approve each orientation.

Validate after each structural/state change: paired sockets; continuous entry-to-exit route; reachable objectives and exits; usable landing strips; no stranded mandatory rooms; visible hazard boundaries; supported spans; coherent flow and drainage. Treat a blocked passage as a designed dead end with an alternate required route. Reject invalid variants rather than hiding failures under decoration. Layouts persist during a life; regeneration on death follows the story foundation, not continuous unexplained reshuffling.

## Biome grammars and module kits

### Ruins

Generate an intelligible original civic, domestic or sacred structure: approach → entrance → circulation → functional rooms → service access. Preserve traces of axes, wall thickness and load-bearing supports, then remove selected roofs, walls and floors along a coherent collapse pattern. Link exposed courtyards and breached halls; avoid arbitrary rubble blobs that erase the plan. Corridors include broad halls, broken arcades and open-air passages. Kit: intact/broken masonry, wall stubs, arch fragments, column bases, stairs, courtyard paving, roof debris, roots and retaining edges. Weathering and vegetation follow exposure and moisture. Hazards: unstable masonry, floor holes and falling rubble; clear cracks, dust and debris cones telegraph them.

### Sewers

Start with a long drainage spine and consistent downstream direction; add rounded/curved branches and access walks, then cisterns, sluices, pumps, filtration and overflow routes at functional locations. Circular cisterns are focal expansions in a predominantly tunnel-based network. In plan, tunnels can curve; in cross-section, rounded brick vaults shelter a central channel with raised maintenance walks. Do not reduce this biome to square chambers connected by short corridors. Kit: straight/curved brick linings, arch ribs, circular rims, channel banks, junctions, sluice frames, grates, walkways, ladders, pipes, valves and pump housings. Hand-worked fantasy drainage machinery is acceptable; avoid modern electrical equipment. Water states: low/clean, dirty/standard, flooded, abandoned, collapsed and sparingly corrupted. Each state preserves or deliberately reroutes access. Hazards: rising water, currents, drain suction, slippery edges and broken grates; show flow, waterlines and safe ledges.

### Mines

Place a branching ore vein first; drives follow it, extraction chambers widen at deposits, and crosscuts connect access/haul routes. Add a coherent haulage spine, loading bays, sumps, ventilation and lift connections. Supports follow roof loads and excavation span, not decorative spacing alone. Kit: rough rock faces, ore seams, timber frames, braces, retaining walls, rails and switches, carts, platforms, ramps and lifts. Corridors are irregular excavated drives with occasional engineered straight haulways. Avoid a fortress plan with rock textures. Hazards: loose roof, failed supports, shafts and flooded workings; show sagging beams, cracks and edge protection.

### Fortress

Establish a formal defensible plan: controlled approach → gate/checkpoint → defended court → garrison/service areas → command/secure core. Separate troop, supply and prisoner circulation where useful. Use consistent masonry thickness, rectangular rooms, aligned doors, disciplined axes and selective symmetry; defensible choke points must have architectural purpose. Kit: thick walls, doors, gatehouses, buttresses, pillars, parapets, stairs, barracks fittings and restrained heraldry. Do not use cave-like random wall erosion as the default. Hazards: traps, portcullises, murder holes and exposed defensive lanes; show mechanisms and architectural warning cues.

### Caves

Generate from geology: joints and fractures → winding passages → chambers at erosion/intersection zones → stream beds, pools and sediment deposits. Irregular footprints and unequal chambers belong here; avoid rectangular rooms softened only at the corners. Connect narrow throats to wider caverns with believable rock mass and natural columns. Kit: concave/convex rock edges, ledges, fissures, stalactites/stalagmites, columns, scree, pools and mineral patches. Human construction appears only where someone adapted the cave. Hazards: falling rock, unstable scree, pits and cold pools; separate walkable shelves from depth with strong edges.

### Sunken

Lay out ancient architecture first, then establish water datum, breaches, drainage and sediment. Use partly dry terraces, shallow flooded halls, deep courts and submerged chambers; not uniform blue water over every floor. Connect architecture via stairs, arcades, causeways and flooded passages with explicit traversal status. Kit: ancient masonry, submerged arches, stepped waterlines, drowned pillars, broken retaining walls, sediment, marine growth and tidal edges. Growth follows immersion; exposed upper walls retain architectural identity. Hazards: currents, pressure leaks, drowned pits and changing water levels. Full underwater traversal is conditional on future gameplay support; it cannot become a mandatory route by art alone.

## Layout libraries

Each row specifies a distinct functional footprint, circulation arrangement or structural problem. It is an archetype brief, not a finished room. Use IDs in future art manifests. Connection counts refer to intended plan relationships; exact sockets and dimensions must be drawn and reviewed per module.

### Ruins — 30 archetypes

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| RUI-01 | Gate court | Broken perimeter encloses an arrival court; gate and inner hall remain legible. |
| RUI-02 | Processional hall | Long axial hall with surviving wall bays and a breached side loop. |
| RUI-03 | Crossing arcade | Four arcaded paths meet around a surviving pier cluster. |
| RUI-04 | Collapsed corner hall | Bent circulation follows an original corner; collapse opens an outer bypass. |
| RUI-05 | Roofless nave | Long sacred hall ends at an apse, with aisles around fallen roof. |
| RUI-06 | Cloister court | Four covered walks surround an overgrown open court. |
| RUI-07 | Domestic courtyard | Household rooms open inward around a well and shared yard. |
| RUI-08 | Great chamber | Broad reception space retains dais, side doors and structural bays. |
| RUI-09 | Pillar gallery | Repeated supports divide a long gallery into parallel aisles. |
| RUI-10 | Shrine recess | Small terminal chapel branches from a public circulation route. |
| RUI-11 | Archive ruin | Reading aisle links storage bays; fallen shelving stays peripheral. |
| RUI-12 | Old armoury | Secure racks flank a central issue aisle and guarded threshold. |
| RUI-13 | Dormitory remnant | Repeated sleeping bays connect to a surviving service corridor. |
| RUI-14 | Refectory shell | Long dining footprint has separate kitchen and hall entrances. |
| RUI-15 | Kitchen range | Hearth wall, prep bay and drain explain a compact service plan. |
| RUI-16 | Store court | Loading entry meets sheltered storage bays around an open yard. |
| RUI-17 | Artisan workshop | Work bays face a shared aisle and external delivery breach. |
| RUI-18 | Bathhouse ruin | Changing bay leads through dry ledges around drained pools. |
| RUI-19 | Study tower base | Compact chamber retains a stair core and wall alcoves. |
| RUI-20 | Cell block remnant | Cells branch from one guarded aisle, with a broken escape wall. |
| RUI-21 | Burial crypt | Recessed tomb bays flank a processional route to a terminal chamber. |
| RUI-22 | Well court | Circular well interrupts a broad square yard with perimeter access. |
| RUI-23 | Flooded cellar | Submerged storage bays border a raised stair-to-stair route. |
| RUI-24 | Collapse fan | Fallen roof and wall form a directional debris fan and edge bypass. |
| RUI-25 | Cave breach | Building foundations break into a natural cavity with retained wall ends. |
| RUI-26 | Broken aqueduct | Channel and service path survive across discontinuous masonry bays. |
| RUI-27 | Gap bridge | Abutments and surviving deck connect two separated building wings. |
| RUI-28 | Upper stair remnant | Stair and landing ascend through an identifiable tower shell. |
| RUI-29 | Descending undercroft | Stairs descend from public hall to supported basement bays. |
| RUI-30 | Sanctum court | Large terminal court retains focal plinth and multiple readable approaches. |

### Sewers — 30 archetypes

Reference library: names and order preserved from the supplied sewer sheet (Image 5). The functional descriptions are this guide's production-planning interpretation. Image text “Rising Water Room” is preserved as a stateful archetype, not a claim that dynamic flooding exists in Godot.

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| SEW-01 | Straight Tunnel | Long central channel with raised maintenance walks and opposed end sockets. |
| SEW-02 | Curved Tunnel | Rounded bend carries channel and inner/outer walks continuously. |
| SEW-03 | T-Junction | Branch drain joins the spine at a shaped confluence with service crossing. |
| SEW-04 | Crossroads | Four drainage approaches meet with explicit flow hierarchy and dry circulation. |
| SEW-05 | Narrow Passage | Restricted service route runs beside a confined drain; mark reduced clearance. |
| SEW-06 | Wide Corridor | Broad vaulted drainage reach has generous banks and spaced arch supports. |
| SEW-07 | Ramp Tunnel | Sloped channel and parallel walk connect declared elevations through paired ramps. |
| SEW-08 | Vertical Shaft | Circular shaft has rim access and a paired ladder or lift destination. |
| SEW-09 | Maintenance Room | Dry work bay branches off the channel with equipment pushed to walls. |
| SEW-10 | Pump Room | Intake, pump housing and discharge form a readable system around service access. |
| SEW-11 | Control Room | Valve platform overlooks a channel or sluice and has a dry approach. |
| SEW-12 | Small Chamber | Compact drainage expansion has limited branching and a small service ledge. |
| SEW-13 | Large Cistern | Circular storage basin has perimeter access and controlled inlet/outlet positions. |
| SEW-14 | Flooded Chamber | Former working chamber floods around a retained or rerouted dry ledge. |
| SEW-15 | Sluice Gate | Gate spans a channel between upstream and downstream reaches with side access. |
| SEW-16 | Overflow Room | High relief outlet and spill basin explain where excess water is diverted. |
| SEW-17 | Storage Room | Dry supply bays connect to maintenance circulation, above normal waterline. |
| SEW-18 | Pipe Junction | Pipe routes converge at a service hub with valves and accessible inspection ring. |
| SEW-19 | Maintenance Walkway | Long raised bank or catwalk follows water with protected entry landings. |
| SEW-20 | Side Tunnel | Secondary branch peels away from the main spine to a smaller working route. |
| SEW-21 | Collapsed Tunnel | Directional vault failure blocks one reach; rubble and alternate access are explicit. |
| SEW-22 | Drainage Pit | Sunken collection pit sits below a rim walk with visible suction/depth boundary. |
| SEW-23 | Guard Post | Small checkpoint controls a service door or bridge without blocking drain flow. |
| SEW-24 | Filtration Room | Sequential screened basins have distinct inlet, outlet and maintenance aisles. |
| SEW-25 | Underwater Passage | Submerged connector has explicit depth and conditional traversal; never assume swimming. |
| SEW-26 | Rising Water Room | Floodable basin has visible waterline states, refuge ledge and reviewed escape route. |
| SEW-27 | Dual Channel | Parallel watercourses are separated by a service spine with controlled cross-links. |
| SEW-28 | Bridge Room | Dry crossing spans an active channel with clear abutments and water edges. |
| SEW-29 | Exit to Other Biome | Drainage arch meets a dedicated adapter to a different environment. |
| SEW-30 | Boss Arena | Large circular basin/platform assembly provides approaches and safe readable boundaries. |

### Mines — 30 archetypes

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| MIN-01 | Adit mouth | Retained entry joins surface masonry to a rough haul drive. |
| MIN-02 | Vein-following drive | Winding excavation follows visible ore with supports at weak spans. |
| MIN-03 | Crosscut | Straighter access cuts across rock to intersect an ore drive. |
| MIN-04 | Haul junction | Rail switch and turning space join working drives without random dead rails. |
| MIN-05 | Blind working face | Terminal ore face has tool space and a return route. |
| MIN-06 | Narrow test drift | Small exploratory bore follows a thin seam with marked clearance. |
| MIN-07 | Extraction stope | Widened chamber tracks a rich deposit with retained rock pillars. |
| MIN-08 | Pillar-and-stall field | Extraction bays alternate with load-bearing untouched rock masses. |
| MIN-09 | Timbered gallery | Long weak-roof passage uses braced frames and a clear haul aisle. |
| MIN-10 | Loading bay | Ore chute feeds cart positions beside the main transport route. |
| MIN-11 | Sorting floor | Broad working floor links ore arrival, sorting bays and waste exit. |
| MIN-12 | Cart siding | Parallel rail spur allows storage beside a through haul route. |
| MIN-13 | Switchback ramp | Supported turns carry haul access between declared elevations. |
| MIN-14 | Lift chamber | Shaft rim, landing and hoist bay form a coherent vertical hub. |
| MIN-15 | Winch room | Anchored winch faces the load direction with protected operating space. |
| MIN-16 | Ventilation junction | Air shaft intersects working access without becoming an unexplained walk exit. |
| MIN-17 | Sump chamber | Low collection basin lies below raised service access and pump position. |
| MIN-18 | Flooded drift | Water fills a low working with dry threshold and reviewed continuation. |
| MIN-19 | Support repair bay | Replacement beams and tools occupy a reinforced side pocket. |
| MIN-20 | Tool store | Secure compact storage opens off a service drive. |
| MIN-21 | Miner refuge | Sheltered resting bay sits away from haul traffic and unstable faces. |
| MIN-22 | Ore assay room | Work bench alcoves connect sample arrival to a quiet inspection aisle. |
| MIN-23 | Waste rock pocket | Spoil piles fill a spent bay while preserving cart unloading access. |
| MIN-24 | Fault crossing | Fractured rock belt demands closer supports and a narrowed protected route. |
| MIN-25 | Collapsed working | Failed support line explains roof debris and a designed alternate connection. |
| MIN-26 | Natural cavern strike | Excavated drive breaches geology; rail ends at a loading platform. |
| MIN-27 | Shaft bridge | Braced deck joins rock abutments across an abandoned shaft. |
| MIN-28 | Salt pillar chamber | Extraction wraps a large retained salt column and readable perimeter route. |
| MIN-29 | Old masonry breakthrough | Mine face cuts an older built wall at a dedicated transition threshold. |
| MIN-30 | Deep seam hall | Large irregular extraction chamber follows an exceptional deposit with support islands. |

### Fortress — 30 archetypes

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| FOR-01 | Gatehouse | Sequential gates and guard bays control a single defended approach. |
| FOR-02 | Inspection court | Enclosed arrival yard links gate, guardroom and inner entry. |
| FOR-03 | Axial hall | Formal straight circulation aligns doors and repeated structural bays. |
| FOR-04 | Defended T-junction | Controlled branch places guard visibility over a circulation split. |
| FOR-05 | Cross hall | Four aligned routes meet in a disciplined supported crossing. |
| FOR-06 | Corner passage | Right-angle defended bend retains consistent wall thickness and sight break. |
| FOR-07 | Guardroom | Compact duty space overlooks a door and connects to troop circulation. |
| FOR-08 | Muster court | Broad drill yard links barracks, armoury and command approach. |
| FOR-09 | Barracks | Repeated sleeping bays flank an orderly central aisle. |
| FOR-10 | Mess hall | Long communal hall connects kitchen service and troop entrance separately. |
| FOR-11 | Fortress kitchen | Hearth/prep/service bays connect stores to mess circulation. |
| FOR-12 | Provision store | Loading aisle serves secure food bays behind the service route. |
| FOR-13 | Armoury | Controlled issue counter and rack bays sit behind a guarded threshold. |
| FOR-14 | Smithy court | Vented forge bay joins repair work to supply and troop routes. |
| FOR-15 | Command hall | Formal audience axis ends at a raised command position. |
| FOR-16 | Map room | Quiet planning chamber branches from the command suite. |
| FOR-17 | Signal tower base | Compact stair core links watch access and a duty alcove. |
| FOR-18 | Watch gallery | Long observation route overlooks a defended outer edge. |
| FOR-19 | Inner gate | Second defensive threshold separates public garrison from secure core. |
| FOR-20 | Portcullis chamber | Gate track, machinery and service landing explain a closing barrier. |
| FOR-21 | Prison intake | Guarded processing bay separates cells from normal troop paths. |
| FOR-22 | Cell corridor | Repeated cells line a watched linear aisle with controlled end doors. |
| FOR-23 | Chapel | Ordered nave and sanctuary sit off garrison circulation. |
| FOR-24 | Infirmary | Bed bays and treatment aisle connect to sheltered service access. |
| FOR-25 | Cistern court | Protected water supply has perimeter access inside defensive walls. |
| FOR-26 | Supply ramp | Wide ramp links loading yard to stores with declared elevation. |
| FOR-27 | Stair hall | Paired landings and defensive turns connect formal floor plans. |
| FOR-28 | Sally port | Narrow controlled exit passes through the outer wall to a transition. |
| FOR-29 | Breached bastion | Original defensive mass remains legible around a localized collapse. |
| FOR-30 | Keep arena | Secure great hall supports a major confrontation with multiple approach lanes. |

### Caves — 30 archetypes

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| CAV-01 | Fracture passage | Narrow angular route follows a geological joint. |
| CAV-02 | Winding tunnel | Curving erosion passage links chambers without regular masonry bays. |
| CAV-03 | Forked fissure | Unequal natural branches split along intersecting cracks. |
| CAV-04 | Confluence cave | Several water-carved approaches meet at an irregular junction. |
| CAV-05 | Low throat | Pinched connector opens at each end with explicit clearance review. |
| CAV-06 | Erosion gallery | Long widened watercourse has shelves along one or both edges. |
| CAV-07 | Dry chamber | Uneven broad floor offers a quiet main route between offset mouths. |
| CAV-08 | Column cavern | Natural rock columns split circulation into unequal connected loops. |
| CAV-09 | Stalactite hall | Ceiling formations align with drip zones, leaving readable floor lanes. |
| CAV-10 | Stalagmite field | Sparse growth clusters form obstacle islands around connected routes. |
| CAV-11 | Sinkhole rim | Circular collapse edge has stable rim access and a visible deep centre. |
| CAV-12 | Scree slope | Loose rock fan descends from a fractured wall beside a stable route. |
| CAV-13 | Rockfall choke | Directional debris narrows one connection and exposes a bypass shelf. |
| CAV-14 | Underground stream | Flowing bed threads through a long cavern with raised banks. |
| CAV-15 | Stream crossing | Shallow ford or explicit stone span connects stable opposite shelves. |
| CAV-16 | Pool chamber | Standing water occupies a low basin beside a continuous shore route. |
| CAV-17 | Lake shore | Broad curved shoreline joins dry approaches without assuming water traversal. |
| CAV-18 | Island cavern | Rock island connects through designed ledges or bridges over depth. |
| CAV-19 | Waterfall chamber | Upper inflow drops to a lower basin; routes declare elevations. |
| CAV-20 | Dry riverbed | Meandering recessed bed retains erosion banks and sediment bars. |
| CAV-21 | Mineral alcove | Terminal pocket exposes one concentrated seam or crystal growth. |
| CAV-22 | Geode cavity | Rounded mineral-lined chamber has irregular entrances and a quiet centre. |
| CAV-23 | Root chamber | Surface roots penetrate cracks and cluster away from the main lane. |
| CAV-24 | Fungal hollow | Moist low chamber holds bounded growth patches and an open route. |
| CAV-25 | Lava-tube remnant | Rounded geological tube has flow-shaped rock and no active lava assumption. |
| CAV-26 | Vertical chimney | Shaft and ledges need explicit paired traversal or a sealed destination. |
| CAV-27 | Ledge traverse | Narrow shelf follows a cavern wall above a clearly marked drop. |
| CAV-28 | Twin-level cavern | Upper shelf and lower floor connect through a declared ramp route. |
| CAV-29 | Excavation contact | Natural chamber meets supported human cutting at a transition mouth. |
| CAV-30 | Great cavern | Large irregular basin combines columns, shelves and several offset entrances. |

### Sunken — 30 archetypes

| ID | Archetype | Function and layout contract |
| --- | --- | --- |
| SUN-01 | Drowned gateway | Ancient entry arch meets a dry threshold and descending waterline. |
| SUN-02 | Tidal vestibule | Stepped entrance basin has alternate reviewed water states. |
| SUN-03 | Submerged avenue | Long formal street retains facades and raised edge routes. |
| SUN-04 | Flooded crossway | Ancient junction keeps building axes beneath uneven inundation. |
| SUN-05 | Arcaded bend | Curved or cornered arcade follows a partly flooded perimeter. |
| SUN-06 | Sealed terminus | Ancient end chamber is visibly closed beyond its flooded floor. |
| SUN-07 | Dry upper hall | Raised surviving floor contrasts with drowned rooms beyond. |
| SUN-08 | Shallow hall | Visible floor and steps show shallow inundation across a long chamber. |
| SUN-09 | Deep court | Sunken central court has elevated perimeter circulation. |
| SUN-10 | Pillar basin | Drowned columns divide a basin with a dry or shallow perimeter route. |
| SUN-11 | Sunken shrine | Ancient focal niche sits above or below a clearly stated water datum. |
| SUN-12 | Drowned sanctuary | Processional architecture leads toward a partly submerged focal platform. |
| SUN-13 | Archive terrace | Raised archive bays overlook silted lower storage. |
| SUN-14 | Ancient armoury | Original secure rack bays survive around a flooded issue aisle. |
| SUN-15 | Habitation court | Domestic doorways face a drowned shared courtyard. |
| SUN-16 | Feasting hall | Long ancient assembly plan survives beneath sediment and varied water. |
| SUN-17 | Service kitchen | Old hearth and drains explain a lower flooded service chamber. |
| SUN-18 | Silted store | Sediment fans partly bury storage bays while preserving a route. |
| SUN-19 | Artisan hall | Work alcoves flank a partly inundated central circulation axis. |
| SUN-20 | Bathing complex | Stepped pools preserve original water use beneath later flooding. |
| SUN-21 | Prison basin | Cells and barred openings reveal old function despite inundation. |
| SUN-22 | Well chamber | Old fresh-water shaft contrasts with surrounding saltwater breach. |
| SUN-23 | Breached retaining wall | Localized wall failure explains incoming flow and debris direction. |
| SUN-24 | Collapsed dome court | Dome debris forms islands around original supports and clear ledges. |
| SUN-25 | Cave-inlet chamber | Ancient hall is opened by a natural water-bearing fissure. |
| SUN-26 | Canal hall | Engineered watercourse runs between built terraces and service steps. |
| SUN-27 | Causeway bridge | Raised ancient span connects two flooded precincts. |
| SUN-28 | Descending stair | Legible steps pass through several waterline states to a lower landing. |
| SUN-29 | Flooded shaft | Vertical ancient access has explicit level pairing and traversal restrictions. |
| SUN-30 | Drowned heart court | Large ancient focal space combines stepped platforms and deep water boundaries. |

## Dedicated transitions

Transitions are authored modules, not abrupt texture swaps. Each has two independently described biome sockets, a structural reason for contact, material overlap, elevation/water handling and a reviewed clear route. Share the technical socket standard while preserving each side's geometry. These examples do not imply a progression order or that every biome pair must connect.

| Pair | Dedicated piece | Function and constraints |
| --- | --- | --- |
| Ruins ↔ Sewers | Broken cellar drain stair | Surface foundation steps into rounded brick maintenance access; drain stays below dry threshold. |
| Mines ↔ Fortress | Reinforced supply adit | Rough supported excavation meets thick defensive gate masonry through a loading/checkpoint bay. |
| Caves ↔ Sunken | Breached ancient water wall | Natural erosion exposes submerged architecture; ledges and water datum explain access. |
| Sewers ↔ Sunken | Tidal outfall and sluice | Municipal drainage meets ancient drowned works with visible backflow barrier and compatible water levels. |
| Sewers ↔ Fortress | Guarded service culvert | Drain and raised service walk pass beneath fortification; grate/gate states are explicit. |
| Ruins ↔ Caves | Collapsed foundation cavity | Intact footing edges frame natural rock; rubble supports the change rather than concealing a missing socket. |
| Mines ↔ Caves | Excavation breakthrough | Tool-cut rock and timbers stop where natural geology opens; rail terminates at a sensible platform. |
| Ruins ↔ Fortress | Repaired defensive threshold | Older broken masonry joins a maintained wall with deliberate repair courses and gate control. |

Produce a distinct adapter for any other allowed pair rather than stretching one of these silently. Match both floor elevations and channel levels or include a visible stair/ramp/drop with declared traversal. Retain endcaps, water seals and wall thickness. Test routes in both directions where intended; one-way drops must be labelled and approved by gameplay design.

## Hazard and state review

Hazards must be tied to architecture/geology and visible before entry. Plan a safe route unless the encounter explicitly requires an approved hazard crossing. Do not put unavoidable new mechanics into a required route. Proposed hazard consequences, trigger timing, forced movement, damage and water simulation belong to Claude's gameplay work.

| Biome | Primary cues | Layout restrictions |
| --- | --- | --- |
| Ruins | Cracks, leaning masonry, dust, exposed floor gaps | Collapse respects original load paths; debris cannot cover every exit. |
| Sewers | Waterlines, ripples/current direction, sluice machinery, broken grates | Every enabled flood state needs connected exits or an explicitly reviewed escape sequence. |
| Mines | Sagging frames, loose roof, shaft rims, submerged rail | Props support spans; pits and flooded workings never masquerade as floor. |
| Fortress | Trap mechanism, slots, gate tracks, defensive sight lanes | Match warning and effect areas; preserve gate/service access. |
| Caves | Fractures, scree fans, depth edges, unstable overhangs | Rockfall comes from plausible overhead sources; stable shelves remain distinguishable. |
| Sunken | Tidal marks, leaks, submerged steps, moving debris | Record depth/elevation per state; underwater/pressure mechanics require separate support. |

Corruption is an overlay on a functional world, not a replacement for it. Keep the shared star language: pearly sheen, faint inner light and salt crystals at edges. Use cold slate, charcoal, wet browns and restrained amber lights; no guns, modern machinery or indiscriminate tentacles. Broad red/neon corruption on concept sheets is not a palette mandate. New factions, ancient historical claims and biome progression are not established by this guide.

## Production delivery and acceptance

Deliver actual environment pieces separately under assets/tiles/<biome>/ when assigned; do not treat this documentation as delivery of ART_JOBS item 9 or any sprite job. Production images must be transparent PNG, hard-edged pixel art, without smoothing, anti-aliasing or image text. Floors, walls and props register to the 32 × 32px grid; larger assembled pieces declare their whole-cell footprint, anchor and occlusion plan. Provide floor variants, wall tops/faces, inner/outer corners, endcaps, doors in each state, supports, hazard edges and transition joins sufficient to assemble the reviewed plans.

ART_JOBS currently specifies character frames 64 × 64px, feet x32/y56, right-facing, equal-size frames left-to-right without gaps, and one animation per row; the job's exact rows/counts override generic examples. Portraits are 128 × 128px; item icons 32 × 32px with a 1px dark outline. Environment sheets do not inherit character dimensions automatically.

Every production folder README must list files, dimensions/frame size, rows and frame counts, facing directions, anchors, grid footprints and applicable states. State “not applicable” for animation/facing on static environment pieces. Supply a plan showing intended blocking, sight, water and hazard footprints for Claude to integrate; art delivery does not authorize editing code.

Review each biome library against these gates:

- Exactly 30 distinct archetypes, with IDs, purpose, dimensions, plan, sockets and allowed orientations.
- A readable original structure or geological process; believable supports, drainage and service routes.
- Compatible joins with no floor seams, wall gaps, occlusion errors or ambiguous water/pit edges.
- Entry-to-exit and objective reachability for every allowed state and structural variant.
- Normal, low-light and character-scale readability with clear hazard boundaries and quiet walking surfaces.
- Both endpoints of every dedicated transition agree on widths, elevation and traversal state.
- Sprite format, anchors, transparency, hard edges and README metadata verified on exported assets.
- Separate gameplay review before enabling conditional flood, underwater, trap, shaft or collapse behavior.

This PR supplies the design guide, documentation index and a concept reference board only. It does not supply 180 completed room plans, any production PNGs, runtime collision, procedural generation or visual playtesting. Future acceptance of those deliverables must be recorded with their actual files and verification evidence.
