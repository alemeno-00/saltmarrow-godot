// canvas_env_water: moving water for Saltmarrow Deep. Author: Claude (code side), 2026-10-29.
// Purpose: soft ripple bands and sparse glints drifting over every water square, drawn ON TOP of the water (stand-in
// or ChatGPT's painting) so the painting keeps its look. Quantised to 2-pixel steps to match the pixel art. The layer
// is lit like the rest of the world, so glints shine near lanterns and almost vanish in the dark.
// Target: Godot 4.7 Compatibility renderer (the web build, WebGL 2). Budget: no texture samples, no branches, two
// sines per ripple layer; cheap enough to cover every water square. One variant, no keywords. No lower-tier fallback
// needed: without the shader the water is simply still.
shader_type canvas_item;

// Squares are 32 pixels (the game's grid).
const float SQUARE = 32.0;
// Where two ripple layers both crest, a glint shows: crest strength from GLINT_FROM (none) to GLINT_TO (full).
const float GLINT_FROM = 0.80;
const float GLINT_TO = 0.97;
// Broad ripple bands: band strength from BAND_FROM to BAND_TO, then scaled down to stay softer than glints.
const float BAND_FROM = 0.55;
const float BAND_TO = 0.92;
const float BAND_SCALE = 0.35;
// Ripple layer A runs mostly along x, layer B along y; each wobbles along the other axis. Frequencies are per square,
// speeds per second; the different values keep the two layers from lining up into a visible grid.
const vec2 A_FREQ = vec2(2.1, 1.3);
const vec2 A_SPEED = vec2(0.9, 0.6);
const float A_WOBBLE = 1.5;
const vec2 B_FREQ = vec2(2.7, 1.7);
const vec2 B_SPEED = vec2(-0.7, -0.5);
const float B_WOBBLE = 1.2;

group_uniforms look;
uniform vec4 glint_colour : source_color = vec4(0.62, 0.84, 0.88, 1.0);   // pale teal, like the concept art's water
uniform float strength : hint_range(0.0, 1.0) = 0.28;                       // how strong the whole effect is
group_uniforms motion;
uniform float speed : hint_range(0.0, 3.0) = 1.0;                           // how fast it moves
uniform float pixel_size : hint_range(1.0, 8.0) = 2.0;                      // the effect's pixel, in art pixels
group_uniforms;

varying vec2 world;

void vertex() {
	world = VERTEX;   // the water layer sits at the level's origin, so this is the level position in pixels
}

void fragment() {
	mediump vec2 p = floor(world / pixel_size) * pixel_size / SQUARE;   // in squares, stepped to the art's pixels
	mediump float t = TIME * speed;
	mediump float a = sin(p.x * A_FREQ.x + t * A_SPEED.x + sin(p.y * A_FREQ.y + t * A_SPEED.y) * A_WOBBLE);
	mediump float b = sin(p.y * B_FREQ.x + t * B_SPEED.x + sin(p.x * B_FREQ.y + t * B_SPEED.y) * B_WOBBLE);
	mediump float glints = smoothstep(GLINT_FROM, GLINT_TO, a * b);
	mediump float bands = smoothstep(BAND_FROM, BAND_TO, a) * BAND_SCALE;
	COLOR = vec4(glint_colour.rgb, (glints + bands) * strength);
}
