import 'package:flutter/material.dart';

import '../../domain/entities/avatar_preset.dart';
import 'app_avatar_widget.dart';

/// Modal bottom sheet cho phép phụ huynh hoặc bé chọn avatar theo phong cách thiết kế ArtKids
class AvatarPickerBottomSheet extends StatefulWidget {
  final String currentAvatarId;
  final bool isChild;
  final ValueChanged<String> onAvatarSelected;

  const AvatarPickerBottomSheet({
    super.key,
    required this.currentAvatarId,
    required this.isChild,
    required this.onAvatarSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentAvatarId,
    required bool isChild,
    required ValueChanged<String> onAvatarSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerBottomSheet(
        currentAvatarId: currentAvatarId,
        isChild: isChild,
        onAvatarSelected: onAvatarSelected,
      ),
    );
  }

  @override
  State<AvatarPickerBottomSheet> createState() =>
      _AvatarPickerBottomSheetState();
}

class _AvatarPickerBottomSheetState extends State<AvatarPickerBottomSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentAvatarId;
  }

  @override
  Widget build(BuildContext context) {
    final presets = widget.isChild
        ? AvatarPreset.childPresets
        : AvatarPreset.parentPresets;
    final selectedPreset =
        AvatarPreset.findById(_selectedId, isChild: widget.isChild);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EA),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1687A7).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isChild
                      ? Icons.face_rounded
                      : Icons.person_pin_rounded,
                  color: const Color(0xFF1687A7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isChild
                          ? 'Chọn Avatar Cho Bé'
                          : 'Chọn Avatar Phụ Huynh',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F3B46),
                      ),
                    ),
                    Text(
                      widget.isChild
                          ? 'Bé thích hóa thân thành bạn nhỏ nào?'
                          : 'Chọn phong cách đại diện của phụ huynh',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF556E74),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF8C9EA2)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Preview Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE2F3F5),
                  const Color(0xFFF7FDFD),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF70C1B3).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                AppAvatarWidget(
                  avatarId: _selectedId,
                  isChild: widget.isChild,
                  radius: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPreset.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedPreset.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF4C6E76),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1687A7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang chọn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Grid các avatar để chọn
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isSelected = preset.id == _selectedId;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedId = preset.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : const Color(0xFFF8FBFB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A52A8)
                            : const Color(0xFFE0ECEE),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1A52A8)
                                    .withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            AppAvatarWidget(
                              avatarId: preset.id,
                              isChild: widget.isChild,
                              radius: 26,
                            ),
                            if (isSelected)
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A52A8),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1A52A8)
                                : const Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Nút xác nhận áp dụng avatar
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A52A8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 4,
                shadowColor:
                    const Color(0xFF1A52A8).withValues(alpha: 0.45),
              ),
              onPressed: () {
                widget.onAvatarSelected(_selectedId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Áp Dụng Avatar Này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
