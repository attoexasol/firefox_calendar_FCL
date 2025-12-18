import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dashboard Welcome Card
/// Converted from React Dashboard Welcome Section
/// Shows user profile with gradient background
class DashboardWelcomeCard extends GetView<DashboardController> {
  const DashboardWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6 in React (24px)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFFFF8C61), // Lighter shade of primary
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with white border - h-16 w-16 border-4 border-white/20
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2), // border-white/20
                width: 4,
              ),
            ),
            child: Obx(
              () => CircleAvatar(
                radius: 32, // 64px total (h-16 w-16)
                backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                backgroundImage: controller.userProfilePicture.value.isNotEmpty
                    ? NetworkImage(controller.userProfilePicture.value)
                    : null,
                onBackgroundImageError:
                    controller.userProfilePicture.value.isNotEmpty
                    ? (exception, stackTrace) {}
                    : null,
                child: controller.userProfilePicture.value.isEmpty
                    ? Text(
                        _getInitials(controller.userName.value),
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 16), // gap-4 in React
          // User Info - flex-1 text-white
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Welcome back," - text-sm opacity-90
                Text(
                  'Welcome back,',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),

                // User name - text-xl font-semibold
                Obx(
                  () => Text(
                    controller.userName.value.isNotEmpty
                        ? controller.userName.value
                        : 'User',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Contact Info - flex flex-col gap-1 text-sm opacity-90
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email - flex items-center gap-2
                    Obx(
                      () => Row(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              controller.userEmail.value,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Phone (conditional)
                    Obx(
                      () => controller.userPhone.value.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    controller.userPhone.value,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get user initials from name
  /// Converts "John William Doe" to "JWD"
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';

    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join('')
        .toUpperCase();
  }
}
