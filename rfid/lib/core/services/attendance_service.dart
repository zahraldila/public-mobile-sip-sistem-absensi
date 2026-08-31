import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/date_time_helper.dart';

enum AttendanceStatus {
  checkInSuccess,
  checkOutSuccess,
  alreadyCompleted,
  error,
}

class OfficeLocation {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final int? radiusMeter;

  OfficeLocation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radiusMeter,
  });

  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      id: int.parse(json['lokasi_id'].toString()),
      name: json['nama_kantor']?.toString() ?? 'Cabang',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      radiusMeter: int.tryParse(json['radius_meter']?.toString() ?? ''),
    );
  }
}

class AttendanceResult {
  final AttendanceStatus status;
  final String employeeName;
  final String employeeId;
  final String? profileImageUrl;
  final String checkInTime;
  final String? checkOutTime;
  final String checkInDate;
  final String? duration;
  final String workScheme;

  AttendanceResult({
    required this.status,
    required this.employeeName,
    required this.employeeId,
    this.profileImageUrl,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInDate,
    this.duration,
    this.workScheme = 'WFO',
  });
}

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil profil perusahaan (nama, logo, primary_color) dari tabel `settings`
  Future<Map<String, String?>> fetchCompanyProfile() async {
    try {
      final List<dynamic> data = await _supabase
          .from('settings')
          .select('key, value');

      String? name = 'PT Selada Indonesia Produktif';
      String? logoUrl;
      String? primaryColorHex = '#0891B2';

      if (data.isNotEmpty) {
        for (var row in data) {
          if (row['key'] == 'company_name' && row['value'] != null) {
            name = row['value'].toString();
          } else if (row['key'] == 'company_logo' && row['value'] != null) {
            final logoPath = row['value'].toString();
            if (logoPath.isNotEmpty) {
              logoUrl = '${SupabaseConfig.url}/storage/v1/object/public/$logoPath';
            }
          } else if (row['key'] == 'primary_color' && row['value'] != null) {
            primaryColorHex = row['value'].toString();
          }
        }
      }

      return {
        'company_name': name,
        'company_logo': logoUrl,
        'primary_color': primaryColorHex,
      };
    } catch (e) {
      debugPrint('Error fetchCompanyProfile: $e');
      return {
        'company_name': 'PT Selada Indonesia Produktif',
        'company_logo': null,
        'primary_color': '#0891B2',
      };
    }
  }

  /// Mengambil daftar seluruh cabang / lokasi kantor aktif dari tabel `lokasi_kantor`
  Future<List<OfficeLocation>> fetchLocations() async {
    try {
      final List<dynamic> data = await _supabase
          .from('lokasi_kantor')
          .select('lokasi_id, nama_kantor, latitude, longitude, radius_meter')
          .order('lokasi_id', ascending: true);

      if (data.isNotEmpty) {
        return data.map((e) => OfficeLocation.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchLocations: $e');
    }

    // Fallback default cabang kantor
    return [
      OfficeLocation(
        id: 1,
        name: 'Kantor Sulaksana',
        latitude: -6.910194028769816,
        longitude: 107.65072801284482,
        radiusMeter: 100,
      ),
      OfficeLocation(
        id: 2,
        name: 'Kantor Cikawao',
        latitude: -6.927558090870104,
        longitude: 107.61457005582317,
        radiusMeter: 100,
      ),
    ];
  }

  /// Memproses presensi kartu NFC
  Future<AttendanceResult> processNfcTap(
    String nfcSerialNumber, {
    OfficeLocation? selectedLocation,
  }) async {
    // 1. Identifikasi kartu di tabel `nfc`
    final nfcData = await _supabase
        .from('nfc')
        .select('pegawai_id')
        .eq('nfc_serial_number', nfcSerialNumber)
        .maybeSingle();

    if (nfcData == null || nfcData['pegawai_id'] == null) {
      throw Exception('Kartu NFC tidak terdaftar');
    }

    final int pegawaiId = int.parse(nfcData['pegawai_id'].toString());

    // 2. Ambil data profil pegawai dari tabel `pegawai`
    final pegawaiData = await _supabase
        .from('pegawai')
        .select('pegawai_id, nama_pegawai, nip, status, foto_profile')
        .eq('pegawai_id', pegawaiId)
        .maybeSingle();

    if (pegawaiData == null) {
      throw Exception('Data pegawai tidak ditemukan');
    }

    // Validasi apakah akun pegawai berstatus Aktif
    final String? employeeStatus = pegawaiData['status']?.toString().trim();
    if (employeeStatus == null || employeeStatus.toLowerCase() != 'aktif') {
      throw Exception('Akun pegawai tidak aktif. Presensi ditolak.');
    }

    final String employeeName = pegawaiData['nama_pegawai']?.toString() ?? 'Pegawai';
    final String employeeNip = pegawaiData['nip']?.toString() ?? 'N/A';
    final String? rawFoto = pegawaiData['foto_profile']?.toString();
    final String? profileImageUrl = (rawFoto != null && rawFoto.isNotEmpty)
        ? '${SupabaseConfig.url}/storage/v1/object/public/$rawFoto'
        : null;

    final now = DateTime.now();
    final String todayDateIso = DateTimeHelper.formatDateIso(now);
    final String todayFormatted = DateTimeHelper.formatDateIndonesian(now);
    final String currentTimeFormatted = DateTimeHelper.formatTime(now);

    // 3. Cek sesi absensi pada HARI INI (ambil sesi terbaru)
    final existingAttendance = await _supabase
        .from('absensi')
        .select()
        .eq('pegawai_id', pegawaiId)
        .eq('tanggal_absensi', todayDateIso)
        .order('jam_checkin', ascending: false)
        .limit(1)
        .maybeSingle();

    // 4. Tentukan Alur Transaksi (Check In / Check Out / Selesai)
    if (existingAttendance == null) {
      // KONDISI 1: Belum ada absensi hari ini -> Lakukan CHECK IN (INSERT)
      int? jadwalId;
      try {
        final jadwal = await _supabase
            .from('jadwal_kerja')
            .select('jadwal_id')
            .order('tanggal_berlaku', ascending: false)
            .limit(1)
            .maybeSingle();
        if (jadwal != null && jadwal['jadwal_id'] != null) {
          jadwalId = int.tryParse(jadwal['jadwal_id'].toString());
        }
      } catch (_) {}

      final insertPayload = {
        'pegawai_id': pegawaiId,
        'tanggal_absensi': todayDateIso,
        'jam_checkin': now.toIso8601String(),
        'skema_kerja': 'WFO',
        'status_kehadiran': 'Hadir',
        if (jadwalId != null) 'jadwal_id': jadwalId,
        if (selectedLocation?.latitude != null) 'latitude': selectedLocation!.latitude,
        if (selectedLocation?.longitude != null) 'longitude': selectedLocation!.longitude,
      };

      await _supabase.from('absensi').insert(insertPayload);

      return AttendanceResult(
        status: AttendanceStatus.checkInSuccess,
        employeeName: employeeName,
        employeeId: employeeNip,
        profileImageUrl: profileImageUrl,
        checkInTime: currentTimeFormatted,
        checkInDate: todayFormatted,
        workScheme: 'WFO',
      );
    } else if (existingAttendance['jam_checkout'] == null) {
      // KONDISI 2: Sudah Check In, belum Check Out -> Lakukan CHECK OUT (UPDATE)
      final DateTime checkInDateTime = DateTime.tryParse(
            existingAttendance['jam_checkin']?.toString() ?? '',
          ) ??
          now;

      final durationText = DateTimeHelper.calculateDuration(checkInDateTime, now);

      await _supabase
          .from('absensi')
          .update({
            'jam_checkout': now.toIso8601String(),
            if (selectedLocation?.latitude != null) 'latitude': selectedLocation!.latitude,
            if (selectedLocation?.longitude != null) 'longitude': selectedLocation!.longitude,
          })
          .eq('absensi_id', existingAttendance['absensi_id']);

      return AttendanceResult(
        status: AttendanceStatus.checkOutSuccess,
        employeeName: employeeName,
        employeeId: employeeNip,
        profileImageUrl: profileImageUrl,
        checkInTime: DateTimeHelper.formatTime(checkInDateTime),
        checkOutTime: currentTimeFormatted,
        checkInDate: todayFormatted,
        duration: durationText,
        workScheme: existingAttendance['skema_kerja']?.toString() ?? 'WFO',
      );
    } else {
      // KONDISI 3: Sudah Check In dan Sudah Check Out hari ini
      return AttendanceResult(
        status: AttendanceStatus.alreadyCompleted,
        employeeName: employeeName,
        employeeId: employeeNip,
        profileImageUrl: profileImageUrl,
        checkInTime: DateTimeHelper.formatTime(
          DateTime.tryParse(existingAttendance['jam_checkin']?.toString() ?? '') ?? now,
        ),
        checkOutTime: DateTimeHelper.formatTime(
          DateTime.tryParse(existingAttendance['jam_checkout']?.toString() ?? '') ?? now,
        ),
        checkInDate: todayFormatted,
      );
    }
  }
}
