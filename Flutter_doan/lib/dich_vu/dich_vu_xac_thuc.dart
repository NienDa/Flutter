import 'package:supabase_flutter/supabase_flutter.dart';

/// Dịch vụ xác thực cho đăng nhập, đăng ký, quên mật khẩu và đăng xuất.
class DichVuXacThuc {
  final SupabaseClient _client = Supabase.instance.client;

  /// Trả về phiên đăng nhập hiện tại.
  Session? get phienHienTai => _client.auth.currentSession;

  /// Trả về luồng thay đổi trạng thái đăng nhập.
  Stream<AuthState> get thayDoiXacThuc => _client.auth.onAuthStateChange;

  /// Đăng nhập bằng email và mật khẩu.
  Future<void> dangNhap({
    required String email,
    required String matKhau,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: matKhau.trim(),
    );
  }

  /// Đăng ký tài khoản mới.
  ///
  /// Metadata `full_name` và `role` sẽ được trigger trong Supabase
  /// sử dụng để tự tạo hồ sơ ở bảng `ho_so`.
  Future<void> dangKy({
    required String email,
    required String matKhau,
    required String hoTen,
    required String vaiTro,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: matKhau.trim(),
      data: {
        'ho_ten': hoTen.trim(),
        'vai_tro': vaiTro,
        'full_name': hoTen.trim(),
        'role': vaiTro,
      },
    );
  }

  /// Gửi email khôi phục mật khẩu theo cơ chế link Reset Password của Supabase.
  ///
  /// Cơ chế này phù hợp với mẫu email dùng `{{ .ConfirmationURL }}`.
  /// Sau khi người dùng bấm link trong email, Supabase tạo phiên recovery
  /// và ứng dụng cho phép nhập mật khẩu mới.
  Future<void> guiEmailDatLaiMatKhau({
    required String email,
    String? redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// Gửi email khôi phục mật khẩu theo cơ chế OTP 6 số.
  ///
  /// Chỉ dùng khi mẫu email Reset Password trong Supabase hiển thị `{{ .Token }}`.
  Future<void> guiMaOtpDatLaiMatKhau({required String email}) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Xác minh mã OTP khôi phục mật khẩu và đặt mật khẩu mới.
  Future<void> xacNhanOtpVaDatLaiMatKhau({
    required String email,
    required String otp,
    required String matKhauMoi,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: otp.trim(),
    );

    await _client.auth.updateUser(
      UserAttributes(password: matKhauMoi.trim()),
    );

    // Sau khi đổi mật khẩu xong thì đăng xuất để người dùng đăng nhập lại
    // bằng mật khẩu mới. Cách này tránh việc tự nhảy thẳng vào app khi test.
    await _client.auth.signOut();
  }

  /// Đặt lại mật khẩu sau khi người dùng đã bấm link Reset Password trong email.
  Future<void> datLaiMatKhauBangLienKet({required String matKhauMoi}) async {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'Phiên đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng gửi lại email khôi phục mật khẩu.',
      );
    }

    await _client.auth.updateUser(UserAttributes(password: matKhauMoi.trim()));

    // Đăng xuất sau khi đổi mật khẩu để người dùng đăng nhập lại bằng mật khẩu mới.
    await _client.auth.signOut();
  }

  /// Đổi mật khẩu cho người dùng đang đăng nhập.
  Future<void> doiMatKhau({required String matKhauMoi}) async {
    await _client.auth.updateUser(
      UserAttributes(password: matKhauMoi.trim()),
    );
  }

  /// Đăng xuất khỏi hệ thống.
  Future<void> dangXuat() async {
    await _client.auth.signOut();
  }
}
