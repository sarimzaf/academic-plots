"""Check the source package and verify the actual installable ZIP."""
from pathlib import Path
import hashlib
import importlib.util
import re
import tempfile
import zipfile
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("package_skill", ROOT / "scripts/package_skill.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


def heading_ids(path):
    # GitHub-style IDs for the ATX headings used in this package; ignore code.
    anchors = set()
    in_code = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("```"):
            in_code = not in_code
        if in_code:
            continue
        match = re.match(r"^#{1,6} +(.+?) *#* *$", line)
        if match:
            slug = re.sub(r"[^\w\- ]", "", match[1].lower()).replace(" ", "-")
            unique, index = slug, 0
            while unique in anchors:
                index += 1
                unique = f"{slug}-{index}"
            anchors.add(unique)
    return anchors


def check_links(root, files):
    for path in files:
        if path.suffix != ".md":
            continue
        for target in re.findall(r"\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            link = urlsplit(target)
            if link.scheme or link.netloc:
                continue
            destination = (path.parent / unquote(link.path)).resolve() if link.path else path
            assert destination.is_relative_to(root.resolve()), f"Link leaves package: {path}: {target}"
            assert destination.is_file(), f"Broken link: {path}: {target}"
            if link.fragment:
                assert unquote(link.fragment) in heading_ids(destination), f"Broken heading: {path}: {target}"


skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
assert skill.startswith("---\nname: academic-plots\n")
assert len(skill.splitlines()) < 300, "Keep the entrypoint concise; use references."
assert len(re.search(r"^description: (.+)$", skill, re.M).group(1)) < 1024
files = package.bundle_files()
check_links(ROOT, files)
for path in files:
    if path.suffix != ".ttf":
        text = path.read_text(encoding="utf-8")
        assert not re.search(r"[A-Za-z]:[/\\]Users[/\\]|/Users/|/home/[^/]+/", text), path
        assert not re.search(r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})", text), path

with tempfile.TemporaryDirectory(prefix="academic-plots-package-") as tmp:
    tmp = Path(tmp)
    first = package.build_bundle(tmp / "one.zip")
    second = package.build_bundle(tmp / "two.zip")
    assert first.read_bytes() == second.read_bytes(), "Package is not deterministic"
    # Simulate Git checkouts with opposite line endings. Font bytes stay intact.
    for newline, label in ((b"\n", "lf"), (b"\r\n", "crlf")):
        checkout = tmp / label
        for source in files:
            target = checkout / source.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            data = source.read_bytes()
            if source.suffix != ".ttf":
                data = data.replace(b"\r\n", b"\n").replace(b"\n", newline)
            target.write_bytes(data)
        rebuilt = package.build_bundle(tmp / f"{label}.zip", root=checkout)
        assert rebuilt.read_bytes() == first.read_bytes(), "Checkout line endings changed the ZIP"
    with zipfile.ZipFile(first) as archive:
        assert archive.testzip() is None
        assert all(info.create_system == 3 for info in archive.infolist())
        for source in files:
            if source.suffix == ".ttf":
                member = "academic-plots/" + source.relative_to(ROOT).as_posix()
                assert archive.read(member) == source.read_bytes(), "Font bytes changed"
        names = set(archive.namelist())
        expected = {"academic-plots/" + p.relative_to(ROOT).as_posix() for p in files}
        assert names == expected
        assert archive.namelist() == sorted(expected), "ZIP member order depends on the OS"
        assert not any("/tests/" in n or "/archive/" in n or "/.git/" in n for n in names)
        archive.extractall(tmp / "unpacked")
    extracted = tmp / "unpacked/academic-plots"
    check_links(extracted, list(extracted.rglob("*.md")))
    expected_hash = hashlib.sha256(first.read_bytes()).hexdigest()
    assert first.with_suffix(".zip.sha256").read_text().startswith(expected_hash + "  ")
    assert first.stat().st_size < 2_000_000, "Unexpected bundle growth"
    print(f"PASS: {len(files)} bundle files, links/anchors, portable paths, licenses, font integrity, checksum and LF/CRLF-stable ZIP ({first.stat().st_size:,} bytes).")
