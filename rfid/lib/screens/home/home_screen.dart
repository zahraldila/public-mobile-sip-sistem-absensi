import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/services/attendance_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/utils/color_helper.dart';
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
  Color _primaryColor = const Color(0xFF0891B2); // Default fallback warna SIP (#0891B2)
  bool _isLoadingProfile = true;

  // Double-scan protection flag
  bool _isProcessing = false;

  // Cooldown 5 detik per nomor seri kartu
  final Map<String, DateTime> _cardCooldowns = {};

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
        _primaryColor = ColorHelper.parseHexColor(
          profile['primary_color'],
          defaultColor: const Color(0xFF0891B2),
        );
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
    final now = DateTime.now();

    // Cooldown 5 detik khusus nomor seri kartu ini
    if (_cardCooldowns.containsKey(nfcSerialNumber)) {
      final lastTap = _cardCooldowns[nfcSerialNumber]!;
      if (now.difference(lastTap).inMilliseconds < 5000) {
        debugPrint('Kartu $nfcSerialNumber masih dalam masa cooldown');
        return;
      }
    }

    if (_isProcessing) return;

    _cardCooldowns[nfcSerialNumber] = now;
    setState(() => _isProcessing = true);

    try {
      final result = await _attendanceService.processNfcTap(nfcSerialNumber);

      if (!mounted) return;

      if (result.status == AttendanceStatus.checkInSuccess) {
        // 1. Putar Suara Check-In
        _ttsService.speakCheckIn(result.employeeName);

        // 2. Tampilkan Layar Sukses Check-In (Auto pop dalam 3 detik)
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

        // 2. Tampilkan Layar Sukses Check-Out (Auto pop dalam 3 detik)
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
      }
    } catch (e) {
      debugPrint('Error proses absensi: $e');
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        if (errorMsg.contains('tidak terdaftar') ||
            errorMsg.contains('tidak aktif') ||
            errorMsg.contains('tidak ditemukan')) {
          _ttsService.speakCardNotFound();
        } else {
          _ttsService.speak('Gagal memproses absensi.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Latar Belakang Classic Executive: Warm Ivory Gradient Halus
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFE),
              Color(0xFFF1F4F9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18.0),
            child: Column(
              children: [
                // Header Perusahaan dengan Warna Dinamis
                CompanyHeader(
                  companyName: _companyName,
                  logoUrl: _logoUrl,
                  isLoading: _isLoadingProfile,
                  primaryColor: _primaryColor,
                ),

                const Spacer(flex: 1),

                // Digital Clock Hub dengan Aksen Warna Dinamis
                ClockWidget(
                  timeStream: _timeStream,
                  primaryColor: _primaryColor,
                ),

                const Spacer(flex: 1),

                // Area Pemindai Kartu NFC (Medallion & Ripple Dinamis sesuai primary_color)
                Expanded(
                  flex: 8,
                  child: NfcScanArea(
                    isProcessing: _isProcessing,
                    primaryColor: _primaryColor,
                    onSimulateTap: () {
                      _handleNfcAttendance('SIMULASI_ID');
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
