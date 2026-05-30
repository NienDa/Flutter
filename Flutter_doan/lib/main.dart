import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cau_hinh/supabase_cau_hinh.dart';
import 'giao_dien/man_hinh_cho.dart';
import 'giao_dien/man_hinh_chinh.dart';
import 'giao_dien/man_hinh_dang_nhap.dart';

Future testSupabase() async {
  try {
    final client = Supabase.instance.client;
    client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        debugPrint('==================== DEBUG SUPABASE ====================');
        debugPrint('Chưa đăng nhập Supabase Auth hoặc đã đăng xuất');
        debugPrint('========================================================');
        return;
      }

      debugPrint('==================== DEBUG SUPABASE ON LOGIN ====================');
      debugPrint('Đang đăng nhập với UID: ${user.id}');
      debugPrint('Email: ${user.email}');
      
      try {
        final hoSo = await client.from('ho_so').select().eq('id', user.id).maybeSingle();
        debugPrint('Dữ liệu hồ sơ người dùng: $hoSo');

        final ghiDanh = await client.from('ghi_danh').select('*, lop:lop_do_an_id(id, ma_lop, ten_lop)');
        debugPrint('Tất cả ghi danh lấy được: $ghiDanh');

        final ghiDanhCuaToi = await client.from('ghi_danh').select('*, lop:lop_do_an_id(id, ma_lop, ten_lop)').eq('sinh_vien_id', user.id);
        debugPrint('Ghi danh của sinh viên này: $ghiDanhCuaToi');
      } catch (err) {
        debugPrint('Lỗi khi truy vấn: $err');
      }
      debugPrint('=================================================================');
    });
  } catch (e) {
    debugPrint('==================== LỖI DEBUG SUPABASE ====================');
    debugPrint(e.toString());
  }
}

/// Hàm khởi động ứng dụng.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseCauHinh.url,
    anonKey: SupabaseCauHinh.anonKey,
  );

  testSupabase();

  runApp(const UngDungDangKyNhom());
}


/// Widget gốc của ứng dụng đồ án.
class UngDungDangKyNhom extends StatelessWidget {
  const UngDungDangKyNhom({super.key});

  @override
  Widget build(BuildContext context) {
    final mau = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      primary: const Color(0xFF1D4ED8),
      secondary: const Color(0xFF0F766E),
      tertiary: const Color(0xFFF59E0B),
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.beVietnamProTextTheme();

    return MaterialApp(
      title: 'Đăng ký nhóm và chọn đề tài',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: mau,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F7FB),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: mau.surface,
          foregroundColor: mau.onSurface,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: mau.onSurface,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: mau.primary),
          selectedLabelTextStyle: TextStyle(
            color: mau.primary,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelTextStyle: TextStyle(color: mau.onSurfaceVariant),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: mau.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: mau.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: mau.primary, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      home: const CongXacThuc(),
    );
  }
}

/// Cổng xác thực để chuyển giữa màn hình đăng nhập, đặt lại mật khẩu và giao diện chính.
class CongXacThuc extends StatelessWidget {
  const CongXacThuc({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            client.auth.currentSession == null) {
          return const ManHinhCho(thongDiep: 'Đang kiểm tra phiên đăng nhập...');
        }

        final session = snapshot.data?.session ?? client.auth.currentSession;
        if (session == null) {
          return const ManHinhDangNhap();
        }

        return const ManHinhChinh();
      },
    );
  }
}

