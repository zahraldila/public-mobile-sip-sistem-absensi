import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  /// Mengambil posisi GPS fisik terkini dari sensor perangkat
  static Future<Position?> getCurrentPosition() async {
    try {
      // 1. Cek apakah layanan GPS aktif di perangkat
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Layanan lokasi (GPS) tidak aktif di perangkat');
        return null;
      }

      // 2. Cek status izin akses lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Izin lokasi ditolak oleh pengguna');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Izin lokasi ditolak secara permanen');
        return null;
      }

      // 3. Ambil posisi GPS realtime dengan timeout aman
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error getCurrentPosition GPS: $e');
      return null;
    }
  }
}
