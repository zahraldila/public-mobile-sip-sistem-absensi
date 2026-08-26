import 'package:flutter/material.dart';
import 'dart:async';

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
        // Go back to previous screen automatically
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
      backgroundColor: const Color(0xFFF4F6F9), // Latar belakang abu-abu kebiruan terang
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Ikon Check Out (Keluar)
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF1949B8), // Warna biru tua
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            // Judul
            const Text(
              'CHECK OUT BERHASIL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1949B8), // Warna biru tua
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Subjudul
            Text(
              'Terima kasih, ${widget.employeeName.split(' ').first}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 32),
            // Kartu Identitas dan Detail
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Foto Profil
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.profileImageUrl != null
                        ? NetworkImage(widget.profileImageUrl!)
                        : null,
                    child: widget.profileImageUrl == null
                        ? const Icon(Icons.person, size: 35, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Nama
                  Text(
                    widget.employeeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ID Pegawai
                  Text(
                    'ID: ${widget.employeeId}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tombol Attendance Completed
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D51D3), // Biru tombol
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Attendance Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Garis Pemisah (opsional, tapi di desain tidak ada garis tegas, kita skip saja atau pakai container terpisah)
                  
                  // Row Detail 1: Check In
                  _buildDetailRow(
                    icon: Icons.login_rounded,
                    label: 'CHECK IN',
                    value: widget.checkInTime,
                    valueColor: Colors.black87,
                  ),
                  const SizedBox(height: 12),
                  
                  // Row Detail 2: Check Out
                  _buildDetailRow(
                    icon: Icons.logout_rounded,
                    label: 'CHECK OUT',
                    value: widget.checkOutTime,
                    valueColor: const Color(0xFF1D51D3), // Biru
                  ),
                  const SizedBox(height: 12),
                  
                  // Row Detail 3: Duration
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
            // Auto Reset / Redirecting Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EAF5), // Latar belakang biru-abu
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Redirecting...',
                    style: const TextStyle(
                      fontSize: 14,
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
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE), // Biru sangat muda
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
