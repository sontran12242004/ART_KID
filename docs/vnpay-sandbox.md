# VNPay Sandbox cho cửa hàng ART_KID

Phạm vi hiện tại: phụ huynh thanh toán đơn học cụ qua cổng VNPay Sandbox; không thu tiền thật. Luồng web local được hỗ trợ. Không dùng chức năng này cho khóa học hoặc subscription; các nghiệp vụ đó vẫn dùng quy trình hiện có.

## Luồng đã tích hợp

1. Chọn VNPay tại trang thanh toán, backend tính giá và tạo đơn `pending` theo giỏ hàng thật. Khi thiếu key, cả giao diện lẫn API chặn trước khi tạo đơn.
2. Backend tạo bản ghi `vnpay_payments`, mã tham chiếu riêng và URL có chữ ký HMAC-SHA512; số tiền lấy từ đơn, nhân 100 theo giao thức VNPay. URL có hạn 15 phút, thời gian GMT+7.
3. Trình duyệt chuyển đến VNPay. `ReturnUrl` chỉ xác minh thông tin và chuyển về màn hình kết quả, không ghi nhận đã thu tiền.
4. VNPay gọi IPN server-to-server. Backend kiểm tra chữ ký, merchant, mã tham chiếu, số tiền, trạng thái giao dịch và chống xử lý trùng trước khi ghi `paid`.
5. Trang kết quả lấy trạng thái từ backend, kiểm tra lại trong khoảng 1 phút và có nút kiểm tra thủ công. Nếu đã hủy/thất bại có thể thử thanh toán lại cho đơn còn hiệu lực. Đơn hàng cũng có nút tiếp tục thanh toán.
6. Thanh toán thành công không đồng nghĩa đã giao hàng: các bước xác nhận/xử lý kho và giao hàng hiện có vẫn tiếp tục. Đơn đã trả tiền không được hủy theo quy trình hủy đơn chưa thanh toán. Trường hợp nhận tiền muộn cho đơn đã hủy hoặc thu trùng được ghi log giao dịch và tracking để quản trị viên đối soát; chưa tích hợp API hoàn tiền tự động.

## Đăng ký lấy key

Truy cập [đăng ký VNPay Sandbox](https://sandbox.vnpayment.vn/devreg/), điền email và thông tin website theo form hiện tại. Theo [tài liệu kết nối chính thức](https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html), thông tin kết nối được gửi qua email đăng ký. Lấy hai giá trị:

- `vnp_TmnCode`: mã website/terminal.
- `vnp_HashSecret`: secret tạo và xác minh chữ ký, không phải mật khẩu đăng nhập portal.

Chỉ dùng key sandbox. Không đưa HashSecret vào Dart, `env/dev.env`, URL trình duyệt hoặc commit Git.

## URL callback khi chạy local

IPN là cuộc gọi từ máy chủ VNPay đến API của bạn, vì vậy `localhost:5080` không thể nhận IPN từ VNPay. Cần một URL HTTPS public trỏ vào backend cổng 5080. Ví dụ sau khi cài và cấu hình [ngrok theo hướng dẫn chính thức](https://ngrok.com/docs/start):

```powershell
ngrok http 5080
```

Giữ tunnel hoạt động trong suốt quá trình thanh toán và nhận IPN. Giả sử địa chỉ nhận được là `https://YOUR-BACKEND.ngrok-free.app`:

| Mục | URL |
| --- | --- |
| Website/app local | `http://localhost:8080` |
| Return URL | `https://YOUR-BACKEND.ngrok-free.app/api/v1/payments/vnpay/return` |
| IPN URL | `https://YOUR-BACKEND.ngrok-free.app/api/v1/payments/vnpay/ipn` |

Đăng ký/cập nhật IPN URL trong cấu hình merchant VNPay Sandbox; nếu portal không có mục chỉnh IPN, gửi URL này cho bộ phận hỗ trợ VNPay Sandbox để họ cấu hình. IPN URL không được truyền thành một tham số `vnp_IpnUrl` trong URL thanh toán. Khi địa chỉ tunnel thay đổi, cập nhật cả cấu hình backend và cấu hình IPN bên VNPay.

## Điền cấu hình

Mở PowerShell tại thư mục gốc dự án và chạy:

```powershell
.\backend\scripts\configure-vnpay.ps1 -PublicApiBaseUrl "https://YOUR-BACKEND.ngrok-free.app"
.\backend\scripts\restart-api.ps1
```

Script hỏi TmnCode và HashSecret (che nội dung secret khi nhập), ghi riêng mục `Vnpay` vào file đã được Git ignore `backend/src/ArtKids.API/appsettings.Local.json`. Cấu hình database, Cloudinary và các mục khác được giữ lại. Script chưa xác minh key với gateway; giao dịch sandbox đầu tiên sẽ kiểm tra key thực tế.

Nếu tự sửa JSON, gộp mục sau vào file local hiện có, không thay toàn bộ file:

```json
{
  "Vnpay": {
    "Enabled": true,
    "TmnCode": "REPLACE_WITH_SANDBOX_TMN_CODE",
    "HashSecret": "REPLACE_WITH_SANDBOX_HASH_SECRET",
    "PaymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html",
    "ReturnUrl": "https://YOUR-BACKEND.ngrok-free.app/api/v1/payments/vnpay/return",
    "FrontendReturnUrl": "http://localhost:8080/#/parent/payments/vnpay/result"
  }
}
```

File cấu hình được commit `backend/src/ArtKids.API/appsettings.json` chỉ có placeholder và `Enabled: false`. Không cần sửa source để bật sau này. Nếu dùng frontend domain khác, đổi `FrontendReturnUrl` về domain đó để phiên trong tab được khôi phục đúng. Bản mobile native cần cấu hình app/universal link phù hợp; URL mẫu trên dành cho web local.

## Chạy thử

1. Chạy local bằng `run-local.ps1`, backend Development tự áp dụng migration mới. Mở frontend, Ctrl+F5, đăng nhập phụ huynh.
2. Thêm học cụ vào giỏ, nhập địa chỉ, chọn **Cổng thanh toán VNPAY** và đặt hàng.
3. Thanh toán trên sandbox theo [thông tin thẻ test VNPay](https://sandbox.vnpayment.vn/apis/docs/gioi-thieu/): ngân hàng **NCB**, số thẻ **9704198526191432198**, chủ thẻ **NGUYEN VAN A**, ngày phát hành **07/15**, OTP **123456**. Dùng dữ liệu test mới nhất trên trang chính thức nếu VNPay thay đổi.
4. Sau khi quay lại, chờ IPN rồi kiểm tra trạng thái **Thanh toán thành công**. Nếu vẫn chờ, kiểm tra tunnel/IPN registration và log API; không đổi trạng thái paid thủ công để bỏ qua IPN.
5. Thử hủy ở trang VNPay, quay lại rồi thanh toán lại. Có thể mở đơn chưa trả tiền từ danh sách đơn hàng để tiếp tục thanh toán.

## API và kiểm thử

- `GET /api/v1/payments/vnpay/config`: chỉ trả trạng thái cấu hình, không trả secret.
- `POST /api/v1/payments/vnpay/orders/{id}/url`: phụ huynh sở hữu đơn tạo URL.
- `GET /api/v1/payments/vnpay/orders/{id}`: phụ huynh sở hữu đơn xem trạng thái.
- `GET /api/v1/payments/vnpay/return`: public, xác minh chữ ký, chuyển về frontend.
- `GET /api/v1/payments/vnpay/ipn`: public, xác minh chữ ký; JSON trả đúng `RspCode`/`Message`.

```powershell
$env:ARTKIDS_TEST_POSTGRES = '1'
python backend/tests/vnpay_test.py
```

Bộ test dùng database tạm và key giả để kiểm tra chữ ký, số tiền, Return không ghi paid, IPN lặp, phân quyền, hủy/thử lại, nhận tiền sau hủy và thiếu cấu hình. Chưa thể kiểm tra giao dịch đầu-cuối với VNPay thật khi chưa có TmnCode/HashSecret và IPN public được đăng ký.
