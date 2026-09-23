from pathlib import Path
import shutil

root = Path(".")
src = root / "ci" / "a17_polish.gd"
dst = root / "scripts" / "a17_polish.gd"
if not src.exists():
    raise SystemExit("ci/a17_polish.gd missing")
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

visual = dst.read_text(encoding="utf-8")

visual = visual.replace(
'''\tif player:
\t\tplayer.position = Vector3(0.0, 0.35, 31.0)
\t\tplayer.rotation_degrees.y = 0.0''',
'''\tif player:
\t\tplayer.position = Vector3(0.0, 0.35, 26.5)
\t\tplayer.rotation_degrees.y = 0.0
\t\tfor cam in player.find_children("*", "Camera3D", true, false):
\t\t\tcam.fov = 68.0''',
1,
)

# Matte-painted set extension: the approved main-street concept becomes the far
# boundary of a short real 3D street segment.
visual = visual.replace(
    'Vector3(0, 35.0, -62.0), Vector2(132.0, 74.25)',
    'Vector3(0, 8.0, 15.0), Vector2(28.0, 15.75)',
    1,
)
visual = visual.replace(
    'Vector3(0, 31.0, 72.0), Vector2(112.0, 63.0)',
    'Vector3(0, 47.0, 67.0), Vector2(188.0, 105.8)',
    1,
)
visual = visual.replace(
    'Vector3(68.0, 28.0, 8.0), Vector2(96.0, 54.0)',
    'Vector3(61.0, 44.0, 8.0), Vector2(160.0, 90.0)',
    1,
)
visual = visual.replace(
    'Vector3(-68.0, 26.0, 8.0), Vector2(92.0, 51.75)',
    'Vector3(-61.0, 42.0, 8.0), Vector2(154.0, 86.6)',
    1,
)

# Only the near 3D road remains visible; the approved concept takes over before
# primitive geometry can dominate the frame.
visual = visual.replace(
    'Vector3(0, 0.08, 4), Vector3(13.8, 0.10, 73), Color(0.065,0.068,0.064)',
    'Vector3(0, 0.08, 22), Vector3(13.8, 0.10, 13), Color(0.22,0.215,0.19)',
    1,
)
visual = visual.replace(
    'Vector3(side*8.15, 0.18, 4), Vector3(2.6,0.22,73), Color(0.31,0.30,0.27)',
    'Vector3(side*8.15, 0.18, 22), Vector3(2.6,0.22,13), Color(0.24,0.235,0.215)',
    1,
)
visual = visual.replace(
    'Vector3(side*6.75, 0.30,4),Vector3(0.20,0.44,73)',
    'Vector3(side*6.75, 0.30,22),Vector3(0.20,0.44,13)',
    1,
)
visual = visual.replace('for z in range(-28, 38, 5):', 'for z in range(17, 30, 4):', 1)
visual = visual.replace('rng.randf_range(-22.0,35.0)', 'rng.randf_range(17.0,28.0)')
visual = visual.replace('Color(0.72,0.57,0.18)', 'Color(0.52,0.43,0.14)')

# Remove blocky building/car silhouettes from the initial sightline. The real
# workshop remains at the left edge; the street ahead is driven by the approved art.
facades = '''\t_build_facade(Vector3(-14.5,4.0,7.0),Vector3(10.0,8.0,24.0),Color(0.30,0.14,0.085),false)
\t_build_facade(Vector3(14.5,3.2,13.0),Vector3(10.0,6.4,18.0),Color(0.25,0.23,0.19),true)
\t_build_facade(Vector3(-14.5,3.0,-16.0),Vector3(10.0,6.0,12.0),Color(0.35,0.20,0.12),false)
\t_build_facade(Vector3(14.5,4.5,-14.0),Vector3(10.0,9.0,14.0),Color(0.24,0.18,0.14),true)'''
visual = visual.replace(facades, '\t# Photo-backed set extension keeps the center sightline free of graybox facades.', 1)
visual = visual.replace('\t_create_car(Vector3(-3.8,0.60,13.0),-4.0,Color(0.20,0.21,0.18),1.0)\n', '', 1)
visual = visual.replace('\t_create_car(Vector3(3.6,0.60,-4.0),5.0,Color(0.28,0.17,0.12),0.92)\n', '', 1)
visual = visual.replace('\t_create_car(Vector3(-3.1,0.60,-18.0),-2.0,Color(0.13,0.16,0.16),0.88)\n', '', 1)

visual = visual.replace('for z in [-20.0,-2.0,17.0,34.0]:', 'for z in [21.0,28.0]:', 1)
visual = visual.replace('for z in [-23.0,4.0,29.0]:', 'for z in [25.0]:', 1)
visual = visual.replace(
    'var tree_positions := [Vector3(-9.7,0,-9),Vector3(9.5,0,-12),Vector3(-10.0,0,8),Vector3(10.2,0,9),Vector3(-10.5,0,20),Vector3(10.6,0,24),Vector3(-11.5,0,-25),Vector3(11.2,0,-29)]',
    'var tree_positions := []',
    1,
)
visual = visual.replace('rng.randf_range(-30.0,36.0)', 'rng.randf_range(18.0,29.0)')
visual = visual.replace(
    'if abs(x) < 5.7 and rng.randf() > 0.10:\n\t\t\tcontinue',
    'if abs(x) < 6.8:\n\t\t\tcontinue',
    1,
)
visual = visual.replace(
    'rng.randf_range(0.08,0.15),rng.randf_range(0.25,0.39),rng.randf_range(0.055,0.11)',
    'rng.randf_range(0.055,0.11),rng.randf_range(0.17,0.30),rng.randf_range(0.035,0.08)',
)
visual = visual.replace(
    'Color(0.10+rng.randf()*0.04,0.25+rng.randf()*0.10,0.06+rng.randf()*0.04)',
    'Color(0.065+rng.randf()*0.03,0.17+rng.randf()*0.08,0.04+rng.randf()*0.025)',
)
visual = visual.replace(
    'Color(0.14,0.29+rng.randf()*0.08,0.07)',
    'Color(0.07,0.18+rng.randf()*0.07,0.04)',
)

# The native status/objective panels are enough; remove the extra dark overlay card.
plate = '''\tvar plate := ColorRect.new()
\tplate.position = Vector2(14,12)
\tplate.size = Vector2(455,122)
\tplate.color = Color(0.008,0.014,0.012,0.58)
\tplate.z_index = -8
\thud.add_child(plate)
'''
visual = visual.replace(plate, '', 1)
visual = visual.replace('label.position = Vector2(24,108)', 'label.position = Vector2(24,665)', 1)

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

# Compact HUD and move ecology data away from the objective card.
text = text.replace("ecosystem_label.position = Vector2(20, 164)", "ecosystem_label.position = Vector2(20, 655)")
text = text.replace("ecosystem_label.position = Vector2(20, 122)", "ecosystem_label.position = Vector2(20, 655)")
text = text.replace("status_panel.size = Vector2(420, 48)", "status_panel.size = Vector2(360, 44)")
text = text.replace('stats_label.add_theme_font_size_override("font_size", 14)', 'stats_label.add_theme_font_size_override("font_size", 13)')
text = text.replace("objective_panel.size = Vector2(470, 84)", "objective_panel.size = Vector2(420, 72)")
text = text.replace("objective_label.size = Vector2(442, 66)", "objective_label.size = Vector2(392, 54)")
text = text.replace('objective_label.add_theme_font_size_override("font_size", 14)', 'objective_label.add_theme_font_size_override("font_size", 12)')
text = text.replace("Color(0.015, 0.025, 0.022, 0.72)", "Color(0.015, 0.025, 0.022, 0.52)")
text = text.replace("Color(0.018, 0.030, 0.024, 0.68)", "Color(0.018, 0.030, 0.024, 0.50)")

world.write_text(text, encoding="utf-8")
print("A1.7 cinematic polish applied")
