import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Create Event Screen
/// Converted from React CreateMeetingModal component
/// Allows users to create or edit events/meetings
class CreateEventScreen extends GetView<CreateEventController> {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, isDark),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(children: [_buildForm(context, isDark)]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build top bar with back button and title
  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.handleCancel,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => Text(
                controller.isEditMode.value ? 'Edit the Event' : 'Add an event',
                style: AppTextStyles.h4.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main form
  Widget _buildForm(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Description text
        Obx(
          () => Text(
            controller.isEditMode.value
                ? 'Update event details and information'
                : 'Schedule a new meeting or event with your team',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Title Field
        _buildTitleField(isDark),

        const SizedBox(height: 16),

        // Date Picker
        _buildDatePicker(context, isDark),

        const SizedBox(height: 16),

        // Time Inputs
        Row(
          children: [
            Expanded(child: _buildStartTimeField(context, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildEndTimeField(context, isDark)),
          ],
        ),

        const SizedBox(height: 16),

        // Status Selector
        _buildStatusSelector(isDark),

        const SizedBox(height: 16),

        // Event Type Selector
        _buildEventTypeSelector(isDark),

        const SizedBox(height: 16),

        // Description Field
        _buildDescriptionField(isDark),

        const SizedBox(height: 24),

        // Action Buttons
        _buildActionButtons(isDark),
      ],
    );
  }

  /// Build title input field
  Widget _buildTitleField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title *',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.titleController,
          decoration: const InputDecoration(hintText: 'Event title'),
        ),
      ],
    );
  }

  /// Build date picker
  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => InkWell(
            onTap: () => _showDatePickerDialog(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.inputBackgroundDark
                    : AppColors.inputBackgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.formatDate(controller.selectedDate.value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: controller.selectedDate.value == null
                            ? (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight)
                            : (isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show date picker dialog
  Future<void> _showDatePickerDialog(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = controller.selectedDate.value ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: controller.isEditMode.value ? DateTime(2000) : now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryForegroundLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.handleDateSelect(picked);
    }
  }

  /// Build start time field
  Widget _buildStartTimeField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Time *',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => InkWell(
            onTap: () => _showTimePicker(context, isStartTime: true),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.inputBackgroundDark
                    : AppColors.inputBackgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.startTime.value.isEmpty
                          ? 'Select time'
                          : controller.formatTime(controller.startTime.value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: controller.startTime.value.isEmpty
                            ? (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight)
                            : (isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build end time field
  Widget _buildEndTimeField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End Time *',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => InkWell(
            onTap: () => _showTimePicker(context, isStartTime: false),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.inputBackgroundDark
                    : AppColors.inputBackgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.endTime.value.isEmpty
                          ? 'Select time'
                          : controller.formatTime(controller.endTime.value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: controller.endTime.value.isEmpty
                            ? (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight)
                            : (isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show time picker dialog
  Future<void> _showTimePicker(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final now = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryForegroundLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';

      if (isStartTime) {
        controller.setStartTime(timeString);
      } else {
        controller.setEndTime(timeString);
      }
    }
  }

  /// Build status selector
  Widget _buildStatusSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inputBackgroundDark
                  : AppColors.inputBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: DropdownButton<String>(
              value: controller.status.value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                DropdownMenuItem(value: 'tentative', child: Text('Tentative')),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.setStatus(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build event type selector
  Widget _buildEventTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Type',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inputBackgroundDark
                  : AppColors.inputBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: DropdownButton<String>(
              value: controller.eventType.value.isEmpty
                  ? null
                  : controller.eventType.value,
              hint: Text(
                'Select event type',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: CreateEventController.eventCategories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.setEventType(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build description field
  Widget _buildDescriptionField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Event description...'),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(bool isDark) {
    return Obx(
      () => Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.handleCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Submit Button
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryForegroundLight,
                        ),
                      ),
                    )
                  : Text(
                      controller.isEditMode.value
                          ? 'Confirm Changes'
                          : 'Add Event',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.primaryForegroundLight,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
