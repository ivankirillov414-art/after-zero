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

    replacements = {
        "var noise := player.get_noise_level()": "var noise: float = float(player.get_noise_level())",
        "var tall := facade.z < 0.0": "var tall: bool = facade.z < 0.0",
        "var x := facade.x - 6.0 + float(column) * 3.0": "var x: float = float(facade.x - 6.0 + float(column) * 3.0)",
        "@export var loot: Array[Dictionary] = []": "@export var loot: Array = []",
        "@export var salvage: Array[Dictionary] = []": "@export var salvage: Array = []",
        "core.modulate = Color(1.15,0.75,0.55) if hostile else (Color(0.95,1.08,0.72) if active else Color.WHITE)": "var core_mat := core.material_override as StandardMaterial3D\n\tif core_mat:\n\t\tcore_mat.albedo_color = Color(0.55,0.20,0.10) if hostile else (Color(0.34,0.48,0.16) if active else Color(0.25,0.34,0.12))",
        "body_mesh.modulate = Color(1.15,0.65,0.45) if alert>0.0 else Color.WHITE": "var body_mat := body_mesh.material_override as StandardMaterial3D\n\t\tif body_mat:\n\t\t\tbody_mat.albedo_color = Color(0.48,0.20,0.10) if alert > 0.0 else Color(0.22,0.32,0.14)",
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
