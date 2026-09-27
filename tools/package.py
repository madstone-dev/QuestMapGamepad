"""Create a deterministic addon ZIP from an explicit runtime-file allowlist."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon/QuestMapGamepad"


def build(output_dir=None):
    toc = (ADDON / "QuestMapGamepad.toc").read_text(encoding="utf-8")
    version = re.search(r"^## Version: (.+)$", toc, re.M).group(1)
    runtime = ["QuestMapGamepad.toc", "Bindings.xml", "Licenses/ATT-MIT.txt"]
    runtime += [line.replace("\\", "/") for line in toc.splitlines() if line and not line.startswith("#")]
    def text_bytes(path):
        return path.read_text(encoding="utf-8").encode("utf-8")

    files = {name: text_bytes(ADDON / name) for name in runtime}
    for name in ("LICENSE", "README.md", "THIRD_PARTY_NOTICES.md", "CHANGELOG.md"):
        files[name] = text_bytes(ROOT / name)
    files["TESTING.md"] = text_bytes(ROOT / "docs/TESTING.md")
    out = Path(output_dir) if output_dir else ROOT / "dist"
    out.mkdir(parents=True, exist_ok=True)
    target = out / f"QuestMapGamepad-{version}.zip"
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(files.items()):
            entry = zipfile.ZipInfo("QuestMapGamepad/" + name, date_time=(2026, 9, 27, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            archive.writestr(entry, data)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix(".zip.sha256").write_text(f"{digest}  {target.name}\n", encoding="ascii")
    print(f"{target.name}: {len(files)} files, {target.stat().st_size:,} bytes; SHA256 {digest}")
    return target


if __name__ == "__main__":
    build()
