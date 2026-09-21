# ⚡ ArtKids AI Inference Worker (GPU-bound)

Worker chuyên xử lý các tác vụ AI nặng tải, yêu cầu GPU chuyên dụng:
- **Tiêu thụ Job từ Hàng đợi**: Lắng nghe hàng đợi Redis / Celery từ `orchestrator`.
- **Thực thi Pipeline AI**:
  - Nhận diện nét vẽ, con vật, màu sắc qua Google Gemini Vision API.
  - Phối hợp khung xương chuyển động hoạt hình 2D (Rive/Lottie).
  - Tái tạo mô hình khối 3D (.GLB) từ ảnh vẽ nét tay.
- **Tối ưu Hóa Chi Phí Hạ Tầng**:
  - Tách biệt hoàn toàn khỏi Web/API server.
  - Tự động scale số lượng worker theo số lượng job trong hàng đợi (Queue Length Autoscale).
  - Chạy trên các máy chủ GPU Spot / On-demand (NVIDIA T4 / A10G) giúp tiết kiệm đến 70% chi phí vận hành.
