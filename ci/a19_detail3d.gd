extends Node3D

# AFTER ZERO A1.9 — first authored-detail 3D pass.
# Replaces the most visible A1.8 procedural placeholders (workshop, market,
# near street buildings, cars and blob trees) with denser real 3D geometry.
# Existing gameplay collision/interaction nodes remain untouched.

var world: Node3D
var rng := RandomNumberGenerator.new()
var mats: Dictionary = {}

func build(target_world: Node3D, player: Node3D, hud: CanvasLayer) -> void:
	world = target_world
	rng.seed = 240919
	_hide_a18_placeholders(target_world)
	_tune_environment(target_world)
	_create_materials()
	_build_workshop_detail()
	_build_main_street_facades()
	_build_market_detail()
	_build_vehicle_set()
	_build_street_trees()
	_build_ground_growth()
	_build_distant_ridge()
	_build_story_prop_visuals()
	_cleanup_hud(hud)
	if player:
		# Start where the story actually begins: inside the workshop, looking at
		# the workbench/note rather than dropped in the middle of the road.
		player.position = Vector3(-22.0, 0.35, 5.75)
		player.rotation_degrees.y = 180.0
		for camera in player.find_children("*", "Camera3D", true, false):
			camera.fov = 70.0

func _hide_a18_placeholders(target_world: Node3D) -> void:
	var replace_names := {
		"WorkshopVisual": true,
		"PineRidgeMarketVisual": true,
		"HardwareBlock": true,
		"CivicBlock": true,
		"GarageRowVisual": true,
		"AbandonedCar3D": true,
		"Tree3D": true
	}
	for child in target_world.get_children():
		var script = child.get_script()
		if script == null:
			continue
		if not str(script.resource_path).contains("a18_real3d.gd"):
			continue
		for sub in child.get_children():
			if sub is MultiMeshInstance3D:
				sub.visible = false
			elif replace_names.has(str(sub.name)) and sub is Node3D:
				sub.visible = false

func _tune_environment(target_world: Node3D) -> void:
	for child in target_world.get_children():
		if child is WorldEnvironment and child.environment:
			var env: Environment = child.environment
			env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			env.tonemap_exposure = 0.92
			env.ambient_light_energy = 0.43
			env.fog_enabled = true
			env.fog_light_color = Color(0.45, 0.54, 0.50)
			env.fog_light_energy = 0.24
			env.fog_density = 0.00125
			env.fog_height = -0.8
			env.fog_height_density = 0.022
		elif child is DirectionalLight3D:
			child.light_color = Color(1.0, 0.84, 0.66)
			child.light_energy = 0.96
			child.rotation_degrees = Vector3(-37.0, -31.0, 0.0)
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
uniform vec3 brick_color = vec3(0.30,0.12,0.065);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment(){
	vec2 uv=UV*vec2(22.0,26.0);
	float row=floor(uv.y);
	uv.x += mod(row,2.0)*0.5;
	vec2 cell=fract(uv);
	float edge=min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y));
	float mortar=1.0-smoothstep(0.045,0.070,edge);
	float n=0.82+hash(floor(uv))*0.23;
	float grime=0.78+noise(UV*7.0)*0.28;
	vec3 brick=brick_color*n*grime;
	vec3 mortar_col=vec3(0.31,0.30,0.27);
	ALBEDO=mix(brick,mortar_col,mortar);
	ROUGHNESS=0.93;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("brick_color", Vector3(base.r,base.g,base.b))
	return mat

func _concrete_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
float hash(vec2 p){return fract(sin(dot(p,vec2(91.17,287.41)))*43758.5453);}
void fragment(){
	vec2 p=UV*vec2(38.0,38.0);
	float g=hash(floor(p))*0.10;
	float stain=hash(floor(UV*vec2(6.0,11.0)))*0.08;
	ALBEDO=vec3(0.29+g-stain,0.285+g-stain,0.265+g-stain);
	ROUGHNESS=0.95;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat

func _leaf_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, depth_prepass_alpha;
uniform vec3 leaf_color = vec3(0.08,0.24,0.06);
float hash(vec2 p){return fract(sin(dot(p,vec2(41.7,289.1)))*43758.5453);}
void fragment(){
	vec2 p=UV*2.0-1.0;
	float radial=length(vec2(p.x*1.18,p.y));
	float serration=0.08*sin(18.0*atan(p.y,p.x));
	float mask=1.0-smoothstep(0.72+serration,0.92+serration,radial);
	if(mask<0.38){discard;}
	float vein=0.05*(1.0-abs(p.x))*smoothstep(-1.0,1.0,p.y);
	float n=0.86+0.18*hash(floor(UV*vec2(9.0,11.0)));
	ALBEDO=leaf_color*n+vec3(vein);
	ROUGHNESS=0.98;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("leaf_color", Vector3(color.r,color.g,color.b))
	return mat

func _grass_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, unshaded;
void fragment(){
	vec2 p=UV;
	float width=mix(0.42,0.04,p.y);
	float d=abs(p.x-0.5);
	if(d>width){discard;}
	float base=0.55+0.45*p.y;
	ALBEDO=mix(vec3(0.035,0.095,0.025),vec3(0.14,0.25,0.055),base);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat

func _create_materials() -> void:
	mats["brick_red"]=_brick_material(Color(0.32,0.13,0.07))
	mats["brick_dark"]=_brick_material(Color(0.22,0.095,0.050))
	mats["brick_warm"]=_brick_material(Color(0.37,0.17,0.085))
	mats["concrete"]=_concrete_material()
	mats["concrete_dark"]=_std(Color(0.17,0.18,0.17),0.96)
	mats["metal"]=_std(Color(0.055,0.062,0.060),0.42,0.58)
	mats["rust"]=_std(Color(0.28,0.105,0.045),0.91,0.25)
	mats["wood"]=_std(Color(0.20,0.105,0.045),0.95)
	mats["wood_dark"]=_std(Color(0.105,0.060,0.034),0.98)
	mats["glass"]=_std(Color(0.025,0.070,0.078,0.62),0.10,0.18,true)
	mats["glass_dark"]=_std(Color(0.012,0.025,0.028,0.80),0.08,0.22,true)
	mats["paint_green"]=_std(Color(0.055,0.18,0.105),0.83)
	mats["paint_cream"]=_std(Color(0.54,0.50,0.39),0.90)
	mats["paper"]=_std(Color(0.72,0.66,0.48),0.98)
	mats["rubber"]=_std(Color(0.012,0.013,0.012),0.99)
	mats["leaf_dark"]=_leaf_material(Color(0.055,0.17,0.045))
	mats["leaf_mid"]=_leaf_material(Color(0.085,0.255,0.055))
	mats["leaf_light"]=_leaf_material(Color(0.13,0.34,0.065))
	mats["grass"]=_grass_material()

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size=size
	var inst := MeshInstance3D.new()
	inst.mesh=mesh
	inst.position=pos
	inst.rotation_degrees=rot
	inst.material_override=mat
	parent.add_child(inst)
	return inst

func _cyl(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO, segments: int = 14) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius*0.92
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=segments
	var inst := MeshInstance3D.new()
	inst.mesh=mesh
	inst.position=pos
	inst.rotation_degrees=rot
	inst.material_override=mat
	parent.add_child(inst)
	return inst

func _quad(parent: Node3D, pos: Vector3, size: Vector2, mat: Material, rot: Vector3) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size=size
	var inst := MeshInstance3D.new()
	inst.mesh=mesh
	inst.position=pos
	inst.rotation_degrees=rot
	inst.material_override=mat
	inst.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	parent.add_child(inst)
	return inst

func _root(name_value: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name=name_value
	node.position=pos
	add_child(node)
	return node

func _label(parent: Node3D, value: String, pos: Vector3, rot: Vector3, font_size: int = 34) -> Label3D:
	var label := Label3D.new()
	label.text=value
	label.position=pos
	label.rotation_degrees=rot
	label.font_size=font_size
	label.pixel_size=0.009
	label.outline_size=5
	label.modulate=Color(0.82,0.78,0.62)
	label.double_sided=true
	parent.add_child(label)
	return label

func _leaf_cross(parent: Node3D, pos: Vector3, size: Vector2, mat: Material, yaw: float = 0.0) -> void:
	_quad(parent,pos,size,mat,Vector3(0,yaw,0))
	_quad(parent,pos,size,mat,Vector3(0,yaw+60.0,0))
	_quad(parent,pos,size,mat,Vector3(0,yaw+120.0,0))

func _ivy_strip(parent: Node3D, start: Vector3, end: Vector3, count: int) -> void:
	var delta: Vector3=end-start
	var length: float=delta.length()
	var middle: Vector3=(start+end)*0.5
	_cyl(parent,middle,0.026,length,mats["leaf_dark"],Vector3.ZERO,6)
	for i in range(count):
		var t: float=float(i+1)/float(count+1)
		var p: Vector3=start.lerp(end,t)+Vector3(rng.randf_range(-0.18,0.18),0,rng.randf_range(-0.18,0.18))
		var lm: Material=mats["leaf_mid"] if i%3 else mats["leaf_light"]
		_leaf_cross(parent,p,Vector2(rng.randf_range(0.38,0.65),rng.randf_range(0.28,0.48)),lm,rng.randf_range(0,180))

func _build_workshop_detail() -> void:
	var root := _root("WorkshopA19",Vector3(-22,0,7))
	# Shell aligned to the real gameplay workshop collision.
	_box(root,Vector3(0,0.06,0),Vector3(9.8,0.12,7.8),mats["concrete"])
	_box(root,Vector3(0,2.5,3.78),Vector3(9.8,5.0,0.28),mats["brick_dark"])
	_box(root,Vector3(-4.76,2.5,0),Vector3(0.28,5.0,7.8),mats["brick_dark"])
	_box(root,Vector3(4.76,2.5,0),Vector3(0.28,5.0,7.8),mats["brick_dark"])
	_box(root,Vector3(0,5.0,0),Vector3(9.8,0.25,7.8),mats["metal"])
	# Steel portal and raised roll-up door at the open front.
	_box(root,Vector3(-4.2,2.35,-3.82),Vector3(0.32,4.7,0.32),mats["metal"])
	_box(root,Vector3(4.2,2.35,-3.82),Vector3(0.32,4.7,0.32),mats["metal"])
	_box(root,Vector3(0,4.55,-3.82),Vector3(8.7,0.35,0.32),mats["metal"])
	for y in [3.78,4.00,4.22]:
		_box(root,Vector3(0,y,-3.70),Vector3(8.0,0.12,0.16),mats["metal"])
	# Roof structure.
	for z in [-2.6,-0.8,1.0,2.8]:
		_box(root,Vector3(0,4.58,z),Vector3(9.2,0.16,0.16),mats["metal"])
	# Workbench EXACTLY where the story interaction lives.
	_box(root,Vector3(-1.2,0.80,1.50),Vector3(2.15,0.16,1.05),mats["wood"])
	for x in [-2.10,-0.30]:
		for z in [1.10,1.90]:
			_box(root,Vector3(x,0.40,z),Vector3(0.10,0.80,0.10),mats["metal"])
	# Pegboard / tool silhouettes.
	_box(root,Vector3(-1.2,2.05,3.58),Vector3(3.2,1.55,0.10),mats["wood_dark"])
	for i in range(8):
		var tx: float=-2.45+float(i)*0.36
		_box(root,Vector3(tx,2.00,3.48),Vector3(0.05,0.72 if i%2==0 else 0.48,0.06),mats["metal"],Vector3(0,0,rng.randf_range(-18,18)))
	# Visible note exactly over the note interaction.
	_box(root,Vector3(-1.2,1.165,1.35),Vector3(0.46,0.018,0.34),mats["paper"],Vector3(0,8,0))
	# Generator aligned to gameplay object world (-25,.65,9.3) => local(-3,.65,2.3)
	_build_generator(root,Vector3(-3.0,0.64,2.30))
	# Terminal aligned to gameplay archive terminal.
	_build_terminal(root,Vector3(3.30,0.90,2.30))
	# Cabinets and shelving.
	_build_shelf(root,Vector3(3.85,0.0,3.18),1.45,2.8)
	_build_shelf(root,Vector3(2.15,0.0,3.18),1.25,2.2)
	for x in [-4.0,-3.55]:
		for y in [0.62,1.20,1.78]:
			_cyl(root,Vector3(x,y,-1.9),0.42,0.24,mats["rubber"],Vector3(0,0,90),18)
	# Floor clutter kept out of the walking line.
	for p in [Vector3(3.5,0.28,-1.8),Vector3(2.75,0.23,-2.25),Vector3(-3.7,0.22,-2.0)]:
		_box(root,p,Vector3(0.62,0.45,0.52),mats["wood"])
	# Daylight bounce from the open bay keeps the unpowered workshop readable.
	var daylight := OmniLight3D.new()
	daylight.position = Vector3(0,3.0,-2.6)
	daylight.light_color = Color(0.72,0.82,0.86)
	daylight.light_energy = 1.25
	daylight.omni_range = 8.0
	root.add_child(daylight)
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(-1.5,2.2,2.6)
	bounce.light_color = Color(0.52,0.60,0.54)
	bounce.light_energy = 0.58
	bounce.omni_range = 5.0
	root.add_child(bounce)
	# Exterior sign and subtle ivy on one corner only.
	_box(root,Vector3(0,4.05,-3.99),Vector3(5.9,0.68,0.16),mats["paint_green"])
	_label(root,"RIVERDALE REPAIR",Vector3(0,4.08,-4.10),Vector3.ZERO,36)
	_ivy_strip(root,Vector3(-4.55,0.35,-3.76),Vector3(-4.55,4.35,-3.76),8)

func _build_generator(parent: Node3D, pos: Vector3) -> void:
	var g := Node3D.new(); g.position=pos; parent.add_child(g)
	_box(g,Vector3(0,0.42,0),Vector3(1.15,0.18,0.82),mats["metal"])
	_box(g,Vector3(0,0.86,0),Vector3(0.88,0.62,0.68),mats["rust"])
	_cyl(g,Vector3(-0.40,0.20,-0.32),0.17,0.10,mats["rubber"],Vector3(90,0,0),14)
	_cyl(g,Vector3(0.40,0.20,-0.32),0.17,0.10,mats["rubber"],Vector3(90,0,0),14)
	_box(g,Vector3(0,1.22,0),Vector3(0.75,0.23,0.55),mats["paint_green"])
	_box(g,Vector3(0.45,0.85,-0.35),Vector3(0.12,0.30,0.10),mats["metal"])

func _build_terminal(parent: Node3D, pos: Vector3) -> void:
	var t := Node3D.new(); t.position=pos; parent.add_child(t)
	_box(t,Vector3(0,0.65,0),Vector3(0.82,1.30,0.55),mats["metal"])
	_box(t,Vector3(0,1.03,-0.29),Vector3(0.62,0.42,0.05),mats["glass_dark"])
	_box(t,Vector3(0,0.28,-0.31),Vector3(0.52,0.12,0.10),mats["paint_green"])

func _build_shelf(parent: Node3D, pos: Vector3, width: float, height: float) -> void:
	var r := Node3D.new(); r.position=pos; parent.add_child(r)
	for x in [-width*0.5,width*0.5]:
		_box(r,Vector3(x,height*0.5,0),Vector3(0.07,height,0.42),mats["metal"])
	for y in [0.25,height*0.34,height*0.65,height*0.96]:
		_box(r,Vector3(0,y,0),Vector3(width,0.07,0.42),mats["metal"])
	for i in range(6):
		_box(r,Vector3(rng.randf_range(-width*0.35,width*0.35),rng.randf_range(0.45,height*0.88),rng.randf_range(-0.12,0.12)),Vector3(rng.randf_range(0.18,0.30),rng.randf_range(0.16,0.26),rng.randf_range(0.18,0.28)),mats["paint_cream"])

func _build_main_street_facades() -> void:
	_storefront(Vector3(-15.0,0,-15.0),10.0,15.0,7.0,mats["brick_red"],"RIVERDALE HARDWARE",1.0)
	_storefront(Vector3(-15.0,0,2.0),9.5,13.0,6.2,mats["brick_warm"],"PINE CAFE",1.0)
	_storefront(Vector3(15.0,0,-14.0),10.0,15.0,8.5,mats["brick_dark"],"MAIN STREET GOODS",-1.0)
	_storefront(Vector3(15.0,0,3.0),9.5,13.0,6.7,mats["brick_red"],"RIVERDALE SUPPLY",-1.0)

func _storefront(pos: Vector3, width: float, depth: float, height: float, wall_mat: Material, sign_text: String, front_sign: float) -> void:
	var root := _root(sign_text.replace(" ","_"),pos)
	_box(root,Vector3(0,height*0.5,0),Vector3(width,height,depth),wall_mat)
	# Cornice / parapet.
	_box(root,Vector3(0,height+0.18,0),Vector3(width+0.45,0.34,depth+0.45),mats["concrete_dark"])
	var front_x: float=front_sign*(width*0.5+0.055)
	var rot_y: float=90.0 if front_sign>0 else -90.0
	# Ground-floor recessed shopfront.
	_box(root,Vector3(front_x,1.45,0),Vector3(0.09,2.55,depth*0.76),mats["glass_dark"])
	for z in [-depth*0.28,0.0,depth*0.28]:
		_box(root,Vector3(front_x-front_sign*0.03,1.45,z),Vector3(0.13,2.70,0.10),mats["metal"])
	# Upper windows with trim.
	var stories: int=int(max(1.0,floor((height-3.2)/2.4)))
	for story in range(stories):
		var y: float=4.1+float(story)*2.35
		if y>height-0.65: continue
		for z in [-depth*0.30,-depth*0.10,depth*0.10,depth*0.30]:
			_box(root,Vector3(front_x,y,z),Vector3(0.08,1.22,1.28),mats["glass"])
			_box(root,Vector3(front_x-front_sign*0.035,y,z),Vector3(0.15,1.44,1.50),mats["concrete_dark"])
			_box(root,Vector3(front_x,y,z),Vector3(0.09,1.20,1.25),mats["glass"])
	# Awning and sign.
	_box(root,Vector3(front_x+front_sign*0.42,2.85,0),Vector3(0.85,0.18,depth*0.78),mats["paint_green"],Vector3(0,0,front_sign*-8.0))
	_label(root,sign_text,Vector3(front_x+front_sign*0.16,3.45,0),Vector3(0,rot_y,0),31)
	# Downspout and selective ivy.
	_cyl(root,Vector3(front_x,2.1,depth*0.44),0.055,4.2,mats["metal"])
	_ivy_strip(root,Vector3(front_x,0.40,-depth*0.44),Vector3(front_x,height*0.88,-depth*0.44),7)

func _build_market_detail() -> void:
	var root := _root("PineRidgeMarketA19",Vector3(22,0,22))
	_box(root,Vector3(0,2.45,0),Vector3(18.0,4.9,12.0),mats["brick_warm"])
	_box(root,Vector3(0,5.02,0),Vector3(18.5,0.28,12.5),mats["concrete_dark"])
	var front_x: float=-9.05
	# Deep dark interior behind glass.
	_box(root,Vector3(front_x+0.45,1.55,0),Vector3(0.45,2.65,10.2),_std(Color(0.010,0.016,0.014),1.0))
	for z in [-4.0,-1.35,1.35,4.0]:
		_box(root,Vector3(front_x,1.55,z),Vector3(0.07,2.55,2.10),mats["glass"])
		_box(root,Vector3(front_x-0.05,1.55,z),Vector3(0.12,2.76,2.30),mats["metal"])
		_box(root,Vector3(front_x,1.55,z),Vector3(0.08,2.52,2.05),mats["glass"])
	_box(root,Vector3(front_x-0.50,3.25,0),Vector3(1.05,0.22,10.6),mats["paint_green"],Vector3(0,0,8))
	_label(root,"PINE RIDGE MARKET",Vector3(front_x-0.20,3.85,0),Vector3(0,-90,0),34)
	# Entry doors and bollards.
	_box(root,Vector3(front_x-0.02,1.30,-5.0),Vector3(0.08,2.55,1.45),mats["glass_dark"])
	for z in [-5.7,-4.3]:
		_cyl(root,Vector3(front_x-0.75,0.55,z),0.09,1.1,mats["rust"])
	# Interior shelving silhouettes visible through the dark shopfront.
	for x in [-6.9,-5.6]:
		for z in [-3.5,-1.2,1.2,3.5]:
			_box(root,Vector3(x,1.15,z),Vector3(0.16,2.1,1.25),mats["metal"])
			for y in [0.45,1.05,1.65]:
				_box(root,Vector3(x-0.15,y,z),Vector3(0.80,0.08,1.15),mats["metal"])
	# Rooftop growth.
	for i in range(11):
		_leaf_cross(root,Vector3(rng.randf_range(-7.5,7.5),5.22,rng.randf_range(-4.8,4.8)),Vector2(rng.randf_range(0.7,1.3),rng.randf_range(0.55,1.0)),mats["leaf_mid"],rng.randf_range(0,180))
	_ivy_strip(root,Vector3(front_x,0.35,5.45),Vector3(front_x,4.55,5.45),8)

func _build_vehicle_set() -> void:
	# Park vehicles near the curb so the first-person street composition stays open.
	_car(Vector3(-5.0,0.38,-13.0),-5.0,Color(0.13,0.15,0.14),1.0)
	_car(Vector3(5.1,0.38,16.0),4.0,Color(0.24,0.105,0.055),0.96)
	_pickup(Vector3(-5.0,0.38,13.0),-2.0,Color(0.18,0.20,0.17),0.98)

func _car(pos: Vector3, yaw: float, color: Color, scale_value: float) -> void:
	var r := _root("CarA19",pos); r.rotation_degrees.y=yaw
	var body_mat := _std(color,0.86,0.12)
	_box(r,Vector3(0,0.44,0),Vector3(1.82,0.50,3.75)*scale_value,body_mat)
	_box(r,Vector3(0,0.80,-0.15),Vector3(1.55,0.32,2.00)*scale_value,body_mat)
	# Cabin reads less boxy through sloped windshield/rear glass.
	_box(r,Vector3(0,1.03,-0.57),Vector3(1.36,0.58,0.05)*scale_value,mats["glass_dark"],Vector3(22,0,0))
	_box(r,Vector3(0,0.98,0.70),Vector3(1.36,0.50,0.05)*scale_value,mats["glass_dark"],Vector3(-18,0,0))
	_box(r,Vector3(0,0.92,0.02),Vector3(1.42,0.48,1.05)*scale_value,body_mat)
	for side in [-1.0,1.0]:
		_box(r,Vector3(side*0.765,0.92,0.02),Vector3(0.05,0.40,1.25)*scale_value,mats["glass_dark"])
		_box(r,Vector3(side*0.92,0.52,0.20),Vector3(0.10,0.22,2.35)*scale_value,body_mat)
	for sx in [-0.92,0.92]:
		for sz in [-1.22,1.22]:
			_cyl(r,Vector3(sx*scale_value,0.27,sz*scale_value),0.31*scale_value,0.24*scale_value,mats["rubber"],Vector3(0,0,90),18)
	_box(r,Vector3(0,0.40,-1.93),Vector3(1.55,0.18,0.10)*scale_value,mats["metal"])
	_box(r,Vector3(0,0.40,1.93),Vector3(1.55,0.18,0.10)*scale_value,mats["metal"])
	# Small vegetation, not blob canopy.
	for i in range(3):
		_leaf_cross(r,Vector3(rng.randf_range(-0.55,0.55),rng.randf_range(0.65,0.98),rng.randf_range(-1.1,1.1)),Vector2(0.48,0.36),mats["leaf_dark"],rng.randf_range(0,180))

func _pickup(pos: Vector3, yaw: float, color: Color, scale_value: float) -> void:
	var r := _root("PickupA19",pos); r.rotation_degrees.y=yaw
	var body_mat := _std(color,0.88,0.12)
	_box(r,Vector3(0,0.45,0.20),Vector3(1.95,0.56,4.25)*scale_value,body_mat)
	_box(r,Vector3(0,0.92,-0.72),Vector3(1.65,0.72,1.55)*scale_value,body_mat)
	_box(r,Vector3(0,0.98,-1.25),Vector3(1.45,0.44,0.05)*scale_value,mats["glass_dark"],Vector3(18,0,0))
	# Open bed inset.
	_box(r,Vector3(0,0.72,1.20),Vector3(1.55,0.18,1.55)*scale_value,mats["metal"])
	for side in [-1.0,1.0]:
		_box(r,Vector3(side*0.86,0.93,1.18),Vector3(0.10,0.56,1.70)*scale_value,body_mat)
	for sx in [-0.99,0.99]:
		for sz in [-1.38,1.38]:
			_cyl(r,Vector3(sx*scale_value,0.28,sz*scale_value),0.34*scale_value,0.25*scale_value,mats["rubber"],Vector3(0,0,90),18)

func _build_street_trees() -> void:
	var positions := [
		Vector3(-9.4,0,-24),Vector3(9.5,0,-20),Vector3(-9.6,0,-4),
		Vector3(9.7,0,8),Vector3(-9.8,0,20),Vector3(10.0,0,32)
	]
	for i in range(positions.size()):
		_tree(positions[i],0.86+rng.randf()*0.18,i)

func _tree(pos: Vector3, scale_value: float, variant: int) -> void:
	var r := _root("TreeA19",pos)
	var h: float=6.4*scale_value
	_cyl(r,Vector3(0,h*0.48,0),0.19*scale_value,h,mats["wood_dark"],Vector3.ZERO,12)
	# Visible branch structure.
	for i in range(7):
		var angle: float=float(i)*137.5
		var y: float=h*(0.48+0.062*float(i))
		var branch := _cyl(r,Vector3(0,y,0),0.055*scale_value,2.5*scale_value,mats["wood_dark"],Vector3(58,angle,0),8)
		branch.position += Vector3(sin(deg_to_rad(angle))*0.48,0,cos(deg_to_rad(angle))*0.48)
	# Many smaller leaf cards read as foliage rather than oversized blobs.
	for i in range(42):
		var angle: float=TAU*float(i)/42.0+rng.randf_range(-0.32,0.32)
		var radius: float=rng.randf_range(0.50,2.15)*scale_value
		var y: float=rng.randf_range(h*0.56,h*1.03)
		var mat: Material=mats["leaf_dark"] if (i+variant)%3==0 else (mats["leaf_mid"] if i%3 else mats["leaf_light"])
		_leaf_cross(r,Vector3(cos(angle)*radius,y,sin(angle)*radius),Vector2(rng.randf_range(0.42,0.82),rng.randf_range(0.34,0.70))*scale_value,mat,rng.randf_range(0,180))

func _build_ground_growth() -> void:
	# Bushes at sidewalk edges.
	for i in range(44):
		var side: float=-1.0 if i%2==0 else 1.0
		var x: float=side*rng.randf_range(7.2,10.5)
		var z: float=rng.randf_range(-34,35)
		var mat: Material=mats["leaf_dark"] if i%3==0 else mats["leaf_mid"]
		_leaf_cross(self,Vector3(x,rng.randf_range(0.35,0.60),z),Vector2(rng.randf_range(0.65,1.20),rng.randf_range(0.48,0.88)),mat,rng.randf_range(0,180))
	# Tapered grass cards via MultiMesh.
	var blade := QuadMesh.new(); blade.size=Vector2(0.10,0.48); blade.material=mats["grass"]
	var mm := MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=blade; mm.instance_count=900
	for i in range(mm.instance_count):
		var side: float=-1.0 if i%2==0 else 1.0
		var x: float=side*rng.randf_range(6.85,12.8)
		var z: float=rng.randf_range(-38,38)
		var yaw: float=rng.randf_range(0,TAU)
		var scale_y: float=rng.randf_range(0.55,1.35)
		var basis := Basis(Vector3.UP,yaw).scaled(Vector3(rng.randf_range(0.8,1.2),scale_y,1.0))
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,0.26,z)))
	var inst := MultiMeshInstance3D.new(); inst.multimesh=mm; add_child(inst)

func _build_distant_ridge() -> void:
	# Two real 3D ridge layers remove the flat horizon without returning to 2.5D cards.
	var back_mat := _std(Color(0.055,0.095,0.070),1.0)
	var near_mat := _std(Color(0.075,0.125,0.080),1.0)
	for layer in range(2):
		var z: float=-47.0-float(layer)*8.0
		var mat: Material=near_mat if layer==0 else back_mat
		for i in range(9):
			var x: float=-44.0+float(i)*11.0
			var radius: float=8.5+rng.randf_range(-1.5,1.5)
			var height: float=12.0+rng.randf_range(-2.0,5.0)
			var cone := CylinderMesh.new()
			cone.top_radius=0.0
			cone.bottom_radius=radius
			cone.height=height
			cone.radial_segments=7
			var mi := MeshInstance3D.new()
			mi.mesh=cone
			mi.position=Vector3(x,height*0.5,z)
			mi.material_override=mat
			add_child(mi)

func _build_story_prop_visuals() -> void:
	# Story note / generator / terminal proxies in the old world remain invisible,
	# but collisions and interact scripts still work. These visuals align exactly.
	var note := _root("StoryNoteVisual",Vector3(-23.2,1.17,8.35))
	_box(note,Vector3.ZERO,Vector3(0.46,0.018,0.34),mats["paper"],Vector3(0,8,0))

func _cleanup_hud(hud: CanvasLayer) -> void:
	if hud == null:
		return
	for label in hud.find_children("*","Label",true,false):
		var txt: String=str(label.text)
		if txt.contains("REAL 3D A1.8") or txt.contains("A1.7"):
			label.visible=false
	var tag := Label.new()
	tag.position=Vector2(1060,18)
	tag.size=Vector2(195,18)
	tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	tag.text="AFTER ZERO  ·  A1.9.1 DETAIL 3D"
	tag.add_theme_font_size_override("font_size",10)
	tag.modulate=Color(0.80,0.82,0.76,0.58)
	hud.add_child(tag)
