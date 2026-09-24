from pathlib import Path
import shutil

root = Path(".")
src = root / "ci" / "a19_detail3d.gd"
dst = root / "scripts" / "a19_detail3d.gd"
if not src.exists():
    raise SystemExit("ci/a19_detail3d.gd missing")
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

world = root / "scripts" / "world.gd"
text = world.read_text(encoding="utf-8")

const_line = 'const A19_DETAIL3D_SCRIPT := preload("res://scripts/a19_detail3d.gd")'
if "A19_DETAIL3D_SCRIPT" not in text:
    anchor = 'const A18_REAL3D_SCRIPT := preload("res://scripts/a18_real3d.gd")'
    if anchor in text:
        text = text.replace(anchor, anchor + "\n" + const_line, 1)
    else:
        insert_at = text.find("\nvar ")
        if insert_at < 0:
            raise SystemExit("Cannot place A1.9 preload")
        text = text[:insert_at] + "\n" + const_line + text[insert_at:]

if "detail3d_a19.build(self, player, hud)" not in text:
    ready_start = text.find("func _ready() -> void:")
    process_start = text.find("\nfunc _process", ready_start)
    if ready_start < 0 or process_start < 0:
        raise SystemExit("Cannot locate _ready block")
    ready_block = text[ready_start:process_start]
    target = "\treal3d_a18.build(self, player, hud)"
    idx = ready_block.rfind(target)
    if idx < 0:
        raise SystemExit("Cannot locate A1.8 build call")
    insert_at = ready_start + idx + len(target)
    addition = '\n\tvar detail3d_a19 := A19_DETAIL3D_SCRIPT.new()\n\tadd_child(detail3d_a19)\n\tdetail3d_a19.build(self, player, hud)'
    text = text[:insert_at] + addition + text[insert_at:]

text = text.replace("user://after_zero_a1_8_save.json", "user://after_zero_a1_9_save.json")
world.write_text(text, encoding="utf-8")

project = root / "project.godot"
ptext = project.read_text(encoding="utf-8")
for old in ['config/version="0.1.8"', 'config/version="0.1.7.1"', 'config/version="0.1.7"']:
    ptext = ptext.replace(old, 'config/version="0.1.9"')
project.write_text(ptext, encoding="utf-8")

(root / "CHANGELOG_A1_9.md").write_text("""# After Zero A1.9 — DETAIL 3D

- Continued directly from the A1.8 real-3D slice.
- Replaced the closest placeholder workshop, market, storefronts, cars and blob trees with denser authored procedural 3D.
- Workshop start now aligns with the actual story workbench, note, generator and terminal interactions.
- Added real workshop interior detail: steel portal, raised garage door, roof beams, pegboard/tools, shelving, generator, archive terminal, tires and clutter.
- Reworked Riverdale storefront facades with recessed shopfronts, upper windows, cornices, awnings, signs, drainpipes and ivy.
- Reworked Pine Ridge Market facade and entrance.
- Replaced sphere foliage with alpha-cut crossed leaf cards and tapered grass cards.
- Added more detailed abandoned sedan/pickup geometry.
- Player now starts inside the workshop where the first objective actually is.
""", encoding="utf-8")

print("A1.9 detailed 3D patch applied")
