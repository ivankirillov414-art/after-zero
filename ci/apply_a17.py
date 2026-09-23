from pathlib import Path
import shutil

root = Path(".")
src = root / "ci" / "visual_a17.gd"
dst = root / "scripts" / "visual_a17.gd"
if not src.exists():
    raise SystemExit("ci/visual_a17.gd missing")
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

world = root / "scripts" / "world.gd"
text = world.read_text(encoding="utf-8")

if "A17_VISUAL_SCRIPT" not in text:
    save_line = 'const SAVE_PATH := "user://after_zero_a1_6_save.json"'
    if save_line in text:
        text = text.replace(
            save_line,
            'const SAVE_PATH := "user://after_zero_a1_7_save.json"\nconst A17_VISUAL_SCRIPT := preload("res://scripts/visual_a17.gd")',
            1,
        )
    else:
        first_const = text.find("const ")
        if first_const >= 0:
            line_end = text.find("\n", first_const)
            text = text[:line_end+1] + 'const A17_VISUAL_SCRIPT := preload("res://scripts/visual_a17.gd")\n' + text[line_end+1:]
        else:
            text = 'const A17_VISUAL_SCRIPT := preload("res://scripts/visual_a17.gd")\n' + text

needle = "\t_update_objective()\n\nfunc _process"
if "visual_a17.build(self, player, hud)" not in text:
    if needle not in text:
        raise SystemExit("Could not locate end of _ready() in world.gd")
    text = text.replace(
        needle,
        "\t_update_objective()\n\tvar visual_a17 := A17_VISUAL_SCRIPT.new()\n\tadd_child(visual_a17)\n\tvisual_a17.build(self, player, hud)\n\nfunc _process",
        1,
    )

text = text.replace("ПОСЛЕ НУЛЯ / ЗЕЛЁНЫЙ ПРЕДЕЛ / A1.5", "ПОСЛЕ НУЛЯ / ЗЕЛЁНЫЙ ПРЕДЕЛ / A1.7")
text = text.replace("ПОСЛЕ НУЛЯ / ЗЕЛЁНЫЙ ПРЕДЕЛ / A1.6", "ПОСЛЕ НУЛЯ / ЗЕЛЁНЫЙ ПРЕДЕЛ / A1.7")
world.write_text(text, encoding="utf-8")

project = root / "project.godot"
p = project.read_text(encoding="utf-8")
if 'config/version=' in p:
    import re
    p = re.sub(r'config/version="[^"]+"', 'config/version="0.1.7"', p, count=1)
else:
    p = p.replace('[application]\n', '[application]\nconfig/version="0.1.7"\n', 1)
p = p.replace("После нуля — A1.6.1", "После нуля — A1.7")
p = p.replace("После нуля — A1.6", "После нуля — A1.7")
project.write_text(p, encoding="utf-8")

print("A1.7 visual overlay applied")
