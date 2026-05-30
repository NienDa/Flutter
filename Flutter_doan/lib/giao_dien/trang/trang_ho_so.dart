import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dich_vu/dich_vu_ho_so.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import '../thanh_phan/khung_trang_hien_dai.dart';

/// Trang cho phép người dùng xem và cập nhật hồ sơ cá nhân.
class TrangHoSo extends StatefulWidget {
  const TrangHoSo({
    super.key,
    required this.hoSo,
    required this.onDaCapNhat,
  });

  final HoSoNguoiDung hoSo;
  final Future<void> Function() onDaCapNhat;

  @override
  State<TrangHoSo> createState() => _TrangHoSoState();
}

class _TrangHoSoState extends State<TrangHoSo> {
  final _dichVuHoSo = DichVuHoSo();
  late final TextEditingController _hoTenController;
  late final TextEditingController _emailController;
  late final TextEditingController _vaiTroController;
  late final TextEditingController _soDienThoaiController;
  late final TextEditingController _lopController;
  late final TextEditingController _khoaController;
  late final TextEditingController _nganhController;
  late final TextEditingController _anhController;

  bool _dangLuu = false;
  bool _dangTaiAnh = false;

  Future<void> _chonVaTaiLenAnh() async {
    if (_dangTaiAnh) return;

    try {
      final ImagePicker boChon = ImagePicker();
      final XFile? anh = await boChon.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (anh == null) return;

      setState(() {
        _dangTaiAnh = true;
      });

      final bytes = await anh.readAsBytes();
      final duoiFile = anh.name.split('.').last.toLowerCase();
      final nguoiDungId = Supabase.instance.client.auth.currentUser?.id ?? 'anonym';
      final tenFile = '${nguoiDungId}_${DateTime.now().millisecondsSinceEpoch}.$duoiFile';

      final client = Supabase.instance.client;
      
      // Thử tự động tạo bucket 'avatars' chế độ công khai nếu chưa có
      try {
        await client.storage.createBucket(
          'avatars',
          const BucketOptions(public: true),
        );
      } catch (_) {
        // Bỏ qua nếu đã tồn tại hoặc không có quyền tạo (cần tạo bằng tay trên Console)
      }

      await client.storage.from('avatars').uploadBinary(
        tenFile,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$duoiFile',
          upsert: false,
        ),
      );

      final publicUrl = client.storage.from('avatars').getPublicUrl(tenFile);

      setState(() {
        _anhController.text = publicUrl;
        _dangTaiAnh = false;
      });

      if (mounted) {
        ThongBao.thanhCong(context, 'Tải ảnh lên thành công! Hãy nhấn "Lưu hồ sơ" để hoàn tất.');
      }
    } catch (e) {
      setState(() {
        _dangTaiAnh = false;
      });
      if (mounted) {
        ThongBao.loi(
          context,
          'Lỗi khi tải ảnh lên: $e\n\n'
          'Gợi ý: Hãy đảm bảo bạn đã tạo một storage bucket công khai tên là "avatars" trên Supabase console.',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _hoTenController = TextEditingController(text: widget.hoSo.hoTen);
    _emailController = TextEditingController(text: widget.hoSo.email ?? '');
    _vaiTroController = TextEditingController(text: widget.hoSo.nhanVaiTro);
    _soDienThoaiController =
        TextEditingController(text: widget.hoSo.soDienThoai ?? '');
    _lopController =
        TextEditingController(text: widget.hoSo.lopHanhChinh ?? '');
    _khoaController = TextEditingController(text: widget.hoSo.khoa ?? '');
    _nganhController = TextEditingController(text: widget.hoSo.nganh ?? '');
    _anhController =
        TextEditingController(text: widget.hoSo.anhDaiDienUrl ?? '');
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _emailController.dispose();
    _vaiTroController.dispose();
    _soDienThoaiController.dispose();
    _lopController.dispose();
    _khoaController.dispose();
    _nganhController.dispose();
    _anhController.dispose();
    super.dispose();
  }


  /// Lưu các trường hồ sơ mà người dùng được phép sửa.
  Future<void> _luuHoSo() async {
    final hoTen = _hoTenController.text.trim();
    final soDienThoai = _soDienThoaiController.text.trim();
    final anhUrl = _anhController.text.trim();

    if (hoTen.length < 3) {
      ThongBao.loi(context, 'Họ tên phải có ít nhất 3 ký tự.');
      return;
    }
    if (soDienThoai.isNotEmpty && !RegExp(r'^[0-9+ ]{9,15}$').hasMatch(soDienThoai)) {
      ThongBao.loi(context, 'Số điện thoại chỉ nên gồm số, dấu + hoặc khoảng trắng, từ 9 đến 15 ký tự.');
      return;
    }

    setState(() => _dangLuu = true);

    try {
      await _dichVuHoSo.capNhatHoSo({
        'ho_ten': hoTen,
        'so_dien_thoai': soDienThoai,
        'lop_hanh_chinh': _lopController.text.trim(),
        'khoa': _khoaController.text.trim(),
        'nganh': _nganhController.text.trim(),
        'anh_dai_dien_url': anhUrl,
      });

      if (!mounted) return;
      ThongBao.thanhCong(context, 'Đã cập nhật hồ sơ.');
      await widget.onDaCapNhat();
    } catch (loi) {
      if (!mounted) return;
      ThongBao.loi(context, loi);
    } finally {
      if (mounted) {
        setState(() => _dangLuu = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return KhungTrangHienDai(
      tieuDe: 'Chỉnh sửa hồ sơ cá nhân',
      hanhDong: [
        FilledButton.icon(
          onPressed: _dangLuu ? null : _luuHoSo,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu'),
        ),
      ],
      noiDung: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,

        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mau.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: mau.outlineVariant),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    InkWell(
                      onTap: _dangTaiAnh ? null : _chonVaTaiLenAnh,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: mau.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: mau.primaryContainer,
                          backgroundImage: _anhController.text.trim().isEmpty
                              ? null
                              : NetworkImage(_anhController.text.trim()),
                          child: _dangTaiAnh
                              ? const CircularProgressIndicator()
                              : (_anhController.text.trim().isEmpty
                                  ? Icon(Icons.person, color: mau.primary, size: 48)
                                  : null),
                        ),
                      ),
                    ),
                    if (!_dangTaiAnh)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: mau.primary,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: _dangTaiAnh ? null : _chonVaTaiLenAnh,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_dangTaiAnh ? 'Đang tải ảnh...' : 'Chọn ảnh đại diện'),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: mau.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: mau.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _hoTenController,
                        decoration: const InputDecoration(
                          labelText: 'Họ tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _vaiTroController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _soDienThoaiController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      if (widget.hoSo.laSinhVien) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _lopController,
                          decoration: const InputDecoration(
                            labelText: 'Lớp hành chính',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                        ),
                      ],
                      if (!widget.hoSo.laQuanTriVien) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: const ['Công nghệ thông tin', 'Trí tuệ nhân tạo'].contains(_khoaController.text.trim())
                              ? _khoaController.text.trim()
                              : null,
                          items: const [
                            DropdownMenuItem(value: 'Công nghệ thông tin', child: Text('Công nghệ thông tin')),
                            DropdownMenuItem(value: 'Trí tuệ nhân tạo', child: Text('Trí tuệ nhân tạo')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _khoaController.text = val ?? '';
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Khoa',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ],
                      if (widget.hoSo.laSinhVien) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: const [
                            'Công nghệ phần mềm',
                            'Công nghệ phần cứng',
                            'Khoa học dữ liệu',
                            'An toàn thông tin',
                            'Khoa học máy tính',
                            'An ninh mạng'
                          ].contains(_nganhController.text.trim())
                              ? _nganhController.text.trim()
                              : null,
                          items: const [
                            DropdownMenuItem(value: 'Công nghệ phần mềm', child: Text('Công nghệ phần mềm')),
                            DropdownMenuItem(value: 'Công nghệ phần cứng', child: Text('Công nghệ phần cứng')),
                            DropdownMenuItem(value: 'Khoa học dữ liệu', child: Text('Khoa học dữ liệu')),
                            DropdownMenuItem(value: 'An toàn thông tin', child: Text('An toàn thông tin')),
                            DropdownMenuItem(value: 'Khoa học máy tính', child: Text('Khoa học máy tính')),
                            DropdownMenuItem(value: 'An ninh mạng', child: Text('An ninh mạng')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _nganhController.text = val ?? '';
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Ngành',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                      ],
                    ],
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