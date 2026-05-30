class HoSoNguoiDung {
HoSoNguoiDung({
required this.id,
required this.hoTen,
required this.vaiTro,
this.email,
this.maSinhVien,
this.maGiangVien,
this.lopHanhChinh,
this.khoa,
this.nganh,
this.soDienThoai,
this.anhDaiDienUrl,
this.dangHoatDong = true,
});

final String id;
final String hoTen;
final String vaiTro;

final String? email;
final String? maSinhVien;
final String? maGiangVien;

final String? lopHanhChinh;

final String? khoa;
final String? nganh;

final String? soDienThoai;
final String? anhDaiDienUrl;

final bool dangHoatDong;

factory HoSoNguoiDung.tuMap(Map<String, dynamic> map) {
return HoSoNguoiDung(
id: map['id'].toString(),
hoTen: map['ho_ten'] ?? '',
vaiTro: map['vai_tro'] ?? 'sinh_vien',
email: map['email'],
maSinhVien: map['ma_sinh_vien'],
maGiangVien: map['ma_giang_vien'],

lopHanhChinh: map['lop_hanh_chinh'],
khoa: map['khoa'],
nganh: map['nganh'],
soDienThoai: map['so_dien_thoai'],
anhDaiDienUrl: map['anh_dai_dien_url'],
dangHoatDong: map['dang_hoat_dong'] ?? true,
);

}

Map<String, dynamic> sangMapThemMoi() {
return {
'id': id,
'ho_ten': hoTen,
'vai_tro': vaiTro,
'email': email,
'ma_sinh_vien': maSinhVien,
'ma_giang_vien': maGiangVien,
'lop_hanh_chinh': lopHanhChinh,
'khoa': khoa,
'nganh': nganh,
'so_dien_thoai': soDienThoai,
'anh_dai_dien_url': anhDaiDienUrl,
'dang_hoat_dong': dangHoatDong,
};
}

Map<String, dynamic> sangMapCapNhat() {
return {
'ho_ten': hoTen,
'lop_hanh_chinh': lopHanhChinh,
'khoa': khoa,
'nganh': nganh,
'so_dien_thoai': soDienThoai,
'anh_dai_dien_url': anhDaiDienUrl,
};
}

bool get laSinhVien => vaiTro == 'sinh_vien';

bool get laGiangVien => vaiTro == 'giang_vien';

bool get laQuanTriVien => vaiTro == 'quan_tri_vien';

String get nhanVaiTro {
switch (vaiTro) {
case 'giang_vien':
return 'Giảng viên';

  case 'quan_tri_vien':
    return 'Quản trị viên';

  default:
    return 'Sinh viên';
}


}
}
