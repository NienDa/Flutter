import 'package:supabase_flutter/supabase_flutter.dart';

import '../mo_hinh/ho_so_nguoi_dung.dart';
import 'dich_vu_nhat_ky.dart';

/// Dịch vụ xử lý hồ sơ người dùng.
class DichVuHoSo {
  final SupabaseClient _client = Supabase.instance.client;
  final DichVuNhatKy _dichVuNhatKy = DichVuNhatKy();

  /// Lấy hồ sơ của người dùng đang đăng nhập.
  ///
  /// Nếu vai trò trong bảng `ho_so` không khớp với metadata đăng ký,
  /// hàm sẽ tự động cập nhật lại để sửa tài khoản cũ bị lỗi.
  Future<HoSoNguoiDung?> layHoSoHienTai() async {
    final nguoiDung = _client.auth.currentUser;
    if (nguoiDung == null) return null;

    final duLieu = await _client
        .from('ho_so')
        .select()
        .eq('id', nguoiDung.id)
        .maybeSingle()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Không thể kết nối đến máy chủ Supabase (Hết thời gian chờ). Vui lòng kiểm tra lại kết nối mạng của trình giả lập.',
          ),
        );

    if (duLieu == null) return null;

    final hoSo = HoSoNguoiDung.tuMap(Map<String, dynamic>.from(duLieu));

    // Sửa lỗi tài khoản cũ: nếu vai_tro trong DB bị lưu sai so với
    // metadata đã chọn lúc đăng ký, tự động cập nhật lại DB.
    final meta = nguoiDung.userMetadata ?? {};
    final vaiTroMeta = (meta['vai_tro'] ?? meta['role'])?.toString();
    if (vaiTroMeta != null &&
        vaiTroMeta.isNotEmpty &&
        vaiTroMeta != 'sinh_vien' &&
        hoSo.vaiTro != vaiTroMeta) {
      try {
        await _client
            .from('ho_so')
            .update({'vai_tro': vaiTroMeta})
            .eq('id', nguoiDung.id);
        return HoSoNguoiDung.tuMap({
          ...Map<String, dynamic>.from(duLieu),
          'vai_tro': vaiTroMeta,
        });
      } catch (_) {
        // Nếu không cập nhật được thì vẫn trả về hồ sơ gốc
      }
    }

    return hoSo;
  }

  /// Cập nhật hồ sơ cá nhân của người dùng đang đăng nhập.
  Future<void> capNhatHoSo(Map<String, dynamic> duLieuCapNhat) async {
    final nguoiDung = _client.auth.currentUser;
    if (nguoiDung == null) {
      throw Exception('Chưa đăng nhập.');
    }

    await _client.from('ho_so').update(duLieuCapNhat).eq('id', nguoiDung.id);

    await _dichVuNhatKy.ghiNhatKy(
      hanhDong: 'Cập nhật hồ sơ',
      loaiDoiTuong: 'ho_so',
      doiTuongId: nguoiDung.id,
      duLieu: duLieuCapNhat,
    );
  }
}
