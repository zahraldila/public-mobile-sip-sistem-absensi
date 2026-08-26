class DateTimeHelper {
  DateTimeHelper._();

  static const List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  /// Format: HH:mm:ss (contoh: 08:01:23)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// Format: HH:mm (contoh: 08:01)
  static String formatTimeShort(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format: Hari, DD Bulan YYYY (contoh: Rabu, 26 Agustus 2026)
  static String formatDateIndonesian(DateTime time) {
    final dayName = _days[time.weekday - 1];
    final monthName = _months[time.month - 1];
    return '$dayName, ${time.day} $monthName ${time.year}';
  }

  /// Format: YYYY-MM-DD (untuk query tabel database)
  static String formatDateIso(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  /// Menghitung selisih durasi antara Check In dan Check Out (contoh: "08 Jam 45 Menit")
  static String calculateDuration(DateTime start, DateTime end) {
    final difference = end.difference(start);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')} Jam ${minutes.toString().padLeft(2, '0')} Menit';
  }
}
