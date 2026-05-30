import 'package:supabase_flutter/supabase_flutter.dart';

/// Dịch vụ ghi nhật ký hệ thống vào bảng `nhat_ky_he_thong`.
class DichVuNhatKy {
  final SupabaseClient _client = Supabase.instance.client;

  /// Ghi một hành động vào hệ thống.
  ///
  /// Hàm này được gọi sau các thao tác thêm, sửa, xoá để hỗ trợ
  /// kiểm tra lịch sử làm việc trong đồ án.
  Future<void> ghiNhatKy({
    required String hanhDong,
    required String loaiDoiTuong,
    Object? doiTuongId,
    Map<String, dynamic>? duLieu,
  }) async {
    final nguoiDung = _client.auth.currentUser;
    if (nguoiDung == null) return;

    await _client.from('nhat_ky_he_thong').insert({
      'nguoi_thuc_hien_id': nguoiDung.id,
      'hanh_dong': hanhDong,
      'loai_doi_tuong': loaiDoiTuong,
      'doi_tuong_id': doiTuongId?.toString().isEmpty == true ? null : doiTuongId,
      'du_lieu': duLieu ?? <String, dynamic>{},
    });
  }
}