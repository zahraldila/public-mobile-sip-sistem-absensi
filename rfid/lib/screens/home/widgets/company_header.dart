import 'package:flutter/material.dart';

class CompanyHeader extends StatelessWidget {
  final String companyName;
  final String? logoUrl;
  final bool isLoading;
  final Color primaryColor;

  const CompanyHeader({
    super.key,
    required this.companyName,
    this.logoUrl,
    this.isLoading = false,
    this.primaryColor = const Color(0xFF0891B2),
  });

  Widget _buildDefaultLogo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'SIP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo Perusahaan dengan Frame Elegan
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : (logoUrl != null && logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultLogo(),
                      ),
                    )
                  : _buildDefaultLogo()),
        ),
        const SizedBox(width: 14),

        // Nama Perusahaan
        Expanded(
          child: isLoading
              ? Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
