import 'package:flutter/material.dart';

import '../dich_vu/dich_vu_ho_so.dart';
import '../dich_vu/dich_vu_xac_thuc.dart';
import '../mo_hinh/ho_so_nguoi_dung.dart';
import '../tien_ich/thong_bao.dart';
import 'man_hinh_cho.dart';
import 'trang/trang_danh_ba_ho_so.dart';
import 'trang/trang_de_tai.dart';
import 'trang/trang_ho_so.dart';
import 'trang/trang_nguyen_vong_de_tai.dart';
import 'trang/trang_nhom_do_an.dart';
import 'trang/trang_tong_quan.dart';
import 'trang/trang_yeu_cau_vao_nhom.dart';
import 'trang/trang_lop_do_an.dart';
import 'trang/trang_ghi_danh.dart';
import 'trang/trang_thanh_vien_nhom.dart';

/// Cấu hình một mục điều hướng trên menu trái.
class MucDieuHuong {
  const MucDieuHuong({
    required this.nhan,
    required this.icon,
    required this.builder,
  });

  final String nhan;
  final IconData icon;
  final Widget Function() builder;
}

/// Màn hình chính sau khi người dùng đăng nhập thành công.
class ManHinhChinh extends StatefulWidget {
  const ManHinhChinh({super.key});

  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> {
  final DichVuHoSo _dichVuHoSo = DichVuHoSo();
  final DichVuXacThuc _dichVuXacThuc = DichVuXacThuc();

  HoSoNguoiDung? _hoSo;
  bool _dangTaiHoSo = true;
  int _chiSoDangChon = 0;

  @override
  void initState() {
    super.initState();
    _taiHoSo();
  }

  /// Tải hồ sơ hiện tại từ Supabase để dựng menu đúng vai trò.
  Future<void> _taiHoSo() async {
    setState(() => _dangTaiHoSo = true);

    try {
      final hoSo = await _dichVuHoSo.layHoSoHienTai();

      if (!mounted) return;
      setState(() {
        _hoSo = hoSo;
      });
    } catch (loi) {
      if (!mounted) return;
      ThongBao.loi(context, loi);
    } finally {
      if (mounted) {
        setState(() => _dangTaiHoSo = false);
      }
    }
  }

  /// Trả về danh sách menu theo vai trò của người dùng.
  List<MucDieuHuong> _taoDanhSachMenu(HoSoNguoiDung hoSo) {
    final menu = <MucDieuHuong>[];

    if (hoSo.laQuanTriVien) {
      menu.addAll([
        MucDieuHuong(
          nhan: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          builder: () => TrangTongQuan(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Hồ sơ người dùng',
          icon: Icons.contacts_outlined,
          builder: () => TrangDanhBaHoSo(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Lớp đồ án',
          icon: Icons.class_outlined,
          builder: () => TrangLopDoAn(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Ghi danh',
          icon: Icons.how_to_reg_outlined,
          builder: () => TrangGhiDanh(hoSo: hoSo),
        ),
      ]);
    } else if (hoSo.laGiangVien) {
      menu.addAll([
        MucDieuHuong(
          nhan: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          builder: () => TrangTongQuan(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Lớp đồ án',
          icon: Icons.class_outlined,
          builder: () => TrangLopDoAn(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Đề tài',
          icon: Icons.topic_outlined,
          builder: () => TrangDeTai(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Thành viên nhóm',
          icon: Icons.people_outline,
          builder: () => TrangThanhVienNhom(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Nguyện vọng',
          icon: Icons.playlist_add_check_circle_outlined,
          builder: () => TrangNguyenVongDeTai(hoSo: hoSo),
        ),
      ]);
    } else {
      menu.addAll([
        MucDieuHuong(
          nhan: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          builder: () => TrangTongQuan(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Nhóm của lớp',
          icon: Icons.groups_outlined,
          builder: () => TrangNhomDoAn(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Xin vào nhóm',
          icon: Icons.mark_email_unread_outlined,
          builder: () => TrangYeuCauVaoNhom(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Thành viên nhóm',
          icon: Icons.people_outline,
          builder: () => TrangThanhVienNhom(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Đề tài công bố',
          icon: Icons.topic_outlined,
          builder: () => TrangDeTai(hoSo: hoSo),
        ),
        MucDieuHuong(
          nhan: 'Nguyện vọng',
          icon: Icons.playlist_add_check_circle_outlined,
          builder: () => TrangNguyenVongDeTai(hoSo: hoSo),
        ),
      ]);
    }

    menu.add(
      MucDieuHuong(
        nhan: 'Hồ sơ cá nhân',
        icon: Icons.person_outline,
        builder: () => TrangHoSo(
          hoSo: hoSo,
          onDaCapNhat: _taiHoSo,
        ),
      ),
    );

    return menu;
  }

  /// Đăng xuất người dùng ra khỏi ứng dụng.
  Future<void> _dangXuat() async {
    final dongY = await ThongBao.xacNhan(
      context,
      tieuDe: 'Đăng xuất',
      noiDung: 'Bạn có chắc muốn đăng xuất khỏi hệ thống không?',
    );

    if (!dongY) return;

    try {
      await _dichVuXacThuc.dangXuat();
    } catch (loi) {
      if (!mounted) return;
      ThongBao.loi(context, loi);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTaiHoSo) {
      return const ManHinhCho(thongDiep: 'Đang tải...');
    }

    final hoSo = _hoSo;
    if (hoSo == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải hồ sơ người dùng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Có thể tài khoản của bạn đã bị xóa khỏi hệ thống hoặc gặp lỗi kết nối.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _taiHoSo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại hồ sơ'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _dangXuat,
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final danhSachMenu = _taoDanhSachMenu(hoSo);
    if (_chiSoDangChon >= danhSachMenu.length) {
      _chiSoDangChon = 0;
    }

    final trangHienTai = danhSachMenu[_chiSoDangChon];

    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final laManHinhLon = constraints.maxWidth >= 1100;

            Widget noiDung = AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(trangHienTai.nhan),
                child: trangHienTai.builder(),
              ),
            );

            if (laManHinhLon) {
              return Scaffold(
                body: Row(
                  children: [
                    _ThanhMenuVaiTro(
                      hoSo: hoSo,
                      danhSachMenu: danhSachMenu,
                      chiSoDangChon: _chiSoDangChon,
                      onChon: (index) {
                        setState(() => _chiSoDangChon = index);
                      },
                      onDangXuat: _dangXuat,
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF5F7FB),
                        child: noiDung,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(trangHienTai.nhan),
                actions: [
                  IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: _dangXuat,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              drawer: _DrawerVaiTro(
                hoSo: hoSo,
                danhSachMenu: danhSachMenu,
                chiSoDangChon: _chiSoDangChon,
                onChon: (index) {
                  Navigator.of(context).pop();
                  setState(() => _chiSoDangChon = index);
                },
              ),
              body: noiDung,
            );
          },
        );
      },
    );
  }
}

class _ThanhMenuVaiTro extends StatelessWidget {
  const _ThanhMenuVaiTro({
    required this.hoSo,
    required this.danhSachMenu,
    required this.chiSoDangChon,
    required this.onChon,
    required this.onDangXuat,
  });

  final HoSoNguoiDung hoSo;
  final List<MucDieuHuong> danhSachMenu;
  final int chiSoDangChon;
  final ValueChanged<int> onChon;
  final VoidCallback onDangXuat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 282,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              _TheVaiTroNguoiDung(hoSo: hoSo),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: danhSachMenu.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final muc = danhSachMenu[index];
                    final dangChon = index == chiSoDangChon;
                    return _MucMenuVaiTro(
                      muc: muc,
                      dangChon: dangChon,
                      onTap: () => onChon(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDangXuat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TheVaiTroNguoiDung extends StatelessWidget {
  const _TheVaiTroNguoiDung({
    required this.hoSo,
  });

  final HoSoNguoiDung hoSo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: (hoSo.anhDaiDienUrl != null && hoSo.anhDaiDienUrl!.isNotEmpty)
                ? NetworkImage(hoSo.anhDaiDienUrl!)
                : null,
            child: (hoSo.anhDaiDienUrl != null && hoSo.anhDaiDienUrl!.isNotEmpty)
                ? null
                : Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hoSo.hoTen.isNotEmpty ? hoSo.hoTen : 'Người dùng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hoSo.nhanVaiTro,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MucMenuVaiTro extends StatelessWidget {
  const _MucMenuVaiTro({
    required this.muc,
    required this.dangChon,
    required this.onTap,
  });

  final MucDieuHuong muc;
  final bool dangChon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: dangChon
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dangChon
                ? Colors.white
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              muc.icon,
              size: 21,
              color: dangChon
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                muc.nhan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dangChon
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  fontWeight: dangChon ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerVaiTro extends StatelessWidget {
  const _DrawerVaiTro({
    required this.hoSo,
    required this.danhSachMenu,
    required this.chiSoDangChon,
    required this.onChon,
  });

  final HoSoNguoiDung hoSo;
  final List<MucDieuHuong> danhSachMenu;
  final int chiSoDangChon;
  final ValueChanged<int> onChon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                ),
              ),
              child: _TheVaiTroNguoiDung(hoSo: hoSo),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: danhSachMenu.length,
                itemBuilder: (context, index) {
                  final muc = danhSachMenu[index];
                  final dangChon = index == chiSoDangChon;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      selected: dangChon,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(muc.icon),
                      title: Text(muc.nhan),
                      onTap: () => onChon(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
