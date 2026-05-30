# Ứng Dụng Quản Lý Đăng Ký Nhóm và Đề Tài (Flutter + Supabase)
Dự án phát triển ứng dụng di động hỗ trợ khoa và giảng viên quản lý việc đăng ký nhóm, chọn đề tài đồ án của sinh viên một cách tự động và minh bạch.
##  Tính năng nổi bật
* **Quản trị viên:** Quản lý tài khoản, tạo lớp đồ án, ghi danh sinh viên.
* **Giảng viên:** Thêm đề tài, quản lý nhóm, duyệt nguyện vọng chọn đề tài.
* **Sinh viên:** Đăng ký nhóm, quản lý thành viên, gửi nguyện vọng chọn đề tài.
* **Hệ thống tự động:** Giao diện quản lý (CRUD) động, bảo mật với Supabase RLS.
## Công nghệ sử dụng
* **Frontend:** Flutter & Dart (Sử dụng Material Design 3).
* **Backend:** Supabase (PostgreSQL, Authentication, Row-Level Security).
##  Hướng dẫn cài đặt
1. Clone dự án về máy: 
2. Cài đặt các package: `flutter pub get`
3. Cấu hình Supabase: 
   - Thay thế `supabaseUrl` và `supabaseKey` trong file `lib/main.dart` bằng thông tin project Supabase của bạn.
4. Chạy ứng dụng: `flutter run`
