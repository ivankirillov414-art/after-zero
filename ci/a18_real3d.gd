extends Node3D

# AFTER ZERO A1.8 — true 3D visual environment.
# All visible world geometry below is generated as real 3D meshes. The old
# graybox is kept only as invisible collision / interaction scaffolding.

var world: Node3D
var rng := RandomNumberGenerator.new()
var mats: Dictionary = {}

func build(target_world: Node3D, player: Node3D, hud: CanvasLayer) -> void:
	world = target_world
	rng.seed = 180923
	_disable_photo_shell(target_world)
	_hide_graybox_keep_gameplay(target_world)
	_tune_environment(target_world)
	_create_materials()
	_build_ground_and_roads()
	_build_workshop()
	_build_market()
	_build_town_blocks()
	_build_gas_station()
	_build_greenbelt_lab()
	_build_street_props()
	_build_abandoned_cars()
	_build_vegetation()
	_build_grass_multimesh()
	_cleanup_hud(hud)
	if player:
		player.position = Vector3(0.0, 0.35, 34.0)
		player.rotation_degrees.y = 0.0
		for camera in player.find_children("*", "Camera3D", true, false):
			camera.fov = 72.0

func _disable_photo_shell(target_world: Node3D) -> void:
	for child in target_world.get_children():
		var script = child.get_script()
		if script != null and str(script.resource_path).contains("a17_polish.gd"):
			if child is Node3D:
				child.visible = false

func _script_ancestor_path(node: Node, stop: Node) -> String:
	var p := node.get_parent()
	while p != null and p != stop:
		var script = p.get_script()
		if script != null:
			return str(script.resource_path)
		p = p.get_parent()
	return ""

func _hide_graybox_keep_gameplay(target_world: Node3D) -> void:
	# Hide all old world art, including the A1.7 photo-card shell. Re-enable only
	# visuals that belong to real gameplay scripts such as pickups/enemies.
	for label in target_world.find_children("*", "Label3D", true, false):
		label.visible = false
	for mesh in target_world.find_children("*", "MeshInstance3D", true, false):
		var owner_script: String = _script_ancestor_path(mesh, target_world)
		mesh.visible = owner_script != "" and not owner_script.contains("a17_polish.gd")

func _tune_environment(target_world: Node3D) -> void:
	for child in target_world.get_children():
		if child is WorldEnvironment and child.environment:
			var env: Environment = child.environment
			var sky := Sky.new()
			var sky_mat := ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color(0.09,0.20,0.34)
			sky_mat.sky_horizon_color = Color(0.70,0.78,0.76)
			sky_mat.ground_bottom_color = Color(0.08,0.10,0.07)
			sky_mat.ground_horizon_color = Color(0.34,0.42,0.32)
			sky_mat.sun_angle_max = 16.0
			sky_mat.sun_curve = 0.10
			sky.sky_material = sky_mat
			env.background_mode = Environment.BG_SKY
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_color = Color(0.68, 0.72, 0.62)
			env.ambient_light_energy = 0.56
			env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			env.tonemap_exposure = 1.08
			env.fog_enabled = true
			env.fog_light_color = Color(0.54, 0.64, 0.62)
			env.fog_light_energy = 0.34
			env.fog_density = 0.0018
			env.fog_height = -1.0
			env.fog_height_density = 0.028
		elif child is DirectionalLight3D:
			child.rotation_degrees = Vector3(-42.0, -34.0, 0.0)
			child.light_color = Color(1.0, 0.88, 0.70)
			child.light_energy = 1.18
			child.shadow_enabled = true

func _std(color: Color, roughness: float = 0.88, metallic: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _brick_material(base: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color = vec3(0.34, 0.15, 0.09);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
	vec2 uv = UV * vec2(18.0, 28.0);
	float row = floor(uv.y);
	uv.x += mod(row,2.0)*0.5;
	vec2 cell = fract(uv);
	float mortar = 1.0 - step(0.055, min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
	float variation = 0.82 + 0.22*hash(floor(uv));
	vec3 brick = base_color * variation;
	vec3 mortar_col = vec3(0.30,0.29,0.25);
	ALBEDO = mix(brick,mortar_col,mortar);
	ROUGHNESS = 0.92;
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("base_color", Vector3(base.r, base.g, base.b))
	return m

func _asphalt_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float noise(vec2 p){
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){float v=0.0; float a=0.5; for(int i=0;i<5;i++){v+=a*noise(p);p=p*2.04+vec2(13.7,9.1);a*=0.5;}return v;}
void fragment(){
	vec2 p=UV*vec2(8.0,42.0);
	float n=fbm(p*0.75); float grit=fbm(p*5.0);
	float wet=smoothstep(0.72,0.86,fbm(p*0.30+vec2(8.0,2.0)));
	float crack=smoothstep(0.88,0.965,abs(fbm(p*2.0)-0.5)*2.0);
	vec3 c=vec3(0.085,0.086,0.078)*(0.68+n*0.55+grit*0.11);
	c=mix(c,vec3(0.025,0.034,0.034),wet*0.62);
	c=mix(c,vec3(0.018),crack*0.55);
	ALBEDO=c; ROUGHNESS=mix(0.96,0.28,wet*0.78);
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	return m

func _create_materials() -> void:
	mats["brick_red"] = _brick_material(Color(0.36,0.16,0.09))
	mats["brick_dark"] = _brick_material(Color(0.25,0.12,0.07))
	mats["concrete"] = _std(Color(0.36,0.36,0.32),0.94)
	mats["concrete_dark"] = _std(Color(0.24,0.25,0.23),0.96)
	mats["asphalt"] = _asphalt_material()
	mats["metal_dark"] = _std(Color(0.075,0.085,0.080),0.48,0.55)
	mats["metal_rust"] = _std(Color(0.30,0.13,0.065),0.88,0.26)
	mats["glass"] = _std(Color(0.025,0.070,0.078,0.68),0.12,0.14,true)
	mats["wood"] = _std(Color(0.24,0.13,0.065),0.94)
	mats["green_dark"] = _std(Color(0.075,0.20,0.07),0.99)
	mats["green_mid"] = _std(Color(0.12,0.30,0.085),0.99)
	mats["green_light"] = _std(Color(0.20,0.39,0.10),0.99)
	mats["yellow"] = _std(Color(0.48,0.36,0.08),0.88)
	mats["paint_green"] = _std(Color(0.075,0.22,0.16),0.82)
	mats["paint_cream"] = _std(Color(0.58,0.55,0.43),0.90)
	mats["white"] = _std(Color(0.67,0.67,0.61),0.92)
	mats["rubber"] = _std(Color(0.018,0.019,0.018),0.99)

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.rotation_degrees = rot
	inst.material_override = material
	parent.add_child(inst)
	return inst

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, rot: Vector3 = Vector3.ZERO, segments: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.rotation_degrees = rot
	inst.material_override = material
	parent.add_child(inst)
	return inst

func _sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, material: Material, segments: int = 10) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = 6
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.scale = scale_value
	inst.material_override = material
	parent.add_child(inst)
	return inst

func _plane(parent: Node3D, pos: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = material
	parent.add_child(inst)
	return inst

func _label(parent: Node3D, text_value: String, pos: Vector3, rot: Vector3, size: int = 42, color: Color = Color(0.88,0.84,0.70)) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = pos
	label.rotation_degrees = rot
	label.font_size = size
	label.pixel_size = 0.010
	label.outline_size = 6
	label.modulate = color
	label.double_sided = true
	parent.add_child(label)
	return label

func _building_root(name_value: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = name_value
	root.position = pos
	add_child(root)
	return root

func _build_ground_and_roads() -> void:
	_plane(self,Vector3(0,-0.035,0),Vector2(92,92),mats["green_dark"])
	_plane(self,Vector3(0,0.012,0),Vector2(14,84),mats["asphalt"])
	_plane(self,Vector3(0,0.016,8),Vector2(82,12),mats["asphalt"])
	for side in [-1.0,1.0]:
		_box(self,Vector3(side*8.0,0.10,0),Vector3(2.6,0.20,84),mats["concrete"])
		_box(self,Vector3(side*6.65,0.22,0),Vector3(0.22,0.42,84),mats["concrete_dark"])
	for z in range(-38,40,5):
		_box(self,Vector3(-0.17,0.030,float(z)),Vector3(0.08,0.018,2.4),mats["yellow"])
		_box(self,Vector3(0.17,0.030,float(z)),Vector3(0.08,0.018,2.4),mats["yellow"])
	for x in range(-5,6,2):
		_box(self,Vector3(float(x),0.032,8.0),Vector3(0.72,0.018,3.2),mats["white"])
	var puddle := _std(Color(0.07,0.13,0.14,0.38),0.10,0.05,true)
	for p in [Vector3(-2.5,0.04,-7),Vector3(2.7,0.04,18),Vector3(-3.5,0.04,31)]:
		var q := QuadMesh.new()
		q.size = Vector2(rng.randf_range(1.4,2.8),rng.randf_range(0.7,1.4))
		var mi := MeshInstance3D.new()
		mi.mesh=q; mi.position=p; mi.rotation_degrees=Vector3(-90,0,rng.randf_range(-20,20)); mi.material_override=puddle
		add_child(mi)

func _build_workshop() -> void:
	var root := _building_root("WorkshopVisual",Vector3(-22,0,7))
	_box(root,Vector3(0,0.10,0),Vector3(10,0.20,8),mats["concrete_dark"])
	_box(root,Vector3(0,2.5,3.85),Vector3(10,5,0.30),mats["brick_dark"])
	_box(root,Vector3(-4.85,2.5,0),Vector3(0.30,5,8),mats["brick_dark"])
	_box(root,Vector3(4.85,2.5,0),Vector3(0.30,5,8),mats["brick_dark"])
	_box(root,Vector3(0,5.05,0),Vector3(10,0.30,8),mats["metal_dark"])
	_box(root,Vector3(0,4.55,-3.88),Vector3(9.7,0.72,0.35),mats["paint_green"])
	_box(root,Vector3(-4.35,2.2,-3.88),Vector3(0.60,4.4,0.35),mats["metal_dark"])
	_box(root,Vector3(4.35,2.2,-3.88),Vector3(0.60,4.4,0.35),mats["metal_dark"])
	_label(root,"RIVERDALE REPAIR",Vector3(0,4.62,-4.08),Vector3(0,0,0),38)
	_box(root,Vector3(-2.8,0.92,2.8),Vector3(3.8,0.22,0.95),mats["wood"])
	for x in [-4.35,-1.25]:
		for z in [2.45,3.15]:
			_box(root,Vector3(x,0.46,z),Vector3(0.12,0.92,0.12),mats["metal_dark"])
	_box(root,Vector3(3.8,1.65,2.9),Vector3(1.35,3.0,0.45),mats["metal_dark"])
	for y in [0.45,1.20,1.95,2.70]:
		_box(root,Vector3(3.8,y,2.65),Vector3(1.25,0.10,0.62),mats["metal_dark"])
	_box(root,Vector3(2.0,0.80,2.9),Vector3(1.35,1.55,0.65),mats["metal_rust"])
	_box(root,Vector3(-3.8,0.62,0.4),Vector3(1.6,1.15,1.0),mats["paint_green"])
	for x in [-2.4,2.4]:
		var light := OmniLight3D.new()
		light.position=Vector3(x,3.8,0.8); light.light_color=Color(1.0,0.64,0.32); light.light_energy=1.7; light.omni_range=7.0
		root.add_child(light)
	_vine(root,Vector3(-4.72,0.4,-3.8),Vector3(-4.70,4.4,-3.8),5)
	_vine(root,Vector3(4.72,0.4,3.65),Vector3(4.70,4.5,3.65),5)

func _storefront_windows(root: Node3D, front_x: float, z_center: float, z_span: float, count: int) -> void:
	var step: float = z_span / float(count)
	for i in range(count):
		var z: float = z_center - z_span*0.5 + step*(float(i)+0.5)
		_box(root,Vector3(front_x,1.55,z),Vector3(0.09,2.35,step*0.72),mats["glass"])
		_box(root,Vector3(front_x-0.03,2.76,z),Vector3(0.13,0.10,step*0.80),mats["metal_dark"])

func _build_market() -> void:
	var root := _building_root("PineRidgeMarketVisual",Vector3(22,0,22))
	_box(root,Vector3(0,2.35,0),Vector3(18,4.7,12),mats["brick_red"])
	_box(root,Vector3(0,4.82,0),Vector3(18.5,0.26,12.5),mats["concrete_dark"])
	_storefront_windows(root,-9.06,0,9.0,4)
	_box(root,Vector3(-9.18,3.28,0),Vector3(0.25,0.38,10.2),mats["paint_green"])
	_label(root,"PINE RIDGE MARKET",Vector3(-9.37,3.72,0),Vector3(0,-90,0),36)
	_box(root,Vector3(-9.12,1.35,-4.55),Vector3(0.12,2.55,1.45),mats["glass"])
	for z in [-5.5,5.5]:
		_vine(root,Vector3(-9.12,0.35,z),Vector3(-9.08,4.5,z),7)
	for i in range(8):
		_leaf_cluster(root,Vector3(rng.randf_range(-7,7),5.0,rng.randf_range(-5,5)),rng.randf_range(0.45,0.85))

func _build_town_blocks() -> void:
	_build_shop_block("HardwareBlock",Vector3(-20,0,-18),Vector3(18,10,20),mats["brick_red"],"RIVERDALE HARDWARE",true)
	_build_shop_block("CivicBlock",Vector3(20,0,-20),Vector3(16,14,18),mats["brick_dark"],"MAIN STREET",false)
	_build_garage_row()

func _build_shop_block(name_value: String, pos: Vector3, size: Vector3, material: Material, sign_text: String, left_side: bool) -> void:
	var root := _building_root(name_value,pos)
	_box(root,Vector3(0,size.y*0.5,0),size,material)
	_box(root,Vector3(0,size.y+0.18,0),Vector3(size.x+0.4,0.30,size.z+0.4),mats["concrete_dark"])
	var front_x: float = size.x*0.5+0.06 if left_side else -size.x*0.5-0.06
	var rot_y: float = 90.0 if left_side else -90.0
	var stories: int = int(max(2.0,floor(size.y/3.1)))
	for story in range(stories):
		var y: float = 2.0 + float(story)*3.0
		if y > size.y-0.7: continue
		for i in range(5):
			var z: float = -size.z*0.38 + float(i)*(size.z*0.76/4.0)
			_box(root,Vector3(front_x,y,z),Vector3(0.09,1.55,2.0),mats["glass"])
			_box(root,Vector3(front_x-0.02 if left_side else front_x+0.02,y,z),Vector3(0.14,1.78,2.22),mats["metal_dark"])
			_box(root,Vector3(front_x,y,z),Vector3(0.10,1.45,1.85),mats["glass"])
	_box(root,Vector3(front_x,3.05,0),Vector3(0.55,0.22,size.z*0.82),mats["paint_green"])
	_label(root,sign_text,Vector3(front_x + (0.24 if left_side else -0.24),3.55,0),Vector3(0,rot_y,0),34)
	for z in [-size.z*0.45,size.z*0.45]:
		_vine(root,Vector3(front_x,0.35,z),Vector3(front_x,size.y*0.86,z),8)

func _build_garage_row() -> void:
	var root := _building_root("GarageRowVisual",Vector3(-23,0,25))
	_box(root,Vector3(0,1.75,0),Vector3(22,3.5,9),mats["brick_dark"])
	_box(root,Vector3(0,3.62,0),Vector3(22.4,0.26,9.4),mats["metal_dark"])
	for i in range(4):
		var x: float = -8.0 + float(i)*5.3
		_box(root,Vector3(x,1.45,-4.56),Vector3(4.2,2.65,0.13),mats["metal_dark"])
		for y in [0.65,1.35,2.05]:
			_box(root,Vector3(x,y,-4.65),Vector3(3.8,0.06,0.06),mats["metal_rust"])

func _build_gas_station() -> void:
	var root := _building_root("PineRidgeGasVisual",Vector3(10.8,0,-1.5))
	_box(root,Vector3(0,4.25,0),Vector3(9.5,0.48,6.3),mats["paint_cream"])
	_box(root,Vector3(0,4.50,-3.0),Vector3(9.5,0.55,0.28),mats["paint_green"])
	_label(root,"PINE RIDGE GAS",Vector3(0,4.52,-3.18),Vector3(0,0,0),30)
	for p in [Vector3(-3.7,2.1,-2.3),Vector3(3.7,2.1,-2.3),Vector3(-3.7,2.1,2.3),Vector3(3.7,2.1,2.3)]:
		_cylinder(root,p,0.16,4.2,mats["metal_dark"])
	for x in [-2.2,2.2]:
		_box(root,Vector3(x,0.85,0),Vector3(0.85,1.7,0.72),mats["metal_rust"])
		_box(root,Vector3(x,1.18,-0.38),Vector3(0.48,0.38,0.05),mats["glass"])
	_box(root,Vector3(5.2,1.35,2.8),Vector3(4.4,2.7,3.2),mats["brick_dark"])
	_box(root,Vector3(5.2,1.45,1.15),Vector3(2.4,1.75,0.08),mats["glass"])

func _build_greenbelt_lab() -> void:
	var root := _building_root("GreenbeltLabVisual",Vector3(33,0,-24))
	_box(root,Vector3(0,3.2,0),Vector3(12,6.4,15),mats["concrete"])
	_box(root,Vector3(0,6.55,0),Vector3(12.4,0.30,15.4),mats["concrete_dark"])
	for x in [-3.8,-1.3,1.3,3.8]:
		_box(root,Vector3(x,2.0,7.56),Vector3(2.0,3.4,0.10),mats["glass"])
	_label(root,"GREENBELT ECOLOGY LAB",Vector3(0,5.15,7.75),Vector3(0,0,0),32,Color(0.15,0.32,0.19))
	var greenhouse := _building_root("GreenhouseVisual",Vector3(24,0,-32))
	_box(greenhouse,Vector3(0,1.65,0),Vector3(9,3.3,8),_std(Color(0.18,0.34,0.27,0.35),0.18,0.12,true))
	for x in [-4.4,0.0,4.4]:
		_box(greenhouse,Vector3(x,1.7,0),Vector3(0.10,3.5,8.2),mats["metal_dark"])
	for z in [-3.9,0.0,3.9]:
		_box(greenhouse,Vector3(0,1.7,z),Vector3(9.2,3.5,0.10),mats["metal_dark"])
	for i in range(10):
		_leaf_cluster(greenhouse,Vector3(rng.randf_range(-3.8,3.8),0.55,rng.randf_range(-3.2,3.2)),rng.randf_range(0.45,0.8))

func _build_street_props() -> void:
	for z in [-28.0,-11.0,8.0,27.0]:
		_street_lamp(Vector3(-7.5,0,z),1.0)
		_street_lamp(Vector3(7.5,0,z),-1.0)
	for z in [-31.0,-4.0,24.0]:
		_cylinder(self,Vector3(10.6,3.4,z),0.14,6.8,mats["wood"])
		_box(self,Vector3(10.6,5.8,z),Vector3(2.4,0.13,0.13),mats["wood"])
	_box(self,Vector3(8.8,0.55,19.8),Vector3(1.0,1.1,0.82),mats["metal_dark"])
	_cylinder(self,Vector3(7.4,0.58,24.0),0.18,1.16,mats["metal_rust"])
	for p in [Vector3(-8.6,0.36,13),Vector3(8.9,0.36,-18),Vector3(-8.5,0.36,-30)]:
		_box(self,p,Vector3(0.75,0.72,0.75),mats["wood"])

func _street_lamp(pos: Vector3, inward: float) -> void:
	_cylinder(self,pos+Vector3(0,2.7,0),0.075,5.4,mats["metal_dark"])
	_box(self,pos+Vector3(inward*0.65,5.18,0),Vector3(1.25,0.09,0.09),mats["metal_dark"])
	_box(self,pos+Vector3(inward*1.20,5.02,0),Vector3(0.36,0.18,0.28),mats["metal_dark"])

func _build_abandoned_cars() -> void:
	_car(Vector3(-3.3,0.42,-14),-8.0,Color(0.17,0.19,0.17),1.0)
	_car(Vector3(3.4,0.42,16),5.0,Color(0.30,0.15,0.08),0.95)
	_car(Vector3(-2.5,0.42,30),-3.0,Color(0.12,0.15,0.16),0.92)

func _car(pos: Vector3, yaw: float, color: Color, scale_value: float) -> void:
	var root := _building_root("AbandonedCar3D",pos)
	root.rotation_degrees.y=yaw
	var body_mat := _std(color,0.90,0.10)
	_box(root,Vector3(0,0.45,0),Vector3(1.85,0.52,3.8)*scale_value,body_mat)
	_box(root,Vector3(0,0.88,-0.20),Vector3(1.52,0.64,1.90)*scale_value,body_mat)
	_box(root,Vector3(0,0.97,-1.17),Vector3(1.36,0.38,0.05)*scale_value,mats["glass"])
	_box(root,Vector3(0,0.97,0.78),Vector3(1.36,0.38,0.05)*scale_value,mats["glass"])
	for side in [-1.0,1.0]:
		_box(root,Vector3(side*0.77,0.95,-0.18),Vector3(0.05,0.40,1.52)*scale_value,mats["glass"])
	for sx in [-0.90,0.90]:
		for sz in [-1.25,1.25]:
			_cylinder(root,Vector3(sx*scale_value,0.28,sz*scale_value),0.32*scale_value,0.22*scale_value,mats["rubber"],Vector3(0,0,90),14)
	for i in range(4):
		_leaf_cluster(root,Vector3(rng.randf_range(-0.55,0.55),rng.randf_range(0.70,1.05),rng.randf_range(-1.35,1.35)),rng.randf_range(0.25,0.45))

func _build_vegetation() -> void:
	var trees := [
		Vector3(-10.0,0,-31),Vector3(9.8,0,-27),Vector3(-10.6,0,-9),Vector3(10.4,0,10),
		Vector3(-11.0,0,19),Vector3(11.0,0,31),Vector3(-31,0,-3),Vector3(30,0,-7),
		Vector3(-34,0,29),Vector3(37,0,30)
	]
	for p in trees:
		_tree(p,rng.randf_range(0.82,1.18))
	for i in range(88):
		var side: float = -1.0 if i%2==0 else 1.0
		var x: float = side*rng.randf_range(7.0,12.0)
		var z: float = rng.randf_range(-38,38)
		_leaf_cluster(self,Vector3(x,0.35,z),rng.randf_range(0.28,0.65))
	for data in [
		[Vector3(-10.8,0,-24),Vector3(-10.8,7.8,-24)],
		[Vector3(11.8,0,-17),Vector3(11.8,9.0,-17)],
		[Vector3(12.8,0,26),Vector3(12.8,4.2,26)]
	]:
		_vine(self,data[0],data[1],8)

func _tree(pos: Vector3, scale_value: float) -> void:
	var root := _building_root("Tree3D",pos)
	var h: float = 6.2*scale_value
	_cylinder(root,Vector3(0,h*0.5,0),0.22*scale_value,h,mats["wood"],Vector3.ZERO,10)
	for i in range(5):
		var y: float = h*(0.50+float(i)*0.075)
		var angle: float = rng.randf_range(0,360)
		var branch := _cylinder(root,Vector3(0,y,0),0.07*scale_value,2.2*scale_value,mats["wood"],Vector3(62,angle,0),8)
		branch.position += Vector3(sin(deg_to_rad(angle))*0.45,0,cos(deg_to_rad(angle))*0.45)
	for i in range(12):
		var angle: float = TAU*float(i)/12.0 + rng.randf_range(-0.25,0.25)
		var r: float = rng.randf_range(0.6,1.8)*scale_value
		var y: float = rng.randf_range(h*0.62,h*1.03)
		var mat: Material = mats["green_dark"] if i%3==0 else (mats["green_mid"] if i%3==1 else mats["green_light"])
		_sphere(root,Vector3(cos(angle)*r,y,sin(angle)*r),Vector3(rng.randf_range(1.2,2.0),rng.randf_range(0.75,1.3),rng.randf_range(1.1,1.9))*scale_value,mat,10)

func _leaf_cluster(parent: Node3D, pos: Vector3, scale_value: float) -> void:
	for i in range(3):
		var mat: Material = mats["green_dark"] if i==0 else mats["green_mid"]
		_sphere(parent,pos+Vector3(rng.randf_range(-0.35,0.35),rng.randf_range(0.1,0.5),rng.randf_range(-0.35,0.35))*scale_value,Vector3(rng.randf_range(0.6,1.0),rng.randf_range(0.38,0.72),rng.randf_range(0.6,1.0))*scale_value,mat,8)

func _vine(parent: Node3D, start: Vector3, finish: Vector3, leaves: int) -> void:
	var delta: Vector3 = finish-start
	var height: float = delta.length()
	var middle: Vector3 = (start+finish)*0.5
	_cylinder(parent,middle,0.035,height,mats["green_dark"],Vector3.ZERO,6)
	for i in range(leaves):
		var t: float = float(i+1)/float(leaves+1)
		var p: Vector3 = start.lerp(finish,t)+Vector3(rng.randf_range(-0.25,0.25),0,rng.randf_range(-0.25,0.25))
		_sphere(parent,p,Vector3(0.18,0.10,0.28),mats["green_mid"],6)

func _build_grass_multimesh() -> void:
	var blade := QuadMesh.new()
	blade.size = Vector2(0.040,0.38)
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.055,0.14,0.035)
	grass_mat.roughness=1.0
	grass_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	blade.material=grass_mat
	var mm := MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=blade
	mm.instance_count=620
	for i in range(mm.instance_count):
		var x: float
		if i%2==0: x=rng.randf_range(-13.0,-6.8)
		else: x=rng.randf_range(6.8,13.0)
		var z: float=rng.randf_range(-39,39)
		var angle: float=rng.randf_range(0,TAU)
		var scale_y: float=rng.randf_range(0.55,1.35)
		var basis := Basis(Vector3.UP,angle).scaled(Vector3(rng.randf_range(0.75,1.25),scale_y,rng.randf_range(0.75,1.25)))
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,0.26,z)))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh=mm
	add_child(inst)

func _cleanup_hud(hud: CanvasLayer) -> void:
	if hud == null: return
	var stealth = world.get("stealth_label")
	if stealth != null:
		stealth.visible = false
	var eco = world.get("ecosystem_label")
	if eco != null:
		eco.visible = false
	for label in hud.find_children("*","Label",true,false):
		var txt: String = str(label.text)
		if txt.begins_with("ПОСЛЕ НУЛЯ") or txt.contains("WASD") or txt.begins_with("ЭКОСИСТЕМА") or txt.begins_with("ШУМ"):
			label.visible=false
		elif txt.begins_with("HP"):
			label.position=Vector2(22,18); label.add_theme_font_size_override("font_size",13)
		elif txt.begins_with("ТЕКУЩАЯ ЗАДАЧА"):
			label.position=Vector2(22,48); label.size=Vector2(410,52); label.add_theme_font_size_override("font_size",12)
	for old in hud.find_children("*","Label",true,false):
		if str(old.text).contains("A1.7"):
			old.visible=false
	var tag := Label.new()
	tag.position=Vector2(1080,18); tag.size=Vector2(175,18); tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	tag.text="AFTER ZERO  ·  REAL 3D A1.8"; tag.add_theme_font_size_override("font_size",10); tag.modulate=Color(0.86,0.87,0.80,0.70)
	hud.add_child(tag)
