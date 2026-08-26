import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/services/attendance_service.dart';
import '../../core/services/tts_service.dart';
import '../attendance/checkout_success_screen.dart';
import '../attendance/success_screen.dart';
import 'widgets/clock_widget.dart';
import 'widgets/company_header.dart';
import 'widgets/nfc_scan_area.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TtsService _ttsService = TtsService();

  late Stream<DateTime> _timeStream;

  String _companyName = 'PT Selada Indonesia Produktif';
  String? _logoUrl;
  bool _isLoadingProfile = true;

  // Double-scan protection flag
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );

    _ttsService.init();
    _loadCompanyProfile();
    _initNfcListener();
  }

  Future<void> _loadCompanyProfile() async {
    final profile = await _attendanceService.fetchCompanyProfile();
    if (mounted) {
      setState(() {
        _companyName = profile['company_name'] ?? 'PT Selada Indonesia Produktif';
        _logoUrl = profile['company_logo'];
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _initNfcListener() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) return;

      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          String nfcId = '';
          try {
            // ignore: invalid_use_of_protected_member
            final dynamic pigeonTag = tag.data;
            if (pigeonTag != null && pigeonTag.id != null) {
              final List<int> idList = List<int>.from(pigeonTag.id);
              nfcId = idList
                  .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join(':');
            }
          } catch (e) {
            debugPrint('Error parse NFC tag: $e');
          }

          if (nfcId.isNotEmpty) {
            _handleNfcAttendance(nfcId);
          }
        },
      );
    } catch (e) {
      debugPrint('Error inisialisasi NFC Session: $e');
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _ttsService.stop();
    super.dispose();
  }

  /// Memproses alur absensi NFC
  Future<void> _handleNfcAttendance(String nfcSerialNumber) async {
    if (_isProcessing) return; // Mencegah double tap / scan berulang

    setState(() => _isProcessing = true);

    try {
      final result = await _attendanceService.processNfcTap(nfcSerialNumber);

      if (!mounted) return;

      if (result.status == AttendanceStatus.checkInSuccess) {
        // 1. Putar Suara Check-In
        _ttsService.speakCheckIn(result.employeeName);

        // 2. Tampilkan Layar Sukses Check-In (Akan auto pop dalam 3 detik)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              employeeName: result.employeeName,
              employeeId: result.employeeId,
              checkInTime: result.checkInTime,
              checkInDate: result.checkInDate,
              status: result.workScheme,
              profileImageUrl: result.profileImageUrl,
            ),
          ),
        );
      } else if (result.status == AttendanceStatus.checkOutSuccess) {
        // 1. Putar Suara Check-Out
        _ttsService.speakCheckOut(result.employeeName);

        // 2. Tampilkan Layar Sukses Check-Out (Akan auto pop dalam 3 detik)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutSuccessScreen(
              employeeName: result.employeeName,
              employeeId: result.employeeId,
              checkInTime: result.checkInTime,
              checkOutTime: result.checkOutTime ?? '-',
              duration: result.duration ?? '-',
              profileImageUrl: result.profileImageUrl,
            ),
          ),
        );
      } else if (result.status == AttendanceStatus.alreadyCompleted) {
        // 1. Putar Suara Absensi Sudah Selesai
        _ttsService.speakAlreadyCompleted();

        // 2. Tampilkan notifikasi info sejenak
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF60A5FA)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${result.employeeName}, Anda sudah menyelesaikan absensi hari ini.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Error proses absensi: $e');
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        if (errorMsg.contains('Kartu NFC tidak terdaftar')) {
          _ttsService.speakCardNotFound();
        } else {
          _ttsService.speak('Gagal memproses absensi.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 3));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false); // Scanner kembali siap membaca kartu berikutnya
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Header Perusahaan (Logo & Nama)
              CompanyHeader(
                companyName: _companyName,
                logoUrl: _logoUrl,
                isLoading: _isLoadingProfile,
              ),

              const Spacer(flex: 1),

              // Jam Realtime & Tanggal Indonesia
              ClockWidget(timeStream: _timeStream),

              const Spacer(flex: 1),

              // Area Pemindaian Kartu NFC dengan Animasi Pulse/Ripple
              Expanded(
                flex: 6,
                child: NfcScanArea(
                  isProcessing: _isProcessing,
                  onSimulateTap: () {
                    // Fitur simulasi kartu jika diuji di emulator / tanpa perangkat NFC fisik
                    _handleNfcAttendance('SIMULASI_ID');
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
