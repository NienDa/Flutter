import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý lớp đồ án.
class TrangLopDoAn extends StatelessWidget {
  TrangLopDoAn({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();



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


  /// Kiểm tra mã lớp không được trùng trong toàn hệ thống.
  Future<void> _kiemTraTrungMaLop(
    Map<String, dynamic> duLieuMoi,
    Map<String, dynamic>? duLieuCu,
  ) async {
    final maLop = duLieuMoi['ma_lop']?.toString().trim().toUpperCase() ?? '';
    if (maLop.isEmpty) return;

    duLieuMoi['ma_lop'] = maLop;

    final danhSachTrung = await _dichVuDuLieu.layDanhSach(
      bang: 'lop_do_an',
      boLoc: {'ma_lop': maLop},
    );

    final idCu = duLieuCu?['id']?.toString();
    final biTrung = danhSachTrung.any((dong) => dong['id']?.toString() != idCu);

    if (biTrung) {
      throw Exception('Mã lớp "$maLop" đã tồn tại. Vui lòng nhập mã lớp khác.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrangQuanLyCoBan(
      tieuDe: 'Quản lý lớp đồ án',
      moTa:
          'Mở lớp theo học kỳ, gắn môn học, giảng viên và thời điểm đăng ký/chọn đề tài.',
      bang: 'lop_do_an',
      hoSo: hoSo,
      selectClause: '*, giang_vien:giang_vien_id(ho_ten)',
      sapXepTheo: 'tao_luc',
      duocThem: hoSo.laQuanTriVien,
      duocSua: hoSo.laQuanTriVien,
      duocXoa: hoSo.laQuanTriVien,
      boLoc: hoSo.laGiangVien ? {'giang_vien_id': hoSo.id} : null,
      danhSachCot: const [
        CotBang(tenTruong: 'ma_lop', nhan: 'Mã lớp'),
        CotBang(tenTruong: 'ten_lop', nhan: 'Tên lớp'),
        CotBang(tenTruong: 'hoc_ky', nhan: 'Học kỳ'),
        CotBang(tenTruong: 'ten_mon_hoc', nhan: 'Môn học'),
        CotBang(tenTruong: 'giang_vien.ho_ten', nhan: 'Giảng viên'),
        CotBang(tenTruong: 'trang_thai', nhan: 'Trạng thái'),
      ],
      danhSachTruong: [
        const TruongBieuMau(
          tenTruong: 'hoc_ky',
          nhan: 'Học kỳ',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 100,
        ),
        const TruongBieuMau(
          tenTruong: 'ten_mon_hoc',
          nhan: 'Môn học',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 150,
        ),
        TruongBieuMau(
          tenTruong: 'giang_vien_id',
          nhan: 'Giảng viên phụ trách',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          taiLuaChon: _taiGiangVien,
        ),
        TruongBieuMau(
          tenTruong: 'ma_lop',
          nhan: 'Mã lớp',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 30,
          bieuThucHopLe: RegExp(r'^[A-Z0-9_\-]+$'),
          thongBaoBieuThuc:
              'Mã lớp chỉ gồm chữ in hoa, số, dấu gạch ngang hoặc gạch dưới.',
        ),
        const TruongBieuMau(
          tenTruong: 'ten_lop',
          nhan: 'Tên lớp',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 150,
        ),
        const TruongBieuMau(
          tenTruong: 'mo_ta',
          nhan: 'Mô tả',
          kieu: KieuTruong.vanBanNhieuDong,
          doDaiToiDa: 500,
        ),

        const TruongBieuMau(
          tenTruong: 'mo_dang_ky_luc',
          nhan: 'Mở đăng ký lúc',
          kieu: KieuTruong.ngayGio,
        ),
        const TruongBieuMau(
          tenTruong: 'dong_dang_ky_luc',
          nhan: 'Đóng đăng ký lúc',
          kieu: KieuTruong.ngayGio,
        ),
        const TruongBieuMau(
          tenTruong: 'mo_chon_de_tai_luc',
          nhan: 'Mở chọn đề tài lúc',
          kieu: KieuTruong.ngayGio,
        ),
        const TruongBieuMau(
          tenTruong: 'dong_chon_de_tai_luc',
          nhan: 'Đóng chọn đề tài lúc',
          kieu: KieuTruong.ngayGio,
        ),
        const TruongBieuMau(
          tenTruong: 'cho_phep_sinh_vien_tao_nhom',
          nhan: 'Cho phép sinh viên tạo nhóm',
          kieu: KieuTruong.boolean,
          giaTriMacDinh: true,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'can_giang_vien_duyet',
          nhan: 'Cần giảng viên duyệt',
          kieu: KieuTruong.boolean,
          giaTriMacDinh: true,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'ban_nhap',
          luaChonTinh: [
            LuaChonMuc(giaTri: 'ban_nhap', nhan: 'Bản nháp'),
            LuaChonMuc(giaTri: 'mo_dang_ky', nhan: 'Mở đăng ký'),
            LuaChonMuc(giaTri: 'dong_dang_ky', nhan: 'Đóng đăng ký'),
            LuaChonMuc(giaTri: 'hoan_thanh', nhan: 'Hoàn thành'),
          ],
        ),
      ],
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        await _kiemTraTrungMaLop(duLieuMoi, duLieuCu);

        if (hoSo.laGiangVien) {
          duLieuMoi['giang_vien_id'] = hoSo.id;
        }
        if (duLieuCu != null && !hoSo.laQuanTriVien && !hoSo.laGiangVien) {
          duLieuMoi['giang_vien_id'] = duLieuCu['giang_vien_id'];
        }
        return duLieuMoi;
      },
      hamKiemTraBieuMau: (duLieuMoi, _) {

        final moDangKy = DateTime.tryParse(
          duLieuMoi['mo_dang_ky_luc']?.toString() ?? '',
        );
        final dongDangKy = DateTime.tryParse(
          duLieuMoi['dong_dang_ky_luc']?.toString() ?? '',
        );
        if (moDangKy != null &&
            dongDangKy != null &&
            !moDangKy.isBefore(dongDangKy)) {
          return 'Thời gian mở đăng ký phải trước thời gian đóng đăng ký.';
        }

        final moChonDeTai = DateTime.tryParse(
          duLieuMoi['mo_chon_de_tai_luc']?.toString() ?? '',
        );
        final dongChonDeTai = DateTime.tryParse(
          duLieuMoi['dong_chon_de_tai_luc']?.toString() ?? '',
        );
        if (moChonDeTai != null &&
            dongChonDeTai != null &&
            !moChonDeTai.isBefore(dongChonDeTai)) {
          return 'Thời gian mở chọn đề tài phải trước thời gian đóng chọn đề tài.';
        }
        return null;
      },
      onRowTap: (lop) => _moDanhSachSinhVien(context, lop),
    );
  }

  void _moDanhSachSinhVien(BuildContext context, Map<String, dynamic> lop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _DanhSachSinhVienLopSheet(
              lop: lop,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _DanhSachSinhVienLopSheet extends StatefulWidget {
  const _DanhSachSinhVienLopSheet({
    required this.lop,
    required this.scrollController,
  });

  final Map<String, dynamic> lop;
  final ScrollController scrollController;

  @override
  State<_DanhSachSinhVienLopSheet> createState() => __DanhSachSinhVienLopSheetState();
}

class __DanhSachSinhVienLopSheetState extends State<_DanhSachSinhVienLopSheet> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  bool _dangTai = true;
  List<Map<String, dynamic>> _danhSach = [];
  String _tuKhoa = '';

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final duLieu = await _dichVuDuLieu.layDanhSach(
        bang: 'ghi_danh',
        boLoc: {'lop_do_an_id': widget.lop['id']},
        selectClause: '*, sinh_vien:sinh_vien_id(ho_ten, ma_sinh_vien, email)',
      );
      if (!mounted) return;
      setState(() {
        _danhSach = duLieu;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách: $e')),
      );
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  String _nhanTrangThai(String? trangThai) {
    switch (trangThai) {
      case 'cho_duyet':
        return 'Chờ duyệt';
      case 'da_duyet':
        return 'Đã duyệt';
      case 'tu_choi':
        return 'Từ chối';
      case 'da_huy':
        return 'Đã huỷ';
      default:
        return trangThai ?? '—';
    }
  }

  Color _mauTrangThai(String? trangThai) {
    switch (trangThai) {
      case 'da_duyet':
        return Colors.green.shade700;
      case 'cho_duyet':
        return Colors.orange.shade700;
      case 'tu_choi':
      case 'da_huy':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dsLoc = _danhSach.where((dong) {
      final sv = dong['sinh_vien'];
      if (sv == null) return false;
      final hoTen = (sv['ho_ten']?.toString() ?? '').toLowerCase();
      final mssv = (sv['ma_sinh_vien']?.toString() ?? '').toLowerCase();
      final tuKhoaLoc = _tuKhoa.trim().toLowerCase();
      return hoTen.contains(tuKhoaLoc) || mssv.contains(tuKhoaLoc);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách sinh viên',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lớp: ${widget.lop['ma_lop']} - ${widget.lop['ten_lop']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => setState(() => _tuKhoa = val),
            decoration: const InputDecoration(
              hintText: 'Tìm sinh viên theo tên hoặc MSSV...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : dsLoc.isEmpty
                    ? Center(
                        child: Text(
                          _danhSach.isEmpty
                              ? 'Chưa có sinh viên nào ghi danh trong lớp này.'
                              : 'Không tìm thấy sinh viên phù hợp.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: dsLoc.length,
                        itemBuilder: (context, index) {
                          final dong = dsLoc[index];
                          final sv = dong['sinh_vien'] ?? {};
                          final hoTen = sv['ho_ten']?.toString() ?? '—';
                          final mssv = sv['ma_sinh_vien']?.toString() ?? 'Chưa có MSSV';
                          final email = sv['email']?.toString() ?? '—';
                          final trangThai = dong['trang_thai']?.toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                child: Text(
                                  hoTen.isNotEmpty ? hoTen[0].toUpperCase() : '?',
                                ),
                              ),
                              title: Text(
                                hoTen,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MSSV: $mssv'),
                                  Text('Email: $email'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _mauTrangThai(trangThai).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _mauTrangThai(trangThai),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _nhanTrangThai(trangThai),
                                  style: TextStyle(
                                    color: _mauTrangThai(trangThai),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
