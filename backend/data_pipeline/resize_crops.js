// assets/crops/ içindeki tüm fotoğrafları 256px genişliğe resize eder + JPEG q80.
// Amaç: APK boyutunu 635 MB'tan ~15-25 MB'a indirmek.
// Tek seferlik — çalıştırdıktan sonra dosyalar yerinde güncellenir.

const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const CROPS_DIR = path.resolve(__dirname, '..', '..', 'assets', 'crops');
const MAP_FILE = path.resolve(__dirname, '..', '..', 'lib', 'data', 'crop_images.json');
const MAP_FILE_OUT = path.resolve(__dirname, '..', '..', 'assets', 'data', 'crop_images.json');
const TARGET_WIDTH = 256;
const JPEG_QUALITY = 80;

async function resizeOne(fp) {
  const ext = path.extname(fp).toLowerCase();
  const tmp = fp + '.tmp.jpg';
  try {
    // Her şey JPEG'e çevrilir — ufak, hızlı, şeffaflık gerektirmiyor
    await sharp(fp)
      .resize({ width: TARGET_WIDTH, withoutEnlargement: true })
      .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
      .toFile(tmp);

    const newName = path.basename(fp, ext) + '.jpg';
    const newPath = path.join(path.dirname(fp), newName);

    // Eski dosyayı sil, yenisini yerine koy
    if (newPath !== fp) fs.unlinkSync(fp);
    fs.renameSync(tmp, newPath);
    return { ok: true, from: path.basename(fp), to: path.basename(newPath) };
  } catch (e) {
    try { fs.unlinkSync(tmp); } catch (_) {}
    return { ok: false, from: path.basename(fp), error: e.message };
  }
}

async function main() {
  const files = fs.readdirSync(CROPS_DIR).filter(f => {
    return /\.(jpg|jpeg|png|webp|gif)$/i.test(f);
  });

  console.log(`Resizing ${files.length} files to ${TARGET_WIDTH}px wide…`);
  const renameMap = {}; // oldFilename -> newFilename

  let ok = 0, fail = 0;
  for (let i = 0; i < files.length; i++) {
    const fp = path.join(CROPS_DIR, files[i]);
    const r = await resizeOne(fp);
    if (r.ok) {
      if (r.from !== r.to) renameMap[r.from] = r.to;
      ok++;
    } else {
      console.log(`  FAIL ${r.from}: ${r.error}`);
      fail++;
    }
    if (i % 30 === 29) console.log(`  ${i+1}/${files.length}`);
  }

  // crop_images.json'daki eski isimleri yeni isimlere güncelle
  if (fs.existsSync(MAP_FILE)) {
    const map = JSON.parse(fs.readFileSync(MAP_FILE, 'utf-8'));
    for (const k of Object.keys(map)) {
      if (renameMap[map[k]]) map[k] = renameMap[map[k]];
    }
    // assets/data/ altına taşı
    if (!fs.existsSync(path.dirname(MAP_FILE_OUT))) {
      fs.mkdirSync(path.dirname(MAP_FILE_OUT), { recursive: true });
    }
    fs.writeFileSync(MAP_FILE_OUT, JSON.stringify(map, null, 2));
    // Eskisini sil
    if (MAP_FILE_OUT !== MAP_FILE) fs.unlinkSync(MAP_FILE);
    console.log(`Map → ${MAP_FILE_OUT} (${Object.keys(map).length} entries)`);
  }

  console.log(`\n✓ Resize tamam: ${ok} başarılı, ${fail} başarısız`);
}

main().catch(e => { console.error(e); process.exit(1); });
