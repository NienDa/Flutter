import 'package:supabase_flutter/supabase_flutter.dart';

/// Dịch vụ thông báo nội bộ trong hệ thống.
class DichVuThongBao {
  final SupabaseClient _client = Supabase.instance.client;

  /// Lấy danh sách thông báo của người đang đăng nhập.
  Future<List<Map<String, dynamic>>> layThongBao({int gioiHan = 50}) async {
    final duLieu = await _client
        .from('thong_bao_he_thong')
        .select('*, nguoi_tao:tao_boi(ho_ten)')
        .order('tao_luc', ascending: false)
        .limit(gioiHan);

    return List<Map<String, dynamic>>.from(duLieu as List);
  }

  /// Đếm số thông báo chưa đọc.
  Future<int> demChuaDoc() async {
    final duLieu = await _client
        .from('thong_bao_he_thong')
        .select('id')
        .eq('da_doc', false);

    return (duLieu as List).length;
  }

  /// Đánh dấu một thông báo là đã đọc.
  Future<void> danhDauDaDoc(String id) async {
    await _client
        .from('thong_bao_he_thong')
        .update({'da_doc': true})
        .eq('id', id);
  }

  /// Đánh dấu tất cả thông báo là đã đọc.
  Future<void> danhDauTatCaDaDoc() async {
    final nguoiDung = _client.auth.currentUser;
    if (nguoiDung == null) return;

    await _client
        .from('thong_bao_he_thong')
        .update({'da_doc': true})
        .eq('nguoi_nhan_id', nguoiDung.id)
        .eq('da_doc', false);
  }

  /// Gửi thông báo qua RPC bảo mật trong Supabase.
  Future<void> guiThongBao({
    required String nguoiNhanId,
    required String tieuDe,
    required String noiDung,
    String loai = 'he_thong',
    String? duongDan,
  }) async {
    await _client.from('thong_bao_he_thong').insert({
      'nguoi_nhan_id': nguoiNhanId,
      'tieu_de': tieuDe,
      'noi_dung': noiDung,
      'loai': loai,
      'duong_dan': duongDan,
    });
  }

  /// Tạo thông báo tự động sau khi thêm dữ liệu nghiệp vụ.
  ///
  /// Hàm này cố ý bắt lỗi riêng để thông báo không làm hỏng thao tác chính.
  Future<void> taoThongBaoSauKhiThem({
    required String bang,
    required Map<String, dynamic> banGhi,
  }) async {
    try {
      switch (bang) {
        case 'ghi_danh':
          await _thongBaoGhiDanh(banGhi);
          break;
        case 'nhom_do_an':
          await _thongBaoNhomMoi(banGhi);
          break;
        case 'yeu_cau_vao_nhom':
          await _thongBaoYeuCauMoi(banGhi);
          break;
        case 'nguyen_vong_de_tai':
          await _thongBaoNguyenVongMoi(banGhi);
          break;
        case 'de_tai':
          if (banGhi['trang_thai'] == 'da_cong_bo') {
            await _thongBaoDeTaiCongBo(banGhi);
          }
          break;
      }
    } catch (_) {
      // Không chặn thao tác chính nếu bảng thông báo/migration chưa được chạy.
    }
  }

  /// Tạo thông báo tự động sau khi cập nhật dữ liệu nghiệp vụ.
  Future<void> taoThongBaoSauKhiCapNhat({
    required String bang,
    required Map<String, dynamic> banGhiMoi,
    Map<String, dynamic>? duLieuCapNhat,
  }) async {
    try {
      switch (bang) {
        case 'ghi_danh':
          await _thongBaoGhiDanh(banGhiMoi);
          break;
        case 'nhom_do_an':
          if (duLieuCapNhat?.containsKey('trang_thai') == true) {
            await _thongBaoTrangThaiNhom(banGhiMoi);
          }
          break;
        case 'yeu_cau_vao_nhom':
          if (duLieuCapNhat?.containsKey('trang_thai') == true) {
            await _thongBaoKetQuaYeuCau(banGhiMoi);
          }
          break;
        case 'de_tai':
          if (banGhiMoi['trang_thai'] == 'da_cong_bo') {
            await _thongBaoDeTaiCongBo(banGhiMoi);
          }
          break;
      }
    } catch (_) {
      // Không chặn thao tác chính nếu gửi thông báo lỗi.
    }
  }

  Future<void> _thongBaoGhiDanh(Map<String, dynamic> ghiDanh) async {
    final sinhVienId = ghiDanh['sinh_vien_id']?.toString();
    if (sinhVienId == null) return;

    final lop = await _layLop(ghiDanh['lop_do_an_id']);
    final trangThai = ghiDanh['trang_thai']?.toString() ?? '';
    await guiThongBao(
      nguoiNhanId: sinhVienId,
      tieuDe: 'Cập nhật ghi danh lớp đồ án',
      noiDung:
          'Trạng thái ghi danh của bạn tại lớp ${_tenLop(lop)} là: ${_nhanTrangThai(trangThai)}.',
      loai: 'ghi_danh',
    );
  }

  Future<void> _thongBaoNhomMoi(Map<String, dynamic> nhom) async {
    final lop = await _layLop(nhom['lop_do_an_id']);
    final giangVienId = lop?['giang_vien_id']?.toString();
    if (giangVienId == null) return;

    await guiThongBao(
      nguoiNhanId: giangVienId,
      tieuDe: 'Có nhóm mới chờ duyệt',
      noiDung:
          'Nhóm "${nhom['ten_nhom']}" vừa được tạo trong lớp ${_tenLop(lop)}. Vui lòng kiểm tra và duyệt nhóm.',
      loai: 'nhom_do_an',
    );
  }

  Future<void> _thongBaoTrangThaiNhom(Map<String, dynamic> nhom) async {
    final taoBoi = nhom['tao_boi']?.toString();
    if (taoBoi == null) return;

    final trangThai = nhom['trang_thai']?.toString() ?? '';
    await guiThongBao(
      nguoiNhanId: taoBoi,
      tieuDe: 'Cập nhật trạng thái nhóm',
      noiDung:
          'Nhóm "${nhom['ten_nhom']}" đã chuyển sang trạng thái: ${_nhanTrangThai(trangThai)}.',
      loai: 'nhom_do_an',
    );
  }

  Future<void> _thongBaoYeuCauMoi(Map<String, dynamic> yeuCau) async {
    final nhomId = yeuCau['nhom_id']?.toString();
    if (nhomId == null) return;

    final truongNhom = await _client
        .from('thanh_vien_nhom')
        .select('sinh_vien_id')
        .eq('nhom_id', nhomId)
        .eq('vai_tro', 'nhom_truong')
        .eq('trang_thai', 'da_chap_nhan')
        .maybeSingle();

    final truongNhomId = truongNhom?['sinh_vien_id']?.toString();
    if (truongNhomId == null) return;

    await guiThongBao(
      nguoiNhanId: truongNhomId,
      tieuDe: 'Có yêu cầu xin vào nhóm',
      noiDung: 'Một sinh viên vừa gửi yêu cầu xin vào nhóm của bạn.',
      loai: 'yeu_cau_vao_nhom',
    );
  }

  Future<void> _thongBaoKetQuaYeuCau(Map<String, dynamic> yeuCau) async {
    final sinhVienId = yeuCau['sinh_vien_id']?.toString();
    if (sinhVienId == null) return;

    final trangThai = yeuCau['trang_thai']?.toString() ?? '';
    await guiThongBao(
      nguoiNhanId: sinhVienId,
      tieuDe: 'Kết quả yêu cầu vào nhóm',
      noiDung:
          'Yêu cầu vào nhóm của bạn đã được cập nhật: ${_nhanTrangThai(trangThai)}.',
      loai: 'yeu_cau_vao_nhom',
    );
  }

  Future<void> _thongBaoNguyenVongMoi(Map<String, dynamic> nguyenVong) async {
    final lop = await _layLop(nguyenVong['lop_do_an_id']);
    final giangVienId = lop?['giang_vien_id']?.toString();
    if (giangVienId == null) return;

    await guiThongBao(
      nguoiNhanId: giangVienId,
      tieuDe: 'Có nguyện vọng đề tài mới',
      noiDung:
          'Một nhóm trong lớp ${_tenLop(lop)} vừa gửi nguyện vọng chọn đề tài.',
      loai: 'nguyen_vong_de_tai',
    );
  }

  Future<void> _thongBaoDeTaiCongBo(Map<String, dynamic> deTai) async {
    final lopId = deTai['lop_do_an_id']?.toString();
    if (lopId == null) return;

    final ghiDanh = await _client
        .from('ghi_danh')
        .select('sinh_vien_id')
        .eq('lop_do_an_id', lopId)
        .eq('trang_thai', 'da_duyet');

    for (final dong in List<Map<String, dynamic>>.from(ghiDanh as List)) {
      final sinhVienId = dong['sinh_vien_id']?.toString();
      if (sinhVienId == null) continue;
      await guiThongBao(
        nguoiNhanId: sinhVienId,
        tieuDe: 'Có đề tài mới được công bố',
        noiDung:
            'Đề tài "${deTai['ten_de_tai']}" đã được công bố trong lớp của bạn.',
        loai: 'de_tai',
      );
    }
  }

  Future<Map<String, dynamic>?> _layLop(dynamic lopId) async {
    if (lopId == null) return null;
    final duLieu = await _client
        .from('lop_do_an')
        .select('id, ma_lop, ten_lop, giang_vien_id')
        .eq('id', lopId)
        .maybeSingle();
    return duLieu == null ? null : Map<String, dynamic>.from(duLieu);
  }

  String _tenLop(Map<String, dynamic>? lop) {
    if (lop == null) return 'lớp đồ án';
    return '${lop['ma_lop'] ?? ''} - ${lop['ten_lop'] ?? ''}'.trim();
  }

  String _nhanTrangThai(String giaTri) {
    switch (giaTri) {
      case 'cho_duyet':
        return 'Chờ duyệt';
      case 'da_duyet':
        return 'Đã duyệt';
      case 'tu_choi':
        return 'Từ chối';
      case 'da_huy':
        return 'Đã huỷ';
      case 'da_khoa':
        return 'Đã khoá';
      case 'da_cong_bo':
        return 'Đã công bố';
      case 'da_gan_nhom':
        return 'Đã gán nhóm';
      case 'da_xem':
        return 'Đã xem';
      default:
        return giaTri.replaceAll('_', ' ');
    }
  }
}
