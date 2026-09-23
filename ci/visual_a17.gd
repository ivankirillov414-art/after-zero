extends Node3D

var root_world: Node3D
var rng := RandomNumberGenerator.new()

func build(world: Node3D, player: Node3D, hud: CanvasLayer) -> void:
	root_world = world
	rng.seed = 170923
	_hide_legacy(world)
	_tune_environment(world)
	_build_ground_and_streets()
	_build_workshop()
	_build_hardware_block()
	_build_market()
	_build_corner_block()
	_build_street_props()
	_build_vehicles()
	_build_vegetation()
	_build_horizon()
	_cleanup_hud(hud)
	if player:
		player.position = Vector3(-22.0, 0.25, 5.8)
		player.rotation_degrees.y = -24.0

func _hide_legacy(world: Node3D) -> void:
	var hide_names := {
		"BlockA":true,"BlockB":true,"Store":true,"Garages":true,
		"AbandonedCar":true,"Debris":true,"TreeTrunk":true,
		"BusShell":true,"MarketAnnex":true,"LabWing":true,
		"LabGreenhouse":true,"LabService":true
	}
	for child in world.get_children():
		if child is Label3D:
			child.visible = false
		elif child is MeshInstance3D and child.mesh is SphereMesh:
			child.visible = false
		elif hide_names.has(str(child.name)):
			for mesh in child.find_children("*", "MeshInstance3D", true, false):
				mesh.visible = false

func _tune_environment(world: Node3D) -> void:
	for child in world.get_children():
		if child is WorldEnvironment and child.environment:
			var env := child.environment
			var sky := Sky.new()
			var sm := ProceduralSkyMaterial.new()
			sm.sky_top_color = Color(0.08, 0.16, 0.27)
			sm.sky_horizon_color = Color(0.78, 0.78, 0.68)
			sm.ground_bottom_color = Color(0.06, 0.075, 0.06)
			sm.ground_horizon_color = Color(0.38, 0.43, 0.34)
			sm.sun_angle_max = 18.0
			sm.sun_curve = 0.08
			sky.sky_material = sm
			env.background_mode = Environment.BG_SKY
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_energy = 0.52
			env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
			env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			env.tonemap_exposure = 1.08
			env.fog_enabled = true
			env.fog_light_color = Color(0.70,0.73,0.64)
			env.fog_light_energy = 0.55
			env.fog_density = 0.0042
			env.fog_height = 1.7
			env.fog_height_density = 0.11
		elif child is DirectionalLight3D:
			child.light_energy = 1.18
			child.light_color = Color(1.0,0.86,0.66)
			child.rotation_degrees = Vector3(-43,-34,0)
			child.shadow_enabled = true
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,145,0)
	fill.light_energy = 0.11
	fill.light_color = Color(0.48,0.62,0.78)
	add_child(fill)

func _mat(color: Color, roughness: float = 0.85, metallic: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(pos: Vector3, size: Vector3, color: Color, roughness: float = 0.85, metallic: float = 0.0, transparent: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _mat(color, roughness, metallic, transparent)
	add_child(inst)
	return inst

func _cylinder(pos: Vector3, radius: float, height: float, color: Color, rot: Vector3 = Vector3.ZERO, roughness: float = 0.9, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.90
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.rotation_degrees = rot
	inst.material_override = _mat(color,roughness,metallic)
	add_child(inst)
	return inst

func _sphere(pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 7
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.scale = scale_value
	inst.material_override = _mat(color,1.0)
	add_child(inst)
	return inst

func _label(pos: Vector3, text: String, size: int, rot_y: float, color: Color = Color(0.86,0.81,0.64)) -> void:
	var label := Label3D.new()
	label.position = pos
	label.rotation_degrees.y = rot_y
	label.text = text
	label.font_size = size
	label.outline_size = max(3,int(size*0.12))
	label.pixel_size = 0.010
	label.modulate = color
	label.double_sided = false
	add_child(label)

func _window_z(pos: Vector3, size: Vector2) -> void:
	_box(pos,Vector3(size.x,size.y,0.045),Color(0.035,0.065,0.075),0.12,0.18)
	_box(pos+Vector3(0,0,-0.03),Vector3(size.x+0.16,0.07,0.03),Color(0.11,0.11,0.10),0.6,0.22)
	_box(pos+Vector3(0,0,-0.03),Vector3(0.07,size.y+0.16,0.03),Color(0.11,0.11,0.10),0.6,0.22)

func _window_x(pos: Vector3, size: Vector2) -> void:
	_box(pos,Vector3(0.045,size.y,size.x),Color(0.035,0.065,0.075),0.12,0.18)
	_box(pos+Vector3(-0.03,0,0),Vector3(0.03,0.07,size.x+0.16),Color(0.11,0.11,0.10),0.6,0.22)
	_box(pos+Vector3(-0.03,0,0),Vector3(0.03,size.y+0.16,0.07),Color(0.11,0.11,0.10),0.6,0.22)

func _build_ground_and_streets() -> void:
	_box(Vector3(0,0.055,0),Vector3(13.1,0.06,91),Color(0.065,0.070,0.067),0.96)
	_box(Vector3(0,0.065,8),Vector3(91,0.06,10.6),Color(0.065,0.070,0.067),0.96)
	for x in [-8.15,8.15]:
		_box(Vector3(x,0.18,0),Vector3(2.9,0.22,91),Color(0.31,0.315,0.29),0.94)
		_box(Vector3(x + (1.52 if x < 0 else -1.52),0.28,0),Vector3(0.18,0.40,91),Color(0.43,0.42,0.37),0.9)
	for x in [-0.20,0.20]:
		for z in range(-42,44,5):
			_box(Vector3(x,0.10,float(z)),Vector3(0.10,0.018,2.7),Color(0.68,0.57,0.20),0.85)
	for x in range(-5,6,2):
		_box(Vector3(float(x),0.10,4.9),Vector3(1.15,0.018,0.28),Color(0.60,0.60,0.56),0.9)
	for p in [Vector3(2.1,0.11,-4.0),Vector3(-2.3,0.11,22.0),Vector3(3.2,0.11,35.0)]:
		_box(p,Vector3(2.3,0.012,0.95),Color(0.10,0.18,0.20,0.62),0.12,0.05,true)

func _build_workshop() -> void:
	_box(Vector3(-22,5.20,2.73),Vector3(10.2,0.58,0.36),Color(0.10,0.18,0.14),0.82)
	_box(Vector3(-26.9,2.75,7),Vector3(0.36,5.5,9),Color(0.27,0.15,0.10),0.93)
	_box(Vector3(-22,5.42,7),Vector3(10.2,0.35,9.1),Color(0.10,0.105,0.095),0.9)
	for x in [-26.6,-17.4]:
		_box(Vector3(x,2.75,2.77),Vector3(0.36,5.5,0.36),Color(0.10,0.10,0.09),0.78,0.08)
	_box(Vector3(-22,4.75,2.54),Vector3(8.8,0.72,0.18),Color(0.11,0.20,0.15),0.75)
	_label(Vector3(-22,4.72,2.42),"RIVERDALE REPAIR",34,180,Color(0.88,0.81,0.61))
	for x in [-25.9,-24.8,-19.7]:
		_box(Vector3(x,1.55,9.9),Vector3(0.95,3.0,0.55),Color(0.09,0.10,0.09),0.62,0.20)
	_box(Vector3(-23.2,0.88,8.5),Vector3(2.6,1.25,1.05),Color(0.25,0.16,0.09),0.9)
	_box(Vector3(-19.3,1.0,9.9),Vector3(2.2,1.55,0.35),Color(0.43,0.39,0.29),0.92)
	for p in [Vector3(-24.4,3.8,6.2),Vector3(-19.7,3.8,8.8)]:
		var l:=OmniLight3D.new()
		l.position=p
		l.omni_range=7.0
		l.light_energy=1.2
		l.light_color=Color(1.0,0.72,0.40)
		add_child(l)
	_create_car(Vector3(-20.3,0.58,5.1),-0.25,Color(0.17,0.20,0.17),0.88)

func _build_hardware_block() -> void:
	_box(Vector3(-20.4,4.6,-18),Vector3(15.2,9.2,20.2),Color(0.31,0.16,0.105),0.96)
	_box(Vector3(-20.4,0.72,-7.82),Vector3(15.3,1.35,0.26),Color(0.22,0.20,0.17),0.92)
	for y in [2.7,5.5,8.55]:
		_box(Vector3(-20.4,y,-7.72),Vector3(15.5,0.20,0.22),Color(0.48,0.34,0.23),0.86)
	for x in [-25.7,-22.2,-18.7,-15.2]:
		for y in [3.7,6.8]:
			_window_z(Vector3(x,y,-7.65),Vector2(2.1,1.65))
	_box(Vector3(-20.4,1.55,-7.62),Vector3(13.0,2.55,0.07),Color(0.045,0.075,0.078),0.16,0.18)
	_box(Vector3(-20.4,2.75,-7.25),Vector3(13.8,0.22,0.85),Color(0.10,0.22,0.17),0.78)
	_label(Vector3(-20.4,4.15,-7.48),"RIVERDALE HARDWARE",30,180)
	_vines_on_wall(Vector3(-25.4,4.7,-7.45),Vector3(1.0,3.7,0.2))

func _build_market() -> void:
	_box(Vector3(21.0,2.55,22.0),Vector3(17.2,5.1,14.2),Color(0.29,0.27,0.22),0.94)
	_box(Vector3(12.30,1.55,22),Vector3(0.06,2.65,11.6),Color(0.045,0.075,0.078),0.15,0.18)
	_box(Vector3(11.80,2.85,22),Vector3(1.05,0.22,12.5),Color(0.11,0.23,0.16),0.76)
	_label(Vector3(12.16,4.05,22),"PINE RIDGE MARKET",28,90)
	for z in [18.0,22.0,26.0]:
		_window_x(Vector3(12.24,1.55,z),Vector2(2.7,2.2))
	_vines_on_wall(Vector3(12.05,3.6,26.0),Vector3(0.25,2.6,1.5))

func _build_corner_block() -> void:
	_box(Vector3(21.0,5.6,-18.0),Vector3(14.2,11.2,18.2),Color(0.25,0.22,0.19),0.95)
	for z in [-24.0,-20.0,-16.0,-12.0]:
		for y in [3.0,6.0,8.7]:
			_window_x(Vector3(13.82,y,z),Vector2(1.8,1.5))
	_box(Vector3(13.35,2.45,-18),Vector3(1.0,0.22,15.6),Color(0.16,0.20,0.15),0.8)
	_label(Vector3(13.68,4.2,-18),"RIVERDALE MARKET",24,90)

func _build_street_props() -> void:
	for z in [-31.0,-9.0,18.0,35.0]:
		_street_light(Vector3(-7.0,0,z),1.0)
		_street_light(Vector3(7.0,0,z),-1.0)
	for z in [-36.0,-12.0,13.0,36.0]:
		_utility_pole(Vector3(11.1,0,z))
	_cylinder(Vector3(-7.8,1.55,7.8),0.07,3.1,Color(0.19,0.20,0.18),Vector3.ZERO,0.7,0.4)
	_label(Vector3(-7.75,2.65,7.8),"MAIN ST",18,-90,Color(0.78,0.84,0.72))
	_cylinder(Vector3(7.7,1.25,-2.0),0.06,2.5,Color(0.19,0.20,0.18),Vector3.ZERO,0.7,0.4)
	_label(Vector3(7.64,2.05,-2.0),"SPEED\n25",13,90,Color(0.84,0.83,0.72))

func _build_vehicles() -> void:
	_create_car(Vector3(-2.8,0.56,-15),0.10,Color(0.18,0.22,0.19),1.0)
	_create_car(Vector3(3.1,0.56,18),-0.08,Color(0.30,0.19,0.15),1.0)
	_create_car(Vector3(-2.1,0.56,30),0.03,Color(0.15,0.17,0.19),0.95)
	_school_bus(Vector3(-2.9,1.25,7.3),-0.02)

func _create_car(pos: Vector3, yaw: float, color: Color, scale_factor: float) -> void:
	var r:=Node3D.new()
	r.position=pos
	r.rotation.y=yaw
	add_child(r)
	var lower:=BoxMesh.new()
	lower.size=Vector3(1.75,0.62,3.65)*scale_factor
	var li:=MeshInstance3D.new()
	li.mesh=lower
	li.position=Vector3(0,0.48,0)
	li.material_override=_mat(color,0.92,0.08)
	r.add_child(li)
	var roof:=BoxMesh.new()
	roof.size=Vector3(1.45,0.58,1.85)*scale_factor
	var ri:=MeshInstance3D.new()
	ri.mesh=roof
	ri.position=Vector3(0,0.98,-0.15)
	ri.material_override=_mat(color.darkened(0.08),0.9,0.08)
	r.add_child(ri)
	for sx in [-0.88,0.88]:
		for sz in [-1.18,1.18]:
			var wm:=CylinderMesh.new()
			wm.top_radius=0.34*scale_factor
			wm.bottom_radius=0.34*scale_factor
			wm.height=0.24*scale_factor
			wm.radial_segments=12
			var wi:=MeshInstance3D.new()
			wi.mesh=wm
			wi.position=Vector3(sx*scale_factor,0.32,sz*scale_factor)
			wi.rotation_degrees=Vector3(0,0,90)
			wi.material_override=_mat(Color(0.03,0.03,0.028),0.98)
			r.add_child(wi)
	for side in [-1.0,1.0]:
		var win:=BoxMesh.new()
		win.size=Vector3(0.03,0.38,1.25)*scale_factor
		var w:=MeshInstance3D.new()
		w.mesh=win
		w.position=Vector3(side*0.735*scale_factor,1.02,-0.15)
		w.material_override=_mat(Color(0.03,0.055,0.06),0.16,0.18)
		r.add_child(w)
	var moss:=SphereMesh.new()
	moss.radius=0.5
	moss.height=1.0
	moss.radial_segments=8
	moss.rings=5
	var mi:=MeshInstance3D.new()
	mi.mesh=moss
	mi.position=Vector3(0.34,0.88,1.28)*scale_factor
	mi.scale=Vector3(0.45,0.12,0.52)*scale_factor
	mi.material_override=_mat(Color(0.17,0.29,0.10),1.0)
	r.add_child(mi)

func _school_bus(pos: Vector3, yaw: float) -> void:
	var r:=Node3D.new()
	r.position=pos
	r.rotation.y=yaw
	add_child(r)
	var body:=BoxMesh.new()
	body.size=Vector3(2.45,2.25,8.2)
	var bi:=MeshInstance3D.new()
	bi.mesh=body
	bi.position=Vector3(0,1.05,0)
	bi.material_override=_mat(Color(0.50,0.37,0.07),0.95,0.04)
	r.add_child(bi)
	for side in [-1.0,1.0]:
		for z in [-2.8,-1.5,0.0,1.5,2.8]:
			var m:=BoxMesh.new()
			m.size=Vector3(0.04,0.72,0.95)
			var w:=MeshInstance3D.new()
			w.mesh=m
			w.position=Vector3(side*1.235,1.55,z)
			w.material_override=_mat(Color(0.04,0.07,0.075),0.18,0.18)
			r.add_child(w)
	for sx in [-1.18,1.18]:
		for z in [-2.5,2.5]:
			var wm:=CylinderMesh.new()
			wm.top_radius=0.47
			wm.bottom_radius=0.47
			wm.height=0.26
			wm.radial_segments=12
			var wi:=MeshInstance3D.new()
			wi.mesh=wm
			wi.position=Vector3(sx,0.38,z)
			wi.rotation_degrees=Vector3(0,0,90)
			wi.material_override=_mat(Color(0.03,0.03,0.028),0.98)
			r.add_child(wi)
	_label(pos+Vector3(0,2.05,-4.14),"SCHOOL BUS",14,180,Color(0.08,0.075,0.05))

func _street_light(pos: Vector3, inward: float) -> void:
	_cylinder(pos+Vector3(0,2.7,0),0.10,5.4,Color(0.10,0.11,0.10),Vector3.ZERO,0.62,0.48)
	_box(pos+Vector3(inward*0.72,5.18,0),Vector3(1.35,0.09,0.09),Color(0.10,0.11,0.10),0.62,0.48)
	_box(pos+Vector3(inward*1.34,5.02,0),Vector3(0.38,0.22,0.25),Color(0.15,0.15,0.12),0.45,0.50)

func _utility_pole(pos: Vector3) -> void:
	_cylinder(pos+Vector3(0,3.4,0),0.15,6.8,Color(0.22,0.14,0.075),Vector3.ZERO,0.97)
	_box(pos+Vector3(0,5.6,0),Vector3(2.2,0.14,0.14),Color(0.18,0.12,0.07),0.92)

func _build_vegetation() -> void:
	var positions := [Vector3(-10,0,-7),Vector3(10,0,-10),Vector3(10,0,22),Vector3(-11,0,30),Vector3(32,0,8),Vector3(-35,0,-4),Vector3(9,0,-31),Vector3(-8,0,37),Vector3(34,0,-27),Vector3(-34,0,22),Vector3(33,0,34),Vector3(-31,0,-34)]
	for p in positions:
		_tree(p,rng.randf_range(0.82,1.25))
	for i in range(58):
		var side: float = -1.0 if i%2==0 else 1.0
		var z: float = rng.randf_range(-42.0,42.0)
		var x: float = side*rng.randf_range(9.3,13.2)
		if Vector2(x+22.0,z-7.0).length()<8.0:
			continue
		_shrub(Vector3(x,0.18,z),rng.randf_range(0.55,1.2))
	for p in [Vector3(-25.3,4.5,-7.45),Vector3(12.05,3.6,26.0),Vector3(13.7,5.0,-12.0)]:
		_vines_on_wall(p,Vector3(0.5,2.8,1.2))
	for i in range(84):
		var gx: float = rng.randf_range(-10.5,10.5)
		var gz: float = rng.randf_range(-43.0,43.0)
		if abs(gx)<5.3 and rng.randf()>0.14:
			continue
		_grass(Vector3(gx,0.12,gz))

func _tree(pos: Vector3, scale_factor: float) -> void:
	var h: float = 5.4*scale_factor
	_cylinder(pos+Vector3(0,h*0.5,0),0.24*scale_factor,h,Color(0.19,0.12,0.065),Vector3.ZERO,1.0)
	var offs := [Vector3(0,h*0.92,0),Vector3(0.7,h*0.80,0.2),Vector3(-0.65,h*0.82,-0.3),Vector3(0.2,h*0.73,0.7),Vector3(-0.2,h*0.75,-0.75)]
	for off in offs:
		_sphere(pos+off*scale_factor,Vector3(rng.randf_range(1.3,2.0),rng.randf_range(0.9,1.45),rng.randf_range(1.2,1.9))*scale_factor,Color(rng.randf_range(0.11,0.19),rng.randf_range(0.27,0.40),rng.randf_range(0.07,0.14)))

func _shrub(pos: Vector3, scale_factor: float) -> void:
	for i in range(4):
		var off: Vector3 = Vector3(rng.randf_range(-0.6,0.6),rng.randf_range(0.25,0.55),rng.randf_range(-0.6,0.6))*scale_factor
		_sphere(pos+off,Vector3(rng.randf_range(0.55,0.95),rng.randf_range(0.38,0.68),rng.randf_range(0.55,0.95))*scale_factor,Color(0.14+rng.randf()*0.05,0.30+rng.randf()*0.10,0.08+rng.randf()*0.04))

func _vines_on_wall(pos: Vector3, scale_value: Vector3) -> void:
	for i in range(9):
		_sphere(pos+Vector3(rng.randf_range(-scale_value.x,scale_value.x),rng.randf_range(-scale_value.y,scale_value.y),rng.randf_range(-scale_value.z,scale_value.z)),Vector3(0.20,0.36,0.42)*rng.randf_range(0.75,1.25),Color(0.11,0.30,0.07))

func _grass(pos: Vector3) -> void:
	for i in range(3):
		_box(pos+Vector3(rng.randf_range(-0.18,0.18),0.10,rng.randf_range(-0.18,0.18)),Vector3(0.035,rng.randf_range(0.18,0.42),0.035),Color(0.18,0.32+rng.randf()*0.08,0.09),1.0)

func _build_horizon() -> void:
	for i in range(7):
		var x: float = float(-60+i*20)
		_sphere(Vector3(x,2.0,-70.0-rng.randf_range(0,10)),Vector3(20,10+rng.randf_range(0,5),8),Color(0.10,0.18,0.13))
	for i in range(24):
		var x: float = rng.randf_range(-65.0,65.0)
		var z: float = rng.randf_range(-58.0,-48.0)
		_tree(Vector3(x,0,z),rng.randf_range(0.6,0.95))

func _cleanup_hud(hud: CanvasLayer) -> void:
	if not hud:
		return
	var backdrop:=ColorRect.new()
	backdrop.position=Vector2(12,12)
	backdrop.size=Vector2(500,154)
	backdrop.color=Color(0.01,0.018,0.015,0.58)
	backdrop.z_index=-5
	hud.add_child(backdrop)
	for node in hud.find_children("*","Label",true,false):
		var text:=str(node.text)
		if text.begins_with("ПОСЛЕ НУЛЯ"):
			node.visible=false
		elif text.contains("WASD"):
			node.visible=false
		elif text.begins_with("HP"):
			node.position=Vector2(22,22)
			node.add_theme_font_size_override("font_size",14)
		elif text.begins_with("ТЕКУЩАЯ ЗАДАЧА"):
			node.position=Vector2(22,58)
			node.size=Vector2(470,78)
			node.add_theme_font_size_override("font_size",14)
		elif text.begins_with("ЭКОСИСТЕМА"):
			node.position=Vector2(22,137)
			node.add_theme_font_size_override("font_size",11)
		elif text.begins_with("ШУМ"):
			node.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			node.position=Vector2(20,-36)
			node.add_theme_font_size_override("font_size",11)
	var ver:=Label.new()
	ver.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ver.position=Vector2(-112,18)
	ver.size=Vector2(92,18)
	ver.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	ver.text="AFTER ZERO  A1.7"
	ver.add_theme_font_size_override("font_size",10)
	ver.modulate=Color(0.72,0.75,0.68,0.58)
	hud.add_child(ver)
