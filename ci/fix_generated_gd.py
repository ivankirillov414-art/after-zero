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
    if touched:
        path.write_text("".join(out), encoding="utf-8")
        changed.append(str(path))

print("Normalized GDScript indentation:")
for item in changed:
    print(" -", item)
