# Turkish Crops Asset

`turkish_crops.sqlite` bu klasörde olmalı.

Bu dosyayı elle oluşturma — veri pipeline'ı otomatik üretir:

```bash
cd backend
pip install -r requirements.txt
python data_pipeline/build_turkish_crops_db.py
```

Script `backend/data_pipeline/seed_plants.json` dosyasını okur, SQLite'a
dönüştürür ve buraya kopyalar. Dosya yoksa uygulama içindeki arama boş
görünür ama uygulama çökmez.

Yeni bitki eklemek için sadece `seed_plants.json`'a satır ekle, scripti
tekrar çalıştır.
