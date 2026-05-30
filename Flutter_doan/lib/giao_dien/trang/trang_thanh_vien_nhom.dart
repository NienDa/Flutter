import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import '../thanh_phan/khung_trang_hien_dai.dart';


class TrangThanhVienNhom extends StatefulWidget {
  const TrangThanhVienNhom({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  State<TrangThanhVienNhom> createState() => _TrangThanhVienNhomState();
}

class _TrangThanhVienNhomState extends State<TrangThanhVienNhom> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  final TextEditingController _timKiemController = TextEditingController();

  bool _dangTai = true;
  String _tuKhoa = '';
  String? _lopDangChonId;

  List<Map<String, dynamic>> _duLieuGoc = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  @override
  void dispose() {
    _timKiemController.dispose();
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    setState(() => _dangTai = true);

    try {
      final duLieu = await _dichVuDuLieu.layDanhSach(
        bang: 'thanh_vien_nhom',
        selectClause: '''
        *,
        nhom:nhom_do_an!thanh_vien_nhom_nhom_id_lop_do_an_id_fkey(
          id,
          ten_nhom,
          trang_thai,
          lop:lop_do_an!nhom_do_an_lop_do_an_id_fkey(
            id,
            ma_lop,
            ten_lop,
            giang_vien_id
          )
        ),
        sinh_vien:ho_so!thanh_vien_nhom_sinh_vien_id_fkey(
          id,
          ho_ten,
          ma_sinh_vien,
          email
        )
        ''',
        sapXepTheo: 'tham_gia_luc',
      );

      if (!mounted) return;
      setState(() {
        _duLieuGoc = duLieu;
      });
    } catch (loi, st) {
      if (!mounted) return;
      ThongBao.loi(context, loi, st);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  List<Map<String, dynamic>> get _duLieuDaLocTheoQuyen {
    final duLieuDangChapNhan = _duLieuGoc.where((dong) {
      return dong['trang_thai']?.toString() == 'da_chap_nhan';
    }).toList(growable: false);

    if (widget.hoSo.laQuanTriVien) {
      return duLieuDangChapNhan;
    }

    if (widget.hoSo.laGiangVien) {
      return duLieuDangChapNhan.where((dong) {
        final nhom = dong['nhom'];
        if (nhom == null) return false;
        final lop = nhom['lop'];
        if (lop == null) return false;
        return lop['giang_vien_id']?.toString() == widget.hoSo.id;
      }).toList(growable: false);
    }

    if (widget.hoSo.laSinhVien) {
      // Chặn thêm ở tầng giao diện: dù policy cũ còn lỏng, sinh viên vẫn chỉ
      // thấy các nhóm có chính sinh viên đó là thành viên đã chấp nhận.
      final nhomCuaSinhVien = duLieuDangChapNhan
          .where((dong) => dong['sinh_vien_id']?.toString() == widget.hoSo.id)
          .map((dong) => dong['nhom_id']?.toString())
          .whereType<String>()
          .toSet();

      return duLieuDangChapNhan.where((dong) {
        return nhomCuaSinhVien.contains(dong['nhom_id']?.toString());
      }).toList(growable: false);
    }

    return duLieuDangChapNhan;
  }

  List<_NhomThanhVien> get _danhSachNhom {
    final mapNhom = <String, _NhomThanhVien>{};

    for (final dong in _duLieuDaLocTheoQuyen) {
      final nhomId = dong['nhom_id']?.toString();
      if (nhomId == null || nhomId.isEmpty) continue;

      final nhom = Map<String, dynamic>.from(dong['nhom'] ?? {});
      final lop = Map<String, dynamic>.from(nhom['lop'] ?? {});

      final nhomHienThi = mapNhom.putIfAbsent(
        nhomId,
        () => _NhomThanhVien(
          id: nhomId,
          lopDoAnId: dong['lop_do_an_id']?.toString() ?? '',
          maLop: lop['ma_lop']?.toString() ?? '—',
          tenLop: lop['ten_lop']?.toString() ?? '',
          tenNhom: nhom['ten_nhom']?.toString() ?? '—',
          trangThaiNhom: nhom['trang_thai']?.toString() ?? '',
        ),
      );

      nhomHienThi.thanhVien.add(dong);
    }

    final ketQua = mapNhom.values.toList(growable: false);
    ketQua.sort((a, b) {
      final soSanhLop = a.maLop.compareTo(b.maLop);
      if (soSanhLop != 0) return soSanhLop;
      return a.tenNhom.compareTo(b.tenNhom);
    });
    return ketQua;
  }

  List<_LopThanhVien> get _danhSachLop {
    final mapLop = <String, _LopThanhVien>{};

    for (final nhom in _danhSachNhom) {
      if (nhom.lopDoAnId.isEmpty) continue;

      mapLop.putIfAbsent(
        nhom.lopDoAnId,
        () => _LopThanhVien(
          id: nhom.lopDoAnId,
          maLop: nhom.maLop,
          tenLop: nhom.tenLop,
        ),
      );
    }

    final ketQua = mapLop.values.toList(growable: false);
    ketQua.sort((a, b) {
      final soSanhMaLop = a.maLop.compareTo(b.maLop);
      if (soSanhMaLop != 0) return soSanhMaLop;
      return a.tenLop.compareTo(b.tenLop);
    });
    return ketQua;
  }

  List<_NhomThanhVien> get _danhSachNhomSauLocLop {
    if (_lopDangChonId == null || _lopDangChonId!.isEmpty) {
      return _danhSachNhom;
    }

    return _danhSachNhom.where((nhom) {
      return nhom.lopDoAnId == _lopDangChonId;
    }).toList(growable: false);
  }

  List<_NhomThanhVien> get _danhSachNhomSauTimKiem {
    final danhSachTheoLop = _danhSachNhomSauLocLop;
    final tuKhoa = _tuKhoa.trim().toLowerCase();
    if (tuKhoa.isEmpty) return danhSachTheoLop;

    return danhSachTheoLop.where((nhom) {
      final noiDungNhom = '${nhom.maLop} ${nhom.tenLop} ${nhom.tenNhom}'
          .toLowerCase();
      final noiDungThanhVien = nhom.thanhVien.map((dong) {
        final sinhVien = Map<String, dynamic>.from(dong['sinh_vien'] ?? {});
        return '${sinhVien['ho_ten'] ?? ''} ${sinhVien['ma_sinh_vien'] ?? ''}';
      }).join(' ').toLowerCase();

      return noiDungNhom.contains(tuKhoa) || noiDungThanhVien.contains(tuKhoa);
    }).toList(growable: false);
  }

  String _nhanVaiTro(String? vaiTro) {
    switch (vaiTro) {
      case 'nhom_truong':
        return 'Nhóm trưởng';
      case 'thanh_vien':
        return 'Thành viên';
      default:
        return vaiTro ?? '—';
    }
  }

  String _nhanTrangThaiThanhVien(String? trangThai) {
    switch (trangThai) {
      case 'cho_duyet':
        return 'Chờ duyệt';
      case 'da_chap_nhan':
        return 'Đã chấp nhận';
      case 'tu_choi':
        return 'Từ chối';
      case 'da_roi':
        return 'Đã rời';
      case 'bi_xoa':
        return 'Bị xoá';
      default:
        return trangThai ?? '—';
    }
  }

  String _vaiTroCuaToi(_NhomThanhVien nhom) {
    Map<String, dynamic>? banGhiCuaToi;
    for (final dong in nhom.thanhVien) {
      if (dong['sinh_vien_id']?.toString() == widget.hoSo.id) {
        banGhiCuaToi = dong;
        break;
      }
    }

    if (banGhiCuaToi == null) return '';
    return _nhanVaiTro(banGhiCuaToi['vai_tro']?.toString());
  }

  Color _mauTheoVaiTro(BuildContext context, String? vaiTro) {
    if (vaiTro == 'nhom_truong') {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.secondary;
  }

  void _moDanhSachThanhVien(_NhomThanhVien nhom) {
    final thanhVien = nhom.thanhVien.toList(growable: false)
      ..sort((a, b) {
        final vaiTroA = a['vai_tro']?.toString() == 'nhom_truong' ? 0 : 1;
        final vaiTroB = b['vai_tro']?.toString() == 'nhom_truong' ? 0 : 1;
        if (vaiTroA != vaiTroB) return vaiTroA.compareTo(vaiTroB);

        final svA = Map<String, dynamic>.from(a['sinh_vien'] ?? {});
        final svB = Map<String, dynamic>.from(b['sinh_vien'] ?? {});
        return (svA['ho_ten']?.toString() ?? '').compareTo(
          svB['ho_ten']?.toString() ?? '',
        );
      });

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
          initialChildSize: 0.72,
          minChildSize: 0.36,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Text(
                  nhom.tenNhom,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${nhom.maLop}${nhom.tenLop.isEmpty ? '' : ' - ${nhom.tenLop}'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...thanhVien.map((dong) {
                  final sinhVien = Map<String, dynamic>.from(
                    dong['sinh_vien'] ?? {},
                  );
                  final vaiTro = dong['vai_tro']?.toString();
                  final trangThai = dong['trang_thai']?.toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _mauTheoVaiTro(context, vaiTro),
                        foregroundColor: Colors.white,
                        child: Text(
                          (sinhVien['ho_ten']?.toString().isNotEmpty ?? false)
                              ? sinhVien['ho_ten'].toString()[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        sinhVien['ho_ten']?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sinhVien['ma_sinh_vien'] != null)
                            Text('MSSV: ${sinhVien['ma_sinh_vien']}'),
                          Text('Vai trò: ${_nhanVaiTro(vaiTro)}'),
                          Text('Trạng thái: ${_nhanTrangThaiThanhVien(trangThai)}'),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _xayDungTheNhom(_NhomThanhVien nhom) {
    final vaiTroCuaToi = _vaiTroCuaToi(nhom);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _moDanhSachThanhVien(nhom),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nhom.tenNhom,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lớp: ${nhom.maLop}${nhom.tenLop.isEmpty ? '' : ' - ${nhom.tenLop}'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.people_outline, size: 18),
                    label: Text('${nhom.thanhVien.length} thành viên'),
                  ),
                  if (vaiTroCuaToi.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text('Vai trò của tôi: $vaiTroCuaToi'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final danhSachLop = _danhSachLop;
    final danhSachNhomSauLocLop = _danhSachNhomSauLocLop;
    final danhSachNhomSauTimKiem = _danhSachNhomSauTimKiem;

    if (_lopDangChonId != null &&
        !danhSachLop.any((lop) => lop.id == _lopDangChonId)) {
      _lopDangChonId = null;
    }

    return KhungTrangHienDai(
      tieuDe: 'Thành viên nhóm',
      moTa: widget.hoSo.laSinhVien
          ? 'Xem các thành viên trong nhóm đồ án mà bạn đang tham gia.'
          : 'Xem thành viên theo từng nhóm đồ án',
      hanhDong: [
        FilledButton.icon(
          onPressed: _taiDuLieu,
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại'),
        ),
      ],
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (danhSachLop.length > 1) ...[
            DropdownButtonFormField<String>(
              value: _lopDangChonId ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Lọc theo lớp đồ án',
                prefixIcon: Icon(Icons.class_outlined),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              selectedItemBuilder: (context) {
                return [
                  const Text(
                    'Tất cả lớp được phân quyền',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  ...danhSachLop.map((lop) {
                    return Text(
                      '${lop.maLop}${lop.tenLop.isEmpty ? '' : ' - ${lop.tenLop}'}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    );
                  }),
                ];
              },
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text(
                    'Tất cả lớp được phân quyền',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                ...danhSachLop.map((lop) {
                  return DropdownMenuItem<String>(
                    value: lop.id,
                    child: Text(
                      '${lop.maLop}${lop.tenLop.isEmpty ? '' : ' - ${lop.tenLop}'}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _lopDangChonId =
                      value == null || value.isEmpty ? null : value;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _timKiemController,
            onChanged: (value) => setState(() => _tuKhoa = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Tìm theo lớp, nhóm hoặc tên sinh viên...',
              suffixIcon: _tuKhoa.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _timKiemController.clear();
                        setState(() => _tuKhoa = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiển thị ${danhSachNhomSauTimKiem.length}/${danhSachNhomSauLocLop.length} nhóm'
            '${_lopDangChonId == null ? ' trong tất cả lớp' : ' trong lớp đã chọn'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          if (_dangTai)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (danhSachNhomSauTimKiem.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                widget.hoSo.laSinhVien
                    ? 'Bạn chưa có nhóm đồ án đã được chấp nhận, hoặc nhóm chưa có thành viên hợp lệ.'
                    : 'Chưa có nhóm nào có thành viên đã được chấp nhận.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          else
            ...danhSachNhomSauTimKiem.map(_xayDungTheNhom),
        ],
      ),
    );
  }
}

class _LopThanhVien {
  const _LopThanhVien({
    required this.id,
    required this.maLop,
    required this.tenLop,
  });

  final String id;
  final String maLop;
  final String tenLop;
}

class _NhomThanhVien {
  _NhomThanhVien({
    required this.id,
    required this.lopDoAnId,
    required this.maLop,
    required this.tenLop,
    required this.tenNhom,
    required this.trangThaiNhom,
  });

  final String id;
  final String lopDoAnId;
  final String maLop;
  final String tenLop;
  final String tenNhom;
  final String trangThaiNhom;
  final List<Map<String, dynamic>> thanhVien = <Map<String, dynamic>>[];
}
