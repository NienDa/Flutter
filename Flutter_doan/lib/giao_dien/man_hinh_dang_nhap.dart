import 'package:flutter/material.dart';

import '../dich_vu/dich_vu_xac_thuc.dart';
import '../tien_ich/thong_bao.dart';

enum _CheDoXacThuc { dangNhap, dangKy }

/// Màn hình đăng nhập, đăng ký.
class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _xacNhanMatKhauController = TextEditingController();
  final _hoTenController = TextEditingController();
  final _dichVuXacThuc = DichVuXacThuc();

  late _CheDoXacThuc _cheDo;
  bool _dangXuLy = false;
  String _vaiTro = 'sinh_vien';

  bool _hienMatKhau = false;
  bool _hienXacNhanMatKhau = false;

  bool get _laDangNhap => _cheDo == _CheDoXacThuc.dangNhap;
  bool get _laDangKy => _cheDo == _CheDoXacThuc.dangKy;

  @override
  void initState() {
    super.initState();
    _cheDo = _CheDoXacThuc.dangNhap;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    _xacNhanMatKhauController.dispose();
    _hoTenController.dispose();
    super.dispose();
  }

  bool _emailHopLe(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  bool _matKhauDuManh(String matKhau) {
    return matKhau.length >= 6 &&
        RegExp(r'[A-Za-z]').hasMatch(matKhau) &&
        RegExp(r'\d').hasMatch(matKhau);
  }

  String? _kiemTraEmail(String email) {
    if (email.trim().isEmpty) return 'Vui lòng nhập email.';
    if (!_emailHopLe(email)) return 'Email không đúng định dạng.';
    return null;
  }

  String? _kiemTraMatKhau(String matKhau, {String nhan = 'Mật khẩu'}) {
    if (matKhau.trim().isEmpty) return 'Vui lòng nhập $nhan.';
    if (!_matKhauDuManh(matKhau)) {
      return '$nhan phải có ít nhất 6 ký tự, gồm chữ và số.';
    }
    return null;
  }

  Future<void> _xuLyDangNhapDangKy() async {
    final email = _emailController.text.trim();
    final matKhau = _matKhauController.text.trim();
    final xacNhanMatKhau = _xacNhanMatKhauController.text.trim();
    final hoTen = _hoTenController.text.trim();

    final loiEmail = _kiemTraEmail(email);
    if (loiEmail != null) {
      ThongBao.loi(context, loiEmail);
      return;
    }

    final loiMatKhau = _laDangNhap ? null : _kiemTraMatKhau(matKhau);
    if (_laDangNhap && matKhau.isEmpty) {
      ThongBao.loi(context, 'Vui lòng nhập mật khẩu.');
      return;
    }
    if (loiMatKhau != null) {
      ThongBao.loi(context, loiMatKhau);
      return;
    }

    if (_laDangKy) {
      if (hoTen.length < 3) {
        ThongBao.loi(context, 'Họ tên phải có ít nhất 3 ký tự.');
        return;
      }
      if (matKhau != xacNhanMatKhau) {
        ThongBao.loi(context, 'Mật khẩu và xác nhận mật khẩu không khớp.');
        return;
      }
    }

    setState(() => _dangXuLy = true);
    try {
      if (_laDangNhap) {
        await _dichVuXacThuc.dangNhap(
          email: email,
          matKhau: matKhau,
        );
      } else {
        await _dichVuXacThuc.dangKy(
          email: email,
          matKhau: matKhau,
          hoTen: hoTen,
          vaiTro: _vaiTro,
        );
        if (!mounted) return;
        ThongBao.thanhCong(
          context,
          'Đăng ký thành công.',
        );
        _chuyenCheDo(_CheDoXacThuc.dangNhap);
      }
    } catch (loi) {
      if (!mounted) return;
      ThongBao.loi(context, loi);
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  void _chuyenCheDo(_CheDoXacThuc cheDo) {
    setState(() {
      _cheDo = cheDo;
      _matKhauController.clear();
      _xacNhanMatKhauController.clear();
      _hoTenController.clear();
    });
  }

  Widget _oMatKhau({
    required TextEditingController controller,
    required String label,
    required bool dangHien,
    required VoidCallback onDoiTrangThai,
  }) {
    return TextField(
      controller: controller,
      obscureText: !dangHien,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onDoiTrangThai,
          icon: Icon(
            dangHien ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
        ),
      ),
    );
  }

  Widget _thanhCheDo(ColorScheme mau) {
    Widget nut(String nhan, _CheDoXacThuc cheDo) {
      final dangChon = _cheDo == cheDo;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _dangXuLy ? null : () => _chuyenCheDo(cheDo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: dangChon ? mau.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              nhan,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dangChon ? mau.onPrimary : mau.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: mau.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          nut('Đăng nhập', _CheDoXacThuc.dangNhap),
          nut('Đăng ký', _CheDoXacThuc.dangKy),
        ],
      ),
    );
  }

  List<Widget> _cacTruongTheoCheDo(ColorScheme mau) {
    return [
      if (_laDangKy) ...[
        TextField(
          controller: _hoTenController,
          decoration: const InputDecoration(
            labelText: 'Họ tên',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.mail_outline),
        ),
      ),
      const SizedBox(height: 14),
      _oMatKhau(
        controller: _matKhauController,
        label: 'Mật khẩu',
        dangHien: _hienMatKhau,
        onDoiTrangThai: () => setState(() => _hienMatKhau = !_hienMatKhau),
      ),
      if (_laDangKy) ...[
        const SizedBox(height: 14),
        _oMatKhau(
          controller: _xacNhanMatKhauController,
          label: 'Xác nhận mật khẩu',
          dangHien: _hienXacNhanMatKhau,
          onDoiTrangThai: () =>
              setState(() => _hienXacNhanMatKhau = !_hienXacNhanMatKhau),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField(
          value: _vaiTro,
          items: const [
            DropdownMenuItem(value: 'sinh_vien', child: Text('Sinh viên')),
            DropdownMenuItem(value: 'giang_vien', child: Text('Giảng viên')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _vaiTro = value);
          },
          decoration: const InputDecoration(
            labelText: 'Vai trò',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
      ],
    ];
  }

  String get _nhanNutChinh => _laDangNhap ? 'Đăng nhập' : 'Đăng ký';

  IconData get _bieuTuongNutChinh => Icons.login;

  VoidCallback? get _hanhDongNutChinh => _dangXuLy ? null : _xuLyDangNhapDangKy;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final tieuDe = _laDangNhap ? 'Chào mừng trở lại' : 'Tạo tài khoản mới';
    final moTa = _laDangNhap
        ? 'Đăng nhập để quản lý lớp, nhóm và đề tài đồ án.'
        : 'Điền thông tin để tạo tài khoản.';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mau.primaryContainer, mau.surface, mau.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: mau.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 42,
                          color: mau.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hệ thống đăng ký nhóm và chọn đề tài',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      _thanhCheDo(mau),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tieuDe,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              moTa,
                              style: TextStyle(color: mau.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._cacTruongTheoCheDo(mau),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _hanhDongNutChinh,
                          icon: _dangXuLy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Icon(_bieuTuongNutChinh),
                          label: Text(_nhanNutChinh),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
