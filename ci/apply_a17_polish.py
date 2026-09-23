from pathlib import Path
import shutil

root = Path(".")
src = root / "ci" / "a17_polish.gd"
dst = root / "scripts" / "a17_polish.gd"
if not src.exists():
    raise SystemExit("ci/a17_polish.gd missing")
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

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

# Keep the native HUD compact; the polish script handles the final placement.
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
print("A1.7 visual shell applied")
