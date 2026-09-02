import 'package:flutter/material.dart';
import '../../../core/utils/color_helper.dart';

class NfcScanArea extends StatefulWidget {
  final bool isProcessing;
  final bool isOnline;
  final VoidCallback? onSimulateTap;
  final Color primaryColor;

  const NfcScanArea({
    super.key,
    required this.isProcessing,
    this.isOnline = true,
    this.onSimulateTap,
    this.primaryColor = const Color(0xFF0891B2),
  });

  @override
  State<NfcScanArea> createState() => _NfcScanAreaState();
}

class _NfcScanAreaState extends State<NfcScanArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;
    final darkerPrimaryColor = ColorHelper.getDarkerColor(primaryColor, 0.75);

    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onSimulateTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Target Sensor Medallion RFID (Dinamis Sesuai primary_color)
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gelombang Ripple Halus (Dinamis)
                  if (!widget.isProcessing)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor
                                  .withOpacity(_fadeAnimation.value * 0.35),
                            ),
                          ),
                        );
                      },
                    ),

                  // Cincin Luar (Acrylic Ring)
                  Container(
                    width: 146,
                    height: 146,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Cincin Tengah Halus (Soft Halo Dinamis)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Inti Medallion (Gradient Dinamis dari primary_color)
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkerPrimaryColor, primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: widget.isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(26.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.contactless,
                            color: Colors.white,
                            size: 48,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Judul Panduan Tegas & Berkelas
            const Text(
              'TEMPELKAN KARTU NFC',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle Deskriptif
            const Text(
              'Dekatkan ID Card / RFID ke area sensor',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),

            // Badge Status Siap Scan (Emerald saat online, Merah saat offline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: widget.isProcessing
                    ? const Color(0xFFF1F5F9)
                    : (!widget.isOnline
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5)),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.isProcessing
                      ? const Color(0xFFCBD5E1)
                      : (!widget.isOnline
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFA7F3D0)),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: widget.isProcessing
                          ? Colors.grey.shade500
                          : (!widget.isOnline
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isProcessing
                        ? 'MEMPROSES...'
                        : (!widget.isOnline ? 'KONEKSI TERPUTUS' : 'READY TO SCAN'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: widget.isProcessing
                          ? Colors.grey.shade700
                          : (!widget.isOnline
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF065F46)),
                      letterSpacing: 0.8,
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
}
