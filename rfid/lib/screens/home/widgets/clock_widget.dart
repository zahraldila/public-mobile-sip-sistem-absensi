import 'package:flutter/material.dart';
import '../../../core/utils/date_time_helper.dart';

class ClockWidget extends StatelessWidget {
  final Stream<DateTime> timeStream;

  const ClockWidget({
    super.key,
    required this.timeStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: timeStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final time = snapshot.data ?? DateTime.now();
        return Column(
          children: [
            Text(
              DateTimeHelper.formatTime(time),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTimeHelper.formatDateIndonesian(time),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E8E),
              ),
            ),
          ],
        );
      },
    );
  }
}
