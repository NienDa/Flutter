import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý nhóm đồ án.
class TrangNhomDoAn extends StatefulWidget {
  const TrangNhomDoAn({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  State<TrangNhomDoAn> createState() => _TrangNhomDoAnState();
}

class _TrangNhomDoAnState extends State<TrangNhomDoAn> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  bool _dangTai = true;
  Set<String> _lopIdsDaGhiDanh = {};

  @override
  void initState() {
    super.initState();
    _taiLopDaGhiDanh();
  }

  Future<void> _taiLopDaGhiDanh() async {
    if (!widget.hoSo.laSinhVien) {
      setState(() => _dangTai = false);
      return;
    }

    try {
      final ghiDanhs = await _dichVuDuLieu.layDanhSach(
        bang: 'ghi_danh',
        boLoc: {'sinh_vien_id': widget.hoSo.id, 'trang_thai': 'da_duyet'},
      );
      final ids = ghiDanhs
          .map((e) => e['lop_do_an_id']?.toString())
          .whereType<String>()
          .toSet();
      if (mounted) {
        setState(() {
          _lopIdsDaGhiDanh = ids;
          _dangTai = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  /// Tải danh sách lớp đồ án.
  Future<List<LuaChonMuc>> _taiLopDoAn() async {
    if (widget.hoSo.laSinhVien) {
      final ghiDanh = await _dichVuDuLieu.layDanhSach(
        bang: 'ghi_danh',
        boLoc: {'sinh_vien_id': widget.hoSo.id, 'trang_thai': 'da_duyet'},
        selectClause: 'lop:lop_do_an_id(id, ma_lop, ten_lop)',
      );

      return ghiDanh
          .map((gd) => gd['lop'])
          .where((lop) => lop != null)
          .map(
            (lop) => LuaChonMuc(
              giaTri: lop['id'],
              nhan: '${lop['ma_lop']} - ${lop['ten_lop']}',
            ),
          )
          .toList();
    }

    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'lop_do_an',
      boLoc: widget.hoSo.laGiangVien ? {'giang_vien_id': widget.hoSo.id} : null,
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

  /// Tải danh sách hồ sơ dùng cho các trường người tạo / người duyệt.
  Future<List<LuaChonMuc>> _taiNguoiDung() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ho_ten'].toString()))
        .toList();
  }

  /// Kiểm tra tên nhóm không được trùng trong cùng một lớp đồ án.
  Future<void> _kiemTraTrungTenNhomTrongLop(
    Map<String, dynamic> duLieuMoi,
    Map<String, dynamic>? duLieuCu,
  ) async {
    final lopDoAnId = duLieuMoi['lop_do_an_id'];
    final tenNhom = duLieuMoi['ten_nhom']?.toString().trim() ?? '';

    if (lopDoAnId == null || tenNhom.isEmpty) return;

    duLieuMoi['ten_nhom'] = tenNhom;

    final danhSachTrung = await _dichVuDuLieu.layDanhSach(
      bang: 'nhom_do_an',
      boLoc: {
        'lop_do_an_id': lopDoAnId,
        'ten_nhom': tenNhom,
      },
    );

    final idCu = duLieuCu?['id']?.toString();
    final biTrung = danhSachTrung.any((dong) => dong['id']?.toString() != idCu);

    if (biTrung) {
      throw Exception(
        'Tên nhóm "$tenNhom" đã tồn tại trong lớp này. Vui lòng nhập tên nhóm khác.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTai) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return TrangQuanLyCoBan(
      tieuDe: 'Quản lý nhóm đồ án',
      moTa:
          'Sinh viên có thể tạo nhóm; giảng viên và quản trị viên có thể duyệt hoặc khoá nhóm.',
      bang: 'nhom_do_an',
      hoSo: widget.hoSo,
      selectClause:
          '*, lop:lop_do_an_id(id, ma_lop, ten_lop, giang_vien_id), nguoi_tao:tao_boi(ho_ten), nguoi_duyet:duyet_boi(ho_ten)',
      sapXepTheo: 'tao_luc',
      duocThem: true,
      duocSua: (dong) {
        if (widget.hoSo.laQuanTriVien || widget.hoSo.laGiangVien) return true;
        return dong['tao_boi']?.toString() == widget.hoSo.id;
      },
      duocXoa: (dong) {
        if (widget.hoSo.laQuanTriVien || widget.hoSo.laGiangVien) return true;
        return dong['tao_boi']?.toString() == widget.hoSo.id;
      },
      tieuDeNutThem: 'Tạo nhóm',
      danhSachCot: const [
        CotBang(tenTruong: 'ten_nhom', nhan: 'Tên nhóm'),
        CotBang(tenTruong: 'lop.ma_lop', nhan: 'Lớp'),
        CotBang(tenTruong: 'nguoi_tao.ho_ten', nhan: 'Tạo bởi'),
        CotBang(tenTruong: 'trang_thai', nhan: 'Trạng thái'),
        CotBang(tenTruong: 'duyet_luc', nhan: 'Duyệt lúc'),
      ],
      danhSachTruong: [
        TruongBieuMau(
          tenTruong: 'lop_do_an_id',
          nhan: 'Lớp đồ án',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          taiLuaChon: _taiLopDoAn,
        ),
        const TruongBieuMau(
          tenTruong: 'ten_nhom',
          nhan: 'Tên nhóm',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 100,
        ),
        const TruongBieuMau(
          tenTruong: 'mo_ta',
          nhan: 'Mô tả',
          kieu: KieuTruong.vanBanNhieuDong,
          doDaiToiDa: 500,
        ),
        TruongBieuMau(
          tenTruong: 'tao_boi',
          nhan: 'Tạo bởi',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          taiLuaChon: _taiNguoiDung,
          hienThiTrongBieuMau: false,
        ),
        TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'dang_tao',
          hienThiTrongBieuMau: !widget.hoSo.laSinhVien,
          luaChonTinh: const [
            LuaChonMuc(giaTri: 'dang_tao', nhan: 'Đang tạo'),
            LuaChonMuc(giaTri: 'cho_duyet', nhan: 'Chờ duyệt'),
            LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'),
            LuaChonMuc(giaTri: 'da_khoa', nhan: 'Đã khoá'),
            LuaChonMuc(giaTri: 'da_huy', nhan: 'Đã huỷ'),
          ],
        ),
        TruongBieuMau(
          tenTruong: 'duyet_boi',
          nhan: 'Duyệt bởi',
          kieu: KieuTruong.luaChon,
          taiLuaChon: _taiNguoiDung,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'duyet_luc',
          nhan: 'Duyệt lúc',
          kieu: KieuTruong.ngayGio,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'khoa_luc',
          nhan: 'Khoá lúc',
          kieu: KieuTruong.ngayGio,
          hienThiTrongBieuMau: false,
        ),
      ],
      hamLocDuLieu: (duLieu) {
        if (widget.hoSo.laQuanTriVien) {
          return duLieu;
        }

        if (widget.hoSo.laGiangVien) {
          return duLieu.where((dong) {
            final lop = dong['lop'];
            if (lop == null) return false;
            return lop['giang_vien_id']?.toString() == widget.hoSo.id;
          }).toList();
        }

        if (widget.hoSo.laSinhVien) {
          return duLieu.where((dong) {
            final lop = dong['lop'];
            if (lop == null) return false;
            return _lopIdsDaGhiDanh.contains(lop['id']?.toString());
          }).toList();
        }

        return duLieu;
      },
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        await _kiemTraTrungTenNhomTrongLop(duLieuMoi, duLieuCu);

        if (widget.hoSo.laSinhVien) {
          final lopDoAnId = duLieuMoi['lop_do_an_id'];

          // Chỉ kiểm tra khi tạo nhóm mới, không kiểm tra khi sửa nhóm cũ
          if (duLieuCu == null && lopDoAnId != null) {
            final tvNhoms = await _dichVuDuLieu.layDanhSach(
              bang: 'thanh_vien_nhom',
              boLoc: {
                'sinh_vien_id': widget.hoSo.id,
                'lop_do_an_id': lopDoAnId,
                'trang_thai': 'da_chap_nhan',
              },
            );
            if (tvNhoms.isNotEmpty) {
              throw Exception(
                'Bạn đã tham gia một nhóm khác trong lớp này rồi. Không thể tạo thêm nhóm mới.',
              );
            }
          }

          duLieuMoi['tao_boi'] = widget.hoSo.id;
          if (duLieuCu == null) {
            duLieuMoi['trang_thai'] = 'cho_duyet';
          } else {
            duLieuMoi['lop_do_an_id'] = duLieuCu['lop_do_an_id'];
            duLieuMoi['tao_boi'] = duLieuCu['tao_boi'];
            duLieuMoi['trang_thai'] = duLieuCu['trang_thai'];
          }
        }
        if ((widget.hoSo.laGiangVien || widget.hoSo.laQuanTriVien) &&
            duLieuMoi['trang_thai'] == 'da_duyet') {
          duLieuMoi['duyet_boi'] = widget.hoSo.id;
          duLieuMoi['duyet_luc'] ??= DateTime.now().toIso8601String();
        }
        if ((widget.hoSo.laGiangVien || widget.hoSo.laQuanTriVien) &&
            duLieuMoi['trang_thai'] == 'da_khoa') {
          duLieuMoi['khoa_luc'] ??= DateTime.now().toIso8601String();
        }
        return duLieuMoi;
      },
    );
  }
}
