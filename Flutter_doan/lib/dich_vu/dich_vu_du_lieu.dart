import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dich_vu_nhat_ky.dart';
import 'dich_vu_thong_bao.dart';

/// Dịch vụ CRUD dùng chung cho hầu hết các bảng trong hệ thống.
class DichVuDuLieu {
  final SupabaseClient _client = Supabase.instance.client;
  final DichVuNhatKy _dichVuNhatKy = DichVuNhatKy();
  final DichVuThongBao _dichVuThongBao = DichVuThongBao();

  /// Lấy danh sách bản ghi từ một bảng.
  ///
  /// Có thể truyền thêm `selectClause`, `boLoc`, `sapXepTheo` để tái sử dụng
  /// cho nhiều màn hình khác nhau.
  Future<List<Map<String, dynamic>>> layDanhSach({
    required String bang,
    String selectClause = '*',
    Map<String, dynamic>? boLoc,
    String? sapXepTheo,
    bool tangDan = true,
    int? gioiHan,
  }) async {
    dynamic truyVan = _client.from(bang).select(selectClause);

    if (boLoc != null) {
      for (final entry in boLoc.entries) {
        truyVan = truyVan.eq(entry.key, entry.value);
      }
    }

    if (sapXepTheo != null && sapXepTheo.isNotEmpty) {
      truyVan = truyVan.order(sapXepTheo, ascending: tangDan);
    }

    if (gioiHan != null) {
      truyVan = truyVan.limit(gioiHan);
    }

    final duLieu = await truyVan;
    return List<Map<String, dynamic>>.from(duLieu as List);
  }

  /// Lấy chi tiết một bản ghi theo khoá chính.
  Future<Map<String, dynamic>?> layTheoId({
    required String bang,
    required Object id,
    String khoaChinh = 'id',
    String selectClause = '*',
  }) async {
    final duLieu = await _client
        .from(bang)
        .select(selectClause)
        .eq(khoaChinh, id)
        .maybeSingle();

    if (duLieu == null) return null;
    return Map<String, dynamic>.from(duLieu);
  }

  /// Thêm một bản ghi mới.
  ///
  /// Hàm sẽ tự ghi log vào bảng `nhat_ky_he_thong`.
  Future<Map<String, dynamic>> themBanGhi({
    required String bang,
    required Map<String, dynamic> duLieu,
    String khoaChinh = 'id',
    bool ghiNhatKy = true,
  }) async {
    final ketQua = await _client.from(bang).insert(duLieu).select().single();
    final banGhi = Map<String, dynamic>.from(ketQua);

    if (ghiNhatKy) {
      await _dichVuNhatKy.ghiNhatKy(
        hanhDong: 'Thêm dữ liệu',
        loaiDoiTuong: bang,
        doiTuongId: banGhi[khoaChinh],
        duLieu: duLieu,
      );
    }

    if (bang == 'nhom_do_an') {
      final taoBoi = banGhi['tao_boi'];
      final nhomId = banGhi['id'];
      final lopId = banGhi['lop_do_an_id'];
      if (taoBoi != null && nhomId != null && lopId != null) {
        try {
          // Dùng upsert để tránh lỗi trùng khoá khi dữ liệu cũ chưa được xoá sạch
          await _client.from('thanh_vien_nhom').upsert({
            'nhom_id': nhomId,
            'sinh_vien_id': taoBoi,
            'vai_tro': 'nhom_truong',
            'trang_thai': 'da_chap_nhan',
            'lop_do_an_id': lopId,
            'tham_gia_luc': DateTime.now().toIso8601String(),
          }, onConflict: 'nhom_id,sinh_vien_id');
        } catch (loiTV) {
          // Rollback: Xoá nhóm vừa tạo nếu không thêm được trưởng nhóm vào bảng thành viên
          await _client.from('nhom_do_an').delete().eq('id', nhomId);
          throw Exception('Tạo nhóm thất bại do không thể khởi tạo thành viên Trưởng nhóm: $loiTV');
        }
      }
    }

    if (bang == 'nhom_do_an' ||
        bang == 'nguyen_vong_de_tai' ||
        bang == 'yeu_cau_vao_nhom') {
      await _dichVuThongBao.taoThongBaoSauKhiThem(bang: bang, banGhi: banGhi);
    }

    return banGhi;
  }

  /// Cập nhật một bản ghi hiện có.
  Future<void> capNhatBanGhi({
    required String bang,
    required Object id,
    required Map<String, dynamic> duLieu,
    String khoaChinh = 'id',
    bool ghiNhatKy = true,
  }) async {
    final ketQua = await _client
        .from(bang)
        .update(duLieu)
        .eq(khoaChinh, id)
        .select()
        .maybeSingle();

    if (ghiNhatKy) {
      await _dichVuNhatKy.ghiNhatKy(
        hanhDong: 'Cập nhật dữ liệu',
        loaiDoiTuong: bang,
        doiTuongId: id,
        duLieu: duLieu,
      );
    }

    if (bang == 'yeu_cau_vao_nhom' && ketQua != null) {
      final banGhiCapNhat = Map<String, dynamic>.from(ketQua);
      if (banGhiCapNhat['trang_thai'] == 'da_duyet') {
        final sinhVienId = banGhiCapNhat['sinh_vien_id'];
        final nhomId = banGhiCapNhat['nhom_id'];
        final lopId = banGhiCapNhat['lop_do_an_id'];
        if (sinhVienId != null && nhomId != null && lopId != null) {
          await _client.from('thanh_vien_nhom').insert({
            'nhom_id': nhomId,
            'sinh_vien_id': sinhVienId,
            'vai_tro': 'thanh_vien',
            'trang_thai': 'da_chap_nhan',
            'lop_do_an_id': lopId,
            'tham_gia_luc': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    if (ketQua != null && (bang == 'de_tai' || bang == 'nguyen_vong_de_tai' || bang == 'yeu_cau_vao_nhom')) {
      await _dichVuThongBao.taoThongBaoSauKhiCapNhat(
        bang: bang,
        banGhiMoi: Map<String, dynamic>.from(ketQua),
        duLieuCapNhat: duLieu,
      );
    }
  }

  /// Xoá một bản ghi khỏi bảng.
  Future<void> xoaBanGhi({
    required String bang,
    required Object id,
    String khoaChinh = 'id',
    bool ghiNhatKy = true,
  }) async {
    final ketQua = await _client.from(bang).delete().eq(khoaChinh, id).select();

    if (ketQua.isEmpty) {
      throw Exception('Bạn không có quyền thực hiện thao tác này.');
    }

    if (ghiNhatKy) {
      await _dichVuNhatKy.ghiNhatKy(
        hanhDong: 'Xoá dữ liệu',
        loaiDoiTuong: bang,
        doiTuongId: id,
        duLieu: {'khoa_chinh': khoaChinh},
      );
    }
  }

  /// Lấy tổng số bản ghi của một bảng dựa trên tập dữ liệu được phép theo RLS.
  Future<int> demSoLuong({
    required String bang,
    Map<String, dynamic>? boLoc,
  }) async {
    try {
      dynamic truyVan = _client.from(bang).select('id');

      if (boLoc != null) {
        for (final entry in boLoc.entries) {
          truyVan = truyVan.eq(entry.key, entry.value);
        }
      }

      final duLieu = await truyVan;
      if (duLieu is List) {
        return duLieu.length;
      }
      return 0;
    } catch (e) {
      try {
        dynamic truyVanDuPhong = _client.from(bang).select('*');
        if (boLoc != null) {
          for (final entry in boLoc.entries) {
            truyVanDuPhong = truyVanDuPhong.eq(entry.key, entry.value);
          }
        }
        final duLieuDuPhong = await truyVanDuPhong;
        if (duLieuDuPhong is List) {
          return duLieuDuPhong.length;
        }
      } catch (e2, st) {
        print('Lỗi đếm số lượng trên bảng $bang: $e2\n$st');
      }
      return 0;
    }
  }

  /// Tìm kiếm cục bộ trong một danh sách bản ghi.
  ///
  /// Hàm này giúp giảm số lần gọi mạng khi người dùng chỉ lọc theo từ khoá.
  List<Map<String, dynamic>> timKiemCucBo(
    List<Map<String, dynamic>> duLieu,
    String tuKhoa,
  ) {
    if (tuKhoa.trim().isEmpty) return duLieu;

    final chuanHoa = tuKhoa.toLowerCase().trim();
    return duLieu.where((banGhi) {
      return jsonEncode(banGhi).toLowerCase().contains(chuanHoa);
    }).toList();
  }
}
