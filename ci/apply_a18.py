from pathlib import Path
import shutil

root = Path('.')
src = root / 'ci' / 'a18_real3d.gd'
dst = root / 'scripts' / 'a18_real3d.gd'
if not src.exists():
    raise SystemExit('ci/a18_real3d.gd missing')
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(src, dst)

world = root / 'scripts' / 'world.gd'
text = world.read_text(encoding='utf-8')
const_line = 'const A18_REAL3D_SCRIPT := preload("res://scripts/a18_real3d.gd")'
if 'A18_REAL3D_SCRIPT' not in text:
    marker = 'const SAVE_PATH := "user://after_zero_a1_7_save.json"'
    if marker in text:
        text = text.replace(marker, marker + '\n' + const_line, 1)
    else:
        marker2 = 'const SAVE_PATH := "user://after_zero_a1_6_save.json"'
        if marker2 in text:
            text = text.replace(marker2, marker2 + '\n' + const_line, 1)
        else:
            insert_at = text.find('\nvar ')
            if insert_at < 0:
                raise SystemExit('Cannot place A18 preload')
            text = text[:insert_at] + '\n' + const_line + text[insert_at:]

if 'real3d_a18.build(self, player, hud)' not in text:
    ready_start = text.find('func _ready() -> void:')
    process_start = text.find('\nfunc _process', ready_start)
    if ready_start < 0 or process_start < 0:
        raise SystemExit('Cannot locate _ready block')
    ready_block = text[ready_start:process_start]
    target = '\t_update_objective()'
    idx = ready_block.rfind(target)
    if idx < 0:
        raise SystemExit('Cannot locate final _update_objective in _ready')
    insert_at = ready_start + idx + len(target)
    addition = '\n\tvar real3d_a18 := A18_REAL3D_SCRIPT.new()\n\tadd_child(real3d_a18)\n\treal3d_a18.build(self, player, hud)'
    text = text[:insert_at] + addition + text[insert_at:]

text = text.replace('user://after_zero_a1_7_save.json', 'user://after_zero_a1_8_save.json')
world.write_text(text, encoding='utf-8')

project = root / 'project.godot'
ptext = project.read_text(encoding='utf-8')
for old in ['config/version="0.1.7.1"', 'config/version="0.1.7"', 'config/version="0.1.6"']:
    ptext = ptext.replace(old, 'config/version="0.1.8"')
project.write_text(ptext, encoding='utf-8')

(root / 'CHANGELOG_A1_8.md').write_text('''# After Zero A1.8 — REAL 3D

- Removed the in-world 2D concept-art shell from the playable view.
- Added real 3D modular Riverdale buildings, workshop interior, Pine Ridge Market, gas station and Greenbelt lab exterior.
- Added real 3D cars, street furniture, curbs, road, procedural asphalt, windows, doors, signs and vegetation.
- Legacy graybox remains invisible only for collision / interaction compatibility.
- Spawn returns to the actual workshop interior.
- HUD reduced to gameplay essentials.
''', encoding='utf-8')
print('A1.8 real 3D patch applied')
