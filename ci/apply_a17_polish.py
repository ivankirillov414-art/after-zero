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

world.write_text(text, encoding="utf-8")
print("A1.7 cinematic polish applied")
