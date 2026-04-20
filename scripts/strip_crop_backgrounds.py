"""One-off: strip backgrounds from assets/crops/*.png using rembg (U^2-Net)."""
from pathlib import Path
from PIL import Image
from rembg import remove, new_session

HERE = Path(__file__).resolve().parent.parent
SRC = HERE / "assets" / "crops" / "_original"
DST = HERE / "assets" / "crops"

session = new_session("u2net")

pngs = sorted(SRC.glob("*.png"))
print(f"Found {len(pngs)} source PNGs in {SRC}")

for p in pngs:
    with Image.open(p) as im:
        im = im.convert("RGBA")
        out = remove(im, session=session)
    out_path = DST / p.name
    out.save(out_path, "PNG", optimize=True)
    print(f"  OK {p.name}  ({out_path.stat().st_size // 1024} KB)")

print("Done.")
