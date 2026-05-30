import 'package:flutter/material.dart';

/// Màn hình chờ dùng trong lúc tải phiên đăng nhập hoặc dữ liệu quan trọng.
class ManHinhCho extends StatelessWidget {
  const ManHinhCho({super.key, this.thongDiep = 'Đang tải dữ liệu...'});

  final String thongDiep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 64,
                width: 64,
                child: CircularProgressIndicator(strokeWidth: 5),
              ),
              const SizedBox(height: 20),
              Text(
                thongDiep,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}