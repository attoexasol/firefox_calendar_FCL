import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Create Event Screen
/// Pure UI layer (no business logic)
class CreateEventScreen extends GetView<CreateEventController> {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildForm(context, isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //──────────────────────────────── TOP BAR ────────────────────────────────
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              controller.resetForm();
              Get.back();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => Text(
                controller.isEditMode.value ? 'Edit Event' : 'Add Event',
                style: AppTextStyles.h4.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //──────────────────────────────── FORM ────────────────────────────────
  Widget _buildForm(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Text(
            controller.isEditMode.value
                ? 'Update event details'
                : 'Schedule a new meeting or event',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildTitle(isDark),
        const SizedBox(height: 16),

        _buildDatePicker(context, isDark),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _buildTime(context, isDark, true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTime(context, isDark, false)),
          ],
        ),
        const SizedBox(height: 16),

        _buildStatus(isDark),
        const SizedBox(height: 16),

        _buildEventType(isDark),
        const SizedBox(height: 16),

        _buildDescription(isDark),
        const SizedBox(height: 24),

        _buildButtons(isDark),
      ],
    );
  }

  //──────────────────────────────── FIELDS ────────────────────────────────
  Widget _buildTitle(bool isDark) {
    return TextField(
      controller: controller.titleController,
      decoration: const InputDecoration(labelText: 'Title *'),
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return Obx(
      () => InkWell(
        onTap: () => _pickDate(context),
        child: _inputBox(
          isDark,
          icon: Icons.calendar_today,
          text: controller.formatDate(controller.selectedDate.value),
          isHint: controller.selectedDate.value == null,
        ),
      ),
    );
  }

  Widget _buildTime(BuildContext context, bool isDark, bool isStart) {
    return Obx(
      () => InkWell(
        onTap: () => _pickTime(context, isStart),
        child: _inputBox(
          isDark,
          icon: Icons.access_time,
          text: isStart
              ? (controller.startTime.value.isEmpty
                  ? 'Start Time'
                  : controller.formatTime(controller.startTime.value))
              : (controller.endTime.value.isEmpty
                  ? 'End Time'
                  : controller.formatTime(controller.endTime.value)),
          isHint: isStart
              ? controller.startTime.value.isEmpty
              : controller.endTime.value.isEmpty,
        ),
      ),
    );
  }

  Widget _buildStatus(bool isDark) {
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: controller.status.value,
        dropdownColor: isDark
            ? AppColors.inputBackgroundDark
            : AppColors.inputBackgroundLight,
        items: const [
          DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
          DropdownMenuItem(value: 'tentative', child: Text('Tentative')),
        ],
        onChanged: controller.status.call,
        decoration: const InputDecoration(labelText: 'Status'),
      ),
    );
  }

  Widget _buildEventType(bool isDark) {
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue:
            controller.eventType.value.isEmpty ? null : controller.eventType.value,
        dropdownColor: isDark
            ? AppColors.inputBackgroundDark
            : AppColors.inputBackgroundLight,
        items: CreateEventController.eventCategories
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          controller.setEventType(value);
        },
        decoration: const InputDecoration(labelText: 'Event Type *'),
      ),
    );
  }

  Widget _buildDescription(bool isDark) {
    return TextField(
      controller: controller.descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Description'),
    );
  }

  //──────────────────────────────── BUTTONS ────────────────────────────────
  Widget _buildButtons(bool isDark) {
    return Obx(
      () {
        // Extract Rx values once at the start
        final isLoading = controller.isLoading.value;
        final isEditMode = controller.isEditMode.value;
        
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        controller.resetForm();
                        Get.back();
                      },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : controller.handleSubmit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditMode
                        ? 'Save Changes'
                        : 'Create Event'),
              ),
            ),
          ],
        );
      },
    );
  }

  //──────────────────────────────── HELPERS ────────────────────────────────
  Widget _inputBox(bool isDark,
      {required IconData icon,
      required String text,
      required bool isHint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Icon(icon,
              size: 18,
              color: isHint
                  ? AppColors.mutedForegroundLight
                  : AppColors.foregroundLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isHint
                    ? AppColors.mutedForegroundLight
                    : AppColors.foregroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.handleDateSelect(picked);
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      isStart ? controller.setStartTime(time) : controller.setEndTime(time);
    }
  }
}
