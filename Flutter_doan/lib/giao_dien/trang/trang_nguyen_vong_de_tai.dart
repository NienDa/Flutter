import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang quản lý nguyện vọng đề tài của từng nhóm.
class TrangNguyenVongDeTai extends StatefulWidget {
  const TrangNguyenVongDeTai({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  State<TrangNguyenVongDeTai> createState() => _TrangNguyenVongDeTaiState();
}

class _TrangNguyenVongDeTaiState extends State<TrangNguyenVongDeTai> {
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
    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'lop_do_an',
      sapXepTheo: 'ma_lop',
    );

    // Sinh viên chỉ được chọn các lớp mình đã ghi danh
    if (widget.hoSo.laSinhVien) {
      return duLieu
          .where((e) => _lopIdsDaGhiDanh.contains(e['id']?.toString()))
          .map(
            (e) => LuaChonMuc(
              giaTri: e['id'],
              nhan: '${e['ma_lop']} - ${e['ten_lop']}',
            ),
          )
          .toList();
    }

    // Giảng viên chỉ được chọn các lớp mình phụ trách
    if (widget.hoSo.laGiangVien) {
      return duLieu
          .where((e) => e['giang_vien_id']?.toString() == widget.hoSo.id)
          .map(
            (e) => LuaChonMuc(
              giaTri: e['id'],
              nhan: '${e['ma_lop']} - ${e['ten_lop']}',
            ),
          )
          .toList();
    }

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

    return duLieu
        .where((e) => e['trang_thai'] != 'da_huy' && e['trang_thai'] != 'da_khoa')
        .map((e) => LuaChonMuc(giaTri: e['id'], nhan: e['ten_nhom'].toString()))
        .toList();
  }

  /// Tải danh sách đề tài theo đúng lớp đang chọn.
  Future<List<LuaChonMuc>> _taiDeTaiTheoLop(
    Map<String, dynamic> duLieuHienTai,
  ) async {
    final lopDoAnId = duLieuHienTai['lop_do_an_id'];
    if (lopDoAnId == null) return const <LuaChonMuc>[];

    final duLieu = await _dichVuDuLieu.layDanhSach(
      bang: 'de_tai',
      boLoc: {'lop_do_an_id': lopDoAnId},
      sapXepTheo: 'ma_de_tai',
    );

    return duLieu
        .where((e) => e['trang_thai'] != 'ban_nhap' && e['trang_thai'] != 'luu_tru')
        .map(
          (e) => LuaChonMuc(
            giaTri: e['id'],
            nhan: '${e['ma_de_tai']} - ${e['ten_de_tai']}',
          ),
        )
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
      tieuDe: 'Nguyện vọng đề tài',
      moTa:
          'Nhóm trưởng gửi thứ tự ưu tiên đề tài cho nhóm của mình hoặc giảng viên theo dõi.',
      bang: 'nguyen_vong_de_tai',
      hoSo: widget.hoSo,
      selectClause: '''
      *,
      nhom:nhom_do_an(
        ten_nhom,
        lop:lop_do_an(
          id,
          ma_lop,
          ten_lop,
          giang_vien_id
        )
      ),
      de_tai:de_tai(ten_de_tai, ma_de_tai)
      ''',
      sapXepTheo: 'nhom_id',
      duocThem: widget.hoSo.laSinhVien,
      duocSua: true,
      duocXoa: widget.hoSo.laQuanTriVien || widget.hoSo.laSinhVien,
      tieuDeNutThem: 'Gửi nguyện vọng',
      danhSachCot: const [
        CotBang(tenTruong: 'nhom.ten_nhom', nhan: 'Nhóm'),
        CotBang(tenTruong: 'de_tai.ten_de_tai', nhan: 'Đề tài'),
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
          tenTruong: 'nhom_id',
          nhan: 'Nhóm đồ án',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          phuThuocTruong: 'lop_do_an_id',
          taiLuaChonTheoDuLieu: _taiNhomDoAnTheoLop,
        ),
        TruongBieuMau(
          tenTruong: 'de_tai_id',
          nhan: 'Đề tài',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          phuThuocTruong: 'lop_do_an_id',
          taiLuaChonTheoDuLieu: _taiDeTaiTheoLop,
        ),
        TruongBieuMau(
          tenTruong: 'trang_thai',
          nhan: 'Trạng thái',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          giaTriMacDinh: 'cho_duyet',
          hienThiTrongBieuMau: !widget.hoSo.laSinhVien,
          luaChonTinh: const [
            LuaChonMuc(giaTri: 'cho_duyet', nhan: 'Chờ duyệt'),
            LuaChonMuc(giaTri: 'da_duyet', nhan: 'Đã duyệt'),
            LuaChonMuc(giaTri: 'tu_choi', nhan: 'Từ chối'),
          ],
        ),
      ],
      nutHanhDongBoSung: (banGhi, taiLai) {
        final laNguoiPhuTrach = widget.hoSo.laQuanTriVien || 
            (widget.hoSo.laGiangVien && banGhi['nhom']?['lop']?['giang_vien_id']?.toString() == widget.hoSo.id);
        final choDuyet = banGhi['trang_thai'] == 'cho_duyet';
        if (laNguoiPhuTrach && choDuyet) {
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
                  tieuDe: 'Duyệt nguyện vọng',
                  noiDung: 'Bạn có chắc muốn duyệt đề tài này cho nhóm?',
                );
                if (!dongY) return;

                try {
                  final capNhatMoiNhat = await _dichVuDuLieu.layTheoId(
                    bang: 'nguyen_vong_de_tai',
                    id: banGhi['id'],
                  );
                  
                  if (!context.mounted) return;
                  if (capNhatMoiNhat == null || capNhatMoiNhat['trang_thai'] != 'cho_duyet') {
                    ThongBao.canhBao(context, 'Nguyện vọng này đã thay đổi trạng thái hoặc không còn tồn tại.');
                    taiLai();
                    return;
                  }

                  final deTaiId = banGhi['de_tai_id'];
                  final nhomId = banGhi['nhom_id'];

                  if (deTaiId != null && nhomId != null) {
                    final deTai = await _dichVuDuLieu.layTheoId(
                      bang: 'de_tai',
                      id: deTaiId,
                    );
                    if (!context.mounted) return;
                    if (deTai != null && deTai['nhom_id'] != null && deTai['nhom_id'] != nhomId) {
                      ThongBao.canhBao(context, 'Đề tài này đã được giao cho một nhóm khác.');
                      return;
                    }

                    // 1. Gán đề tài cho nhóm
                    await _dichVuDuLieu.capNhatBanGhi(
                      bang: 'de_tai',
                      id: deTaiId,
                      duLieu: {'nhom_id': nhomId},
                    );

                    // 2. Tự động chuyển các nguyện vọng khác của cùng nhóm sang trạng thái từ chối
                    final dsKhac = await _dichVuDuLieu.layDanhSach(
                      bang: 'nguyen_vong_de_tai',
                      boLoc: {'nhom_id': nhomId},
                    );

                    for (final nv in dsKhac) {
                      final nvId = nv['id'];
                      if (nvId != banGhi['id']) {
                        await _dichVuDuLieu.capNhatBanGhi(
                          bang: 'nguyen_vong_de_tai',
                          id: nvId,
                          duLieu: {'trang_thai': 'tu_choi'},
                        );
                      }
                    }
                  }

                  // 3. Cập nhật trạng thái nguyện vọng này sang da_duyet
                  await _dichVuDuLieu.capNhatBanGhi(
                    bang: 'nguyen_vong_de_tai',
                    id: banGhi['id'],
                    duLieu: {'trang_thai': 'da_duyet'},
                  );

                  if (!context.mounted) return;
                  ThongBao.thanhCong(context, 'Đã duyệt nguyện vọng đề tài thành công.');
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
      hamXuLyTruocKhiLuu: (duLieuMoi, duLieuCu) async {
        duLieuMoi['thu_tu'] ??= 1;
        if (widget.hoSo.laGiangVien && duLieuCu == null) {
          throw Exception(
            'Giảng viên chỉ được theo dõi nguyện vọng!',
          );
        }

        if (widget.hoSo.laSinhVien) {
          final nhomId = duLieuMoi['nhom_id'];
          final deTaiId = duLieuMoi['de_tai_id'];
          if (nhomId == null || deTaiId == null) {
            throw Exception('Thông tin nhóm hoặc đề tài không hợp lệ.');
          }

          // 1. Kiểm tra xem sinh viên có phải là Nhóm trưởng của nhóm này không
          final checkNhomTruong = await _dichVuDuLieu.layDanhSach(
            bang: 'thanh_vien_nhom',
            boLoc: {
              'sinh_vien_id': widget.hoSo.id,
              'nhom_id': nhomId,
              'vai_tro': 'nhom_truong',
              'trang_thai': 'da_chap_nhan',
            },
          );
          if (checkNhomTruong.isEmpty) {
            throw Exception(
              'Chỉ Nhóm trưởng mới được quyền đăng ký nguyện vọng đề tài cho nhóm.',
            );
          }

          // 2. Kiểm tra nhóm đã có thành viên chưa (đã có dòng nào đã chấp nhận trong nhóm)
          final tvNhom = await _dichVuDuLieu.layDanhSach(
            bang: 'thanh_vien_nhom',
            boLoc: {'nhom_id': nhomId, 'trang_thai': 'da_chap_nhan'},
          );
          if (tvNhom.isEmpty) {
            throw Exception(
              'Nhóm phải có ít nhất 1 thành viên mới được đăng ký nguyện vọng.',
            );
          }

          // 3. Kiểm tra đề tài phải có trạng thái da_cong_bo
          final deTai = await _dichVuDuLieu.layTheoId(
            bang: 'de_tai',
            id: deTaiId,
          );
          if (deTai == null || deTai['trang_thai'] != 'da_cong_bo') {
            throw Exception('Đề tài đã được chọn!');
          }

          duLieuMoi['trang_thai'] = 'cho_duyet';
          duLieuMoi['tao_boi'] = widget.hoSo.id;
        }

        if (widget.hoSo.laGiangVien &&
            duLieuCu != null &&
            duLieuCu['trang_thai'] == 'da_duyet' &&
            duLieuMoi['trang_thai'] != 'da_duyet') {
          final deTaiId = duLieuMoi['de_tai_id'] ?? duLieuCu['de_tai_id'];
          if (deTaiId != null) {
            await _dichVuDuLieu.capNhatBanGhi(
              bang: 'de_tai',
              id: deTaiId,
              duLieu: {'nhom_id': null},
            );
          }
        }

        if (widget.hoSo.laGiangVien &&
            duLieuMoi['trang_thai'] == 'da_duyet' &&
            duLieuCu?['trang_thai'] != 'da_duyet') {
          final deTaiId = duLieuMoi['de_tai_id'] ?? duLieuCu?['de_tai_id'];
          final nhomId = duLieuMoi['nhom_id'] ?? duLieuCu?['nhom_id'];

          if (deTaiId != null && nhomId != null) {
            // 1. Gán đề tài cho nhóm
            await _dichVuDuLieu.capNhatBanGhi(
              bang: 'de_tai',
              id: deTaiId,
              duLieu: {'nhom_id': nhomId},
            );

            // 2. Tự động chuyển các nguyện vọng khác của cùng nhóm sang trạng thái từ chối
            final dsKhac = await _dichVuDuLieu.layDanhSach(
              bang: 'nguyen_vong_de_tai',
              boLoc: {'nhom_id': nhomId},
            );

            for (final nv in dsKhac) {
              final nvId = nv['id'];
              if (nvId != duLieuCu?['id']) {
                await _dichVuDuLieu.capNhatBanGhi(
                  bang: 'nguyen_vong_de_tai',
                  id: nvId,
                  duLieu: {'trang_thai': 'tu_choi'},
                );
              }
            }
          }
        }

        return duLieuMoi;
      },
    );
  }
}
