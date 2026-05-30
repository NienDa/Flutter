import 'package:flutter/material.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import '../thanh_phan/khung_trang_hien_dai.dart';
import '../thanh_phan/o_the_so_lieu.dart';

/// Trang tổng quan hiển thị các số liệu nổi bật theo vai trò.
class TrangTongQuan extends StatefulWidget {
  const TrangTongQuan({
    super.key,
    required this.hoSo,
  });

  final HoSoNguoiDung hoSo;

  @override
  State<TrangTongQuan> createState() => _TrangTongQuanState();
}

class _TrangTongQuanState extends State<TrangTongQuan> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();

  bool _dangTai = true;
  final Map<String, int> _soLieu = {};

  List<Map<String, dynamic>> _danhSachLopThamGia = [];
  Map<String, dynamic>? _nhomHienTai;
  Map<String, dynamic>? _deTaiDaDuyet;
  List<Map<String, dynamic>> _dsNguyenVong = [];

  @override
  void initState() {
    super.initState();
    _taiTongQuan();
  }

  Future<int> _dem(
    String bang, {
    Map<String, dynamic>? boLoc,
  }) {
    return _dichVuDuLieu.demSoLuong(bang: bang, boLoc: boLoc);
  }

  /// Tải các chỉ số chính cho dashboard theo đúng phân quyền.
  Future<void> _taiTongQuan() async {
    setState(() => _dangTai = true);

    final soLieu = <String, int>{};

    try {
      if (widget.hoSo.laQuanTriVien) {
        soLieu['ho_so'] = await _dem('ho_so');
        soLieu['lop_do_an'] = await _dem('lop_do_an');
        soLieu['ghi_danh'] = await _dem('ghi_danh');
        soLieu['de_tai'] = await _dem('de_tai');
        soLieu['nhom_do_an'] = await _dem('nhom_do_an');
      } else if (widget.hoSo.laGiangVien) {
        soLieu['lop_phu_trach'] = await _dem(
          'lop_do_an',
          boLoc: {'giang_vien_id': widget.hoSo.id},
        );
        soLieu['de_tai_phu_trach'] = await _dem(
          'de_tai',
          boLoc: {'giang_vien_id': widget.hoSo.id},
        );
        
        final lopGiangVien = await _dichVuDuLieu.layDanhSach(
          bang: 'lop_do_an',
          boLoc: {'giang_vien_id': widget.hoSo.id},
        );
        final lopIds = lopGiangVien.map((e) => e['id']?.toString()).toSet();
        
        final tatCaNhoms = await _dichVuDuLieu.layDanhSach(bang: 'nhom_do_an');
        final nhomsGiangVien = tatCaNhoms
            .where((nhom) => lopIds.contains(nhom['lop_do_an_id']?.toString()))
            .toList();
        soLieu['nhom_do_an'] = nhomsGiangVien.length;

        final tatCaNguyenVong = await _dichVuDuLieu.layDanhSach(
          bang: 'nguyen_vong_de_tai',
          selectClause: '*, nhom:nhom_do_an(lop:lop_do_an(giang_vien_id))',
        );
        final nvsGiangVien = tatCaNguyenVong.where((dong) {
          final nhom = dong['nhom'];
          if (nhom == null) return false;
          final lop = nhom['lop'];
          if (lop == null) return false;
          return lop['giang_vien_id']?.toString() == widget.hoSo.id;
        }).toList();
        soLieu['nguyen_vong'] = nvsGiangVien.length;
      } else {
        // 1. Lớp đồ án đang tham gia (đã duyệt ghi danh)
        final ghiDanhs = await _dichVuDuLieu.layDanhSach(
          bang: 'ghi_danh',
          boLoc: {'sinh_vien_id': widget.hoSo.id, 'trang_thai': 'da_duyet'},
          selectClause: '*, lop:lop_do_an_id(id, ma_lop, ten_lop)',
        );
        _danhSachLopThamGia = ghiDanhs
            .map((e) => Map<String, dynamic>.from(e['lop'] ?? {}))
            .where((lop) => lop.isNotEmpty)
            .toList();

        // 2. Nhóm hiện tại
        final tvNhoms = await _dichVuDuLieu.layDanhSach(
          bang: 'thanh_vien_nhom',
          boLoc: {'sinh_vien_id': widget.hoSo.id, 'trang_thai': 'da_chap_nhan'},
          selectClause: '*, nhom:nhom_do_an!thanh_vien_nhom_nhom_id_lop_do_an_id_fkey(id, ten_nhom, trang_thai, lop_do_an_id)',
        );
        if (tvNhoms.isNotEmpty) {
          _nhomHienTai = Map<String, dynamic>.from(tvNhoms.first['nhom'] ?? {});
          if (_nhomHienTai != null && _nhomHienTai!.isNotEmpty) {
            _nhomHienTai!['vai_tro_cua_toi'] = tvNhoms.first['vai_tro'];
            final nhomId = _nhomHienTai!['id'];

            // 3. Đề tài đã duyệt cho nhóm
            final deTais = await _dichVuDuLieu.layDanhSach(
              bang: 'de_tai',
              boLoc: {'nhom_id': nhomId},
              selectClause: '*, giang_vien:giang_vien_id(ho_ten), lop:lop_do_an_id(ma_lop)',
            );
            if (deTais.isNotEmpty) {
              _deTaiDaDuyet = deTais.first;
            } else {
              _deTaiDaDuyet = null;
            }

            // 4. Trạng thái nguyện vọng của nhóm
            _dsNguyenVong = await _dichVuDuLieu.layDanhSach(
              bang: 'nguyen_vong_de_tai',
              boLoc: {'nhom_id': nhomId},
              selectClause: '*, de_tai:de_tai_id(ma_de_tai, ten_de_tai)',
              sapXepTheo: 'thu_tu',
            );
          }
        } else {
          _nhomHienTai = null;
          _deTaiDaDuyet = null;
          _dsNguyenVong = [];
        }

        soLieu['lop_cua_toi'] = _danhSachLopThamGia.length;
        soLieu['nhom_cua_toi'] = tvNhoms.length;
        soLieu['yeu_cau_cua_toi'] = await _dem(
          'yeu_cau_vao_nhom',
          boLoc: {'sinh_vien_id': widget.hoSo.id},
        );

        final lopIds = _danhSachLopThamGia.map((e) => e['id']?.toString()).toSet();
        final tatCaDeTai = await _dichVuDuLieu.layDanhSach(
          bang: 'de_tai',
          boLoc: {'trang_thai': 'da_cong_bo'},
        );
        final deTaisSinhVien = tatCaDeTai
            .where((dt) => lopIds.contains(dt['lop_do_an_id']?.toString()))
            .toList();
        soLieu['de_tai'] = deTaisSinhVien.length;

        soLieu['nguyen_vong'] = _dsNguyenVong.length;
      }

      if (!mounted) return;
      setState(() {
        _soLieu
          ..clear()
          ..addAll(soLieu);
      });
    } catch (loi) {
      if (!mounted) return;
      ThongBao.loi(context, loi);
    } finally {
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  List<Widget> _taoDanhSachThe() {
    if (widget.hoSo.laQuanTriVien) {
      return [
        OTheSoLieu(
          tieuDe: 'Người dùng',
          giaTri: (_soLieu['ho_so'] ?? 0).toString(),
          bieuTuong: Icons.people_alt_outlined,
          moTa: 'Tài khoản và hồ sơ đang có trong hệ thống.',
        ),
        OTheSoLieu(
          tieuDe: 'Lớp đồ án',
          giaTri: (_soLieu['lop_do_an'] ?? 0).toString(),
          bieuTuong: Icons.class_outlined,
          moTa: 'Toàn bộ lớp đồ án trong hệ thống.',
        ),
        OTheSoLieu(
          tieuDe: 'Ghi danh',
          giaTri: (_soLieu['ghi_danh'] ?? 0).toString(),
          bieuTuong: Icons.how_to_reg_outlined,
          moTa: 'Sinh viên đã được thêm vào lớp đồ án.',
        ),
        OTheSoLieu(
          tieuDe: 'Đề tài',
          giaTri: (_soLieu['de_tai'] ?? 0).toString(),
          bieuTuong: Icons.topic_outlined,
          moTa: 'Đề tài đang quản lý trên tất cả lớp.',
        ),
        OTheSoLieu(
          tieuDe: 'Nhóm đồ án',
          giaTri: (_soLieu['nhom_do_an'] ?? 0).toString(),
          bieuTuong: Icons.groups_outlined,
          moTa: 'Tất cả nhóm đồ án đã tạo.',
        ),
      ];
    }

    if (widget.hoSo.laGiangVien) {
      return [
        OTheSoLieu(
          tieuDe: 'Lớp phụ trách',
          giaTri: (_soLieu['lop_phu_trach'] ?? 0).toString(),
          bieuTuong: Icons.class_outlined,
          moTa: 'Các lớp đồ án do giảng viên đang phụ trách.',
        ),
        OTheSoLieu(
          tieuDe: 'Đề tài phụ trách',
          giaTri: (_soLieu['de_tai_phu_trach'] ?? 0).toString(),
          bieuTuong: Icons.topic_outlined,
          moTa: 'Đề tài do giảng viên tạo hoặc quản lý.',
        ),
        OTheSoLieu(
          tieuDe: 'Nhóm trong lớp',
          giaTri: (_soLieu['nhom_do_an'] ?? 0).toString(),
          bieuTuong: Icons.groups_outlined,
          moTa: 'Nhóm thuộc các lớp giảng viên phụ trách.',
        ),
        OTheSoLieu(
          tieuDe: 'Nguyện vọng cần duyệt',
          giaTri: (_soLieu['nguyen_vong'] ?? 0).toString(),
          bieuTuong: Icons.playlist_add_check_circle_outlined,
          moTa: 'Nguyện vọng đề tài do nhóm sinh viên gửi.',
        ),
      ];
    }

    return [
      OTheSoLieu(
        tieuDe: 'Lớp đã ghi danh',
        giaTri: (_soLieu['lop_cua_toi'] ?? 0).toString(),
        bieuTuong: Icons.class_outlined,
        moTa: 'Các lớp đồ án sinh viên đã được thêm vào.',
      ),
      OTheSoLieu(
        tieuDe: 'Nhóm của tôi',
        giaTri: (_soLieu['nhom_cua_toi'] ?? 0).toString(),
        bieuTuong: Icons.groups_outlined,
        moTa: 'Nhóm mà sinh viên đang tham gia.',
      ),
      OTheSoLieu(
        tieuDe: 'Yêu cầu của tôi',
        giaTri: (_soLieu['yeu_cau_cua_toi'] ?? 0).toString(),
        bieuTuong: Icons.mark_email_unread_outlined,
        moTa: 'Yêu cầu xin vào nhóm do sinh viên gửi.',
      ),
      OTheSoLieu(
        tieuDe: 'Đề tài công bố',
        giaTri: (_soLieu['de_tai'] ?? 0).toString(),
        bieuTuong: Icons.topic_outlined,
        moTa: 'Đề tài được phép xem trong lớp đã ghi danh.',
      ),
      OTheSoLieu(
        tieuDe: 'Nguyện vọng nhóm',
        giaTri: (_soLieu['nguyen_vong'] ?? 0).toString(),
        bieuTuong: Icons.playlist_add_check_circle_outlined,
        moTa: 'Nguyện vọng đề tài của nhóm sinh viên.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final danhSachThe = _taoDanhSachThe();

    return KhungTrangHienDai(
      tieuDe: 'Tổng quan',
      moTa: 'Xin chào ${widget.hoSo.hoTen}. Xem số liệu thống kê và thông tin tổng quan hệ thống của bạn.',
      hanhDong: [
        FilledButton.icon(
          onPressed: _taiTongQuan,
          icon: const Icon(Icons.refresh),
          label: const Text('Làm mới'),
        ),
      ],
      noiDung: _dangTai
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: danhSachThe
                      .map(
                        (the) => SizedBox(
                          width: 330,
                          child: the,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                if (widget.hoSo.laSinhVien) ...[
                  _BangThongTinSinhVien(
                    danhSachLop: _danhSachLopThamGia,
                    nhom: _nhomHienTai,
                    deTai: _deTaiDaDuyet,
                    nguyenVongs: _dsNguyenVong,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}

class _BangThongTinSinhVien extends StatelessWidget {
  const _BangThongTinSinhVien({
    required this.danhSachLop,
    required this.nhom,
    required this.deTai,
    required this.nguyenVongs,
  });

  final List<Map<String, dynamic>> danhSachLop;
  final Map<String, dynamic>? nhom;
  final Map<String, dynamic>? deTai;
  final List<Map<String, dynamic>> nguyenVongs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin học tập đồ án',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.class_outlined, color: theme.colorScheme.primary),
            ),
            title: const Text(
              'Lớp đồ án đang tham gia',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: danhSachLop.isEmpty
                ? const Text('Chưa được ghi danh vào lớp nào (Cần Admin ghi danh)')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: danhSachLop.map((lop) {
                      return Text(
                        '• ${lop['ma_lop'] ?? ''} - ${lop['ten_lop'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
          ),
          const Divider(height: 24),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
              child: Icon(Icons.groups_outlined, color: theme.colorScheme.secondary),
            ),
            title: const Text(
              'Nhóm hiện tại',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: nhom == null
                ? const Text('Bạn chưa tham gia nhóm nào (Hãy tự tạo hoặc xin vào nhóm)')
                : Text.rich(
                    TextSpan(
                      text: 'Tên nhóm: ',
                      children: [
                        TextSpan(
                          text: '${nhom!['ten_nhom']} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' | Vai trò: '),
                        TextSpan(
                          text: nhom!['vai_tro_cua_toi'] == 'nhom_truong'
                              ? 'Nhóm trưởng'
                              : 'Thành viên',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: nhom!['vai_tro_cua_toi'] == 'nhom_truong'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 24),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.12),
              child: Icon(Icons.topic_outlined, color: theme.colorScheme.tertiary),
            ),
            title: const Text(
              'Đề tài chính thức đã nhận',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: deTai == null
                ? const Text('Chưa được gán đề tài (Đang đợi duyệt nguyện vọng)')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${deTai!['ma_de_tai']} - ${deTai!['ten_de_tai']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Giảng viên phụ trách: ${deTai!['giang_vien']?['ho_ten'] ?? '—'}'),
                    ],
                  ),
          ),
          const Divider(height: 24),

          const Text(
            'Danh sách nguyện vọng của nhóm',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (nguyenVongs.isEmpty)
            const Text(
              'Chưa đăng ký nguyện vọng đề tài nào.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...nguyenVongs.map((nv) {
              final status = nv['trang_thai']?.toString() ?? '';
              Color statusColor = Colors.grey;
              String statusText = status;
              if (status == 'da_duyet') {
                statusColor = Colors.green;
                statusText = 'Đã duyệt nhận';
              } else if (status == 'tu_choi') {
                statusColor = Colors.red;
                statusText = 'Từ chối';
              } else if (status == 'cho_duyet') {
                statusColor = Colors.orange;
                statusText = 'Đang chờ duyệt';
              }

              final dtInfo = nv['de_tai'] ?? {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Text(
                      'NV ${nv['thu_tu']}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        '${dtInfo['ma_de_tai'] ?? '—'} - ${dtInfo['ten_de_tai'] ?? '—'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
