import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý đề tài đồ án.
class TrangDeTai extends StatefulWidget {
  const TrangDeTai({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  State<TrangDeTai> createState() => _TrangDeTaiState();
}

class _TrangDeTaiState extends State<TrangDeTai> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  bool _dangTai = true;
  List<_LopDoAnDoc> _danhSachLop = [];
  String? _lopDangChonId;

  @override
  void initState() {
    super.initState();
    _taiDuLieuBanDau();
  }

  Future<void> _taiDuLieuBanDau() async {
    try {
      List<Map<String, dynamic>> duLieuLop = [];
      if (widget.hoSo.laGiangVien) {
        duLieuLop = await _dichVuDuLieu.layDanhSach(
          bang: 'lop_do_an',
          boLoc: {'giang_vien_id': widget.hoSo.id},
          sapXepTheo: 'ma_lop',
        );
      } else if (widget.hoSo.laSinhVien) {
        final ghiDanhList = await _dichVuDuLieu.layDanhSach(
          bang: 'ghi_danh',
          boLoc: {
            'sinh_vien_id': widget.hoSo.id,
            'trang_thai': 'da_duyet',
          },
          selectClause: '*, lop:lop_do_an_id(*)',
        );
        for (final gd in ghiDanhList) {
          final lop = gd['lop'];
          if (lop != null && lop is Map<String, dynamic>) {
            duLieuLop.add(lop);
          }
        }
        duLieuLop.sort((a, b) => a['ma_lop'].toString().compareTo(b['ma_lop'].toString()));
      } else {
        duLieuLop = await _dichVuDuLieu.layDanhSach(
          bang: 'lop_do_an',
          sapXepTheo: 'ma_lop',
        );
      }

      if (mounted) {
        setState(() {
          _danhSachLop = duLieuLop.map((e) => _LopDoAnDoc(
            id: e['id'].toString(),
            maLop: e['ma_lop'].toString(),
            tenLop: e['ten_lop']?.toString() ?? '',
          )).toList();
          _dangTai = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  /// Tải danh sách lớp đồ án cho combobox.
  Future<List<LuaChonMuc>> _taiLopDoAn() async {
    return _danhSachLop
        .map(
          (e) => LuaChonMuc(
            giaTri: e.id,
            nhan: '${e.maLop} - ${e.tenLop}',
          ),
        )
        .toList();
  }

  /// Tải danh sách giảng viên cho combobox.
  Future<List<LuaChonMuc>> _taiGiangVien() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      boLoc: {'vai_tro': 'giang_vien'},
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ho_ten'].toString()))
        .toList();
  }

  /// Kiểm tra mã đề tài không được trùng trong toàn hệ thống.
  Future<void> _kiemTraTrungMaDeTai(
    Map<String, dynamic> duLieuMoi,
    Map<String, dynamic>? duLieuCu,
  ) async {
    final maDeTai =
        duLieuMoi['ma_de_tai']?.toString().trim().toUpperCase() ?? '';
    if (maDeTai.isEmpty) return;

    duLieuMoi['ma_de_tai'] = maDeTai;

    final danhSachTrung = await _dichVuDuLieu.layDanhSach(
      bang: 'de_tai',
      boLoc: {'ma_de_tai': maDeTai},
    );

    final idCu = duLieuCu?['id']?.toString();
    final biTrung = danhSachTrung.any((dong) => dong['id']?.toString() != idCu);

    if (biTrung) {
      throw Exception(
        'Mã đề tài "$maDeTai" đã tồn tại. Vui lòng nhập mã đề tài khác.',
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
      tieuDe: 'Quản lý đề tài',
      moTa:
          'Tạo danh sách đề tài, mô tả công nghệ, số lượng thành viên và trạng thái công bố.',
      bang: 'de_tai',
      hoSo: widget.hoSo,
      selectClause:
          '*, lop:lop_do_an_id(ma_lop, ten_lop), giang_vien:giang_vien_id(ho_ten), nhom:nhom_id(ten_nhom)',
      sapXepTheo: 'tao_luc',
      duocThem: widget.hoSo.laQuanTriVien || widget.hoSo.laGiangVien,
      duocSua: widget.hoSo.laQuanTriVien || widget.hoSo.laGiangVien,
      duocXoa: widget.hoSo.laQuanTriVien || widget.hoSo.laGiangVien,
      hamKiemTraTruocKhiXoa: (banGhi) {
        if (banGhi['nhom_id'] != null) {
          return 'Không thể xoá đề tài đã có nhóm nhận.';
        }
        return null;
      },
      danhSachCot: const [
        CotBang(tenTruong: 'ma_de_tai', nhan: 'Mã đề tài'),
        CotBang(tenTruong: 'ten_de_tai', nhan: 'Tên đề tài'),
        CotBang(tenTruong: 'lop.ma_lop', nhan: 'Lớp'),
        CotBang(tenTruong: 'giang_vien.ho_ten', nhan: 'Giảng viên'),
        CotBang(tenTruong: 'nhom.ten_nhom', nhan: 'Nhóm nhận'),
        CotBang(tenTruong: 'trang_thai', nhan: 'Trạng thái'),
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
          tenTruong: 'ma_de_tai',
          nhan: 'Mã đề tài',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 30,
          bieuThucHopLe: RegExp(r'^[A-Z0-9_\-]+$'),
          thongBaoBieuThuc:
              'Mã đề tài chỉ gồm chữ in hoa, số, dấu gạch ngang hoặc gạch dưới.',
        ),
        const TruongBieuMau(
          tenTruong: 'ten_de_tai',
          nhan: 'Tên đề tài',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 5,
          doDaiToiDa: 200,
        ),
        const TruongBieuMau(
          tenTruong: 'mo_ta',
          nhan: 'Mô tả',
          kieu: KieuTruong.vanBanNhieuDong,
          batBuoc: true,
          doDaiToiDa: 1000,
        ),
        const TruongBieuMau(
          tenTruong: 'cong_nghe',
          nhan: 'Công nghệ',
          kieu: KieuTruong.vanBanNhieuDong,
          batBuoc: true,
          doDaiToiDa: 1000,
        ),
        const TruongBieuMau(
          tenTruong: 'so_thanh_vien_toi_thieu',
          nhan: 'Số thành viên tối thiểu',
          kieu: KieuTruong.soNguyen,
          batBuoc: true,
          giaTriMacDinh: 1,
          giaTriToiThieu: 1,
          giaTriToiDa: 10,
        ),
        const TruongBieuMau(
          tenTruong: 'so_thanh_vien_toi_da',
          nhan: 'Số thành viên tối đa',
          kieu: KieuTruong.soNguyen,
          batBuoc: true,
          giaTriMacDinh: 5,
          giaTriToiThieu: 1,
          giaTriToiDa: 10,
        ),
        const TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'ban_nhap',
          luaChonTinh: [
            LuaChonMuc(giaTri: 'ban_nhap', nhan: 'Bản nháp'),
            LuaChonMuc(giaTri: 'da_cong_bo', nhan: 'Đã công bố'),
            LuaChonMuc(giaTri: 'dong', nhan: 'Đóng'),
          ],
        ),
        TruongBieuMau(
          tenTruong: 'tao_boi',
          nhan: 'Tạo bởi',
          kieu: KieuTruong.luaChon,
          taiLuaChon: _taiGiangVien,
          hienThiTrongBieuMau: false,
        ),
        TruongBieuMau(
          tenTruong: 'duyet_boi',
          nhan: 'Duyệt bởi',
          kieu: KieuTruong.luaChon,
          taiLuaChon: _taiGiangVien,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'cong_bo_luc',
          nhan: 'Công bố lúc',
          kieu: KieuTruong.ngayGio,
          hienThiTrongBieuMau: false,
        ),
      ],
      boLocTuyChinh: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            value: _lopDangChonId ?? '',
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.class_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Tất cả lớp'),
              ),
              ..._danhSachLop.map((lop) {
                return DropdownMenuItem(
                  value: lop.id,
                  child: Text(
                    '${lop.maLop} - ${lop.tenLop}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _lopDangChonId =
                    (value == null || value.isEmpty) ? null : value;
              });
            },
          ),
        ),
      ],
      hamLocDuLieu: (duLieu) {
        var ds = duLieu;

        // Giảng viên chỉ xem được đề tài thuộc lớp mình phụ trách, Sinh viên chỉ xem được đề tài thuộc lớp đã tham gia
        if (widget.hoSo.laGiangVien || widget.hoSo.laSinhVien) {
          final setIds = _danhSachLop.map((e) => e.id).toSet();
          ds = ds
              .where((dong) => setIds.contains(dong['lop_do_an_id']?.toString()))
              .toList();
        }

        // Lọc theo lớp được chọn
        if (_lopDangChonId != null) {
          ds = ds
              .where((dong) =>
                  dong['lop_do_an_id']?.toString() == _lopDangChonId)
              .toList();
        }

        return ds;
      },
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        await _kiemTraTrungMaDeTai(duLieuMoi, duLieuCu);

        duLieuMoi['giang_vien_id'] ??= widget.hoSo.id;
        duLieuMoi['tao_boi'] ??= widget.hoSo.id;
        if (duLieuMoi['trang_thai'] == 'da_cong_bo') {
          duLieuMoi['duyet_boi'] ??= widget.hoSo.id;
          duLieuMoi['cong_bo_luc'] ??= DateTime.now().toIso8601String();
        }
        return duLieuMoi;
      },
      hamKiemTraBieuMau: (duLieuMoi, _) {
        final toiThieu = duLieuMoi['so_thanh_vien_toi_thieu'] as int?;
        final toiDa = duLieuMoi['so_thanh_vien_toi_da'] as int?;
        if (toiThieu != null && toiDa != null && toiThieu > toiDa) {
          return 'Số thành viên tối thiểu của đề tài không được lớn hơn số thành viên tối đa.';
        }
        return null;
      },
    );
  }
}

class _LopDoAnDoc {
  const _LopDoAnDoc({
    required this.id,
    required this.maLop,
    required this.tenLop,
  });

  final String id;
  final String maLop;
  final String tenLop;
}
