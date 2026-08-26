import 'package:flutter/material.dart';
import '../../../core/utils/date_time_helper.dart';

class ClockWidget extends StatelessWidget {
  final Stream<DateTime> timeStream;
  final Color primaryColor;

  const ClockWidget({
    super.key,
    required this.timeStream,
    this.primaryColor = const Color(0xFF0891B2),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: timeStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final time = snapshot.data ?? DateTime.now();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Jam Digital Realtime (Classic Executive Typography)
            Text(
              DateTimeHelper.formatTime(time),
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -1.8,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),

            // Kapsul Tanggal Bahasa Indonesia dengan Aksen Warna Dinamis
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: primaryColor, // Mengikuti primary_color database
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateTimeHelper.formatDateIndonesian(time),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
