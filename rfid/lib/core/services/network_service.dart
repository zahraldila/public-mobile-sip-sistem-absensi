import 'dart:async';
import 'dart:io';

class NetworkService {
  NetworkService._();

  /// Memeriksa apakah perangkat memiliki akses internet aktif secara instan (< 1 detik)
  static Future<bool> hasInternetConnection() async {
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 1200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(milliseconds: 1200));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Stream periodic untuk memantau status internet secara realtime setiap 1 detik
  static Stream<bool> get onConnectivityChanged async* {
    yield await hasInternetConnection();
    yield* Stream.periodic(const Duration(seconds: 1), (_) => null)
        .asyncMap((_) => hasInternetConnection())
        .distinct();
  }
}
