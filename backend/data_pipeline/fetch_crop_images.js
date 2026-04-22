// seed_plants.json içindeki bitkilere Wikipedia REST API'sinden fotoğraf indirir.
// Her bitki: önce bilimsel ad EN → TR, sonra Türkçe ad EN → TR denenir.
// Çıktı: assets/crops/<slug>.jpg + lib/data/crop_images.json eşleme dosyası.

const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT = path.resolve(__dirname, '..', '..');
const SEED = path.join(ROOT, 'backend', 'data_pipeline', 'seed_plants.json');
const OUT_DIR = path.join(ROOT, 'assets', 'crops');
const MAP_FILE = path.join(ROOT, 'assets', 'data', 'crop_images.json');
const USER_AGENT = 'TarlamAppBot/1.0 (FENG-498 senior project; contact: berkeney09@gmail.com)';

const turkishMap = {'ç':'c','ğ':'g','ı':'i','ö':'o','ş':'s','ü':'u','Ç':'c','Ğ':'g','İ':'i','Ö':'o','Ş':'s','Ü':'u'};
function slug(s) {
  return s.split('').map(c => turkishMap[c] || c).join('')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function httpGet(url, opts = {}) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, {
      headers: { 'User-Agent': USER_AGENT, 'Accept': opts.accept || 'application/json' },
      timeout: 15000,
    }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        resolve(httpGet(res.headers.location, opts));
        return;
      }
      if (res.statusCode !== 200) {
        res.resume();
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      if (opts.binary) {
        const chunks = [];
        res.on('data', c => chunks.push(c));
        res.on('end', () => resolve(Buffer.concat(chunks)));
      } else {
        let body = '';
        res.on('data', c => body += c);
        res.on('end', () => resolve(body));
      }
      res.on('error', reject);
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(new Error('timeout')); });
  });
}

async function wikiSummary(lang, title) {
  const url = `https://${lang}.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`;
  try {
    const body = await httpGet(url);
    const json = JSON.parse(body);
    if (json.thumbnail?.source) {
      const orig = json.originalimage?.source || json.thumbnail.source;
      return orig;
    }
  } catch (_) {}
  return null;
}

async function findImage(sci, tr) {
  const attempts = [
    ['en', sci],
    ['tr', tr],
    ['tr', sci],
    ['en', tr],
  ];
  for (const [lang, q] of attempts) {
    if (!q) continue;
    const img = await wikiSummary(lang, q);
    if (img) return { url: img, source: `${lang}:${q}` };
    await new Promise(r => setTimeout(r, 120));
  }
  return null;
}

async function downloadTo(url, dest) {
  const buf = await httpGet(url, { binary: true, accept: 'image/*' });
  // Boyut kontrolü
  if (buf.length < 1500) throw new Error('image too small');
  fs.writeFileSync(dest, buf);
}

function getExt(url) {
  const m = url.match(/\.(jpg|jpeg|png|webp|gif|svg)(\?|$)/i);
  return m ? '.' + m[1].toLowerCase() : '.jpg';
}

async function main() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  const seed = JSON.parse(fs.readFileSync(SEED, 'utf-8'));
  const plants = seed.plants;
  const map = {};
  const failed = [];
  let ok = 0, skip = 0;

  // Mevcut eşleme varsa yükle (resume)
  if (fs.existsSync(MAP_FILE)) {
    Object.assign(map, JSON.parse(fs.readFileSync(MAP_FILE, 'utf-8')));
  }

  for (let i = 0; i < plants.length; i++) {
    const p = plants[i];
    const tr = p.name_tr;
    const sci = p.scientific_name;
    const base = slug(tr);

    // Zaten haritalı ve dosya varsa atla
    if (map[tr]) {
      const fp = path.join(OUT_DIR, map[tr]);
      if (fs.existsSync(fp) && fs.statSync(fp).size > 1500) {
        skip++;
        continue;
      }
    }

    try {
      const found = await findImage(sci, tr);
      if (!found) {
        failed.push(tr);
        console.log(`[${i+1}/${plants.length}] ${tr} — FAIL (no image)`);
        continue;
      }
      // SVG'leri atla — Flutter Image.asset direkt okuyamaz
      if (found.url.toLowerCase().endsWith('.svg')) {
        failed.push(tr + ' (svg)');
        console.log(`[${i+1}/${plants.length}] ${tr} — SKIP (svg)`);
        continue;
      }
      const ext = getExt(found.url);
      const fn = base + ext;
      const dest = path.join(OUT_DIR, fn);
      await downloadTo(found.url, dest);
      map[tr] = fn;
      ok++;
      console.log(`[${i+1}/${plants.length}] ${tr} → ${fn} (${found.source})`);
    } catch (e) {
      failed.push(tr);
      console.log(`[${i+1}/${plants.length}] ${tr} — ERR ${e.message}`);
    }

    // Periyodik kaydet + Wikipedia'yı yormamak için bekleme
    if (i % 15 === 14) {
      fs.writeFileSync(MAP_FILE, JSON.stringify(map, null, 2));
    }
    await new Promise(r => setTimeout(r, 200));
  }

  fs.writeFileSync(MAP_FILE, JSON.stringify(map, null, 2));
  console.log(`\n✓ Tamamlandı: ${ok} yeni, ${skip} atlandı (var), ${failed.length} başarısız`);
  if (failed.length) {
    fs.writeFileSync(path.join(__dirname, 'failed_plants.txt'), failed.join('\n'));
    console.log('Başarısız liste: backend/data_pipeline/failed_plants.txt');
  }
}

main().catch(e => { console.error(e); process.exit(1); });
