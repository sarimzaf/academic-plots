"""Build the installable skill from its maintained files and license notices."""
from pathlib import Path
import argparse
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def bundle_files(root=ROOT):
    files = [root / name for name in (
        "SKILL.md", "README.md", "LICENSE.md", "NOTICE.md", "scripts/style.R",
        "examples/quickstart.R", "licenses/Paul-Tol.txt", "fonts/Libre_Franklin/OFL.txt",
        "scripts/install-fonts-windows.ps1",
    )]
    files += [root / "references" / name for name in (
        "style-guide.md", "core-plots.md", "multi-panel.md",
        "aspect-ratio.md", "maps.md", "accessibility.md",
    )]
    files += [root / "fonts/Libre_Franklin/static" / f"LibreFranklin-{style}.ttf"
              for style in ("Regular", "Bold", "Italic", "BoldItalic")]
    for path in files:
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"Required regular file missing: {path}")
    # Path ordering is case-insensitive on Windows; sort portable member names.
    return sorted(files, key=lambda path: path.relative_to(root).as_posix())


def build_bundle(destination, root=ROOT):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in bundle_files(root):
            member = "academic-plots/" + path.relative_to(root).as_posix()
            info = zipfile.ZipInfo(member, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3  # Stable Unix metadata on every build platform.
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            data = path.read_bytes()
            if path.suffix != ".ttf":
                data = data.replace(b"\r\n", b"\n")
            archive.writestr(info, data)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(".zip.sha256").write_bytes(
        f"{digest}  {destination.name}\n".encode("ascii"))
    return destination


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "dist/academic-plots.zip")
    args = parser.parse_args()
    result = build_bundle(args.output)
    print(f"Built {result} ({result.stat().st_size:,} bytes) and SHA-256 checksum")
