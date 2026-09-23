from pathlib import Path
import shutil

root = Path(".")
src = root / "ci" / "a17_polish.gd"
dst = root / "scripts" / "a17_polish.gd"
if not src.exists():
    raise SystemExit("ci/a17_polish.gd missing")
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

# Second visual tuning pass: make the approved concept art fill the full distant
# field of view, reduce primitive foreground mass, darken vegetation and clean HUD.
visual = dst.read_text(encoding="utf-8")
visual = visual.replace("player.position = Vector3(0.0, 0.35, 31.0)", "player.position = Vector3(0.0, 0.35, 24.0)")
visual = visual.replace('''	if player:
		player.position = Vector3(0.0, 0.35, 24.0)
		player.rotation_degrees.y = 0.0''','''	if player:
		player.position = Vector3(0.0, 0.35, 28.0)
		player.rotation_degrees.y = 0.0
		for cam in player.find_children("*", "Camera3D", true, false):
			cam.fov = 62.0''')
visual = visual.replace("Vector3(0, 35.0, -62.0), Vector2(132.0, 74.25)", "Vector3(0, 16.0, -2.0), Vector2(72.0, 40.5)")
visual = visual.replace("Vector3(0, 31.0, 72.0), Vector2(112.0, 63.0)", "Vector3(0, 47.0, 67.0), Vector2(188.0, 105.8)")
visual = visual.replace("Vector3(68.0, 28.0, 8.0), Vector2(96.0, 54.0)", "Vector3(61.0, 44.0, 8.0), Vector2(160.0, 90.0)")
visual = visual.replace("Vector3(-68.0, 26.0, 8.0), Vector2(92.0, 51.75)", "Vector3(-61.0, 42.0, 8.0), Vector2(154.0, 86.6)")
visual = visual.replace("Vector3(13.8, 0.10, 73), Color(0.065,0.068,0.064)", "Vector3(13.8, 0.10, 73), Color(0.080,0.082,0.074)")
visual = visual.replace("Color(0.31,0.30,0.27)", "Color(0.265,0.258,0.235)")
visual = visual.replace(
'''\t_build_facade(Vector3(-14.5,4.0,7.0),Vector3(10.0,8.0,24.0),Color(0.30,0.14,0.085),false)
\t_build_facade(Vector3(14.5,3.2,13.0),Vector3(10.0,6.4,18.0),Color(0.25,0.23,0.19),true)
\t_build_facade(Vector3(-14.5,3.0,-16.0),Vector3(10.0,6.0,12.0),Color(0.35,0.20,0.12),false)
\t_build_facade(Vector3(14.5,4.5,-14.0),Vector3(10.0,9.0,14.0),Color(0.24,0.18,0.14),true)''',
'''\t_build_facade(Vector3(-12.2,2.7,13.0),Vector3(4.4,5.4,14.0),Color(0.26,0.12,0.070),false)
\t_build_facade(Vector3(12.2,2.5,10.0),Vector3(4.4,5.0,12.0),Color(0.23,0.21,0.17),true)
\t_build_facade(Vector3(-12.5,3.0,-13.0),Vector3(5.0,6.0,11.0),Color(0.28,0.15,0.085),false)
\t_build_facade(Vector3(12.5,3.4,-12.0),Vector3(5.0,6.8,12.0),Color(0.21,0.16,0.12),true)''')
visual = visual.replace("Color(0.10,0.25+rng.randf()*0.08,0.07)", "Color(0.07,0.18+rng.randf()*0.07,0.045)")
visual = visual.replace("rng.randf_range(0.08,0.15),rng.randf_range(0.25,0.39),rng.randf_range(0.055,0.11)", "rng.randf_range(0.055,0.11),rng.randf_range(0.17,0.30),rng.randf_range(0.035,0.08)")
visual = visual.replace("Color(0.10+rng.randf()*0.04,0.25+rng.randf()*0.10,0.06+rng.randf()*0.04)", "Color(0.065+rng.randf()*0.03,0.17+rng.randf()*0.08,0.04+rng.randf()*0.025)")
visual = visual.replace("Color(0.14,0.29+rng.randf()*0.08,0.07)", "Color(0.07,0.18+rng.randf()*0.07,0.04)")
visual = visual.replace("label.position = Vector2(24,108)", "label.position = Vector2(24,665)")
visual = visual.replace("label.position = Vector2(24,680)", "label.position = Vector2(24,692)")
visual = visual.replace("plate.size = Vector2(455,122)", "plate.size = Vector2(455,98)")

visual = visual.replace(
'''\t_build_facade(Vector3(-12.2,2.7,13.0),Vector3(4.4,5.4,14.0),Color(0.26,0.12,0.070),false)
\t_build_facade(Vector3(12.2,2.5,10.0),Vector3(4.4,5.0,12.0),Color(0.23,0.21,0.17),true)
\t_build_facade(Vector3(-12.5,3.0,-13.0),Vector3(5.0,6.0,11.0),Color(0.28,0.15,0.085),false)
\t_build_facade(Vector3(12.5,3.4,-12.0),Vector3(5.0,6.8,12.0),Color(0.21,0.16,0.12),true)''',
'''\t# Foreground architecture is kept to the frame edges; approved concept art extends the street ahead.''')
visual = visual.replace('\t_create_car(Vector3(-3.8,0.60,13.0),-4.0,Color(0.20,0.21,0.18),1.0)\n', '')
visual = visual.replace('\t_create_car(Vector3(3.6,0.60,-4.0),5.0,Color(0.28,0.17,0.12),0.92)\n', '')
visual = visual.replace('\t_create_car(Vector3(-3.1,0.60,-18.0),-2.0,Color(0.13,0.16,0.16),0.88)\n', '')
visual = visual.replace('var tree_positions := [Vector3(-9.7,0,-9),Vector3(9.5,0,-12),Vector3(-10.0,0,8),Vector3(10.2,0,9),Vector3(-10.5,0,20),Vector3(10.6,0,24),Vector3(-11.5,0,-25),Vector3(11.2,0,-29)]', 'var tree_positions := []')

visual = visual.replace('Vector3(0, 0.08, 4), Vector3(13.8, 0.10, 73)', 'Vector3(0, 0.08, 20), Vector3(13.8, 0.10, 17)')
visual = visual.replace('Vector3(side*8.15, 0.18, 4), Vector3(2.6,0.22,73)', 'Vector3(side*8.15, 0.18, 20), Vector3(2.6,0.22,17)')
visual = visual.replace('Vector3(side*6.75, 0.30,4),Vector3(0.20,0.44,73)', 'Vector3(side*6.75, 0.30,20),Vector3(0.20,0.44,17)')
visual = visual.replace('for z in range(-28, 38, 5):', 'for z in range(11, 29, 5):')
visual = visual.replace('rng.randf_range(-22.0,35.0)', 'rng.randf_range(10.0,28.0)')
visual = visual.replace('for z in [-20.0,-2.0,17.0,34.0]:', 'for z in [17.0,34.0]:')
visual = visual.replace('for z in [-23.0,4.0,29.0]:', 'for z in [29.0]:')
visual = visual.replace('rng.randf_range(-30.0,36.0)', 'rng.randf_range(10.0,34.0)')
visual = visual.replace('plate.color = Color(0.008,0.014,0.012,0.58)', 'plate.color = Color(0.008,0.014,0.012,0.46)')


dst.write_text(visual, encoding="utf-8")

world = root / "scripts" / "world.gd"
text = world.read_text(encoding="utf-8")

const_line = 'const A17_POLISH_SCRIPT := preload("res://scripts/a17_polish.gd")'
if "A17_POLISH_SCRIPT" not in text:
    marker = 'const SAVE_PATH := "user://after_zero_a1_7_save.json"'
    if marker in text:
        text = text.replace(marker, marker + "\n" + const_line, 1)
    else:
        first_var = text.find("\nvar ")
        if first_var < 0:
            raise SystemExit("Could not place A17_POLISH_SCRIPT constant")
        text = text[:first_var] + "\n" + const_line + text[first_var:]

if "polish_a17.build(self, player, hud)" not in text:
    ready_start = text.find("func _ready() -> void:")
    process_start = text.find("\nfunc _process", ready_start)
    if ready_start < 0 or process_start < 0:
        raise SystemExit("Could not locate _ready/_process")
    ready_block = text[ready_start:process_start]
    target = "\t_update_objective()"
    idx = ready_block.rfind(target)
    if idx < 0:
        raise SystemExit("Could not locate _update_objective() in _ready")
    insert_at = ready_start + idx + len(target)
    addition = '\n\tvar polish_a17 := A17_POLISH_SCRIPT.new()\n\tadd_child(polish_a17)\n\tpolish_a17.build(self, player, hud)'
    text = text[:insert_at] + addition + text[insert_at:]


# Put the ecology state out of the objective card so the HUD no longer collides.
text = text.replace("ecosystem_label.position = Vector2(20, 164)", "ecosystem_label.position = Vector2(20, 655)")
text = text.replace("ecosystem_label.position = Vector2(20, 122)", "ecosystem_label.position = Vector2(20, 655)")

world.write_text(text, encoding="utf-8")
print("A1.7 cinematic polish applied")
