import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../dich_vu/dich_vu_du_lieu.dart';
import '../../mo_hinh/ho_so_nguoi_dung.dart';
import '../../tien_ich/thong_bao.dart';
import '../thanh_phan/khung_trang_hien_dai.dart';

/// Kiểu dữ liệu của một trường trong biểu mẫu CRUD.
enum KieuTruong {
  vanBan,
  vanBanNhieuDong,
  soNguyen,
  soThuc,
  boolean,
  ngay,
  ngayGio,
  luaChon,
}

/// Một mục lựa chọn hiển thị trong combobox.
class LuaChonMuc {
  const LuaChonMuc({required this.giaTri, required this.nhan});

  final dynamic giaTri;
  final String nhan;
}

/// Cấu hình cho một trường nhập liệu.
class TruongBieuMau {
  const TruongBieuMau({
    required this.tenTruong,
    required this.nhan,
    required this.kieu,
    this.batBuoc = false,
    this.chiDoc = false,
    this.hienThiTrongBieuMau = true,
    this.goiY,
    this.giaTriMacDinh,
    this.giaTriToiThieu,
    this.giaTriToiDa,
    this.doDaiToiThieu,
    this.doDaiToiDa,
    this.bieuThucHopLe,
    this.thongBaoBieuThuc,
    this.luaChonTinh,
    this.taiLuaChon,
    this.taiLuaChonTheoDuLieu,
    this.phuThuocTruong,
  });

  final String tenTruong;
  final String nhan;
  final KieuTruong kieu;
  final bool batBuoc;
  final bool chiDoc;
  final dynamic hienThiTrongBieuMau;
  final String? goiY;
  final dynamic giaTriMacDinh;
  final num? giaTriToiThieu;
  final num? giaTriToiDa;
  final int? doDaiToiThieu;
  final int? doDaiToiDa;
  final RegExp? bieuThucHopLe;
  final String? thongBaoBieuThuc;
  final List<LuaChonMuc>? luaChonTinh;
  final Future<List<LuaChonMuc>> Function()? taiLuaChon;


  final Future<List<LuaChonMuc>> Function(Map<String, dynamic> duLieuHienTai)?
      taiLuaChonTheoDuLieu;

   final String? phuThuocTruong;
}

/// Cấu hình cho một cột hiển thị trên bảng.
class CotBang {
  const CotBang({
    required this.tenTruong,
    required this.nhan,
    this.hienThi = true,
    this.canGiua = false,
    this.hamDinhDang,
  });

  final String tenTruong;
  final String nhan;
  final bool hienThi;
  final bool canGiua;
  final String Function(dynamic giaTri, Map<String, dynamic> dong)? hamDinhDang;
}

/// Hàm dùng để biến đổi dữ liệu trước khi lưu vào Supabase.
typedef HamXuLyTruocKhiLuu =
    FutureOr<Map<String, dynamic>> Function(
      Map<String, dynamic> duLieuMoi,
      Map<String, dynamic>? duLieuCu,
    );

/// Hàm kiểm tra chéo dữ liệu trong biểu mẫu trước khi đóng hộp thoại.
typedef HamKiemTraBieuMau =
    String? Function(
      Map<String, dynamic> duLieuMoi,
      Map<String, dynamic>? duLieuCu,
    );

/// Widget CRUD tổng quát để tái sử dụng cho hầu hết các bảng trong hệ thống.
class TrangQuanLyCoBan extends StatefulWidget {
  const TrangQuanLyCoBan({
    super.key,
    required this.tieuDe,
    required this.moTa,
    required this.bang,
    required this.hoSo,
    required this.danhSachCot,
    required this.danhSachTruong,
    this.selectClause = '*',
    this.sapXepTheo,
    this.khoaChinh = 'id',
    this.duocThem = true,
    this.duocSua = true,
    this.duocXoa = true,
    this.tieuDeNutThem = 'Thêm mới',
    this.hamXuLyTruocKhiLuu,
    this.hamKiemTraBieuMau,
    this.boLoc,
    this.hamKiemTraTruocKhiXoa,
    this.onRowTap,
    this.hamLocDuLieu,
    this.boLocTuyChinh,
    this.nutHanhDongBoSung,
  });

  final List<Widget> Function(Map<String, dynamic> banGhi, void Function() taiLaiDuLieu)? nutHanhDongBoSung;
  final String tieuDe;
  final String moTa;
  final String bang;
  final HoSoNguoiDung hoSo;
  final List<CotBang> danhSachCot;
  final List<TruongBieuMau> danhSachTruong;
  final String selectClause;
  final String? sapXepTheo;
  final String khoaChinh;
  final bool duocThem;
  final dynamic duocSua;
  final dynamic duocXoa;
  final String tieuDeNutThem;
  final HamXuLyTruocKhiLuu? hamXuLyTruocKhiLuu;
  final HamKiemTraBieuMau? hamKiemTraBieuMau;
  final Map<String, dynamic>? boLoc;
  final String? Function(Map<String, dynamic> banGhi)? hamKiemTraTruocKhiXoa;
  final void Function(Map<String, dynamic> banGhi)? onRowTap;
  final List<Map<String, dynamic>> Function(List<Map<String, dynamic>> duLieu)?
      hamLocDuLieu;
  final List<Widget>? boLocTuyChinh;

  @override
  State<TrangQuanLyCoBan> createState() => _TrangQuanLyCoBanState();
}

class _TrangQuanLyCoBanState extends State<TrangQuanLyCoBan> {
  final DichVuDuLieu _dichVuDuLieu = DichVuDuLieu();
  final TextEditingController _timKiemController = TextEditingController();
  final DateFormat _dinhDangNgay = DateFormat('dd/MM/yyyy');
  final DateFormat _dinhDangNgayGio = DateFormat('dd/MM/yyyy HH:mm');

  bool _dangTai = true;
  List<Map<String, dynamic>> _duLieu = <Map<String, dynamic>>[];
  String _tuKhoa = '';

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

  /// Tải lại dữ liệu từ Supabase và cập nhật giao diện.
  Future<void> _taiDuLieu() async {
    setState(() => _dangTai = true);

    try {
      final duLieu = await _dichVuDuLieu.layDanhSach(
        bang: widget.bang,
        selectClause: widget.selectClause,
        sapXepTheo: widget.sapXepTheo,
        boLoc: widget.boLoc,
      );

      if (!mounted) return;
      setState(() {
        _duLieu = duLieu;
      });
    } catch (loi, st) {
      if (!mounted) return;
      ThongBao.loi(context, loi, st);
    } finally {
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  bool _coQuyenSua(Map<String, dynamic> dong) {
    final ds = widget.duocSua;
    if (ds is bool) return ds;
    if (ds is bool Function(Map<String, dynamic>)) {
      return ds(dong);
    }
    return true;
  }

  bool _coQuyenXoa(Map<String, dynamic> dong) {
    final dx = widget.duocXoa;
    if (dx is bool) return dx;
    if (dx is bool Function(Map<String, dynamic>)) {
      return dx(dong);
    }
    return true;
  }

  /// Trả về danh sách dữ liệu sau khi lọc theo từ khoá tìm kiếm.
  List<Map<String, dynamic>> get _duLieuSauLoc {
    var duLieuNguon = _duLieu;
    if (widget.hamLocDuLieu != null) {
      duLieuNguon = widget.hamLocDuLieu!(duLieuNguon);
    }
    return _dichVuDuLieu.timKiemCucBo(duLieuNguon, _tuKhoa);
  }

  /// Lấy giá trị của một trường theo cú pháp `a.b.c` để hỗ trợ join.
  dynamic _layGiaTri(Map<String, dynamic> banGhi, String duongDan) {
    dynamic hienTai = banGhi;
    for (final phan in duongDan.split('.')) {
      if (hienTai is Map<String, dynamic>) {
        hienTai = hienTai[phan];
      } else {
        return null;
      }
    }
    return hienTai;
  }

  /// Chuyển giá trị thô thành chuỗi đẹp để hiển thị trên bảng.
  String _chuyenThanhChuoi(
    dynamic giaTri,
    CotBang cot,
    Map<String, dynamic> dong,
  ) {
    if (cot.hamDinhDang != null) {
      return cot.hamDinhDang!(giaTri, dong);
    }

    if (giaTri == null) return '—';
    if (giaTri is bool) return giaTri ? 'Có' : 'Không';

    final chuoi = giaTri.toString();
    final kieuNgay = DateTime.tryParse(chuoi);
    if (kieuNgay != null && chuoi.contains('-')) {
      if (chuoi.contains(':')) {
        return _dinhDangNgayGio.format(kieuNgay.toLocal());
      }
      return _dinhDangNgay.format(kieuNgay.toLocal());
    }

    return chuoi;
  }

  String? _kiemTraGiaTriTruong(TruongBieuMau truong, String? value) {
    final chuoi = value?.trim() ?? '';

    if (truong.batBuoc && chuoi.isEmpty) {
      return 'Vui lòng nhập ${truong.nhan.toLowerCase()}.';
    }

    if (chuoi.isEmpty) return null;

    if (truong.doDaiToiThieu != null && chuoi.length < truong.doDaiToiThieu!) {
      return '${truong.nhan} phải có ít nhất ${truong.doDaiToiThieu} ký tự.';
    }

    if (truong.doDaiToiDa != null && chuoi.length > truong.doDaiToiDa!) {
      return '${truong.nhan} không được vượt quá ${truong.doDaiToiDa} ký tự.';
    }

    if (truong.bieuThucHopLe != null &&
        !truong.bieuThucHopLe!.hasMatch(chuoi)) {
      return truong.thongBaoBieuThuc ?? '${truong.nhan} không đúng định dạng.';
    }

    if (truong.kieu == KieuTruong.soNguyen) {
      final so = int.tryParse(chuoi);
      if (so == null) {
        return '${truong.nhan} phải là số nguyên.';
      }

      if (truong.giaTriToiThieu != null && so < truong.giaTriToiThieu!) {
        return '${truong.nhan} phải từ ${truong.giaTriToiThieu} trở lên.';
      }

      if (truong.giaTriToiDa != null && so > truong.giaTriToiDa!) {
        return '${truong.nhan} không được vượt quá ${truong.giaTriToiDa}.';
      }
    }

    if (truong.kieu == KieuTruong.soThuc) {
      final so = double.tryParse(chuoi);
      if (so == null) {
        return '${truong.nhan} phải là số.';
      }

      if (truong.giaTriToiThieu != null && so < truong.giaTriToiThieu!) {
        return '${truong.nhan} phải từ ${truong.giaTriToiThieu} trở lên.';
      }

      if (truong.giaTriToiDa != null && so > truong.giaTriToiDa!) {
        return '${truong.nhan} không được vượt quá ${truong.giaTriToiDa}.';
      }
    }

    return null;
  }

  /// Mở hộp thoại nhập liệu để thêm hoặc sửa một bản ghi.
  Future<Map<String, dynamic>?> _moHopThoaiNhapLieu({
    Map<String, dynamic>? duLieuBanDau,
  }) async {
    final formKey = GlobalKey<FormState>();
    final duLieuLamViec = <String, dynamic>{};
    if (duLieuBanDau != null) {
      duLieuLamViec.addAll(duLieuBanDau);
    }

    for (final truong in widget.danhSachTruong) {
      duLieuLamViec[truong.tenTruong] ??= truong.giaTriMacDinh;
    }

    final nguonLuaChon = <String, List<LuaChonMuc>>{};

    Future<List<LuaChonMuc>> taiLuaChonChoTruong(
      TruongBieuMau truong,
    ) async {
      if (truong.taiLuaChonTheoDuLieu != null) {
        return truong.taiLuaChonTheoDuLieu!(
          Map<String, dynamic>.from(duLieuLamViec),
        );
      }
      if (truong.taiLuaChon != null) {
        return truong.taiLuaChon!.call();
      }
      if (truong.luaChonTinh != null) {
        return truong.luaChonTinh!;
      }
      return const <LuaChonMuc>[];
    }

    for (final truong in widget.danhSachTruong) {
      if (truong.taiLuaChon != null ||
          truong.luaChonTinh != null ||
          truong.taiLuaChonTheoDuLieu != null) {
        nguonLuaChon[truong.tenTruong] = await taiLuaChonChoTruong(truong);
      }
    }

    if (!mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> taiLaiTruongPhuThuoc(String truongCha) async {
              final danhSachPhuThuoc = widget.danhSachTruong
                  .where((truong) => truong.phuThuocTruong == truongCha)
                  .toList(growable: false);

              for (final truongPhuThuoc in danhSachPhuThuoc) {
                final luaChonMoi = await taiLuaChonChoTruong(truongPhuThuoc);
                if (!context.mounted) return;

                setDialogState(() {
                  nguonLuaChon[truongPhuThuoc.tenTruong] = luaChonMoi;

                  final giaTriHienTai =
                      duLieuLamViec[truongPhuThuoc.tenTruong];
                  final conTonTai = luaChonMoi.any(
                    (muc) => muc.giaTri == giaTriHienTai,
                  );

                  if (!conTonTai) {
                    duLieuLamViec[truongPhuThuoc.tenTruong] = null;
                  }
                });

                await taiLaiTruongPhuThuoc(truongPhuThuoc.tenTruong);
              }
            }

            Future<void> chonNgay(String truongTen) async {
              final banDau =
                  DateTime.tryParse(
                    duLieuLamViec[truongTen]?.toString() ?? '',
                  ) ??
                  DateTime.now();

              final ngay = await showDatePicker(
                context: context,
                initialDate: banDau,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (ngay != null) {
                setDialogState(() {
                  duLieuLamViec[truongTen] = DateFormat(
                    'yyyy-MM-dd',
                  ).format(ngay);
                });
              }
            }

            Future<void> chonNgayGio(String truongTen) async {
              final banDau =
                  DateTime.tryParse(
                    duLieuLamViec[truongTen]?.toString() ?? '',
                  ) ??
                  DateTime.now();

              final ngay = await showDatePicker(
                context: context,
                initialDate: banDau,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (ngay == null) return;

              if (!context.mounted) return;
              final gio = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(banDau),
              );

              if (!context.mounted) return;

              final gioChon = gio ?? const TimeOfDay(hour: 0, minute: 0);
              final ketQua = DateTime(
                ngay.year,
                ngay.month,
                ngay.day,
                gioChon.hour,
                gioChon.minute,
              );

              setDialogState(() {
                duLieuLamViec[truongTen] = ketQua.toIso8601String();
              });
            }

            return AlertDialog(
              title: Text(
                duLieuBanDau == null ? 'Thêm bản ghi' : 'Cập nhật bản ghi',
              ),
              content: SizedBox(
                width: 640,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.danhSachTruong
                          .where((truong) {
                            final hienThi = truong.hienThiTrongBieuMau;
                            if (hienThi is bool) {
                              return hienThi;
                            }
                            if (hienThi is bool Function(Map<String, dynamic>)) {
                              return hienThi(duLieuLamViec);
                            }
                            return true;
                          })
                          .map((truong) {
                            final giaTri = duLieuLamViec[truong.tenTruong];
                            final luaChon = nguonLuaChon[truong.tenTruong];
                            final coGiaTriTrongLuaChon =
                                luaChon?.any((muc) => muc.giaTri == giaTri) ??
                                false;

                            switch (truong.kieu) {
                              case KieuTruong.boolean:
                                return SwitchListTile(
                                  value: giaTri == true,
                                  onChanged: truong.chiDoc
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            duLieuLamViec[truong.tenTruong] =
                                                value;
                                          });
                                        },
                                  title: Text(truong.nhan),
                                );
                              case KieuTruong.luaChon:
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DropdownButtonFormField<dynamic>(
                                    key: ValueKey(
                                      '${truong.tenTruong}_${giaTri ?? ''}_${luaChon?.map((muc) => muc.giaTri).join('|') ?? ''}',
                                    ),
                                    initialValue: coGiaTriTrongLuaChon
                                        ? giaTri
                                        : null,
                                    items: (luaChon ?? [])
                                        .map(
                                          (muc) => DropdownMenuItem<dynamic>(
                                            value: muc.giaTri,
                                            child: Text(
                                              muc.nhan,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    isExpanded: true,
                                    hint: Text(
                                      (luaChon == null || luaChon.isEmpty)
                                          ? 'Chưa có dữ liệu để chọn'
                                          : (truong.goiY ??
                                                'Chọn ${truong.nhan.toLowerCase()}'),
                                    ),
                                    onChanged:
                                        truong.chiDoc ||
                                            luaChon == null ||
                                            luaChon.isEmpty
                                        ? null
                                        : (value) async {
                                            setDialogState(() {
                                              duLieuLamViec[truong.tenTruong] =
                                                  value;
                                            });
                                            await taiLaiTruongPhuThuoc(
                                              truong.tenTruong,
                                            );
                                          },
                                    decoration: InputDecoration(
                                      labelText: truong.nhan,
                                      hintText: truong.goiY,
                                    ),
                                    validator: (value) {
                                      if (truong.batBuoc &&
                                          (luaChon == null ||
                                              luaChon.isEmpty)) {
                                        return 'Chưa có dữ liệu ${truong.nhan.toLowerCase()} để chọn.';
                                      }

                                      if (truong.batBuoc && value == null) {
                                        return 'Vui lòng chọn ${truong.nhan.toLowerCase()}.';
                                      }

                                      return null;
                                    },
                                  ),
                                );
                              case KieuTruong.ngay:
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    key: ValueKey(
                                      '${truong.tenTruong}_${giaTri ?? ''}',
                                    ),
                                    readOnly: true,
                                    initialValue: giaTri?.toString() ?? '',
                                    onTap: truong.chiDoc
                                        ? null
                                        : () => chonNgay(truong.tenTruong),
                                    decoration: InputDecoration(
                                      labelText: truong.nhan,
                                      hintText: truong.goiY,
                                      suffixIcon: IconButton(
                                        onPressed: truong.chiDoc
                                            ? null
                                            : () => chonNgay(truong.tenTruong),
                                        icon: const Icon(Icons.calendar_month),
                                      ),
                                    ),
                                    validator: (value) =>
                                        _kiemTraGiaTriTruong(truong, value),
                                  ),
                                );
                              case KieuTruong.ngayGio:
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    key: ValueKey(
                                      '${truong.tenTruong}_${giaTri ?? ''}',
                                    ),
                                    readOnly: true,
                                    initialValue: giaTri?.toString() ?? '',
                                    onTap: truong.chiDoc
                                        ? null
                                        : () => chonNgayGio(truong.tenTruong),
                                    decoration: InputDecoration(
                                      labelText: truong.nhan,
                                      hintText: truong.goiY,
                                      suffixIcon: IconButton(
                                        onPressed: truong.chiDoc
                                            ? null
                                            : () =>
                                                  chonNgayGio(truong.tenTruong),
                                        icon: const Icon(Icons.schedule),
                                      ),
                                    ),
                                    validator: (value) =>
                                        _kiemTraGiaTriTruong(truong, value),
                                  ),
                                );
                              case KieuTruong.vanBanNhieuDong:
                              case KieuTruong.vanBan:
                              case KieuTruong.soNguyen:
                              case KieuTruong.soThuc:
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    initialValue: giaTri?.toString() ?? '',
                                    readOnly: truong.chiDoc,
                                    minLines:
                                        truong.kieu ==
                                            KieuTruong.vanBanNhieuDong
                                        ? 3
                                        : 1,
                                    maxLines:
                                        truong.kieu ==
                                            KieuTruong.vanBanNhieuDong
                                        ? 5
                                        : 1,
                                    keyboardType:
                                        truong.kieu == KieuTruong.soNguyen
                                        ? TextInputType.number
                                        : truong.kieu == KieuTruong.soThuc
                                        ? const TextInputType.numberWithOptions(
                                            decimal: true,
                                          )
                                        : TextInputType.text,
                                    inputFormatters:
                                        truong.kieu == KieuTruong.soNguyen
                                        ? [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ]
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: truong.nhan,
                                      hintText: truong.goiY,
                                    ),
                                    onChanged: (value) {
                                      duLieuLamViec[truong.tenTruong] = value;
                                    },
                                    validator: (value) =>
                                        _kiemTraGiaTriTruong(truong, value),
                                  ),
                                );
                            }
                          })
                          .toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final duLieuKetQua = <String, dynamic>{};

                    for (final truong in widget.danhSachTruong) {
                      final giaTri = duLieuLamViec[truong.tenTruong];
                      if (giaTri == null ||
                          (giaTri is String && giaTri.isEmpty)) {
                        duLieuKetQua[truong.tenTruong] = null;
                        continue;
                      }

                      switch (truong.kieu) {
                        case KieuTruong.soNguyen:
                          duLieuKetQua[truong.tenTruong] = int.tryParse(
                            giaTri.toString(),
                          );
                          break;
                        case KieuTruong.soThuc:
                          duLieuKetQua[truong.tenTruong] = double.tryParse(
                            giaTri.toString(),
                          );
                          break;
                        default:
                          duLieuKetQua[truong.tenTruong] = giaTri;
                      }
                    }

                    final loiBieuMau = widget.hamKiemTraBieuMau?.call(
                      duLieuKetQua,
                      duLieuBanDau,
                    );
                    if (loiBieuMau != null) {
                      ThongBao.canhBao(context, loiBieuMau);
                      return;
                    }

                    Navigator.of(context).pop(duLieuKetQua);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _xacNhanNeuDoiTrangThaiQuanTrong({
    required Map<String, dynamic> duLieuMoi,
    required Map<String, dynamic>? duLieuCu,
  }) async {
    if (duLieuCu == null) return true;

    final trangThaiCu = duLieuCu['trang_thai']?.toString();
    final trangThaiMoi = duLieuMoi['trang_thai']?.toString();

    if (trangThaiMoi == null || trangThaiMoi == trangThaiCu) {
      return true;
    }

    const trangThaiCanXacNhan = {
      'da_duyet',
      'da_khoa',
      'da_cong_bo',
      'tu_choi',
      'da_huy',
      'hoan_thanh',
      'luu_tru',
    };

    if (!trangThaiCanXacNhan.contains(trangThaiMoi)) {
      return true;
    }

    final tenTrangThai =
        {
          'da_duyet': 'Đã duyệt',
          'da_khoa': 'Đã khoá',
          'da_cong_bo': 'Đã công bố',
          'tu_choi': 'Từ chối',
          'da_huy': 'Đã huỷ',
          'hoan_thanh': 'Hoàn thành',
          'luu_tru': 'Lưu trữ',
        }[trangThaiMoi] ??
        trangThaiMoi;

    return ThongBao.xacNhan(
      context,
      tieuDe: 'Xác nhận đổi trạng thái',
      noiDung:
          'Bạn đang đổi trạng thái bản ghi sang "$tenTrangThai". Thao tác này có thể ảnh hưởng đến quy trình xử lý dữ liệu. Bạn có chắc muốn tiếp tục không?',
      nhanDongY: 'Tiếp tục lưu',
      nguyHiem:
          trangThaiMoi == 'tu_choi' ||
          trangThaiMoi == 'da_huy' ||
          trangThaiMoi == 'da_khoa',
    );
  }

  /// Xử lý thêm bản ghi mới.
  Future<void> _themBanGhi() async {
    try {
      final duLieuMoi = await _moHopThoaiNhapLieu();
      if (duLieuMoi == null) return;

      final duLieuCanLuu = widget.hamXuLyTruocKhiLuu == null
          ? duLieuMoi
          : await widget.hamXuLyTruocKhiLuu!(duLieuMoi, null);

      await _dichVuDuLieu.themBanGhi(
        bang: widget.bang,
        duLieu: duLieuCanLuu,
        khoaChinh: widget.khoaChinh,
      );

      if (!mounted) return;
      ThongBao.thanhCong(context, 'Đã thêm dữ liệu thành công.');
      await Future.delayed(const Duration(milliseconds: 300));
      await _taiDuLieu();
    } catch (loi, st) {
      if (!mounted) return;
      ThongBao.loi(context, loi, st);
    }
  }

  /// Xử lý cập nhật bản ghi đã có.
  Future<void> _suaBanGhi(Map<String, dynamic> banGhiCu) async {
    try {
      final duLieuMoi = await _moHopThoaiNhapLieu(duLieuBanDau: banGhiCu);
      if (duLieuMoi == null) return;

      final dongYdoiTrangThai = await _xacNhanNeuDoiTrangThaiQuanTrong(
        duLieuMoi: duLieuMoi,
        duLieuCu: banGhiCu,
      );

      if (!dongYdoiTrangThai) return;

      final duLieuCanLuu = widget.hamXuLyTruocKhiLuu == null
          ? duLieuMoi
          : await widget.hamXuLyTruocKhiLuu!(duLieuMoi, banGhiCu);

      await _dichVuDuLieu.capNhatBanGhi(
        bang: widget.bang,
        id: banGhiCu[widget.khoaChinh],
        duLieu: duLieuCanLuu,
        khoaChinh: widget.khoaChinh,
      );

      if (!mounted) return;
      ThongBao.thanhCong(context, 'Đã cập nhật dữ liệu.');
      await Future.delayed(const Duration(milliseconds: 300));
      await _taiDuLieu();
    } catch (loi, st) {
      if (!mounted) return;
      ThongBao.loi(context, loi, st);
    }
  }

  /// Xử lý xoá bản ghi.
  Future<void> _xoaBanGhi(Map<String, dynamic> banGhi) async {
    if (widget.hamKiemTraTruocKhiXoa != null) {
      final loi = widget.hamKiemTraTruocKhiXoa!(banGhi);
      if (loi != null) {
        ThongBao.canhBao(context, loi);
        return;
      }
    }

    final dongY = await ThongBao.xacNhan(
      context,
      tieuDe: 'Xoá dữ liệu',
      noiDung: 'Bạn có chắc muốn xoá bản ghi này không?',
    );

    if (!dongY) return;

    try {
      await _dichVuDuLieu.xoaBanGhi(
        bang: widget.bang,
        id: banGhi[widget.khoaChinh],
        khoaChinh: widget.khoaChinh,
      );

      if (!mounted) return;
      ThongBao.thanhCong(context, 'Đã xoá dữ liệu.');
      await _taiDuLieu();
    } catch (loi, st) {
      if (!mounted) return;
      ThongBao.loi(context, loi, st);
    }
  }

  Color _mauTrangThai(String giaTri) {
    switch (giaTri) {
      case 'da_duyet':
      case 'da_cong_bo':
      case 'da_gui':
      case 'da_gan_nhom':
      case 'da_chap_nhan':
      case 'da_xem':
      case 'hoan_thanh':
        return Colors.green.shade700;

      case 'cho_duyet':
      case 'dang_tao':
      case 'ban_nhap':
        return Colors.orange.shade700;

      case 'tu_choi':
      case 'da_huy':
      case 'huy':
      case 'da_roi':
      case 'bi_xoa':
        return Colors.red.shade700;

      case 'da_khoa':
      case 'dong':
      case 'dong_dang_ky':
      case 'luu_tru':
        return Colors.blueGrey.shade700;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _xayDungGiaTri(
    CotBang cot,
    dynamic giaTri,
    Map<String, dynamic> dong,
  ) {
    final chuoi = _chuyenThanhChuoi(giaTri, cot, dong);
    if (cot.tenTruong == 'trang_thai') {
      final mau = _mauTrangThai(giaTri?.toString() ?? '');
      return Chip(
        label: Text(
          chuoi,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: mau,
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
      );
    }

    return Text(chuoi, maxLines: 3, overflow: TextOverflow.ellipsis);
  }

  /// Xây dựng bảng hiển thị trên màn hình lớn.
  Widget _xayDungBang(List<Map<String, dynamic>> duLieu) {
    final cotHienThi = widget.danhSachCot
        .where((cot) => cot.hienThi)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [
            ...cotHienThi.map((cot) => DataColumn(label: Text(cot.nhan))),
            const DataColumn(label: Text('Tác vụ')),
          ],
          rows: duLieu.map((dong) {
            return DataRow(
              onSelectChanged: widget.onRowTap != null
                  ? (selected) {
                      if (selected == true) {
                        widget.onRowTap!(dong);
                      }
                    }
                  : null,
              cells: [
                ...cotHienThi.map((cot) {
                  final giaTri = _layGiaTri(dong, cot.tenTruong);
                  return DataCell(
                    Align(
                      alignment: cot.canGiua
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: SizedBox(
                        width: 180,
                        child: _xayDungGiaTri(cot, giaTri, dong),
                      ),
                    ),
                  );
                }),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      if (widget.nutHanhDongBoSung != null)
                        ...widget.nutHanhDongBoSung!(dong, _taiDuLieu),
                      if (widget.onRowTap != null)
                        IconButton.filledTonal(
                          tooltip: 'Xem sinh viên',
                          onPressed: () => widget.onRowTap!(dong),
                          icon: const Icon(Icons.people_outline),
                        ),
                      if (_coQuyenSua(dong))
                        IconButton.filledTonal(
                          tooltip: 'Sửa',
                          onPressed: () => _suaBanGhi(dong),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      if (_coQuyenXoa(dong))
                        IconButton.filledTonal(
                          tooltip: 'Xoá',
                          onPressed: () => _xoaBanGhi(dong),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Xây dựng giao diện dạng thẻ trên màn hình nhỏ.
  Widget _xayDungDanhSachThe(List<Map<String, dynamic>> duLieu) {
    final cotHienThi = widget.danhSachCot
        .where((cot) => cot.hienThi)
        .toList(growable: false);

    return Column(
      children: duLieu.map((dong) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onRowTap != null ? () => widget.onRowTap!(dong) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...cotHienThi.map((cot) {
                    final giaTri = _layGiaTri(dong, cot.tenTruong);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${cot.nhan}: ',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: _chuyenThanhChuoi(giaTri, cot, dong)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 26),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (widget.nutHanhDongBoSung != null)
                        ...widget.nutHanhDongBoSung!(dong, _taiDuLieu),
                      if (widget.onRowTap != null)
                        FilledButton.tonalIcon(
                          onPressed: () => widget.onRowTap!(dong),
                          icon: const Icon(Icons.people_outline),
                          label: const Text('Sinh viên'),
                        ),
                      if (_coQuyenSua(dong))
                        FilledButton.tonalIcon(
                          onPressed: () => _suaBanGhi(dong),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Sửa'),
                        ),
                      if (_coQuyenXoa(dong))
                        FilledButton.tonalIcon(
                          onPressed: () => _xoaBanGhi(dong),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xoá'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duLieuSauLoc = _duLieuSauLoc;

    return KhungTrangHienDai(
      tieuDe: widget.tieuDe,
      moTa: widget.moTa,
      hanhDong: [
        FilledButton.icon(
          onPressed: _taiDuLieu,
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại'),
        ),
        if (widget.duocThem)
          FilledButton.icon(
            onPressed: _themBanGhi,
            icon: const Icon(Icons.add),
            label: Text(widget.tieuDeNutThem),
          ),
      ],
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timKiemController,
                  onChanged: (value) => setState(() => _tuKhoa = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Nhập từ khoá ...',
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
              ),
              if (widget.boLocTuyChinh != null) ...[
                const SizedBox(width: 12),
                ...widget.boLocTuyChinh!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hiển thị ${duLieuSauLoc.length}/${_duLieu.length} bản ghi',
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
          else if (duLieuSauLoc.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _duLieu.isEmpty
                    ? 'Chưa có dữ liệu. Bạn có thể thêm mới nếu có quyền thao tác.'
                    : 'Không thấy dữ liệu phù hợp "$_tuKhoa".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return _xayDungDanhSachThe(duLieuSauLoc);
                }
                return _xayDungBang(duLieuSauLoc);
              },
            ),
        ],
      ),
    );
  }
}
