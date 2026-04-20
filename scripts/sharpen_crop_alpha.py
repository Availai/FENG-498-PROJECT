"""Post-process crop PNGs: sharpen alpha so subject is fully opaque and
background fully transparent, with a 1-2px soft feather for clean edges."""
from pathlib import Path
from PIL import Image
import numpy as np

CROPS = Path(__file__).resolve().parent.parent / "assets" / "crops"

LOW = 40    # alpha <= LOW  -> 0 (pure transparent)
HIGH = 120  # alpha >= HIGH -> 255 (fully opaque)
# between LOW..HIGH -> linear ramp (preserves a 1-2px feather)

pngs = sorted(p for p in CROPS.glob("*.png") if p.is_file())
print(f"Sharpening alpha on {len(pngs)} files")

for p in pngs:
    with Image.open(p) as im:
        im = im.convert("RGBA")
        arr = np.array(im)

    a = arr[:, :, 3].astype(np.int32)
    new_a = np.where(
        a <= LOW,
        0,
        np.where(
            a >= HIGH,
            255,
            ((a - LOW) * 255 // (HIGH - LOW)),
        ),
    ).astype(np.uint8)
    arr[:, :, 3] = new_a

    Image.fromarray(arr, "RGBA").save(p, "PNG", optimize=True)
    opaque = int((new_a == 255).sum())
    total = new_a.size
    print(f"  OK {p.name:18s} opaque={100*opaque/total:5.1f}%")

print("Done.")
