from pathlib import Path

world = Path("scripts/world.gd")
text = world.read_text(encoding="utf-8")

text = text.replace(
    "\t_build_environment()\n\t_build_city_block()",
    "\t_build_environment()\n\t_build_visual_backdrop()\n\t_build_city_block()",
    1,
)

marker = "func _build_city_block() -> void:"
if "func _build_visual_backdrop() -> void:" not in text:
    addition = r'''
func _photo_panel(texture_path: String, region: Rect2, pos: Vector3, size: Vector2, rotation_value: Vector3) -> void:
	var source := load(texture_path) as Texture2D
	if source == null:
		return
	var texture: Texture2D = source
	if region.size.x > 0.0 and region.size.y > 0.0:
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = region
		texture = atlas
	var quad := QuadMesh.new()
	quad.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var panel := MeshInstance3D.new()
	panel.mesh = quad
	panel.position = pos
	panel.rotation_degrees = rotation_value
	panel.material_override = mat
	add_child(panel)

func _build_visual_backdrop() -> void:
	# Art-backed distant scenery: real approved After Zero concept art sits behind
	# the playable geometry, so the first-person view has depth and identity
	# while the near field remains fully 3D and collision-driven.
	_photo_panel(
		"res://docs/visual_reference/01_main_street.png",
		Rect2(0, 0, 1672, 941),
		Vector3(0, 14.5, -50.0),
		Vector2(72.0, 40.5),
		Vector3.ZERO
	)
	_photo_panel(
		"res://docs/visual_reference/02_intersection.png",
		Rect2(0, 0, 1672, 941),
		Vector3(0, 14.5, 50.0),
		Vector2(72.0, 40.5),
		Vector3(0, 180, 0)
	)
	# A cropped market facade from the approved market render gives the
	# Pine Ridge Market a much denser visual read than a bare gray box.
	_photo_panel(
		"res://docs/visual_reference/03_market.png",
		Rect2(650, 205, 1000, 440),
		Vector3(12.36, 2.85, 22.0),
		Vector2(11.5, 5.05),
		Vector3(0, -90, 0)
	)

'''
    text = text.replace(marker, addition + marker, 1)

old_spawn = '''func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(-22, 0.25, 6.2)
	player.rotation_degrees.y = -90.0
	add_child(player)
'''
new_spawn = '''func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	# Start at the workshop threshold, looking down Main Street instead of
	# beginning behind large interior props.
	player.position = Vector3(-7.9, 0.25, 6.2)
	player.rotation_degrees.y = 0.0
	add_child(player)
'''
text = text.replace(old_spawn, new_spawn, 1)
text = text.replace("ecosystem_label.position = Vector2(20, 122)", "ecosystem_label.position = Vector2(20, 164)", 1)

# Slightly more natural road/sidewalk values for the showcase view.
text = text.replace("Color(0.075, 0.078, 0.075)", "Color(0.105, 0.105, 0.095)")
text = text.replace("Color(0.31, 0.32, 0.29)", "Color(0.37, 0.36, 0.32)")

world.write_text(text, encoding="utf-8")

project = Path("project.godot")
ptext = project.read_text(encoding="utf-8")
ptext = ptext.replace('config/version="0.1.7"', 'config/version="0.1.7.1"')
project.write_text(ptext, encoding="utf-8")

print("Applied A1.7.1 visual presentation pass")
