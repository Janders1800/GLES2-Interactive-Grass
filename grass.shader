shader_type spatial;
render_mode cull_disabled;

uniform float wind_speed = 0.2;
uniform float wind_strength = 2.0;
// How big, in world space, is the noise texture
// wind will tile every wind_texture_tile_size
uniform float wind_texture_tile_size = 20.0;
uniform float wind_vertical_strength = 0.3;
uniform vec2 wind_horizontal_direction = vec2(1.0,0.5);

uniform sampler2D color_ramp : hint_black_albedo;
// we need a tiling noise here!
uniform sampler2D wind_noise : hint_black;

uniform vec3 character_position;
uniform float character_radius = 3.0;
uniform sampler2D character_distance_falloff_curve : hint_black_albedo;
uniform float character_push_strength = 1.0;

// Player deformation variables

uniform vec3 player_pos = vec3(0.0);
uniform float interact_power = 0.5;
uniform float radius = 1.0;


void vertex() {
	
	vec3 world_vert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 normalized_wind_direction = normalize(wind_horizontal_direction);
	vec2 world_uv = world_vert.xz / wind_texture_tile_size + normalized_wind_direction * TIME * wind_speed;
	// we displace only the top part of the mesh
	// note that this means that the mesh needs to have UV in a way that the bottom of UV space
	// is at the top of the mesh
	float displacement_affect = (1.0 - UV.y);
	float wind_noise_intensity = (textureLod(wind_noise, world_uv , 0.0).r - 0.5);

	// We convert the direction of the wind into vertex space from world space
	// if we used it directly in vertex space, rotated blades of grass wouldn't behave properly
	vec2 vert_space_horizontal_dir = (inverse(WORLD_MATRIX) * vec4(wind_horizontal_direction, 0.0,0.0)).xy;
	vert_space_horizontal_dir = normalize(vert_space_horizontal_dir);
	
	vec3 bump_wind = vec3(
		wind_noise_intensity * vert_space_horizontal_dir.x,
		1.0 - wind_noise_intensity,
		wind_noise_intensity * vert_space_horizontal_dir.y 
	);
	normalize(bump_wind);
	bump_wind *= vec3(
		wind_strength,
		wind_vertical_strength,
		wind_strength
	);
	VERTEX += bump_wind * displacement_affect;
	
	// Simple deformation based on the player position, needed for GLES2
	
	vec3 direction = world_vert - player_pos;
	direction.y = 0.0;
	direction = normalize(direction);
	float dist = distance(player_pos, world_vert);
	float power = smoothstep(radius, 0.0, dist);
	direction = (vec4(direction, 1.0) * WORLD_MATRIX).xyz; // world space direction to model space
	VERTEX += direction * power * interact_power * (1.0 - UV.y);
	
}

void fragment() {
	ALBEDO = texture(color_ramp, vec2(1.0 - UV.y, 0)).rgb ;
}