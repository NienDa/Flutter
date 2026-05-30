import 'package:flutter/material.dart';

/// Thẻ số liệu dùng ở trang tổng quan.
class OTheSoLieu extends StatelessWidget {
  const OTheSoLieu({
    super.key,
    required this.tieuDe,
    required this.giaTri,
    required this.bieuTuong,
    this.moTa,
  });

  final String tieuDe;
  final String giaTri;
  final IconData bieuTuong;
  final String? moTa;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mau.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: mau.primaryContainer,
            child: Icon(bieuTuong, color: mau.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tieuDe, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  giaTri,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (moTa != null) ...[
                  const SizedBox(height: 4),
                  Text(moTa!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
