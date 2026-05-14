shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

// MIP from VolumeRenderShader1 (three.js).
uniform sampler3D voxel_data : filter_linear, repeat_disable;
uniform sampler2D color_map : filter_nearest;
uniform vec3 voxel_count = vec3(1.0);
uniform vec2 intensity_range = vec2(0.0, 1.0);

varying vec4 v_nearpos;
varying vec4 v_farpos;
varying vec3 v_position;

float sample_volume(vec3 uvw) {
	// Texel-centered clamp so linear 3D sampling never pulls the repeat/clamp border (often black).
	vec3 vc = max(voxel_count, vec3(1.0));
	vec3 lo = vec3(0.5) / vc;
	vec3 hi = (vc - vec3(0.5)) / vc;
	return texture(voxel_data, clamp(uvw, lo, hi)).r;
}

vec4 sample_color_map(float value01) {
	// Same issue on the ramp: u == 1.0 + nearest hits past the last texel → black speckles on peaks.
	float t = clamp(value01, 0.0, 1.0);
	ivec2 cms = textureSize(color_map, 0);
	float w = max(float(cms.x), 1.0);
	float u_texel = (t * (w - 1.0) + 0.5) / w;
	return textureLod(color_map, vec2(u_texel, 0.5), 0.0);
}

void vertex() {
	mat4 viewtransformf = MODELVIEW_MATRIX;
	mat4 viewtransformi = inverse(MODELVIEW_MATRIX);
	vec4 position4 = vec4(VERTEX, 1.0);
	vec4 pos_in_cam = viewtransformf * position4;
	pos_in_cam.z = -pos_in_cam.w;
	v_nearpos = viewtransformi * pos_in_cam;
	pos_in_cam.z = pos_in_cam.w;
	v_farpos = viewtransformi * pos_in_cam;
	v_position = VERTEX + voxel_count * 0.5 - vec3(0.5);
}

void fragment() {
	vec3 farpos = v_farpos.xyz / v_farpos.w;
	vec3 nearpos = v_nearpos.xyz / v_nearpos.w;
	vec3 view_ray = normalize(nearpos.xyz - farpos.xyz);

	float distance = dot(nearpos - v_position, view_ray);
	distance = max(distance, min((-0.5 - v_position.x) / view_ray.x, (voxel_count.x - 0.5 - v_position.x) / view_ray.x));
	distance = max(distance, min((-0.5 - v_position.y) / view_ray.y, (voxel_count.y - 0.5 - v_position.y) / view_ray.y));
	distance = max(distance, min((-0.5 - v_position.z) / view_ray.z, (voxel_count.z - 0.5 - v_position.z) / view_ray.z));

	vec3 front = v_position + view_ray * distance;

	const float relative_step_size = 1.0;
	int nsteps = int(-distance / relative_step_size + 0.5);
	if (nsteps < 1) {
		discard;
	}

	vec3 step = ((v_position - front) / voxel_count) / float(nsteps);
	vec3 start_loc = front / voxel_count;

	const int MAX_STEPS = 887;
	const int REFINEMENT_STEPS = 4;

	float max_val = -1e6;
	int max_i = 100;
	vec3 loc = start_loc;
	for (int iter = 0; iter < MAX_STEPS; iter++) {
		if (iter >= nsteps) {
			break;
		}
		float val = sample_volume(loc);
		if (val > max_val) {
			max_val = val;
			max_i = iter;
		}
		loc += step;
	}
	vec3 iloc = start_loc + step * (float(max_i) - 0.5);
	vec3 istep = step / float(REFINEMENT_STEPS);
	for (int i = 0; i < REFINEMENT_STEPS; i++) {
		max_val = max(max_val, sample_volume(iloc));
		iloc += istep;
	}

	float val_norm = (max_val - intensity_range.x) / max(intensity_range.y - intensity_range.x, 1e-6);
	val_norm = clamp(val_norm, 0.0, 1.0);

	vec4 out_color = sample_color_map(val_norm);
	ALBEDO = out_color.rgb;
	ALPHA = 1.0;
}
