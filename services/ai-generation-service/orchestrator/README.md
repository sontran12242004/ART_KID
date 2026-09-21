# 🎯 ArtKids AI Orchestrator (CPU-bound)

Thành phần điều phối nhẹ (Lightweight API Server & Job Queue Manager):
- **Vai trò**: Tiếp nhận request vẽ tranh từ Flutter app / Web app (`POST /api/v1/ai/generate`).
- **Quản lý hàng đợi (Queue)**: Đưa job vào hàng đợi Redis / BullMQ với mã `jobId`.
- **Cung cấp API Polling & WebSocket**: Cho phép app tra cứu tiến độ sinh hoạt ảnh (`GET /api/v1/ai/jobs/:jobId`).
- **Tối ưu tài nguyên**: Thuần CPU-bound, tiêu thụ rất ít RAM/CPU, có thể autoscale linh hoạt với chi phí cực rẻ khi lượng người dùng đồng thời tăng cao mà không cần máy chủ GPU.
