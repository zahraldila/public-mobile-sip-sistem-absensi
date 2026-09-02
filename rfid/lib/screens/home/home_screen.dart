import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/services/attendance_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/utils/color_helper.dart';
import '../attendance/checkout_success_screen.dart';
import '../attendance/success_screen.dart';
import 'views/branch_selection_view.dart';
import 'widgets/clock_widget.dart';
import 'widgets/company_header.dart';
import 'widgets/location_picker_badge.dart';
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

  // Daftar Cabang / Lokasi Kantor Dinamis
  List<OfficeLocation> _locations = [];
  OfficeLocation? _selectedLocation;

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
    _loadLocations();
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

  Future<void> _loadLocations() async {
    final locs = await _attendanceService.fetchLocations();
    if (mounted && locs.isNotEmpty) {
      setState(() {
        _locations = locs;
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

  /// Memproses alur absensi NFC dengan lokasi cabang terpilih
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

    // 1. CEK STATUS GPS TERLEBIH DAHULU (Wajib Aktif)
    final bool isGpsOn = await LocationService.isLocationEnabled();
    if (!isGpsOn) {
      _ttsService.speakLocationDisabled();
      if (mounted) {
        _showLocationDisabledAlert();
      }
      return;
    }

    _cardCooldowns[nfcSerialNumber] = now;
    setState(() => _isProcessing = true);

    try {
      final result = await _attendanceService.processNfcTap(
        nfcSerialNumber,
        selectedLocation: _selectedLocation,
      );

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
      } else if (result.status == AttendanceStatus.alreadyCompleted) {
        // 1. Putar Suara: "Absensi hari ini sudah selesai, [Nama Pegawai]."
        _ttsService.speakAlreadyCompleted(result.employeeName);

        // 2. Tampilkan notifikasi visual sejenak di layar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${result.employeeName}, absensi hari ini sudah selesai.',
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
    } catch (e) {
      debugPrint('Error proses absensi: $e');
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        final bool isGpsDisabled = e is LocationDisabledException ||
            errorMsg.contains('Location belum aktif') ||
            errorMsg.toLowerCase().contains('location belum aktif');
        final bool isPermissionDenied = e is LocationPermissionDeniedException ||
            errorMsg.contains('Izin akses lokasi');

        if (isGpsDisabled) {
          _ttsService.speakLocationDisabled();
        } else if (isPermissionDenied) {
          _ttsService.speak('Izin akses lokasi belum diberikan.');
        } else if (errorMsg.contains('tidak aktif')) {
          _ttsService.speakInactiveAccount();
        } else if (errorMsg.contains('tidak terdaftar') ||
            errorMsg.contains('tidak ditemukan')) {
          _ttsService.speakCardNotFound();
        } else {
          _ttsService.speak('Gagal memproses absensi.');
        }

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isGpsDisabled ? const Color(0xFFD97706) : const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(
                  isGpsDisabled ? Icons.location_off_rounded : Icons.error_outline_rounded,
                  color: isGpsDisabled ? Colors.white : const Color(0xFFEF4444),
                ),
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
                if (isGpsDisabled) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      LocationService.openLocationSettings();
                    },
                    child: const Text(
                      'Aktifkan',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 4));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Menampilkan dialog peringatan ketika GPS / Location dalam kondisi OFF
  void _showLocationDisabledAlert() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lingkaran Ikon dengan Sentuhan Tema Dinamis
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: _primaryColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Location Belum Aktif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Location belum aktif. Silakan aktifkan Location untuk melakukan absensi.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Tombol Aksi Utama dengan Warna Brand Dinamis
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    LocationService.openLocationSettings();
                  },
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text(
                    'Aktifkan Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. TAMPILAN AWAL: Jika lokasi cabang belum dipilih, tampilkan layar pemilihan cabang
    if (_selectedLocation == null) {
      return BranchSelectionView(
        companyName: _companyName,
        logoUrl: _logoUrl,
        locations: _locations,
        primaryColor: _primaryColor,
        onLocationConfirmed: (OfficeLocation chosenLocation) {
          setState(() {
            _selectedLocation = chosenLocation;
          });
        },
      );
    }

    // 2. TAMPILAN UTAMA: Setelah cabang dipilih, tampilkan jam digital dan area scanner absensi
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
                // Header Perusahaan dengan Badge Cabang Terpilih
                CompanyHeader(
                  companyName: _companyName,
                  logoUrl: _logoUrl,
                  isLoading: _isLoadingProfile,
                  primaryColor: _primaryColor,
                  trailing: LocationPickerBadge(
                    locations: _locations,
                    selectedLocation: _selectedLocation,
                    primaryColor: _primaryColor,
                    onLocationChanged: (newLoc) {
                      setState(() => _selectedLocation = newLoc);
                    },
                  ),
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
