# 🚚 ArtKids Fulfillment Service

Dịch vụ độc lập chuyên trách đóng gói, kết nối đối tác vận chuyển và theo dõi đơn hàng học cụ tận nhà:
- Tạo đơn vận chuyển tự động qua API đối tác logistics (VNPost, Giao Hàng Nhanh - GHN, GHTK).
- Sinh mã vận đơn (`trackingNumber`) và cập nhật thời gian giao hàng dự kiến.
- Tiếp nhận Webhook từ đơn vị vận chuyển để cập nhật trạng thái đơn hàng (`packed` $\rightarrow$ `shipping` $\rightarrow$ `delivered`).
- Gửi thông báo cập nhật hành trình đến ứng dụng phụ huynh (Parent Dashboard).
