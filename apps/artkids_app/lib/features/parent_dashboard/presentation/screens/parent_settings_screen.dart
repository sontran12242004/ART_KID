import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../domain/entities/avatar_preset.dart';
import '../providers/parent_profile_provider.dart';
import '../widgets/app_avatar_widget.dart';
import '../widgets/avatar_picker_bottom_sheet.dart';

/// Màn hình Cài Đặt & Quản Lý Thông Tin Phụ Huynh & Bé (Cho phép đổi Avatar)
class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() =>
      _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _parentNameController;
  late TextEditingController _parentEmailController;
  late TextEditingController _parentPhoneController;

  late TextEditingController _childNicknameController;
  late TextEditingController _childInterestsController;

  late String _parentAvatarId;
  late String _childAvatarId;
  late int _childAge;
  late int _childBirthYear;

  late bool _notificationsEnabled;
  late bool _dailyDrawingReminder;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(parentProfileProvider);

    _parentNameController = TextEditingController(text: profile.parentName);
    _parentEmailController = TextEditingController(text: profile.parentEmail);
    _parentPhoneController = TextEditingController(text: profile.parentPhone);

    _childNicknameController = TextEditingController(
      text: profile.childNickname,
    );
    _childInterestsController = TextEditingController(
      text: profile.childInterests,
    );

    _parentAvatarId = profile.parentAvatarId;
    _childAvatarId = profile.childAvatarId;
    _childAge = profile.childAge;
    _childBirthYear = profile.childBirthYear;

    _notificationsEnabled = profile.notificationsEnabled;
    _dailyDrawingReminder = profile.dailyDrawingReminder;
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _childNicknameController.dispose();
    _childInterestsController.dispose();
    super.dispose();
  }

  void _openParentAvatarPicker() {
    AvatarPickerBottomSheet.show(
      context: context,
      currentAvatarId: _parentAvatarId,
      isChild: false,
      onAvatarSelected: (newId) {
        setState(() {
          _parentAvatarId = newId;
        });
      },
    );
  }

  void _openChildAvatarPicker() {
    AvatarPickerBottomSheet.show(
      context: context,
      currentAvatarId: _childAvatarId,
      isChild: true,
      onAvatarSelected: (newId) {
        setState(() {
          _childAvatarId = newId;
        });
      },
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    ref
        .read(parentProfileProvider.notifier)
        .saveAll(
          parentName: _parentNameController.text.trim(),
          parentEmail: _parentEmailController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          parentAvatarId: _parentAvatarId,
          childNickname: _childNicknameController.text.trim(),
          childAge: _childAge,
          childBirthYear: _childBirthYear,
          childInterests: _childInterestsController.text.trim(),
          childAvatarId: _childAvatarId,
          notificationsEnabled: _notificationsEnabled,
          dailyDrawingReminder: _dailyDrawingReminder,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Đã cập nhật thông tin và avatar thành công!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Color(0xFF00B894),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE76F51)),
            SizedBox(width: 8),
            Text('Đăng Xuất Tài Khoản?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng ArtKids không?',
          style: TextStyle(fontSize: 14.5, color: Color(0xFF4C6E76)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE76F51),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go(RoutePaths.parentLogin);
            },
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentPreset = AvatarPreset.findById(_parentAvatarId, isChild: false);
    final childPreset = AvatarPreset.findById(_childAvatarId, isChild: true);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F3F5), Color(0xFFF7FDFD), Color(0xFFF4F9FA)],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1687A7),
                        size: 28,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Cài Đặt & Hồ Sơ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1687A7,
                        ).withValues(alpha: 0.12),
                        foregroundColor: const Color(0xFF1687A7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Lưu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Section 1: Hồ Sơ Phụ Huynh
                        _buildSectionHeader(
                          icon: Icons.person_pin_rounded,
                          title: 'Hồ Sơ Phụ Huynh',
                          subtitle:
                              'Quản lý thông tin tài khoản và người giám hộ',
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            // Avatar Changer for Parent
                            Center(
                              child: Column(
                                children: [
                                  AppAvatarWidget(
                                    avatarId: _parentAvatarId,
                                    isChild: false,
                                    radius: 44,
                                    showEditBadge: true,
                                    editBadgeIcon: Icons.camera_alt_rounded,
                                    onTap: _openParentAvatarPicker,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF1687A7),
                                    ),
                                    icon: const Icon(
                                      Icons.palette_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Đổi Avatar: ${parentPreset.name}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: _openParentAvatarPicker,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Fields
                            const Text(
                              'Họ và tên phụ huynh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AuthTextField(
                              controller: _parentNameController,
                              hintText: 'Nhập họ và tên',
                              prefixIcon: Icons.person_rounded,
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                  ? 'Vui lòng nhập họ tên'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Email nhận thông báo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AuthTextField(
                              controller: _parentEmailController,
                              hintText: 'Nhập email',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!val.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Số điện thoại liên hệ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AuthTextField(
                              controller: _parentPhoneController,
                              hintText: 'Nhập số điện thoại',
                              prefixIcon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),

                            // Badge trạng thái
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF81C784),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tài khoản chính (Đã xác minh phụ huynh)',
                                      style: TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section 2: Hồ Sơ Của Bé
                        _buildSectionHeader(
                          icon: Icons.child_care_rounded,
                          title: 'Hồ Sơ Của Bé',
                          subtitle:
                              'Cá nhân hóa trải nghiệm học tập và sáng tạo',
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            // Avatar Changer for Child
                            Center(
                              child: Column(
                                children: [
                                  AppAvatarWidget(
                                    avatarId: _childAvatarId,
                                    isChild: true,
                                    radius: 44,
                                    showEditBadge: true,
                                    editBadgeIcon: Icons.auto_awesome_rounded,
                                    onTap: _openChildAvatarPicker,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF1687A7),
                                    ),
                                    icon: const Icon(
                                      Icons.face_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Đổi Avatar Bé: ${childPreset.name}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: _openChildAvatarPicker,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Biệt danh của bé (Nickname)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AuthTextField(
                              controller: _childNicknameController,
                              hintText: 'VD: Bé Bo, Nhím, Sóc Nâu...',
                              prefixIcon: Icons.face_rounded,
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                  ? 'Vui lòng nhập biệt danh'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Chọn độ tuổi của bé
                            const Text(
                              'Độ tuổi của bé',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [3, 4, 5, 6, 7, 8, 9, 10].map((age) {
                                final isSelected = _childAge == age;
                                return ChoiceChip(
                                  label: Text('$age tuổi'),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF1687A7),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1A3B44),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: const Color(0xFFF1F8F9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF1687A7)
                                          : const Color(
                                              0xFF70C1B3,
                                            ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _childAge = age;
                                        _childBirthYear =
                                            DateTime.now().year - age;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Chủ đề hội họa bé yêu thích',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF33555D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AuthTextField(
                              controller: _childInterestsController,
                              hintText: 'VD: Động vật, Cổ tích, Vũ trụ AI...',
                              prefixIcon: Icons.brush_rounded,
                            ),
                            const SizedBox(height: 14),

                            // COPPA Notice Box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F9),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF70C1B3),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF1687A7),
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tuân thủ chuẩn COPPA: ArtKids chỉ lưu biệt danh để cá nhân hóa tranh vẽ, tuyệt đối không thu thập danh tính thật của trẻ.',
                                      style: TextStyle(
                                        color: Color(0xFF4C6E76),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section 3: Bảo Mật & Tiện Ích
                        _buildSectionHeader(
                          icon: Icons.security_rounded,
                          title: 'Bảo Vệ & Cài Đặt Hệ Thống',
                          subtitle: 'Mã PIN Kid Mode và nhắc nhở học tập',
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            // Quản lý Đơn hàng của tôi
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE17055,
                                  ).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFFE17055),
                                  size: 22,
                                ),
                              ),
                              title: const Text(
                                'Đơn Hàng Của Tôi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: const Text(
                                'Theo dõi đơn hàng & hành trình giao Kit học cụ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  context.push(RoutePaths.parentOrders),
                            ),
                            const Divider(height: 20),

                            // Nút đổi mã PIN
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0984E3,
                                  ).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pin_outlined,
                                  color: Color(0xFF0984E3),
                                  size: 22,
                                ),
                              ),
                              title: const Text(
                                'Mã PIN Trẻ Em (Kid Gate)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: const Text(
                                'Khóa bảo vệ không cho bé thoát ra ngoài Kid Mode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  context.push(RoutePaths.parentKidPinSetup),
                            ),
                            const Divider(height: 20),

                            // Switch thông báo
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: const Color(0xFF1687A7),
                              title: const Text(
                                'Thông báo tiến trình vẽ của bé',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: const Text(
                                'Nhận cập nhật khi bé hoàn thành tranh mới',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                              value: _notificationsEnabled,
                              onChanged: (val) {
                                setState(() => _notificationsEnabled = val);
                              },
                            ),
                            const Divider(height: 20),

                            // Switch nhắc nhở
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: const Color(0xFF1687A7),
                              title: const Text(
                                'Nhắc nhở bé luyện vẽ mỗi ngày',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: const Text(
                                'Duy trì thói quen sáng tạo vào 19:30 mỗi tối',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                              value: _dailyDrawingReminder,
                              onChanged: (val) {
                                setState(() => _dailyDrawingReminder = val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Main Save Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A52A8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: _isSaving ? null : _saveSettings,
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1A52A8,
                                    ).withValues(alpha: 0.38),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Lưu Thay Đổi',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Logout Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE76F51),
                            side: const BorderSide(
                              color: Color(0xFFE76F51),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text(
                            'Đăng Xuất Khỏi Tài Khoản',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: _confirmLogout,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1687A7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1687A7), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F3B46),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF556E74)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EFEF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1687A7).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
