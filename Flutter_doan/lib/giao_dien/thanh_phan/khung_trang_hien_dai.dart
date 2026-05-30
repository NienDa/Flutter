import 'package:flutter/material.dart';

/// Khung trang dùng chung để tạo giao diện đồng nhất cho toàn app.
class KhungTrangHienDai extends StatelessWidget {
  const KhungTrangHienDai({
    super.key,
    required this.tieuDe,
    required this.noiDung,
    this.moTa,
    this.hanhDong,
  });

  final String tieuDe;
  final String? moTa;
  final Widget noiDung;
  final List<Widget>? hanhDong;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [mau.primary, mau.secondary],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: mau.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Wrap(
              runSpacing: 18,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tieuDe,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                      ),
                      if (moTa != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          moTa!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.90),
                                height: 1.45,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hanhDong != null)
                  Wrap(spacing: 12, runSpacing: 12, children: hanhDong!),
              ],
            ),
          ),
          const SizedBox(height: 22),
          noiDung,
        ],
      ),
    );
  }
}
