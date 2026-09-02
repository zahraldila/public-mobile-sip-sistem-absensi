import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationDisabledException implements Exception {
  final String message;
  LocationDisabledException([this.message = 'Location belum aktif. Silakan aktifkan Location untuk melakukan absensi.']);

  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException([this.message = 'Izin akses lokasi belum diberikan. Silakan izinkan akses lokasi untuk melakukan absensi.']);

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();

  /// Membuka halaman pengaturan lokasi di perangkat
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error openLocationSettings: $e');
      return false;
    }
  }

  /// Cek apakah GPS aktif
  static Future<bool> isLocationEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error isLocationEnabled: $e');
      return false;
    }
  }

  /// Mengambil posisi GPS fisik terkini dari sensor perangkat
  /// Melempar [LocationDisabledException] jika GPS dalam kondisi OFF
  static Future<Position?> getCurrentPosition({bool strict = true}) async {
    // 1. Cek apakah layanan GPS aktif di perangkat
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Layanan lokasi (GPS) tidak aktif di perangkat');
      if (strict) {
        throw LocationDisabledException();
      }
      return null;
    }

    // 2. Cek status izin akses lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Izin lokasi ditolak oleh pengguna');
        if (strict) {
          throw LocationPermissionDeniedException();
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Izin lokasi ditolak secara permanen');
      if (strict) {
        throw LocationPermissionDeniedException(
          'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengizinkan akses lokasi.',
        );
      }
      return null;
    }

    // 3. Ambil posisi GPS realtime dengan timeout aman
    try {
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
