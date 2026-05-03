# LocaVN — Tài Liệu Mô Tả Ứng Dụng CSDL Xăng Dầu

**Phiên bản:** 1.0  
**Nền tảng:** Flutter (iOS & Android)  
**Backend:** ASP.NET Core + SQL Server  
**Cập nhật:** 2026  

---

## 1. Tổng Quan

**LocaVN** là ứng dụng di động thuộc hệ thống **Cơ sở dữ liệu xăng dầu**, phục vụ công tác tra cứu, cập nhật, giám sát và phản ánh thông tin liên quan đến hoạt động kinh doanh xăng dầu.

Ứng dụng hướng tới việc kết nối dữ liệu giữa:

- Người dân / khách hàng sử dụng xăng dầu
- Cửa hàng bán lẻ xăng dầu
- Doanh nghiệp đầu mối / thương nhân phân phối
- Cơ quan quản lý nhà nước
- Lãnh đạo theo dõi, điều hành và giám sát thị trường

LocaVN không phải là ứng dụng quản lý xe cá nhân. Đây là ứng dụng phục vụ hệ sinh thái dữ liệu xăng dầu, tập trung vào bản đồ cửa hàng, giá bán, tồn kho, phản ánh vi phạm, dịch vụ cửa hàng và các báo cáo quản lý.

---

## 2. Mục Tiêu Ứng Dụng

### 2.1 Mục tiêu đối với người dân

- Tra cứu cửa hàng xăng dầu gần nhất.
- Xem thông tin cửa hàng, trạng thái hoạt động, dịch vụ cung cấp.
- Xem giá bán xăng dầu tại cửa hàng nếu được công khai.
- Gửi phản ánh về tình trạng vi phạm, bán sai giá, đóng cửa bất thường, chất lượng dịch vụ hoặc chất lượng nhiên liệu.
- Theo dõi các phản ánh đã gửi.

### 2.2 Mục tiêu đối với cửa hàng xăng dầu

- Cập nhật thông tin cửa hàng.
- Nhập giá bán xăng dầu.
- Nhập thông tin tồn kho, nhập kho, xuất kho.
- Khai báo dịch vụ cung cấp tại cửa hàng.
- Quản lý phản ánh liên quan đến cửa hàng.

### 2.3 Mục tiêu đối với cán bộ / cơ quan quản lý

- Theo dõi hoạt động cửa hàng xăng dầu theo địa bàn.
- Xem dữ liệu giá bán, tồn kho, nhập xuất.
- Theo dõi phản ánh của người dân.
- Kiểm tra tình trạng cập nhật dữ liệu của các đơn vị.

### 2.4 Mục tiêu đối với lãnh đạo

- Xem dashboard tổng quan.
- Theo dõi tồn kho, giá bán, nhập xuất và cân đối cung cầu.
- Xem bản đồ phân bố cửa hàng, doanh nghiệp, trạng thái hoạt động.
- Nhận diện các khu vực có rủi ro thiếu nguồn cung hoặc biến động bất thường.

---

## 3. Nhóm Người Dùng

| Nhóm người dùng | Vai trò |
|---|---|
| Người dân / Khách hàng | Tra cứu cửa hàng, xem thông tin, gửi phản ánh |
| Cửa hàng xăng dầu | Cập nhật giá bán, tồn kho, dịch vụ, thông tin cửa hàng |
| Doanh nghiệp / thương nhân | Theo dõi dữ liệu thuộc phạm vi quản lý |
| Cán bộ quản lý | Giám sát địa bàn, kiểm tra dữ liệu, xử lý phản ánh |
| Lãnh đạo | Xem báo cáo, dashboard, bản đồ điều hành |

---

## 4. Kiến Trúc Ứng Dụng

```text
mobile/lib/
├── main.dart
├── app/
│   ├── theme/
│   ├── routing/
│   └── di/
├── core/
│   ├── auth/
│   ├── network/
│   ├── router/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── map/
│   ├── stations/
│   ├── station_detail/
│   ├── store/
│   ├── store_services/
│   ├── store_sale_prices/
│   ├── inventory/
│   ├── reports/
│   ├── leader/
│   ├── bad_reports/
│   ├── my_reviews/
│   ├── more/
│   └── account/
└── shared/
    ├── widgets/
    ├── theme/
    └── components/
```

---

## 5. Các Chức Năng Chính

### 5.1 Xác Thực Và Phân Quyền

**Mục đích:** Cho phép người dùng đăng nhập và truy cập chức năng theo vai trò.

**Chức năng:**

- Đăng nhập.
- Đăng ký tài khoản nếu hệ thống cho phép.
- Quên mật khẩu.
- Đổi mật khẩu.
- Tự động lưu phiên đăng nhập.
- Điều hướng theo loại tài khoản.
- Chặn truy cập chức năng không có quyền.

**Vai trò đăng nhập tham khảo:**

| Loại tài khoản | Mô tả |
|---|---|
| Người dân | Tra cứu và gửi phản ánh |
| Store / Cửa hàng | Nhập giá, tồn kho, dịch vụ |
| Doanh nghiệp / thương nhân | Quản lý dữ liệu đơn vị |
| Leader / Lãnh đạo | Xem dashboard, báo cáo tổng hợp |
| Admin | Quản trị hệ thống |

---

### 5.2 Bản Đồ Cửa Hàng Xăng Dầu

**Mục đích:** Hiển thị vị trí các cửa hàng xăng dầu trên bản đồ.

**Chức năng:**

- Hiển thị marker cửa hàng xăng dầu.
- Xem cửa hàng gần vị trí người dùng.
- Lọc theo tỉnh/thành phố, loại nhiên liệu, trạng thái.
- Hiển thị trạng thái cửa hàng: đang hoạt động, tạm dừng, ngừng hoạt động, có cảnh báo/phản ánh.
- Nhấn marker để xem thông tin nhanh.
- Mở màn hình chi tiết cửa hàng.
- Chỉ đường đến cửa hàng nếu tích hợp bản đồ ngoài.

**Dữ liệu hiển thị nhanh trên marker:**

- Tên cửa hàng.
- Địa chỉ.
- Trạng thái hoạt động.
- Khoảng cách.
- Dịch vụ nổi bật.
- Giá bán nếu được phép hiển thị.
- Tồn kho nếu người dùng có quyền xem.

---

### 5.3 Danh Sách Và Chi Tiết Cửa Hàng Xăng Dầu

#### 5.3.1 Danh sách cửa hàng

- Tìm kiếm theo tên cửa hàng.
- Tìm kiếm theo địa chỉ.
- Lọc theo tỉnh, huyện, xã.
- Lọc theo trạng thái hoạt động.
- Lọc theo dịch vụ.
- Lọc theo loại nhiên liệu.
- Hiển thị danh sách dạng card/list.

#### 5.3.2 Chi tiết cửa hàng

| Nhóm thông tin | Nội dung |
|---|---|
| Thông tin chung | Tên cửa hàng, mã cửa hàng, địa chỉ, đơn vị quản lý |
| Vị trí | Tọa độ, bản đồ, khoảng cách |
| Trạng thái | Đang hoạt động, tạm dừng, ngừng hoạt động |
| Giá bán | Giá xăng dầu hiện hành tại cửa hàng |
| Tồn kho | Số lượng tồn kho theo loại nhiên liệu nếu có quyền |
| Dịch vụ | Rửa xe, thay dầu, bơm lốp, cửa hàng tiện ích... |
| Phản ánh | Các phản ánh liên quan nếu có quyền |
| Hình ảnh | Ảnh cửa hàng nếu được cập nhật |

---

### 5.4 Giá Bán Xăng Dầu Tại Cửa Hàng

**Mục đích:** Cho phép cửa hàng cập nhật và quản lý giá bán.

**Chức năng:**

- Xem danh sách giá bán hiện tại.
- Thêm mới giá bán.
- Cập nhật giá bán.
- Quản lý giá theo từng mặt hàng: Xăng RON 95, Xăng E5 RON 92, Dầu DO, Dầu hỏa, các mặt hàng khác nếu có.
- Ghi nhận thời gian cập nhật.
- Ghi chú lý do điều chỉnh nếu cần.
- Hiển thị lịch sử thay đổi giá.

**Vai trò sử dụng:**

- Cửa hàng xăng dầu.
- Cán bộ quản lý.
- Lãnh đạo xem tổng hợp.

---

### 5.5 Tồn Kho Và Nhập Xuất Kho

**Mục đích:** Quản lý dữ liệu tồn kho, nhập kho, xuất kho tại cửa hàng.

**Chức năng:**

- Nhập phiếu nhập kho.
- Nhập phiếu xuất kho.
- Một phiếu có thể có nhiều mặt hàng.
- Xem tồn kho hiện tại theo loại nhiên liệu.
- Xem lịch sử nhập xuất.
- Lọc theo thời gian, mặt hàng, loại giao dịch.
- Tổng hợp dữ liệu phục vụ báo cáo tồn kho.

**Dữ liệu phiếu nhập/xuất:**

| Trường | Mô tả |
|---|---|
| Cửa hàng | Đơn vị phát sinh giao dịch |
| Ngày giao dịch | Ngày nhập/xuất |
| Loại giao dịch | Nhập kho hoặc xuất kho |
| Mặt hàng | Loại nhiên liệu |
| Số lượng | Lượng nhập/xuất |
| Đơn vị tính | Lít, m3, tấn... |
| Ghi chú | Thông tin bổ sung |

---

### 5.6 Dịch Vụ Tại Cửa Hàng

**Mục đích:** Cho phép cửa hàng khai báo các dịch vụ cung cấp cho người dân.

**Ví dụ dịch vụ:**

- Rửa xe.
- Thay dầu.
- Bơm lốp.
- Cửa hàng tiện ích.
- Nhà vệ sinh.
- Cafe / nghỉ chân.
- Thanh toán điện tử.
- Sạc xe điện nếu có.

**Chức năng:**

- Thêm / sửa / xóa dịch vụ.
- Khai báo giá dịch vụ nếu có.
- Hiển thị dịch vụ trên trang chi tiết cửa hàng.
- Cho phép người dân xem nhanh dịch vụ trước khi đến cửa hàng.

---

### 5.7 Phản Ánh Vi Phạm / Báo Cáo Sự Cố

**Mục đích:** Cho phép người dân gửi phản ánh liên quan đến cửa hàng xăng dầu.

**Loại phản ánh:**

- Bán sai giá.
- Không bán hàng / đóng cửa bất thường.
- Hạn chế lượng bán.
- Chất lượng nhiên liệu.
- Thái độ phục vụ.
- Không xuất hóa đơn.
- An toàn phòng cháy chữa cháy.
- Vệ sinh môi trường.
- Khác.

**Chức năng người dân:**

- Chọn cửa hàng liên quan.
- Chọn loại phản ánh.
- Nhập mô tả chi tiết.
- Gửi phản ánh.
- Theo dõi phản ánh đã gửi.
- Đính kèm ảnh sẽ triển khai khi backend hỗ trợ upload.

**Chức năng quản lý:**

- Xem danh sách phản ánh.
- Lọc theo cửa hàng, địa bàn, trạng thái, thời gian.
- Xem chi tiết phản ánh.
- Cập nhật trạng thái xử lý.
- Ghi chú kết quả xử lý.

---

### 5.8 Đánh Giá / Nhận Xét Cửa Hàng

**Mục đích:** Cho phép người dùng đánh giá trải nghiệm tại cửa hàng.

**Chức năng:**

- Gửi đánh giá.
- Chấm điểm nếu có.
- Nhập nội dung nhận xét.
- Xem danh sách đánh giá.
- Quản lý đánh giá của tôi.

**Ghi chú:** Đánh giá khác với phản ánh vi phạm. Đánh giá phục vụ trải nghiệm người dùng; phản ánh là dữ liệu nghiệp vụ cần xử lý.

---

### 5.9 Báo Cáo Và Thống Kê

**Mục đích:** Cung cấp dữ liệu tổng hợp cho quản lý và lãnh đạo.

**Nhóm báo cáo:**

- Tổng số cửa hàng xăng dầu.
- Số cửa hàng theo trạng thái hoạt động.
- Số cửa hàng theo tỉnh/thành phố.
- Dữ liệu giá bán theo khu vực.
- Dữ liệu tồn kho theo mặt hàng.
- Dữ liệu nhập/xuất theo kỳ.
- Thống kê phản ánh.
- Thống kê dịch vụ cửa hàng.

**Dạng hiển thị:**

- KPI cards.
- Biểu đồ cột.
- Biểu đồ đường.
- Biểu đồ tròn.
- Bảng số liệu.
- Bản đồ chuyên đề.

---

### 5.10 Dashboard Lãnh Đạo

**Mục đích:** Cung cấp góc nhìn tổng quan cho vai trò lãnh đạo.

**Chức năng:**

- Tổng quan tồn kho xăng dầu.
- Nhập xuất trong kỳ.
- Cân đối cung cầu.
- Biến động giá.
- Bản đồ phân bố cửa hàng/doanh nghiệp.
- Biến động tồn kho.
- Cảnh báo bất thường.
- Tổng hợp phản ánh người dân.

**Gợi ý KPI:**

| KPI | Mô tả |
|---|---|
| Tổng tồn kho | Tổng tồn kho theo nhóm xăng/dầu/khí |
| Nhập trong kỳ | Lượng nhập theo kỳ |
| Xuất trong kỳ | Lượng xuất theo kỳ |
| Cân đối | Chênh lệch nhập - xuất - tồn |
| Số cửa hàng hoạt động | Tổng cửa hàng đang hoạt động |
| Số phản ánh mới | Phản ánh chưa xử lý |
| Khu vực rủi ro | Địa bàn có tồn kho thấp hoặc phản ánh tăng |

---

## 6. Luồng Điều Hướng

```text
App Start
│
├── Chưa đăng nhập
│   ├── Đăng nhập
│   ├── Đăng ký
│   └── Quên mật khẩu
│
└── Đã đăng nhập
    ├── Vai trò Người dân
    │   ├── Bản đồ
    │   ├── Danh sách cửa hàng
    │   ├── Chi tiết cửa hàng
    │   ├── Gửi phản ánh
    │   └── Tài khoản
    │
    ├── Vai trò Cửa hàng
    │   ├── Dashboard cửa hàng
    │   ├── Giá bán
    │   ├── Nhập xuất kho
    │   ├── Tồn kho
    │   ├── Dịch vụ
    │   └── Tài khoản
    │
    └── Vai trò Lãnh đạo
        ├── Dashboard lãnh đạo
        ├── Bản đồ
        ├── Báo cáo
        └── Tài khoản
```

---

## 7. Phân Quyền Chức Năng

| Chức năng | Người dân | Cửa hàng | Cán bộ | Lãnh đạo |
|---|---:|---:|---:|---:|
| Xem bản đồ cửa hàng | ✅ | ✅ | ✅ | ✅ |
| Xem chi tiết cửa hàng | ✅ | ✅ | ✅ | ✅ |
| Gửi phản ánh | ✅ | ✅ | ✅ | ❌ |
| Xem phản ánh của tôi | ✅ | ✅ | ✅ | ❌ |
| Nhập giá bán | ❌ | ✅ | ✅ | ❌ |
| Nhập xuất kho | ❌ | ✅ | ✅ | ❌ |
| Quản lý dịch vụ cửa hàng | ❌ | ✅ | ✅ | ❌ |
| Xem báo cáo địa bàn | ❌ | ❌ | ✅ | ✅ |
| Xem dashboard toàn quốc | ❌ | ❌ | ❌ | ✅ |

---

## 8. Kết Nối Backend

App giao tiếp với backend thông qua REST API.

### 8.1 Endpoint dự kiến

| Module | Endpoint gốc | Mô tả |
|---|---|---|
| Auth | `/api/auth` | Đăng nhập, đăng ký, đổi mật khẩu |
| Stations | `/api/stations` | Danh sách, chi tiết cửa hàng |
| Map | `/api/map` | Dữ liệu marker bản đồ |
| Prices | `/api/station-prices` | Giá bán tại cửa hàng |
| Inventory | `/api/station-inventory` | Tồn kho, nhập xuất |
| Services | `/api/store-services` | Dịch vụ cửa hàng |
| Reports | `/api/reports` | Báo cáo, thống kê |
| Leader | `/api/leader` | Dashboard lãnh đạo |
| Bad Reports | `/api/bad-reports` | Phản ánh vi phạm |
| Reviews | `/api/reviews` | Đánh giá cửa hàng |
| Uploads | `/api/uploads` | Upload ảnh trong phase sau |

### 8.2 Xác thực

- Sử dụng JWT Bearer Token.
- Token được gắn tự động vào request.
- Khi token hết hạn, app xử lý đăng xuất hoặc refresh token nếu backend hỗ trợ.

### 8.3 Xử lý lỗi

App cần hiển thị thông báo thân thiện khi:

- Mất kết nối mạng.
- Server không phản hồi.
- Sai tài khoản/mật khẩu.
- Không có quyền truy cập.
- Dữ liệu nhập không hợp lệ.
- Phiên đăng nhập hết hạn.
- Backend chưa hỗ trợ chức năng upload ảnh.

---

## 9. Yêu Cầu Kỹ Thuật

| Hạng mục | Yêu cầu |
|---|---|
| Flutter SDK | Từ 3.x trở lên |
| Dart | Từ 3.x trở lên |
| Android | Android 5.0 / API 21 trở lên |
| iOS | iOS 13 trở lên |
| Backend | ASP.NET Core |
| Database | SQL Server |
| Network client | Dio |
| State management | Riverpod theo kiến trúc hiện tại |
| Map | Google Maps hoặc provider tương đương |
| Auth | JWT Bearer |
| Storage | Secure storage cho token |
| Offline | Chưa hỗ trợ đầy đủ trong MVP |

---

## 10. Phạm Vi MVP / Phase 1

### 10.1 Trong phạm vi hiện tại

- Đăng nhập / đăng ký.
- Phân quyền theo vai trò.
- Bản đồ cửa hàng xăng dầu.
- Danh sách và chi tiết cửa hàng.
- Giá bán tại cửa hàng.
- Dịch vụ cửa hàng.
- Tồn kho / nhập xuất kho cho cửa hàng.
- Phản ánh vi phạm.
- Đánh giá cửa hàng.
- Báo cáo cơ bản.
- Dashboard lãnh đạo cơ bản.

### 10.2 Ngoài phạm vi / Phase sau

- Upload ảnh đầy đủ cho phản ánh/đánh giá.
- Push notification.
- Offline mode.
- Refresh token đầy đủ.
- AI cảnh báo bất thường.
- Dự báo cung cầu.
- Tối ưu bản đồ nâng cao / clustering lớn.
- Tích hợp thanh toán hoặc dịch vụ thương mại nếu có.

---

## 11. Nguyên Tắc UI/UX

### 11.1 Nguyên tắc chung

- Giao diện hiện đại, dễ sử dụng.
- Màu sắc hiện tại giữ ổn định nếu đã được duyệt.
- Không tự ý thay đổi theme khi chỉ sửa logic.
- Ưu tiên thao tác nhanh cho cửa hàng nhập dữ liệu.
- Thông tin quản lý phải rõ ràng, dễ đọc.
- Tránh hiển thị quá nhiều số liệu trên màn hình nhỏ.

### 11.2 Form nhập liệu

- Có validation rõ ràng.
- Có loading state khi submit.
- Chống submit trùng.
- Không làm mất dữ liệu khi lỗi mạng nếu có thể.
- Hiển thị thông báo thành công/lỗi dễ hiểu.
- Các trường bắt buộc phải được đánh dấu rõ.

### 11.3 Bản đồ

- Marker rõ ràng.
- Không render quá nhiều marker gây lag.
- Có filter đơn giản.
- Click marker hiển thị thông tin nhanh.
- Tối ưu dữ liệu marker từ API nhẹ.

### 11.4 Báo cáo

- Số liệu dùng định dạng tiếng Việt.
- Đơn vị đo rõ ràng.
- KPI quan trọng hiển thị nổi bật.
- Biểu đồ chỉ dùng khi giúp người dùng hiểu nhanh hơn.

---

## 12. Dữ Liệu Chính

### 12.1 Station / Cửa hàng xăng dầu

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| Code | Mã cửa hàng |
| Name | Tên cửa hàng |
| Address | Địa chỉ |
| ProvinceId | Tỉnh/thành |
| WardId | Xã/phường |
| Latitude | Vĩ độ |
| Longitude | Kinh độ |
| Status | Trạng thái hoạt động |
| OwnerUnitId | Đơn vị quản lý |
| Phone | Số điện thoại nếu có |

### 12.2 Fuel Product / Mặt hàng xăng dầu

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| Name | Tên mặt hàng |
| Code | Mã mặt hàng |
| UnitId | Đơn vị tính |
| IsActive | Trạng thái sử dụng |

### 12.3 Station Price / Giá bán

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| StationId | Cửa hàng |
| ProductId | Mặt hàng |
| Price | Giá bán |
| EffectiveDate | Ngày hiệu lực |
| IsCurrent | Giá hiện hành |
| Note | Ghi chú |

### 12.4 Inventory Transaction / Nhập xuất kho

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| StationId | Cửa hàng |
| TransactionDate | Ngày giao dịch |
| TransactionType | Nhập / xuất |
| Note | Ghi chú |

### 12.5 Inventory Transaction Detail

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| HeaderId | Phiếu nhập/xuất |
| ProductId | Mặt hàng |
| Quantity | Số lượng |
| UnitId | Đơn vị tính |
| Amount | Giá trị nếu có |

### 12.6 Bad Report / Phản ánh vi phạm

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| UserId | Người gửi |
| StationId | Cửa hàng liên quan |
| ReportType | Loại phản ánh |
| Description | Nội dung |
| Status | Trạng thái xử lý |
| CreatedAt | Thời gian gửi |
| ImageUrls | Danh sách ảnh nếu backend hỗ trợ |

### 12.7 Store Service / Dịch vụ cửa hàng

| Field | Mô tả |
|---|---|
| Id | Khóa chính |
| StationId | Cửa hàng |
| ServiceName | Tên dịch vụ |
| Price | Giá dịch vụ nếu có |
| IsAvailable | Có cung cấp hay không |
| Note | Ghi chú |

---

## 13. Các Chỉ Số Báo Cáo Chính

| Chỉ số | Mô tả |
|---|---|
| Tổng số cửa hàng | Tổng cửa hàng xăng dầu trong hệ thống |
| Cửa hàng đang hoạt động | Số cửa hàng hoạt động |
| Cửa hàng tạm dừng | Số cửa hàng tạm dừng/ngừng hoạt động |
| Tổng tồn kho | Tổng lượng tồn theo mặt hàng |
| Nhập trong kỳ | Lượng nhập theo kỳ |
| Xuất trong kỳ | Lượng xuất theo kỳ |
| Cân đối cung cầu | Chỉ số phục vụ lãnh đạo điều hành |
| Giá bán hiện hành | Giá tại cửa hàng hoặc theo kỳ |
| Số phản ánh mới | Phản ánh chưa xử lý |
| Tỷ lệ xử lý phản ánh | Tỷ lệ đã xử lý / tổng phản ánh |

---

## 14. Ghi Chú Cho AI Khi Viết Tài Liệu Hoặc Code

Khi sử dụng tài liệu này cho Claude, Cursor hoặc Codex, cần lưu ý:

- LocaVN là app của hệ thống CSDL xăng dầu.
- Không mô tả LocaVN như app quản lý xe cá nhân.
- Không mô tả LocaVN như app gọi xe, chia sẻ cuốc xe hoặc quản lý chi phí xe.
- Các domain chính cần giữ đúng:
  - bản đồ cửa hàng xăng dầu
  - cửa hàng xăng dầu
  - giá bán
  - tồn kho / nhập xuất kho
  - dịch vụ cửa hàng
  - phản ánh vi phạm
  - đánh giá cửa hàng
  - báo cáo / dashboard lãnh đạo
- Không tự ý thêm HTTM nếu scope hiện tại là app xăng dầu.
- Nếu làm HTTM, cần tách riêng module/tài liệu.
- Không tự ý thay đổi màu sắc UI nếu người dùng đã xác nhận UI hiện tại ổn.
- Khi sửa code phải làm trên branch riêng và commit theo từng nhóm thay đổi.

---

## 15. Kết Luận

LocaVN là ứng dụng mobile phục vụ hệ thống Cơ sở dữ liệu xăng dầu, tập trung vào bản đồ cửa hàng xăng dầu, giá bán, tồn kho, dịch vụ cửa hàng, phản ánh vi phạm và dashboard quản lý. Ứng dụng cần ưu tiên tính chính xác dữ liệu, phân quyền rõ ràng, trải nghiệm nhập liệu nhanh cho cửa hàng và giao diện dễ hiểu cho người dân cũng như lãnh đạo.
