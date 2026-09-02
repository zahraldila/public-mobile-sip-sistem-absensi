import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Prioritaskan Google Text-to-Speech Engine jika di Android
      if (Platform.isAndroid) {
        try {
          final dynamic engines = await _flutterTts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _flutterTts.setEngine('com.google.android.tts');
          }
        } catch (e) {
          debugPrint('Info getEngines: $e');
        }
      }

      // Set Bahasa Indonesia
      await _flutterTts.setLanguage('id-ID');

      // Cari dan pasang model suara Bahasa Indonesia Google jika tersedia
      try {
        final dynamic voices = await _flutterTts.getVoices;
        if (voices is List) {
          for (var voice in voices) {
            if (voice is Map) {
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              if (locale.contains('id-id') || locale.contains('id_id') || locale == 'ind') {
                await _flutterTts.setVoice({
                  'name': voice['name'].toString(),
                  'locale': voice['locale'].toString(),
                });
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Info voice selector: $e');
      }

      // Parameter artikulasi suara yang natural
      await _flutterTts.setSpeechRate(0.48); // Kecepatan bicara natural
      await _flutterTts.setVolume(1.0);      // Volume maksimal
      await _flutterTts.setPitch(1.0);       // Pitch natural (tidak cempreng/robotik)
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inisialisasi TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await _flutterTts.stop(); // Hentikan suara sebelumnya jika masih ada
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error memutar suara TTS: $e');
    }
  }

  Future<void> speakCheckIn(String employeeName) async {
    final name = employeeName.isNotEmpty ? employeeName : 'Pegawai';
    await speak('Check In berhasil. Selamat bekerja, $name.');
  }

  Future<void> speakCheckOut(String employeeName) async {
    final name = employeeName.isNotEmpty ? employeeName : 'Pegawai';
    await speak('Check Out berhasil. Terima kasih, $name.');
  }

  Future<void> speakAlreadyCompleted(String employeeName) async {
    final name = employeeName.isNotEmpty ? employeeName : 'Pegawai';
    await speak('Absensi hari ini sudah selesai, $name.');
  }

  Future<void> speakCardNotFound() async {
    await speak('Kartu tidak terdaftar. Silakan hubungi administrator.');
  }

  Future<void> speakInactiveAccount() async {
    await speak('Akun pegawai tidak aktif. Silakan hubungi administrator.');
  }

  Future<void> speakLocationDisabled() async {
    await speak('Location belum aktif. Silakan aktifkan Location untuk melakukan absensi.');
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stop TTS: $e');
    }
  }
}
