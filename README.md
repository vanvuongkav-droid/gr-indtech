# GR-INDTECH

Ứng dụng web quản lý công việc, dự án, nhân sự phòng ban và năng lực dự án cho doanh nghiệp xây dựng.

## Cấu trúc

- `dist/`: ứng dụng web tĩnh sẵn sàng triển khai.
- `database/schema.sql`: lược đồ PostgreSQL dành cho Neon.
- `vercel.json`: cấu hình triển khai Vercel.
- `.env.example`: mẫu biến môi trường, không chứa thông tin bí mật.

## Triển khai trên Vercel

1. Nhập kho GitHub vào Vercel.
2. Chọn framework `Other` nếu Vercel yêu cầu.
3. Giữ thư mục đầu ra là `dist` theo `vercel.json`.
4. Thêm `DATABASE_URL` trong Vercel Project Settings khi kích hoạt API kết nối Neon.

Không đưa tệp `.env` hoặc chuỗi kết nối Neon thật lên GitHub.

