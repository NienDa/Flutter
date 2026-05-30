import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý ghi danh sinh viên vào lớp đồ án.
class TrangGhiDanh extends StatelessWidget {
  TrangGhiDanh({
    super.key,
    required this.hoSo,
  });

  final HoSoNguoiDung hoSo;
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();

  /// Tải danh sách lớp đồ án cho combobox.
  Future<List<LuaChonMuc>> _taiLopDoAn() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'lop_do_an',
      sapXepTheo: 'ma_lop',
    );

    return duLieu
        .map(
          (e) => LuaChonMuc(
            giaTri: e['id'],
            nhan: '${e['ma_lop']} - ${e['ten_lop']}',
          ),
        )
        .toList();
  }

  /// Tải danh sách sinh viên chưa được ghi danh vào lớp đang chọn.
  Future<List<LuaChonMuc>> _taiSinhVienTheoLop(
    Map<String, dynamic> duLieuHienTai,
  ) async {
    final lopDoAnId = duLieuHienTai['lop_do_an_id'];
    if (lopDoAnId == null) return const <LuaChonMuc>[];

    final sinhVienDaGhiDanh = await _dichVuDuLieu.layDanhSach(
      bang: 'ghi_danh',
      boLoc: {'lop_do_an_id': lopDoAnId},
    );

    final sinhVienDangSua = duLieuHienTai['sinh_vien_id']?.toString();
    final dsIdDaGhiDanh = sinhVienDaGhiDanh
        .map((dong) => dong['sinh_vien_id']?.toString())
        .whereType<String>()
        .where((id) => id != sinhVienDangSua)
        .toSet();

    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      boLoc: {'vai_tro': 'sinh_vien'},
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .where((e) => !dsIdDaGhiDanh.contains(e['id']?.toString()))
        .map(
          (e) => LuaChonMuc(
            giaTri: e['id'],
            nhan: '${e['ho_ten']} (${e['ma_sinh_vien'] ?? 'Chưa có MSSV'})',
          ),
        )
        .toList();
  }

  /// Kiểm tra một sinh viên không được ghi danh trùng vào cùng một lớp.
  Future<void> _kiemTraTrungGhiDanh(
    Map<String, dynamic> duLieuMoi,
    Map<String, dynamic>? duLieuCu,
  ) async {
    final lopDoAnId = duLieuMoi['lop_do_an_id'];
    final sinhVienId = duLieuMoi['sinh_vien_id'];

    if (lopDoAnId == null || sinhVienId == null) return;

    final danhSachTrung = await _dichVuDuLieu.layDanhSach(
      bang: 'ghi_danh',
      boLoc: {
        'lop_do_an_id': lopDoAnId,
        'sinh_vien_id': sinhVienId,
      },
    );

    final idCu = duLieuCu?['id']?.toString();
    final biTrung = danhSachTrung.any((dong) => dong['id']?.toString() != idCu);

    if (biTrung) {
      throw Exception('Sinh viên này đã được thêm vào lớp đồ án đã chọn.');
    }
  }

  /// Tải danh sách người duyệt để chọn nhanh.
  Future<List<LuaChonMuc>> _taiNguoiDuyet() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .map(
          (e) => LuaChonMuc(
            giaTri: e['id'],
            nhan: e['ho_ten'].toString(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return TrangQuanLyCoBan(
      tieuDe: 'Quản lý ghi danh',
      moTa: 'Ghi danh sinh viên vào lớp đồ án và cập nhật trạng thái duyệt.',
      bang: 'ghi_danh',
      hoSo: hoSo,
      selectClause:
          '*, lop:lop_do_an_id(ma_lop, ten_lop), sinh_vien:sinh_vien_id(ho_ten, ma_sinh_vien), nguoi_duyet:duyet_boi(ho_ten)',
      sapXepTheo: 'ghi_danh_luc',
      duocThem: hoSo.laQuanTriVien || hoSo.laGiangVien,
      duocSua: hoSo.laQuanTriVien || hoSo.laGiangVien,
      duocXoa: hoSo.laQuanTriVien || hoSo.laGiangVien,
      danhSachCot: const [
        CotBang(tenTruong: 'lop.ma_lop', nhan: 'Mã lớp'),
        CotBang(tenTruong: 'lop.ten_lop', nhan: 'Tên lớp'),
        CotBang(tenTruong: 'sinh_vien.ho_ten', nhan: 'Sinh viên'),
        CotBang(tenTruong: 'trang_thai', nhan: 'Trạng thái'),
        CotBang(tenTruong: 'ghi_danh_luc', nhan: 'Ghi danh lúc'),
      ],
      danhSachTruong: [
        TruongBieuMau(
          tenTruong: 'lop_do_an_id',
          nhan: 'Lớp đồ án',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          taiLuaChon: _taiLopDoAn,
        ),
        TruongBieuMau(
          tenTruong: 'sinh_vien_id',
          nhan: 'Sinh viên',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          phuThuocTruong: 'lop_do_an_id',
          taiLuaChonTheoDuLieu: _taiSinhVienTheoLop,
        ),
        const TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'da_duyet',
          luaChonTinh: [
            LuaChonMuc(giaTri: 'cho_duyet', nhan: 'Chờ duyệt'),
            LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'),
            LuaChonMuc(giaTri: 'tu_choi', nhan: 'Từ chối'),
            LuaChonMuc(giaTri: 'huy', nhan: 'Huỷ'),
          ],
        ),
        const TruongBieuMau(
          tenTruong: 'ghi_danh_luc',
          nhan: 'Ghi danh lúc',
          kieu: KieuTruong.ngayGio,
        ),
        TruongBieuMau(
          tenTruong: 'duyet_boi',
          nhan: 'Duyệt bởi',
          kieu: KieuTruong.luaChon,
          taiLuaChon: _taiNguoiDuyet,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'duyet_luc',
          nhan: 'Duyệt lúc',
          kieu: KieuTruong.ngayGio,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'ghi_chu',
          nhan: 'Ghi chú',
          kieu: KieuTruong.vanBanNhieuDong,
          hienThiTrongBieuMau: false,
        ),
      ],
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        await _kiemTraTrungGhiDanh(duLieuMoi, duLieuCu);

        if (duLieuMoi['trang_thai'] == 'da_duyet') {
          duLieuMoi['duyet_boi'] ??= hoSo.id;
          duLieuMoi['duyet_luc'] ??= DateTime.now().toIso8601String();
        }
        duLieuMoi['ghi_danh_luc'] ??=
            duLieuCu?['ghi_danh_luc'] ?? DateTime.now().toIso8601String();
        return duLieuMoi;
      },
    );
  }
}