import 'package:flutter/material.dart';
import '../../../core/services/attendance_service.dart';

class LocationPickerBadge extends StatelessWidget {
  final List<OfficeLocation> locations;
  final OfficeLocation? selectedLocation;
  final ValueChanged<OfficeLocation> onLocationChanged;
  final Color primaryColor;

  const LocationPickerBadge({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.primaryColor = const Color(0xFF0891B2),
  });

  /// Menampilkan Pop-up Dialog Pemilihan Cabang (Bisa untuk awal buka app & ganti cabang)
  static Future<void> showLocationDialog({
    required BuildContext context,
    required List<OfficeLocation> locations,
    required OfficeLocation? initialSelected,
    required ValueChanged<OfficeLocation> onConfirmed,
    required Color primaryColor,
    bool isDismissible = true,
  }) async {
    OfficeLocation? tempSelected = initialSelected ?? (locations.isNotEmpty ? locations.first : null);

    await showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon & Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.domain_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Lokasi Cabang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tentukan cabang aktif perangkat ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    const SizedBox(height: 12),

                    // Daftar Pilihan Cabang dari Supabase
                    if (locations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: locations.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final loc = locations[index];
                            final isSelected = tempSelected?.id == loc.id;

                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempSelected = loc;
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.08)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor
                                            : const Color(0xFFE2E8F0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                          if (loc.latitude != null && loc.longitude != null)
                                            Text(
                                              'GPS: ${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 22,
                                        color: primaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Tombol Konfirmasi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: tempSelected == null
                            ? null
                            : () {
                                onConfirmed(tempSelected!);
                                Navigator.pop(dialogContext);
                              },
                        child: const Text(
                          'Pilih Cabang Ini',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationName = selectedLocation?.name ?? 'Pilih Cabang...';

    return InkWell(
      onTap: locations.isEmpty
          ? null
          : () => showLocationDialog(
                context: context,
                locations: locations,
                initialSelected: selectedLocation,
                onConfirmed: onLocationChanged,
                primaryColor: primaryColor,
                isDismissible: true,
              ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 15,
              color: primaryColor,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                locationName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
