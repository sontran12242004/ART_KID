import 'package:flutter/foundation.dart';

/// Kiểm tra cấu hình phần cứng thiết bị để tối ưu hóa đồ họa 2D vs 3D.
///
/// Phân tích kỹ thuật & Đánh đổi hiệu năng:
/// - **2D Vector Animation (Rive / Lottie)**:
///   - Sử dụng Skia/Impeller Canvas native, RAM chiếm dụng rất thấp (~15-30MB).
///   - Chạy cực kỳ mượt mà 60fps trên Android Emulator và các thiết bị tầm trung (Snapdragon 680, Helio G88, RAM 3-4GB).
/// - **3D glTF Model Rendering (model_viewer_plus / Filament / WebGL WebView)**:
///   - Khởi tạo context WebGL / OpenGL ES ngốn thêm 120-250MB RAM và tiêu tốn pin/GPU.
///   - Trên Android Emulator, nếu không bật Host GPU Acceleration (`-gpu host`), model 3D có thể giật lag hoặc crash do software rendering (`swiftshader`).
///   - Giải pháp: Mặc định ưu tiên 2D Rive Animation cho trẻ em, chỉ kích hoạt 3D khi thiết bị đủ mạnh hoặc người dùng chủ động chọn chế độ 3D.
class DeviceCapabilityChecker {
  DeviceCapabilityChecker._();

  static bool get isRunningOnWeb => kIsWeb;

  /// Đánh giá xem có nên render 3D nặng hay fallback về 2D Rive animation mượt mà
  static bool prefer2dOver3d({bool isEmulator = false, int availableRamMb = 4096}) {
    if (isEmulator && availableRamMb < 4096) {
      return true; // Fallback về 2D trên emulator RAM thấp
    }
    if (availableRamMb < 3000) {
      return true; // Thiết bị Android giá rẻ/tầm trung -> 2D animation là tối ưu
    }
    return false;
  }
}
