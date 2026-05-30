import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tiện ích hiển thị thông báo nhanh trên ứng dụng.
///
/// Nguyên tắc xử lý lỗi:
/// - Lỗi nhập liệu/chức năng phải hiện rõ trên giao diện để người dùng biết cần sửa gì.
/// - Lỗi kỹ thuật gốc vẫn được ghi vào console/debug log khi chạy debug.
class ThongBao {
  static const String _loiMacDinh =
      'Đã xảy ra lỗi trong quá trình xử lý. Vui lòng kiểm tra lại hoặc thử lại sau.';

  static void _ghiLogLoi(Object loi, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    debugPrint('================= LOI KY THUAT =================');
    debugPrint(loi.toString());

    if (stackTrace != null) {
      debugPrint('----------------- STACK TRACE ------------------');
      debugPrint(stackTrace.toString());
    }

    debugPrint('================================================');

    developer.log(
      'Lỗi kỹ thuật trong ứng dụng',
      name: 'ThongBao.loi',
      error: loi,
      stackTrace: stackTrace,
    );
  }

  static String _boTienToException(String noiDung) {
    return noiDung
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^AuthException:\s*'), '')
        .replaceFirst(RegExp(r'^PostgrestException:\s*'), '')
        .trim();
  }

  static String _thongBaoTuChuoiNguoiDung(String noiDung) {
    final daLamSach = _boTienToException(noiDung);
    if (daLamSach.isEmpty) return _loiMacDinh;
    return daLamSach;
  }

  static String? _layThongBaoTuPostgrestException(String noiDungGoc) {
    final laLoiPostgrestNguoiDung =
        noiDungGoc.contains('PostgrestException') &&
        noiDungGoc.contains('P0001');

    if (!laLoiPostgrestNguoiDung) return null;

    final match = RegExp(
      r'message:\s*([\s\S]*?),\s*code:\s*P0001',
      caseSensitive: false,
    ).firstMatch(noiDungGoc);

    final thongBao = match?.group(1)?.trim();

    if (thongBao == null ||
        thongBao.isEmpty ||
        thongBao.toLowerCase() == 'null') {
      return null;
    }

    return _thongBaoTuChuoiNguoiDung(thongBao);
  }

  static String _chuyenLoiSangTiengViet(Object loi) {
    final noiDungGoc = loi.toString();

    final thongBaoTuDatabase = _layThongBaoTuPostgrestException(noiDungGoc);
    if (thongBaoTuDatabase != null) {
      return thongBaoTuDatabase;
    }

    if (loi is String) {
      return _thongBaoTuChuoiNguoiDung(loi);
    }

    final noiDung = noiDungGoc.toLowerCase();

    if (noiDung.contains('over_email_send_rate_limit') ||
        noiDung.contains('email rate limit exceeded') ||
        noiDung.contains('rate limit') ||
        noiDung.contains('for security purposes')) {
      return 'Bạn đã yêu cầu gửi email quá nhiều lần. Vui lòng đợi khoảng 60 giây rồi thử lại.';
    }

    if (noiDung.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
    }

    if (noiDung.contains('email not confirmed')) {
      return 'Tài khoản chưa xác minh email. Vui lòng kiểm tra Gmail trước khi đăng nhập.';
    }

    if (noiDung.contains('user already registered') ||
        noiDung.contains('already registered')) {
      return 'Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.';
    }

    if (noiDung.contains('unable to validate email address') ||
        noiDung.contains('email address is invalid')) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại địa chỉ email.';
    }

    if (noiDung.contains('password should be at least') ||
        noiDung.contains('weak_password') ||
        noiDung.contains('weak password')) {
      return 'Mật khẩu chưa đủ mạnh. Vui lòng nhập mật khẩu có ít nhất 6 ký tự, gồm chữ và số.';
    }

    if (noiDung.contains('new password should be different') ||
        noiDung.contains('same_password')) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }

    if (noiDung.contains('otp') && noiDung.contains('expired')) {
      return 'Mã OTP đã hết hạn. Vui lòng gửi mã mới.';
    }

    if (noiDung.contains('invalid') && noiDung.contains('otp')) {
      return 'Mã OTP không đúng. Vui lòng kiểm tra lại.';
    }

    if (noiDung.contains('invalid refresh token') ||
        noiDung.contains('session_not_found') ||
        (noiDung.contains('session') && noiDung.contains('not found'))) {
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (noiDung.contains('duplicate key') ||
        noiDung.contains('unique constraint')) {
      return 'Dữ liệu này đã tồn tại trong hệ thống. Vui lòng kiểm tra lại mã hoặc thông tin đã nhập.';
    }

    if (noiDung.contains('foreign key') ||
        noiDung.contains('violates foreign key constraint')) {
      return 'Không thể thực hiện thao tác vì dữ liệu này đang liên kết với dữ liệu khác trong hệ thống.';
    }

    if (noiDung.contains('check constraint')) {
      return 'Dữ liệu nhập chưa đúng điều kiện ràng buộc. Vui lòng kiểm tra lại.';
    }

    if (noiDung.contains('permission denied') ||
        noiDung.contains('row-level security') ||
        noiDung.contains('rls')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }

    if (noiDung.contains('network') ||
        noiDung.contains('socket') ||
        noiDung.contains('connection') ||
        noiDung.contains('failed host lookup')) {
      return 'Không thể kết nối đến hệ thống. Vui lòng kiểm tra mạng và thử lại.';
    }

    if (noiDung.startsWith('exception:')) {
      return _thongBaoTuChuoiNguoiDung(noiDungGoc);
    }

    return _loiMacDinh;
  }

  static void _hienSnackBar(
    BuildContext context, {
    required String noiDung,
    required Color mauNen,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: mauNen,
          duration: Duration(seconds: noiDung.length > 90 ? 7 : 5),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  noiDung,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void thanhCong(BuildContext context, String noiDung) {
    _hienSnackBar(
      context,
      noiDung: noiDung,
      mauNen: Colors.green.shade700,
      icon: Icons.check_circle_outline,
    );
  }

  static void canhBao(BuildContext context, String noiDung) {
    _hienSnackBar(
      context,
      noiDung: noiDung,
      mauNen: Colors.orange.shade800,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Hiển thị lỗi thân thiện trên giao diện.
  ///
  /// Nếu `loi` là chuỗi tự kiểm tra từ UI, nội dung được hiển thị nguyên văn
  /// và không ghi ra terminal như lỗi kỹ thuật.
  static void loi(BuildContext context, Object loi, [StackTrace? stackTrace]) {
    if (loi is! String) {
      _ghiLogLoi(loi, stackTrace);
    }

    _hienSnackBar(
      context,
      noiDung: _chuyenLoiSangTiengViet(loi),
      mauNen: Colors.red.shade700,
      icon: Icons.error_outline,
    );
  }

  static Future<bool> xacNhan(
    BuildContext context, {
    required String tieuDe,
    required String noiDung,
    String nhanDongY = 'Đồng ý',
    String nhanHuy = 'Huỷ',
    bool nguyHiem = false,
  }) async {
    final ketQua = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tieuDe),
          content: Text(noiDung),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(nhanHuy),
            ),
            FilledButton(
              style: nguyHiem
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(nhanDongY),
            ),
          ],
        );
      },
    );

    return ketQua ?? false;
  }
}
