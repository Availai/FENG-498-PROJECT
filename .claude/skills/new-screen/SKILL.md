---
name: new-screen
description: Use when the user asks to scaffold a new Flutter screen in lib/screens/. Triggers like "yeni ekran ekle X", "screens/ altına Y ekran oluştur", "new screen for Z". Follows Tarlam conventions (Riverpod ConsumerWidget, AppColors theme, Turkish UI, particle background).
---

# new-screen — Tarlam Ekran İskeleti

## Amaç
`lib/screens/` altına Tarlam konvansiyonlarına uygun yeni bir Flutter ekran oluşturur. Boilerplate'i elle yazmayı önler, hardcoded renk/ingilizce string riski sıfırlar.

## İş Akışı

### 1. Dosya Adı
Kullanıcıdan ekran amacını al, snake_case + `_screen.dart` üret:
- "Hasat raporu ekranı" → `harvest_report_screen.dart`
- "Gübre takvimi" → `fertilizer_calendar_screen.dart`

`lib/screens/` altında aynı adda dosya varsa kullanıcıyı uyar, dur.

### 2. Sınıf Adı
PascalCase + `Screen` suffix: `HarvestReportScreen`, `FertilizerCalendarScreen`.

### 3. Şablon
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_background.dart';

class {{ClassName}} extends ConsumerStatefulWidget {
  const {{ClassName}}({super.key});

  @override
  ConsumerState<{{ClassName}}> createState() => _{{ClassName}}State();
}

class _{{ClassName}}State extends ConsumerState<{{ClassName}}> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('{{Turkish Title}}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          const ParticleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TODO: içerik
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Türkçe Başlık Zorla
Kullanıcı başlık vermediyse Türkçe öner (İngilizce ASLA):
- "Harvest Report" → "Hasat Raporu"
- "Fertilizer Schedule" → "Gübreleme Takvimi"

### 5. Route Eklenmesi
Ekran `navigation_screen.dart`'a bağlanacaksa (alt menüde görünecekse):
- `lib/screens/navigation_screen.dart` dosyasını aç
- Mevcut pages listesine yeni ekranı ekle
- Bottom nav'a icon+label ekle

Kullanıcıya sor: **"Bu ekran ana navigasyonda mı, yoksa başka bir ekrandan push ile mi açılacak?"** Cevaba göre davran. Push ise route eklemez, sadece kullanıcıya örnek kod ver:
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => const {{ClassName}}(),
));
```

## Kaçınılacaklar
- Hardcoded `Colors.green`, `Color(0xFF...)` — SADECE `AppColors.*`.
- İngilizce string (AppBar title, SnackBar, dialog, error).
- `StatelessWidget` + `Provider.of` kombinasyonu — Riverpod `ConsumerStatefulWidget` veya `ConsumerWidget`.
- Yeni tema/renk tanımı — app_theme.dart'a dokunma.

## Doğrulama
```bash
flutter analyze lib/screens/{{file_name}}.dart
```
0 issue beklenir.
