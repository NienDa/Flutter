import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý yêu cầu xin vào nhóm.
class TrangYeuCauVaoNhom extends StatefulWidget {
  const TrangYeuCauVaoNhom({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  State<TrangYeuCauVaoNhom> createState() => _TrangYeuCauVaoNhomState();
}

class _TrangYeuCauVaoNhomState extends State<TrangYeuCauVaoNhom> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  bool _dangTai = true;
  Set<String> _lopIdsDaGhiDanh = {};
  Set<String> _nhomIdsLamNhomTruong = {};

  @override
  void initState() {
    super.initState();
    _taiDuLieuBanDau();
  }

  Future<void> _taiDuLieuBanDau() async {
    try {
      await Future.wait([
        _taiLopDaGhiDanh(),
        _taiNhomIdsLamNhomTruong(),
      ]);
    } catch (e) {
      // Bỏ qua lỗi tải ban đầu
    } finally {
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  Future<void> _taiLopDaGhiDanh() async {
    if (!widget.hoSo.laSinhVien) return;

    final ghiDanhs = await _dichVuDuLieu.layDanhSach(
      bang: 'ghi_danh',
      boLoc: {'sinh_vien_id': widget.hoSo.id, 'trang_thai': 'da_duyet'},
    );
    final ids = ghiDanhs
        .map((e) => e['lop_do_an_id']?.toString())
        .whereType<String>()
        .toSet();
    _lopIdsDaGhiDanh = ids;
  }

  Future<void> _taiNhomIdsLamNhomTruong() async {
    final tvNhoms = await _dichVuDuLieu.layDanhSach(
      bang: 'thanh_vien_nhom',
      boLoc: {
        'sinh_vien_id': widget.hoSo.id,
        'vai_tro': 'nhom_truong',
        'trang_thai': 'da_chap_nhan',
      },
    );
    final ids = tvNhoms
        .map((e) => e['nhom_id']?.toString())
        .whereType<String>()
        .toSet();
    _nhomIdsLamNhomTruong = ids;
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

  /// Tải danh sách nhóm theo đúng lớp đang chọn.
  Future<List<LuaChonMuc>> _taiNhomDoAnTheoLop(
    Map<String, dynamic> duLieuHienTai,
  ) async {
    final lopDoAnId = duLieuHienTai['lop_do_an_id'];
    if (lopDoAnId == null) return const <LuaChonMuc>[];

    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'nhom_do_an',
      boLoc: {'lop_do_an_id': lopDoAnId},
      sapXepTheo: 'ten_nhom',
    );

    final tenDaThem = <String>{};

    return duLieu
        .where((e) => e['trang_thai'] != 'da_huy' && e['trang_thai'] != 'da_khoa')
        .where((e) => tenDaThem.add(e['ten_nhom'].toString().toLowerCase()))
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ten_nhom'].toString()))
        .toList();
  }

  /// Tải danh sách sinh viên.
  Future<List<LuaChonMuc>> _taiSinhVien() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      boLoc: {'vai_tro': 'sinh_vien'},
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ho_ten'].toString()))
        .toList();
  }

  /// Tải danh sách người xử lý.
  Future<List<LuaChonMuc>> _taiNguoiXuLy() async {
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'ho_so',
      sapXepTheo: 'ho_ten',
    );

    return duLieu
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ho_ten'].toString()))
        .toList();
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
      tieuDe: 'Yêu cầu vào nhóm',
      moTa:
          'Sinh viên gửi yêu cầu vào nhóm; nhóm trưởng hoặc giảng viên xử lý yêu cầu.',
      bang: 'yeu_cau_vao_nhom',
      hoSo: widget.hoSo,
      selectClause: '''
      *,
      nhom:nhom_do_an!yeu_cau_vao_nhom_nhom_id_lop_do_an_id_fkey(
        ten_nhom,
        lop:lop_do_an!nhom_do_an_lop_do_an_id_fkey(
          id,
          ma_lop,
          giang_vien_id
        )
      ),
      sinh_vien:ho_so!yeu_cau_vao_nhom_sinh_vien_id_fkey(ho_ten),
      nguoi_xu_ly:ho_so!yeu_cau_vao_nhom_xu_ly_boi_fkey(ho_ten)''',
      sapXepTheo: 'tao_luc',
      duocThem: widget.hoSo.laSinhVien,
      duocSua: (dong) {
        if (widget.hoSo.laQuanTriVien) return true;

        final laNguoiGui = dong['sinh_vien_id']?.toString() == widget.hoSo.id;
        final laNhomTruong =
            _nhomIdsLamNhomTruong.contains(dong['nhom_id']?.toString());

        return laNguoiGui || laNhomTruong;
      },
      duocXoa: (dong) {
        if (widget.hoSo.laQuanTriVien) return true;

        final laNguoiGui = dong['sinh_vien_id']?.toString() == widget.hoSo.id;
        final laNhomTruong =
            _nhomIdsLamNhomTruong.contains(dong['nhom_id']?.toString());

        return laNguoiGui || laNhomTruong;
      },
      tieuDeNutThem: 'Gửi yêu cầu',
      danhSachCot: const [
        CotBang(tenTruong: 'nhom.lop.ma_lop', nhan: 'Lớp'),
        CotBang(tenTruong: 'nhom.ten_nhom', nhan: 'Nhóm'),
        CotBang(tenTruong: 'sinh_vien.ho_ten', nhan: 'Sinh viên'),
        CotBang(tenTruong: 'trang_thai', nhan: 'Trạng thái'),
        CotBang(tenTruong: 'tao_luc', nhan: 'Tạo lúc'),
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
          tenTruong: 'nhom_id',
          nhan: 'Nhóm đồ án',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          phuThuocTruong: 'lop_do_an_id',
          taiLuaChonTheoDuLieu: _taiNhomDoAnTheoLop,
        ),
        TruongBieuMau(
          tenTruong: 'sinh_vien_id',
          nhan: 'Sinh viên',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          taiLuaChon: _taiSinhVien,
          hienThiTrongBieuMau: !widget.hoSo.laSinhVien,
        ),
        const TruongBieuMau(
          tenTruong: 'loi_nhan',
          nhan: 'Lời nhắn',
          kieu: KieuTruong.vanBanNhieuDong,
          doDaiToiDa: 500,
        ),
        TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'cho_duyet',
          hienThiTrongBieuMau: (duLieu) {
            if (duLieu['id'] == null) return false;
            if (widget.hoSo.laQuanTriVien) return true;

            final laNguoiGui =
                duLieu['sinh_vien_id']?.toString() == widget.hoSo.id;
            final laNhomTruong =
                _nhomIdsLamNhomTruong.contains(duLieu['nhom_id']?.toString());
            return laNguoiGui || laNhomTruong;
          },
          taiLuaChonTheoDuLieu: (duLieu) async {
            final laNguoiGui =
                duLieu['sinh_vien_id']?.toString() == widget.hoSo.id;
            final laNhomTruong =
                _nhomIdsLamNhomTruong.contains(duLieu['nhom_id']?.toString());

            if (widget.hoSo.laQuanTriVien) {
              return const [
                LuaChonMuc(giaTri: 'cho_duyet', nhan: 'Chờ duyệt'),
                LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'),
                LuaChonMuc(giaTri: 'tu_choi', nhan: 'Từ chối'),
                LuaChonMuc(giaTri: 'da_huy', nhan: 'Đã huỷ'),
              ];
            }

            final list = <LuaChonMuc>[];
            final trangThaiHienTai =
                duLieu['trang_thai']?.toString() ?? 'cho_duyet';

            if (trangThaiHienTai == 'cho_duyet') {
              list.add(const LuaChonMuc(giaTri: 'cho_duyet', nhan: 'Chờ duyệt'));
            } else if (trangThaiHienTai == 'da_duyet') {
              list.add(const LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'));
            } else if (trangThaiHienTai == 'tu_choi') {
              list.add(const LuaChonMuc(giaTri: 'tu_choi', nhan: 'Từ chối'));
            } else if (trangThaiHienTai == 'da_huy') {
              list.add(const LuaChonMuc(giaTri: 'da_huy', nhan: 'Đã huỷ'));
            }

            if (laNhomTruong) {
              if (!list.any((e) => e.giaTri == 'da_duyet')) {
                list.add(
                  const LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'),
                );
              }
              if (!list.any((e) => e.giaTri == 'tu_choi')) {
                list.add(const LuaChonMuc(giaTri: 'tu_choi', nhan: 'Từ chối'));
              }
            }
            if (laNguoiGui) {
              if (!list.any((e) => e.giaTri == 'da_huy')) {
                list.add(const LuaChonMuc(giaTri: 'da_huy', nhan: 'Đã huỷ'));
              }
            }
            return list;
          },
        ),
        TruongBieuMau(
          tenTruong: 'xu_ly_boi',
          nhan: 'Xử lý bởi',
          kieu: KieuTruong.luaChon,
          taiLuaChon: _taiNguoiXuLy,
          hienThiTrongBieuMau: false,
        ),
        const TruongBieuMau(
          tenTruong: 'xu_ly_luc',
          nhan: 'Xử lý lúc',
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
            final nhom = dong['nhom'];
            if (nhom == null) return false;
            final lop = nhom['lop'];
            if (lop == null) return false;
            return lop['giang_vien_id']?.toString() == widget.hoSo.id;
          }).toList();
        }

        if (widget.hoSo.laSinhVien) {
          return duLieu.where((dong) {
            final nhom = dong['nhom'];
            if (nhom == null) return false;
            final lop = nhom['lop'];
            if (lop == null) return false;
            return _lopIdsDaGhiDanh.contains(lop['id']?.toString());
          }).toList();
        }

        return duLieu;
      },
      nutHanhDongBoSung: (banGhi, taiLai) {
        final laNhomTruong = _nhomIdsLamNhomTruong.contains(banGhi['nhom_id']?.toString());
        final choDuyet = banGhi['trang_thai'] == 'cho_duyet';
        if (laNhomTruong && choDuyet) {
          return [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text(
                'Chấp nhận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final dongY = await ThongBao.xacNhan(
                  context,
                  tieuDe: 'Duyệt yêu cầu',
                  noiDung: 'Bạn có chắc muốn nhận sinh viên này vào nhóm?',
                );
                if (!dongY) return;

                try {
                  final capNhatMoiNhat = await _dichVuDuLieu.layTheoId(
                    bang: 'yeu_cau_vao_nhom',
                    id: banGhi['id'],
                  );
                  
                  if (!context.mounted) return;
                  if (capNhatMoiNhat == null || capNhatMoiNhat['trang_thai'] != 'cho_duyet') {
                    ThongBao.canhBao(context, 'Yêu cầu này đã thay đổi trạng thái hoặc không còn tồn tại.');
                    taiLai();
                    return;
                  }

                  await _dichVuDuLieu.capNhatBanGhi(
                    bang: 'yeu_cau_vao_nhom',
                    id: banGhi['id'],
                    duLieu: {
                      'trang_thai': 'da_duyet',
                      'xu_ly_boi': widget.hoSo.id,
                      'xu_ly_luc': DateTime.now().toIso8601String(),
                    },
                  );
                  if (!context.mounted) return;
                  ThongBao.thanhCong(context, 'Đã duyệt yêu cầu vào nhóm thành công.');
                  taiLai();
                } catch (e) {
                  if (!context.mounted) return;
                  ThongBao.loi(context, e);
                }
              },
            ),
          ];
        }
        return [];
      },
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        if (duLieuCu == null) {
          if (widget.hoSo.laSinhVien) {
            final lopDoAnId = duLieuMoi['lop_do_an_id'];
            final nhomId = duLieuMoi['nhom_id'];
            if (lopDoAnId == null || nhomId == null) {
              throw Exception('Thông tin lớp hoặc nhóm không hợp lệ.');
            }

            // 1. Kiểm tra đã ghi danh lớp đó chưa
            final ghiDanhs = await _dichVuDuLieu.layDanhSach(
              bang: 'ghi_danh',
              boLoc: {
                'sinh_vien_id': widget.hoSo.id,
                'lop_do_an_id': lopDoAnId,
                'trang_thai': 'da_duyet',
              },
            );
            if (ghiDanhs.isEmpty) {
              throw Exception('Bạn chưa được Admin ghi danh vào lớp học này.');
            }

            // 2. Kiểm tra đã có nhóm trong lớp đó chưa
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
                'Bạn đã tham gia một nhóm trong lớp học này rồi.',
              );
            }

            // 3. Kiểm tra số lượng thành viên trong nhóm nhận yêu cầu
            final tvCuaNhom = await _dichVuDuLieu.layDanhSach(
              bang: 'thanh_vien_nhom',
              boLoc: {'nhom_id': nhomId, 'trang_thai': 'da_chap_nhan'},
            );

            const int gioiHanThanhVien = 5;
            if (tvCuaNhom.length >= gioiHanThanhVien) {
              throw Exception(
                'Nhóm này đã đầy thành viên ($gioiHanThanhVien/$gioiHanThanhVien).',
              );
            }

            duLieuMoi['sinh_vien_id'] = widget.hoSo.id;
            duLieuMoi['trang_thai'] = 'cho_duyet';
            duLieuMoi.remove('xu_ly_boi');
            duLieuMoi.remove('xu_ly_luc');
          } else {
            throw Exception('Chỉ sinh viên mới được gửi yêu cầu vào nhóm.');
          }
        } else {
          final trangThaiMoi = duLieuMoi['trang_thai'];
          final trangThaiCu = duLieuCu['trang_thai'];

          if (trangThaiMoi != trangThaiCu) {
            if (trangThaiMoi == 'da_duyet' || trangThaiMoi == 'tu_choi') {
              if (trangThaiCu == 'da_huy') {
                throw Exception('Yêu cầu này đã bị sinh viên huỷ trước đó. Không thể duyệt hoặc từ chối.');
              }
              final nhomId = duLieuCu['nhom_id'];
              final kiemTraNhomTruong = await _dichVuDuLieu.layDanhSach(
                bang: 'thanh_vien_nhom',
                boLoc: {
                  'sinh_vien_id': widget.hoSo.id,
                  'nhom_id': nhomId,
                  'vai_tro': 'nhom_truong',
                  'trang_thai': 'da_chap_nhan',
                },
              );

              if (kiemTraNhomTruong.isEmpty) {
                throw Exception(
                  'Chỉ Nhóm trưởng mới có quyền duyệt hoặc từ chối yêu cầu vào nhóm này.',
                );
              }

              duLieuMoi['xu_ly_boi'] = widget.hoSo.id;
              duLieuMoi['xu_ly_luc'] = DateTime.now().toIso8601String();
            } else if (trangThaiMoi == 'da_huy') {
              if (duLieuCu['sinh_vien_id'] != widget.hoSo.id) {
                throw Exception(
                  'Bạn chỉ có quyền hủy yêu cầu do chính mình tạo.',
                );
              }
            } else {
              throw Exception('Thao tác thay đổi trạng thái không hợp lệ.');
            }
          }
        }
        return duLieuMoi;
      },
    );
  }
}
