import 'dart:async';
import 'package:flutter/material.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  final String employeeName;
  final String employeeId;
  final String checkInTime;
  final String checkOutTime;
  final String duration;
  final String? profileImageUrl;

  const CheckoutSuccessScreen({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.checkInTime,
    required this.checkOutTime,
    required this.duration,
    this.profileImageUrl,
  });

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
        // Otomatis kembali ke layar utama kiosk
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ikon Check Out (Biru)
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFF1949B8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              // Judul
              const Text(
                'CHECK OUT BERHASIL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1949B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subjudul
              Text(
                'Terima kasih, ${widget.employeeName.split(' ').first}!',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 24),
              // Kartu Identitas dan Detail Durasi
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Foto Profil Pegawai
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: widget.profileImageUrl != null
                          ? NetworkImage(widget.profileImageUrl!)
                          : null,
                      child: widget.profileImageUrl == null
                          ? const Icon(Icons.person, size: 36, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    // Nama Pegawai
                    Text(
                      widget.employeeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // NIP Pegawai
                    Text(
                      'ID: ${widget.employeeId}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Badge Selesai
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D51D3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Attendance Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Detail: Check In
                    _buildDetailRow(
                      icon: Icons.login_rounded,
                      label: 'CHECK IN',
                      value: widget.checkInTime,
                      valueColor: Colors.black87,
                    ),
                    const SizedBox(height: 10),
                    // Detail: Check Out
                    _buildDetailRow(
                      icon: Icons.logout_rounded,
                      label: 'CHECK OUT',
                      value: widget.checkOutTime,
                      valueColor: const Color(0xFF1D51D3),
                    ),
                    const SizedBox(height: 10),
                    // Detail: Durasi
                    _buildDetailRow(
                      icon: Icons.timer_outlined,
                      label: 'DURATION',
                      value: widget.duration,
                      valueColor: Colors.black87,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Indikator Auto Redirect (Tanpa Tombol Manual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EAF5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Kembali ke scan dalam $_countdown detik...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
