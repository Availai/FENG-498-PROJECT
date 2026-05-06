"""Geçici extraction yardımcısı.

Verilen PDF + sayfa aralığı için ham metni döker. populate_priority_crops.py'ı
manuel doldururken Claude Code'un evidence_text kısmını bire-bir alabilmesi
için kullanılır. Çalışma sonrası repo'ya commit edilmesi zorunlu değildir.

Kullanım:
    python data_pipeline/_pdf_extract.py corn_ipm.pdf 16 22
"""
from __future__ import annotations
import sys
from pathlib import Path
import fitz

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

BASE = Path(__file__).parent / "sources_pdf"


def main() -> int:
    if len(sys.argv) < 4:
        print("Kullanım: _pdf_extract.py <fname> <start_page_1based> <end_page_1based>")
        return 1
    fname, start, end = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    path = BASE / fname
    if not path.exists():
        print(f"[YOK] {path}")
        return 1
    doc = fitz.open(str(path))
    for p in range(start - 1, min(end, doc.page_count)):
        page = doc[p]
        print(f"\n===== PAGE {p+1} =====")
        print(page.get_text())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
