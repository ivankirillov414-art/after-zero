from pathlib import Path

root = Path(".")
changed = []

for path in root.rglob("*.gd"):
    if ".git" in path.parts:
        continue
    text = path.read_text(encoding="utf-8")
    out = []
    touched = False
    for line in text.splitlines(True):
        n = 0
        while n < len(line) and line[n] == " ":
            n += 1
        if n:
            line = ("\t" * n) + line[n:]
            touched = True
        out.append(line)
    new_text = "".join(out)

    # A1.6 generated-code fixes found by real Godot 4.3 runtime validation.
    replacements = {
        "var noise := player.get_noise_level()": "var noise: float = float(player.get_noise_level())",
        "var tall := facade.z < 0.0": "var tall: bool = facade.z < 0.0",
        "var x := facade.x - 6.0 + float(column) * 3.0": "var x: float = float(facade.x - 6.0 + float(column) * 3.0)",
    }
    for old, new in replacements.items():
        if old in new_text:
            new_text = new_text.replace(old, new)
            touched = True

    if touched:
        path.write_text(new_text, encoding="utf-8")
        changed.append(str(path))

print("Patched generated GDScript:")
for item in changed:
    print(" -", item)
