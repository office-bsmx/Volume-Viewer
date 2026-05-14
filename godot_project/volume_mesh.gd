extends MeshInstance3D


@export_file("*.json") var volume_json_path: String = ""
@export var color_map_gradient: Gradient
@export var intensity_range: Vector2 = Vector2(0.0, 1.0)
@export var voxel_scale: float = 0.02

var _color_map_texture: GradientTexture1D


func _ready() -> void:
	_color_map_texture = GradientTexture1D.new()
	_color_map_texture.width = 256

	if volume_json_path.is_empty():
		return
	var tex := load_volume_json(volume_json_path)
	if tex == null:
		return
	_apply_volume_shader_parameters(tex)
	_fit_volume_mesh(tex)


func _apply_volume_shader_parameters(tex: ImageTexture3D) -> void:
	var box: BoxMesh = self.mesh as BoxMesh
	if box == null:
		return
	var mat: ShaderMaterial = box.material as ShaderMaterial
	if mat == null:
		return
	var w: float = tex.get_width()
	var h: float = tex.get_height()
	var d: float = tex.get_depth()
	mat.set_shader_parameter("voxel_data", tex)
	mat.set_shader_parameter("voxel_count", Vector3(w, h, d))
	mat.set_shader_parameter("intensity_range", intensity_range)
	if color_map_gradient != null:
		_color_map_texture.gradient = color_map_gradient
		mat.set_shader_parameter("color_map", _color_map_texture)


func _fit_volume_mesh(tex: ImageTexture3D) -> void:
	var box: BoxMesh = self.mesh as BoxMesh
	if box == null or tex == null:
		push_error("Invalid or empty data in Texture3D or BoxMesh")
		return
	var w: int = tex.get_width()
	var h: int = tex.get_height()
	var d: int = tex.get_depth()
	box.size = Vector3(w, h, d)
	
	var max_dimension: float = max(w, h, d) # use float to prevent rounding which fill result in 0 values
	self.scale = Vector3(2.0/max_dimension, 2.0/max_dimension, 2.0/max_dimension)


func load_volume_json(path: String) -> ImageTexture3D:
	if not ResourceLoader.exists(path):
		return null

	var json: JSON = ResourceLoader.load(path)

	var root: Array
	var legacy_uint8_volume: bool = false
	if typeof(json.data) == TYPE_DICTIONARY:
		var d: Dictionary = json.data
		if str(d.get("encoding", "")) != "float01" or not d.has("volume"):
			return null
		var inner: Variant = d["volume"]
		if typeof(inner) != TYPE_ARRAY:
			return null
		root = inner
	else:
		if typeof(json.data) != TYPE_ARRAY:
			return null
		root = json.data
		legacy_uint8_volume = true

	if root.is_empty():
		return null

	var depth: int = root.size()
	var row0: Variant = root[0]
	if typeof(row0) != TYPE_ARRAY:
		return null
	var height: int = (row0 as Array).size()
	if height == 0:
		return null
	var row00: Variant = (row0 as Array)[0]
	if typeof(row00) != TYPE_ARRAY:
		return null
	var width: int = (row00 as Array).size()

	var images: Array[Image] = []
	images.resize(depth)

	for z in range(depth):
		var plane: Array = root[z] as Array
		if plane.size() != height:
			return null
		var img := Image.create(width, height, false, Image.FORMAT_RF)
		for y in range(height):
			var scanline: Array = plane[y] as Array
			if scanline.size() != width:
				return null
			for x in range(width):
				var raw: Variant = scanline[x]
				var v: float
				if legacy_uint8_volume:
					var vi: int = int(raw) if typeof(raw) in [TYPE_INT, TYPE_FLOAT] else 0
					v = clampf(float(vi) / 255.0, 0.0, 1.0)
				else:
					v = clampf(float(raw) if typeof(raw) in [TYPE_INT, TYPE_FLOAT] else 0.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(v, 0.0, 0.0, 1.0))
		images[z] = img

	var out_tex := ImageTexture3D.new()
	if out_tex.create(Image.FORMAT_RF, width, height, depth, false, images) != OK:
		return null
	return out_tex
