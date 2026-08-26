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
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.5); // Kecepatan bicara normal dan jelas
      await _flutterTts.setVolume(1.0);     // Volume maksimal
      await _flutterTts.setPitch(1.0);      // Nada normal
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

  Future<void> speakAlreadyCompleted() async {
    await speak('Absensi hari ini sudah selesai.');
  }

  Future<void> speakCardNotFound() async {
    await speak('Kartu tidak terdaftar. Silakan hubungi administrator.');
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stop TTS: $e');
    }
  }
}
