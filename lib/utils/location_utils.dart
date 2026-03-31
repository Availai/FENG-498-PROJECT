import 'package:geolocator/geolocator.dart';

Future<void> ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
        'Konum izni kalıcı olarak reddedildi. Lütfen telefon ayarlarından uygulama konumuna izin verin.');
  }
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Konum izni reddedildi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Konum izni kalıcı olarak reddedildi. Lütfen telefon ayarlarından uygulama konumuna izin verin.');
    }
  }
}

Future<Position> getCurrentPosition() async {
  try {
    // Tarla için nokta atışı yüksek hassasiyet
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  } catch (e) {
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) return lastPosition;
    throw Exception(
      'Konum alınamadı. Lütfen açık alana çıkın veya GPS\'i kontrol edin.',
    );
  }
}
