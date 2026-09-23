extends Node3D

var rng := RandomNumberGenerator.new()
var world: Node3D

func build(target_world: Node3D, player: Node3D, hud: CanvasLayer) -> void:
	world = target_world
	rng.seed = 230917
	_hide_legacy_visuals(target_world)
	_tune_world(target_world)
	_build_panorama()
	_build_foreground()
	_build_workshop_front()
	_build_vegetation()
	_cleanup_hud(hud)
	if player:
		player.position = Vector3(0.0, 0.35, 31.0)
		player.rotation_degrees.y = 0.0

func _has_script_ancestor(node: Node, stop: Node) -> bool:
	var p := node.get_parent()
	while p and p != stop:
		if p.get_script() != null:
			return true
		p = p.get_parent()
	return false

func _hide_legacy_visuals(target_world: Node3D) -> void:
	for label in target_world.find_children("*", "Label3D", true, false):
		label.visible = false
	# Keep gameplay nodes/colliders/scripts alive, but hide every legacy graybox
	# mesh. The visual layer below replaces them without breaking interactions.
	for mesh in target_world.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = false

func _tune_world(target_world: Node3D) -> void:
	for node in target_world.get_children():
		if node is WorldEnvironment and node.environment:
			var env: Environment = node.environment
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.12, 0.18, 0.19)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.58, 0.65, 0.56)
			env.ambient_light_energy = 0.72
			env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			env.tonemap_exposure = 1.12
			env.fog_enabled = true
			env.fog_light_color = Color(0.72, 0.74, 0.64)
			env.fog_light_energy = 0.42
			env.fog_density = 0.0022
			env.fog_height = 0.0
			env.fog_height_density = 0.055
		elif node is DirectionalLight3D:
			node.light_energy = 1.34
			node.light_color = Color(1.0, 0.88, 0.70)
			node.rotation_degrees = Vector3(-38.0, -27.0, 0.0)
			node.shadow_enabled = true

func _mat(color: Color, roughness: float = 0.88, metallic: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(pos: Vector3, size: Vector3, color: Color, roughness: float = 0.88, metallic: float = 0.0, transparent: bool = false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = shape
	inst.position = pos
	inst.material_override = _mat(color, roughness, metallic, transparent)
	add_child(inst)
	return inst

func _cyl(pos: Vector3, radius: float, height: float, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.86
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 10
	var inst := MeshInstance3D.new()
	inst.mesh = shape
	inst.position = pos
	inst.rotation_degrees = rot
	inst.material_override = _mat(color, 0.96)
	add_child(inst)
	return inst

func _ellipsoid(pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 10
	shape.rings = 6
	var inst := MeshInstance3D.new()
	inst.mesh = shape
	inst.position = pos
	inst.scale = scale_value
	inst.material_override = _mat(color, 1.0)
	add_child(inst)
	return inst

func _panorama(path: String, pos: Vector3, size: Vector2, rot_y: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("A1.7 panorama missing: " + path)
		return
	var quad := QuadMesh.new()
	quad.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(1,1,1,1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	quad.material = mat
	var card := MeshInstance3D.new()
	card.mesh = quad
	card.position = pos
	card.rotation_degrees.y = rot_y
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)

func _build_panorama() -> void:
	# The approved Riverdale render fills the whole forward frustum. Keeping its
	# edges outside the camera view avoids the "picture floating in the sky" look.
	_panorama("res://docs/visual_reference/01_main_street.png", Vector3(0, 35.0, -78.0), Vector2(310.0, 174.4), 0.0)
	# Rear/side cards only become visible after the player turns away from the
	# opening street vista.
	_panorama("res://docs/visual_reference/02_intersection.png", Vector3(0, 32.0, 92.0), Vector2(250.0, 140.6), 180.0)
	_panorama("res://docs/visual_reference/03_market.png", Vector3(96.0, 32.0, 8.0), Vector2(125.0, 70.3), -90.0)
	_panorama("res://docs/visual_reference/04_workshop.png", Vector3(-96.0, 30.0, 8.0), Vector2(120.0, 67.5), 90.0)

func _road_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.7, 9.2);
		a *= 0.5;
	}
	return v;
}
void fragment() {
	vec2 p = UV * vec2(8.0, 34.0);
	float broad = fbm(p * 0.55);
	float grit = fbm(p * 4.0);
	float puddle = smoothstep(0.70, 0.84, fbm(p * 0.28 + vec2(3.0, 8.0)));
	float crack = smoothstep(0.86, 0.94, abs(fbm(p * 1.8) - 0.50) * 2.0);
	vec3 asphalt = vec3(0.060, 0.064, 0.060);
	asphalt *= 0.60 + broad * 0.72 + grit * 0.24;
	asphalt = mix(asphalt, vec3(0.022, 0.030, 0.030), puddle * 0.72);
	asphalt = mix(asphalt, vec3(0.012, 0.013, 0.012), crack * 0.48);
	ALBEDO = asphalt;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat

func _road_surface() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(13.8, 66.0)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1
	var road := MeshInstance3D.new()
	road.mesh = plane
	road.position = Vector3(0, 0.145, 4)
	road.material_override = _road_material()
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)

func _build_foreground() -> void:
	_road_surface()
	for side in [-1.0, 1.0]:
		_box(Vector3(side*8.15, 0.18, 4), Vector3(2.6,0.22,66), Color(0.22,0.225,0.215),0.96)
		_box(Vector3(side*6.75, 0.30,4),Vector3(0.20,0.44,66),Color(0.29,0.295,0.275),0.93)
	for z in range(-27, 38, 5):
		_box(Vector3(-0.20,0.145,float(z)),Vector3(0.075,0.012,2.25),Color(0.44,0.36,0.10),0.86)
		_box(Vector3(0.20,0.145,float(z)),Vector3(0.075,0.012,2.25),Color(0.44,0.36,0.10),0.86)

func _build_facade(pos: Vector3, size: Vector3, color: Color, right_side: bool) -> void:
	_box(pos,size,color,0.96)
	var face_x: float = pos.x + (-size.x*0.505 if right_side else size.x*0.505)
	for zoff in [-size.z*0.30,0.0,size.z*0.30]:
		for y in [2.2,4.7]:
			if y < size.y - 0.5:
				_box(Vector3(face_x,y,pos.z+zoff),Vector3(0.05,1.35,1.65),Color(0.025,0.05,0.055),0.18,0.16)
	_box(Vector3(face_x,1.45,pos.z),Vector3(0.10,2.4,size.z*0.82),Color(0.045,0.067,0.064),0.22,0.12)
	_box(Vector3(face_x,2.75,pos.z),Vector3(0.18,0.20,size.z*0.92),Color(0.12,0.18,0.13),0.78)

func _build_workshop_front() -> void:
	_box(Vector3(-10.4,2.7,27.0),Vector3(0.45,5.4,10.5),Color(0.17,0.12,0.085),0.94)
	_box(Vector3(-10.15,1.75,27.0),Vector3(0.18,3.1,7.4),Color(0.035,0.055,0.050),0.20,0.15)
	_box(Vector3(-9.85,3.65,27.0),Vector3(0.65,0.55,8.6),Color(0.08,0.19,0.13),0.78)
	var sign := Label3D.new()
	sign.position = Vector3(-9.48,4.05,27.0)
	sign.rotation_degrees.y = 90.0
	sign.text = "RIVERDALE REPAIR"
	sign.font_size = 34
	sign.pixel_size = 0.010
	sign.outline_size = 5
	sign.modulate = Color(0.92,0.84,0.64)
	sign.double_sided = true
	add_child(sign)
	var warm := OmniLight3D.new()
	warm.position = Vector3(-8.9,3.0,27.0)
	warm.light_color = Color(1.0,0.66,0.34)
	warm.light_energy = 1.1
	warm.omni_range = 7.0
	add_child(warm)

func _build_street_furniture() -> void:
	for z in [-20.0,-2.0,17.0,34.0]:
		_lamp(Vector3(-7.2,0,z),1.0)
		_lamp(Vector3(7.2,0,z),-1.0)
	for z in [-23.0,4.0,29.0]:
		_pole(Vector3(10.5,0,z))
	_cyl(Vector3(7.6,0.55,24.0),0.18,1.1,Color(0.45,0.12,0.055))
	_box(Vector3(8.8,0.55,20.5),Vector3(1.0,1.1,0.8),Color(0.08,0.12,0.10),0.95,0.12)

func _lamp(pos: Vector3, inward: float) -> void:
	_cyl(pos+Vector3(0,2.75,0),0.08,5.5,Color(0.08,0.09,0.085))
	_box(pos+Vector3(inward*0.70,5.25,0),Vector3(1.35,0.08,0.08),Color(0.08,0.09,0.085),0.60,0.45)
	_box(pos+Vector3(inward*1.30,5.05,0),Vector3(0.38,0.20,0.25),Color(0.17,0.16,0.12),0.42,0.50)

func _pole(pos: Vector3) -> void:
	_cyl(pos+Vector3(0,3.4,0),0.13,6.8,Color(0.18,0.11,0.06))
	_box(pos+Vector3(0,5.7,0),Vector3(2.2,0.12,0.12),Color(0.15,0.095,0.055),0.94)

func _create_car(pos: Vector3, yaw_deg: float, color: Color, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = yaw_deg
	add_child(root)
	var lower := BoxMesh.new()
	lower.size = Vector3(1.8,0.55,3.7)*scale_factor
	var body := MeshInstance3D.new()
	body.mesh=lower
	body.position=Vector3(0,0.45,0)
	body.material_override=_mat(color,0.93,0.08)
	root.add_child(body)
	var upper := BoxMesh.new()
	upper.size = Vector3(1.45,0.55,1.8)*scale_factor
	var cabin := MeshInstance3D.new()
	cabin.mesh=upper
	cabin.position=Vector3(0,0.93,-0.12)
	cabin.material_override=_mat(color.darkened(0.10),0.91,0.08)
	root.add_child(cabin)
	for sx in [-0.90,0.90]:
		for sz in [-1.20,1.20]:
			var wm:=CylinderMesh.new()
			wm.top_radius=0.33*scale_factor
			wm.bottom_radius=0.33*scale_factor
			wm.height=0.22*scale_factor
			wm.radial_segments=12
			var wheel:=MeshInstance3D.new()
			wheel.mesh=wm
			wheel.position=Vector3(sx*scale_factor,0.30,sz*scale_factor)
			wheel.rotation_degrees=Vector3(0,0,90)
			wheel.material_override=_mat(Color(0.025,0.025,0.022),0.99)
			root.add_child(wheel)
	for side in [-1.0,1.0]:
		var glass_mesh:=BoxMesh.new()
		glass_mesh.size=Vector3(0.025,0.36,1.2)*scale_factor
		var glass:=MeshInstance3D.new()
		glass.mesh=glass_mesh
		glass.position=Vector3(side*0.735*scale_factor,0.98,-0.12)
		glass.material_override=_mat(Color(0.025,0.05,0.055),0.12,0.20)
		root.add_child(glass)
	for i in range(5):
		_ellipsoid(pos+Vector3(rng.randf_range(-0.55,0.55),rng.randf_range(0.65,1.05),rng.randf_range(-1.3,1.3)),Vector3(rng.randf_range(0.25,0.55),rng.randf_range(0.10,0.22),rng.randf_range(0.30,0.65)),Color(0.10,0.25+rng.randf()*0.08,0.07))

func _build_vegetation() -> void:
	# Keep close vegetation low and dark so the high-detail approved environment
	# remains the dominant visual layer instead of being blocked by blob trees.
	for i in range(22):
		var side: float = -1.0 if i%2==0 else 1.0
		var x: float = side*rng.randf_range(7.2,9.3)
		var z: float = rng.randf_range(-42.0,36.0)
		_shrub(Vector3(x,0.18,z),rng.randf_range(0.18,0.42))
	for i in range(58):
		var x: float = rng.randf_range(-9.8,9.8)
		var z: float = rng.randf_range(-30.0,36.0)
		if abs(x) < 5.7 and rng.randf() > 0.10:
			continue
		_grass(Vector3(x,0.20,z))

func _tree(pos: Vector3, scale_factor: float) -> void:
	var h: float = 5.6*scale_factor
	_cyl(pos+Vector3(0,h*0.5,0),0.20*scale_factor,h,Color(0.16,0.095,0.05))
	var centers := [Vector3(0,h*0.93,0),Vector3(0.75,h*0.80,0.15),Vector3(-0.72,h*0.83,-0.18),Vector3(0.20,h*0.72,0.72),Vector3(-0.25,h*0.76,-0.72),Vector3(0.05,h*1.08,-0.15)]
	for off in centers:
		var green := Color(rng.randf_range(0.08,0.15),rng.randf_range(0.25,0.39),rng.randf_range(0.055,0.11))
		_ellipsoid(pos+off*scale_factor,Vector3(rng.randf_range(1.2,1.8),rng.randf_range(0.7,1.2),rng.randf_range(1.1,1.7))*scale_factor,green)

func _shrub(pos: Vector3, scale_factor: float) -> void:
	for i in range(3):
		_ellipsoid(pos+Vector3(rng.randf_range(-0.45,0.45),rng.randf_range(0.24,0.48),rng.randf_range(-0.45,0.45))*scale_factor,Vector3(rng.randf_range(0.45,0.80),rng.randf_range(0.30,0.55),rng.randf_range(0.45,0.80))*scale_factor,Color(0.055+rng.randf()*0.025,0.15+rng.randf()*0.055,0.035+rng.randf()*0.025))

func _grass(pos: Vector3) -> void:
	for i in range(3):
		_box(pos+Vector3(rng.randf_range(-0.12,0.12),0.12,rng.randf_range(-0.12,0.12)),Vector3(0.022,rng.randf_range(0.18,0.42),0.022),Color(0.07,0.18+rng.randf()*0.045,0.035),1.0)

func _cleanup_hud(hud: CanvasLayer) -> void:
	if hud == null:
		return
	for label in hud.find_children("*","Label",true,false):
		var t := str(label.text)
		if t.begins_with("ПОСЛЕ НУЛЯ") or t.contains("WASD"):
			label.visible = false
		elif t.begins_with("HP"):
			label.position = Vector2(24,20)
			label.add_theme_font_size_override("font_size",13)
		elif t.begins_with("ТЕКУЩАЯ ЗАДАЧА"):
			label.position = Vector2(24,48)
			label.size = Vector2(430,52)
			label.add_theme_font_size_override("font_size",12)
		elif t.begins_with("ЭКОСИСТЕМА"):
			label.visible = false
		elif t.begins_with("ШУМ"):
			label.position = Vector2(24,680)
			label.add_theme_font_size_override("font_size",10)
	var plate := ColorRect.new()
	plate.position = Vector2(14,12)
	plate.size = Vector2(455,102)
	plate.color = Color(0.008,0.014,0.012,0.40)
	plate.z_index = -8
	hud.add_child(plate)
	var tag := Label.new()
	tag.position = Vector2(1110,18)
	tag.size = Vector2(145,18)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.text = "AFTER ZERO  ·  A1.7"
	tag.add_theme_font_size_override("font_size",10)
	tag.modulate = Color(0.82,0.84,0.76,0.70)
	hud.add_child(tag)
