"""Her PDF'den ana zararlı/hastalık başlıklarını ve sayfa aralıklarını listeler.

CLAUDE.md sec 27 — okuma adımı. Bu script evidence ÇIKARTMAZ; sadece
hangi sayfaların okunacağını, hangi hastalık/zararlı isimlerinin
bulunacağını raporlar. Bu bilgiyle populate_priority_crops.py manuel
güncellenir (TAGEM PDF formatları farklı, generic parser yazmıyoruz).

Kullanım:
    cd backend
    ./venv/Scripts/python.exe data_pipeline/extract_main_sections.py
"""
from __future__ import annotations
import sys
from pathlib import Path
import fitz  # PyMuPDF

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

PDFS = {
    "corn":      "corn_ipm.pdf",
    "sunflower": "sunflower_ipm.pdf",
    "tea":       "tea_caykur_2025.pdf",
    "citrus":    "citrus_ipm.pdf",
}

BASE = Path(__file__).parent / "sources_pdf"

def main() -> int:
    for tag, fname in PDFS.items():
        path = BASE / fname
        if not path.exists():
            print(f"[YOK] {fname}")
            continue
        doc = fitz.open(str(path))
        print(f"\n{'='*40} {tag.upper()} ({doc.page_count} pages) {'='*40}")

        # 1) TOC dene
        toc = doc.get_toc()
        if toc:
            print(f"-- TOC ({len(toc)} entry) --")
            for level, title, page in toc[:50]:
                # Çoğu PDF'te asıl başlıklar level 1-2'de; şekil/açıklama listeleri gürültü
                if any(noise in title.lower() for noise in
                       ["şekil", "çizelge", "açıklama", "ek "]):
                    continue
                print(f"  {'  '*(level-1)}{title.strip()[:90]}  -> p.{page}")
        else:
            # 2) TOC yoksa ilk 12 sayfaya göz at — içindekiler genelde 4-10 arası
            print("(TOC yok — sayfa 1-12 başlıkları)")
            for i in range(min(12, doc.page_count)):
                t = doc[i].get_text()
                # Sadece ALL CAPS veya numbered headings yakalat (içindekiler tipik)
                lines = [l.strip() for l in t.split("\n") if l.strip()]
                for line in lines:
                    if (line.isupper() and 5 < len(line) < 80) or \
                       (line[:2].replace(".", "").isdigit() and 5 < len(line) < 80):
                        print(f"  p{i+1}: {line[:90]}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
