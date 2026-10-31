// canvas_ui_title_sea: the sea moving in the title screen's painting of Saltmarrow. Author: Claude (code side),
// 2026-10-31. Purpose: a slow swell, light moving on the water, and surf breathing on the rocks, inside a mask
// ChatGPT paints alongside the backdrop (ART_JOBS job 20): red = open sea (the swell and glints), green = surf and
// foam (it pulses). Everything outside the mask is the painting exactly. The swell moves whole art pixels, so the
// painting stays pixel art.
// Target: Godot 4.7 Compatibility renderer (the web build, WebGL 2). Budget: two texture samples (mask, painting)
// and eight sines per pixel, on one full-screen rectangle shown only on the title screen. No branches, one variant,
// no keywords. Fallback: without the mask the game doesn't attach this shader, and the title is simply still.
shader_type canvas_item;

// The swell: long rows rolling in towards the shore (Y), wobbling along their length (X).
const float ROLL_FREQ = 0.16;        // per art pixel, down the screen
const float ROLL_SPEED = 1.1;        // per second
const float ROLL_WOBBLE_FREQ = 0.045;
const float ROLL_WOBBLE_SPEED = 0.5;
const float ROLL_WOBBLE = 2.2;       // how much a row bends along its length
const float SWAY_FREQ = 0.09;        // the sideways drift, per art pixel across
const float SWAY_SPEED = 0.8;
const float SWAY_SHARE = 0.6;        // the sideways shift as a share of the swell
// Glints where two wave trains crest together: crest strength from GLINT_FROM (none) to GLINT_TO (full).
const vec4 GLINT_A = vec4(0.21, 0.9, 0.13, 0.6);    // x freq, x speed, y wobble freq, y wobble speed
const vec4 GLINT_B = vec4(0.27, -0.7, 0.17, -0.5);  // y freq, y speed, x wobble freq, x wobble speed
const float GLINT_A_WOBBLE = 1.5;
const float GLINT_B_WOBBLE = 1.2;
const float GLINT_FROM = 0.82;
const float GLINT_TO = 0.97;
// The surf: a surge moving along the shore, broken into lace that changes LACE_RATE times a second in 2-pixel cells.
const float SURGE_SPEED = 1.6;
const vec2 SURGE_FREQ = vec2(0.06, 0.04);
const float SURGE_FROM = 0.35;
const float LACE_CELL = 2.0;
const float LACE_RATE = 3.0;
const float LACE_COVER = 0.55;       // the share of cells left bare (higher: thinner lace)
const vec2 HASH_DIR = vec2(12.9898, 78.233);   // the usual one-line hash, for the lace pattern
const float HASH_SCALE = 43758.5453;

group_uniforms art;
uniform sampler2D sea_mask : filter_nearest;          // red: open sea; green: surf
uniform vec2 art_size = vec2(1280.0, 720.0);          // the painting's size in its own pixels
group_uniforms look;
uniform float swell : hint_range(0.0, 4.0) = 1.5;     // how far the sea shifts, in art pixels
uniform vec4 glint_colour : source_color = vec4(0.62, 0.78, 0.88, 1.0);
uniform float glint_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec4 foam_colour : source_color = vec4(0.86, 0.9, 0.92, 1.0);
uniform float foam_strength : hint_range(0.0, 1.0) = 0.45;
uniform float speed : hint_range(0.0, 3.0) = 1.0;     // how fast it all moves
group_uniforms;

void fragment() {
	vec2 px = floor(UV * art_size);   // this art pixel
	float t = TIME * speed;
	vec4 m = texture(sea_mask, UV);
	// the swell: shift the painting by whole pixels, only inside the sea
	float roll = sin(px.y * ROLL_FREQ + t * ROLL_SPEED + sin(px.x * ROLL_WOBBLE_FREQ + t * ROLL_WOBBLE_SPEED) * ROLL_WOBBLE);
	float sway = sin(px.x * SWAY_FREQ - t * SWAY_SPEED);
	vec2 shift = vec2(round(sway * swell * SWAY_SHARE), round(roll * swell)) / art_size;
	vec4 col = texture(TEXTURE, UV + shift * m.r);
	// glints: two wave trains multiplied; where both crest the product nears 1
	mediump float a = sin(px.x * GLINT_A.x + t * GLINT_A.y + sin(px.y * GLINT_A.z + t * GLINT_A.w) * GLINT_A_WOBBLE);
	mediump float b = sin(px.y * GLINT_B.x + t * GLINT_B.y + sin(px.x * GLINT_B.z + t * GLINT_B.w) * GLINT_B_WOBBLE);
	mediump float glint = smoothstep(GLINT_FROM, GLINT_TO, a * b) * m.r;
	col.rgb = mix(col.rgb, glint_colour.rgb, glint * glint_strength);
	// the surf: a surge along the shore, broken into flickering lace
	mediump float surge = smoothstep(SURGE_FROM, 1.0, 0.5 + 0.5 * sin(t * SURGE_SPEED + dot(px, SURGE_FREQ)));
	mediump float lace = step(LACE_COVER, fract(sin(dot(floor(px / LACE_CELL), HASH_DIR) + floor(t * LACE_RATE)) * HASH_SCALE));
	col.rgb = mix(col.rgb, foam_colour.rgb, m.g * surge * lace * foam_strength);
	COLOR = col;
}
