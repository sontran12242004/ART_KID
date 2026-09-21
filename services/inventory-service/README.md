# 📦 ArtKids Inventory Service

Dịch vụ độc lập chuyên trách quản lý tồn kho học cụ vật lý (Art Kits) cho hệ sinh thái ArtKids:
- Quản lý danh mục SKU các hộp học cụ theo từng độ tuổi và chương trình học.
- Theo dõi số lượng tồn kho khả dụng (`quantityAvailable`) và số lượng đã giữ chỗ (`quantityReserved`).
- Cảnh báo tự động khi tồn kho chạm ngưỡng tái đặt hàng (`reorderThreshold`).
- Đồng bộ tồn kho real-time khi có đơn đặt hàng từ `commerce-service`.
