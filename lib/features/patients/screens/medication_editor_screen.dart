/// Medication Editor screen — create & edit a medicine reminder.
///
/// Fetches / mutates via `MedicationController`:
///   - `POST /api/v1/medicines/reminders/` — create
///   - `PATCH /api/v1/medicines/reminders/{id}/` — update
///
/// Fields map 1:1 to the `MedicineReminderRequest` schema:
///   patient_id, medicine_name, dosage, times_per_day, reminder_times[],
///   start_date, end_date, is_active.
///
/// No placeholder/static data remains.

import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/patients/controllers/medication_controller.dart';
import 'package:admin/features/patients/models/medicine_reminder.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import '../../../core/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MedicationEditorScreen extends StatefulWidget {
  const MedicationEditorScreen({super.key});

  @override
  State<MedicationEditorScreen> createState() => _MedicationEditorScreenState();
}

class _MedicationEditorScreenState extends State<MedicationEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timesPerDayController = TextEditingController();

  late final MedicationController _controller;
  int _patientId = 0;
  int _reminderId = 0; // 0 => create, >0 => edit
  bool _isEditing = false;
  bool _isSaving = false;

  List<String> _reminderTimes = [];
  String _startDate = '';
  String _endDate = ''; // empty => ongoing
  bool _isActive = true;

  static const int _maxNameChars = 150;
  static const int _maxDosageChars = 100;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<MedicationController>()) {
      Get.put(MedicationController(Get.find<PatientRepository>()));
    }
    _controller = Get.find<MedicationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveArgs();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timesPerDayController.dispose();
    super.dispose();
  }

  void _resolveArgs() {
    final args = Get.arguments as Map<String, dynamic>?;
    _patientId = (args?['patientId'] as num?)?.toInt() ?? 0;
    final reminder = args?['reminder'] as MedicineReminder?;
    _reminderId = (args?['reminderId'] as num?)?.toInt() ?? 0;
    _isEditing = reminder != null || _reminderId > 0;

    debugPrint(
      '[MedicationEditor] Resolved args — patientId=$_patientId '
      'reminderId=$_reminderId isEditing=$_isEditing',
    );

    if (_isEditing && reminder != null) {
      _nameController.text = reminder.medicineName;
      _dosageController.text = reminder.dosage;
      _timesPerDayController.text = '${reminder.timesPerDay}';
      _reminderTimes = List<String>.from(reminder.reminderTimes);
      _startDate = reminder.startDate;
      _endDate = reminder.endDate;
      _isActive = reminder.isActive;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(isMobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildForm(isMobile),
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

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      height: 64,
      decoration: BoxDecoration(
        color: ColorConstants.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              debugPrint('[MedicationEditor] Back pressed');
              Get.back();
            },
            icon: const Icon(Icons.arrow_back, color: ColorConstants.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Reminder' : 'New Reminder',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: ColorConstants.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing
              ? 'Update the medicine reminder for this patient.'
              : 'Create a new medicine reminder for this patient.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Medicine name
        _buildLabel('MEDICINE NAME'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _nameController,
          hint: 'e.g., Folic Acid',
          maxLength: _maxNameChars,
        ),
        const SizedBox(height: 20),

        // Dosage
        _buildLabel('DOSAGE (e.g., 5mg)'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _dosageController,
          hint: 'e.g., 5mg, 10mg/ml',
          maxLength: _maxDosageChars,
        ),
        const SizedBox(height: 20),

        // Times per day
        _buildLabel('TIMES PER DAY'),
        const SizedBox(height: 8),
        _buildTimesPerDayField(),
        const SizedBox(height: 20),

        // Reminder times
        _buildLabel('REMINDER TIMES (click a slot to remove)'),
        const SizedBox(height: 8),
        _buildReminderTimesPicker(),
        const SizedBox(height: 20),

        // Dates
        _buildLabel('DATE RANGE'),
        const SizedBox(height: 8),
        _buildDateRangePicker(),
        const SizedBox(height: 12),

        // Active toggle
        _buildActiveToggle(),

        const SizedBox(height: 28),

        _buildSaveButton(),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ColorConstants.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      style: const TextStyle(color: ColorConstants.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
        ),
        filled: true,
        fillColor: ColorConstants.surfaceContainerLow,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.borderWhite10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.borderWhite10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildTimesPerDayField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _timesPerDayController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: ColorConstants.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g., 2',
              hintStyle: TextStyle(
                color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
              ),
              filled: true,
              fillColor: ColorConstants.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorConstants.borderWhite10,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorConstants.borderWhite10,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColorConstants.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicWidth(
            child: ElevatedButton.icon(
              onPressed: _reminderTimes.length < 8 ? _addReminderTime : null,
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('Add Time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryContainer,
                foregroundColor: ColorConstants.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderTimesPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: _reminderTimes.isEmpty
          ? const Text(
              'No reminder times yet. Tap "Add Time" to schedule doses.',
              style: TextStyle(color: ColorConstants.onSurfaceVariant),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reminderTimes.map((time) {
                return Chip(
                  backgroundColor: ColorConstants.primaryContainer.withOpacity(
                    0.2,
                  ),
                  label: Text(time),
                  labelStyle: const TextStyle(
                    color: ColorConstants.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onDeleted: () {
                    setState(() {
                      _reminderTimes.remove(time);
                    });
                  },
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 16,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _addReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) =>
          Theme(data: _timePickerTheme(), child: child!),
    );
    if (picked == null) return;

    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    final value = '$hh:$mm';

    if (_reminderTimes.contains(value)) {
      Get.snackbar(
        'Duplicate time',
        '$value is already scheduled.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (_reminderTimes.length >= 8) return;

    // Keep times sorted for a clean display.
    setState(() {
      _reminderTimes.add(value);
      _reminderTimes.sort();
    });
    debugPrint('[MedicationEditor] Added reminder time — $value');
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: 'Start date',
            value: _startDate.isEmpty ? 'Tap to set' : _startDate,
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateField(
            label: _endDate.isEmpty ? 'End date (optional)' : 'End date',
            value: _endDate.isEmpty ? 'Ongoing' : _endDate,
            onTap: () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ColorConstants.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.borderWhite10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.date_range,
              color: ColorConstants.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart || _startDate.isEmpty
          ? now
          : DateTime.tryParse(_startDate) ?? now,
      firstDate: isStart ? now.subtract(const Duration(days: 365)) : now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => _themeDatePicker(child),
    );
    if (picked == null) return;

    final value = _formatDate(picked);
    setState(() {
      if (isStart) {
        _startDate = value;
        // If end date is before the new start, clear it.
        if (_endDate.isNotEmpty && _endDate.compareTo(value) < 0) {
          _endDate = '';
        }
      } else {
        _endDate = value;
      }
    });
    debugPrint('[MedicationEditor] ${isStart ? "Start" : "End"} date — $value');
  }

  Widget _buildActiveToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _isActive,
      onChanged: (v) {
        setState(() => _isActive = v);
      },
      activeThumbColor: ColorConstants.tertiary,
      title: const Text(
        'Active reminder',
        style: TextStyle(color: ColorConstants.onSurface),
      ),
      subtitle: Text(
        _isActive
            ? 'The patient will be reminded at the scheduled times.'
            : 'Reminders are paused. Intake history is preserved.',
        style: const TextStyle(
          color: ColorConstants.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        _dosageController.text.trim().isNotEmpty &&
        _reminderTimes.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSave && !_isSaving ? _save : null,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save, size: 18),
        label: Text(
          _isSaving
              ? 'Saving...'
              : (_isEditing ? 'Update Reminder' : 'Save Reminder'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: ColorConstants.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final timesPerDay = int.tryParse(_timesPerDayController.text.trim()) ?? 0;

    final request = MedicineReminderRequest(
      patientId: _patientId,
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      timesPerDay: timesPerDay > 0 ? timesPerDay : _reminderTimes.length,
      reminderTimes: _reminderTimes,
      startDate: _startDate,
      endDate: _endDate.isEmpty ? null : _endDate,
      isActive: _isActive,
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _controller.updateReminder(_reminderId, request);
      } else {
        await _controller.createReminder(request);
      }
      if (mounted) Get.back();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Theme helpers ───────────────────────────────────────────────────────
  ThemeData _timePickerTheme() {
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: ColorConstants.primary,
        surface: ColorConstants.surfaceContainerHigh,
      ),
    );
  }

  Widget _themeDatePicker(Widget? child) {
    return Theme(
      data: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: ColorConstants.primary,
          surface: ColorConstants.surfaceContainerHigh,
        ),
      ),
      child: child!,
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
