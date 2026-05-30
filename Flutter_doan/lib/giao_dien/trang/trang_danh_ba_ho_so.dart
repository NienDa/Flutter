import 'package:flutter/material.dart';

import '../../mo_hinh/ho_so_nguoi_dung.dart';
import 'trang_quan_ly_co_ban.dart';

/// Trang danh bạ hồ sơ để quản trị viên rà soát người dùng.
class TrangDanhBaHoSo extends StatelessWidget {
  const TrangDanhBaHoSo({super.key, required this.hoSo});

  final HoSoNguoiDung hoSo;

  @override
  Widget build(BuildContext context) {
    return TrangQuanLyCoBan(
      tieuDe: 'Danh bạ hồ sơ',
      moTa:
          'Quản trị viên có thể tra cứu và cập nhật nhanh thông tin hồ sơ người dùng trong hệ thống.',
      bang: 'ho_so',
      hoSo: hoSo,
      duocThem: false,
      duocSua: hoSo.laQuanTriVien,
      duocXoa: false,
      sapXepTheo: 'ho_ten',
      hamLocDuLieu: (duLieu) => duLieu.where((dong) => dong['vai_tro'] != 'quan_tri_vien').toList(),
      danhSachCot: const [
        CotBang(tenTruong: 'ho_ten', nhan: 'Họ tên'),
        CotBang(tenTruong: 'email', nhan: 'Email'),
        CotBang(tenTruong: 'vai_tro', nhan: 'Vai trò'),
        CotBang(tenTruong: 'dang_hoat_dong', nhan: 'Hoạt động'),
      ],
      danhSachTruong: [
        TruongBieuMau(
          tenTruong: 'ho_ten',
          nhan: 'Họ tên',
          kieu: KieuTruong.vanBan,
          batBuoc: true,
          doDaiToiThieu: 3,
          doDaiToiDa: 100,
        ),
        TruongBieuMau(
          tenTruong: 'vai_tro',
          nhan: 'Vai trò',
          kieu: KieuTruong.luaChon,
          batBuoc: true,
          luaChonTinh: [
            LuaChonMuc(giaTri: 'sinh_vien', nhan: 'Sinh viên'),
            LuaChonMuc(giaTri: 'giang_vien', nhan: 'Giảng viên'),
          ],
        ),
        TruongBieuMau(
          tenTruong: 'ma_sinh_vien',
          nhan: 'Mã số',
          kieu: KieuTruong.vanBan,
          doDaiToiThieu: 5,
          doDaiToiDa: 30,
          bieuThucHopLe: RegExp(r'^[A-Z0-9_\-]+$'),
          thongBaoBieuThuc:
              'Mã số chỉ gồm chữ in hoa, số, dấu gạch ngang hoặc gạch dưới.',
          hienThiTrongBieuMau: (duLieu) => duLieu['vai_tro'] == 'sinh_vien',
        ),
        TruongBieuMau(
          tenTruong: 'ma_giang_vien',
          nhan: 'Mã số',
          kieu: KieuTruong.vanBan,
          doDaiToiThieu: 3,
          doDaiToiDa: 30,
          bieuThucHopLe: RegExp(r'^[A-Z0-9_\-]+$'),
          thongBaoBieuThuc:
              'Mã số chỉ gồm chữ in hoa, số, dấu gạch ngang hoặc gạch dưới.',
          hienThiTrongBieuMau: (duLieu) => duLieu['vai_tro'] == 'giang_vien',
        ),
        TruongBieuMau(
          tenTruong: 'lop_hanh_chinh',
          nhan: 'Lớp hành chính',
          kieu: KieuTruong.vanBan,
          hienThiTrongBieuMau: (duLieu) => duLieu['vai_tro'] == 'sinh_vien',
        ),
        TruongBieuMau(
          tenTruong: 'khoa',
          nhan: 'Khoa',
          kieu: KieuTruong.luaChon,
          luaChonTinh: const [
            LuaChonMuc(giaTri: 'Công nghệ thông tin', nhan: 'Công nghệ thông tin'),
            LuaChonMuc(giaTri: 'Trí tuệ nhân tạo', nhan: 'Trí tuệ nhân tạo'),
          ],
        ),
        TruongBieuMau(
          tenTruong: 'nganh',
          nhan: 'Ngành',
          kieu: KieuTruong.luaChon,
          hienThiTrongBieuMau: (duLieu) => duLieu['vai_tro'] == 'sinh_vien',
          luaChonTinh: const [
            LuaChonMuc(giaTri: 'Công nghệ phần mềm', nhan: 'Công nghệ phần mềm'),
            LuaChonMuc(giaTri: 'Công nghệ phần cứng', nhan: 'Công nghệ phần cứng'),
            LuaChonMuc(giaTri: 'Khoa học dữ liệu', nhan: 'Khoa học dữ liệu'),
            LuaChonMuc(giaTri: 'An toàn thông tin', nhan: 'An toàn thông tin'),
            LuaChonMuc(giaTri: 'Khoa học máy tính', nhan: 'Khoa học máy tính'),
            LuaChonMuc(giaTri: 'An ninh mạng', nhan: 'An ninh mạng'),
          ],
        ),
        TruongBieuMau(
          tenTruong: 'so_dien_thoai',
          nhan: 'Số điện thoại',
          kieu: KieuTruong.vanBan,
          doDaiToiThieu: 10,
          doDaiToiDa: 11,
          bieuThucHopLe: RegExp(r'^(0|\+84)[0-9]{9,10}$'),
          thongBaoBieuThuc:
              'Số điện thoại phải bắt đầu bằng 0 hoặc +84 và có độ dài hợp lệ.',
        ),
        TruongBieuMau(
          tenTruong: 'dang_hoat_dong',
          nhan: 'Đang hoạt động',
          kieu: KieuTruong.boolean,
          giaTriMacDinh: true,
        ),
      ],
    );
  }
}
