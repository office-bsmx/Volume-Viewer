extends Camera3D


@export var orbit_sensitivity: float = 0.004
@export var pan_sensitivity: float = 0.0025
@export var zoom_step: float = 2.0
@export var min_size: float = 2.0
@export var max_size: float = 400.0

@export var orbit_radius: float = 12.0

var _pivot: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0
var desired_size: float = min_size


func _ready() -> void:
	if size < 0.01:
		size = 20.0
	var offset := global_position - _pivot
	if offset.length_squared() > 0.0001:
		orbit_radius = offset.length()
		_angles_from_offset(offset)
	else:
		_pitch = deg_to_rad(-30.0)
		_yaw = 0.0
	_apply_orbit()

func _process(_delta: float) -> void:
	size = lerpf(size, desired_size, 0.1)

func _angles_from_offset(offset: Vector3) -> void:
	var horiz: float = Vector2(offset.x, offset.z).length()
	_yaw = atan2(offset.x, offset.z)
	_pitch = atan2(offset.y, horiz)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				desired_size = clampf(size - zoom_step, min_size, max_size)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				desired_size = clampf(size + zoom_step, min_size, max_size)
				get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_yaw -= event.relative.x * orbit_sensitivity
			_pitch += event.relative.y * orbit_sensitivity
			_pitch = clampf(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
			_apply_orbit()
			get_viewport().set_input_as_handled()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var k: float = pan_sensitivity * size
			_pivot -= global_transform.basis.x * event.relative.x * k
			_pivot += global_transform.basis.y * event.relative.y * k
			_apply_orbit()
			get_viewport().set_input_as_handled()


func _apply_orbit() -> void:
	var cp: float = cos(_pitch)
	var f: Vector3 = Vector3(cp * sin(_yaw), sin(_pitch), cp * cos(_yaw))
	global_position = _pivot + f * orbit_radius
	look_at(_pivot, Vector3.UP)
