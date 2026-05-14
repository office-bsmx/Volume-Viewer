extends Node3D


@onready var mat: ShaderMaterial = $volume_mesh.mesh.material as ShaderMaterial


func _process(_delta: float) -> void:
	$UI/Root/VBoxContainer/FPS.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_intensity_slider_x_value_changed(value: float) -> void:
	var curr_intensity: Vector2 = mat.get_shader_parameter("intensity_range")
	curr_intensity.x = value
	mat.set_shader_parameter("intensity_range", curr_intensity)


func _on_intensity_slider_y_value_changed(value: float) -> void:
	var curr_intensity: Vector2 = mat.get_shader_parameter("intensity_range")
	curr_intensity.y = value
	mat.set_shader_parameter("intensity_range", curr_intensity)
