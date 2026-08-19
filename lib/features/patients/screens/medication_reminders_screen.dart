/// Medication Reminders screen — fully API-backed.
///
/// Fetches via `MedicationController`:
///   - the patient's medicine reminders (`GET /api/v1/medicines/reminders/`)
///
/// Supports create, edit, toggle active, and delete — all live from the API.
/// No placeholder/static data remains.

import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/routes/route_names.dart';
import 'package:admin/core/widgets/empty_state_widget.dart';
import 'package:admin/core/widgets/error_widget.dart';
import 'package:admin/features/patients/controllers/medication_controller.dart';
import 'package:admin/features/patients/models/medicine_reminder.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import '../../../core/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen>
    with SingleTickerProviderStateMixin {
  late final MedicationController _controller;
  int _patientId = 0;
  String _patientName = '';

  /// Guards against re-triggering the initial load on rebuilds.
  bool _hasLoaded = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveArgsAndLoad();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resolveArgsAndLoad() {
    if (_hasLoaded) {
      debugPrint('[MedicationReminders] Already loaded, skip');
      return;
    }
    final args = Get.arguments as Map<String, dynamic>?;
    _patientId = (args?['patientId'] as num?)?.toInt() ?? 0;
    _patientName = args?['patientName'] as String? ?? '';
    debugPrint(
      '[MedicationReminders] Resolved args — patientId=$_patientId '
      'patientName="$_patientName"',
    );
    if (_patientId != 0) {
      _hasLoaded = true;
      if (_patientName.isEmpty) {
        _loadPatientName();
      }
      _controller.load(_patientId);
    }
  }

  Future<void> _loadPatientName() async {
    try {
      final repo = Get.find<PatientRepository>();
      final patient = await repo.getPatient(_patientId);
      if (mounted) {
        setState(() => _patientName = patient.name);
      }
      debugPrint('[MedicationReminders] Loaded patient name="${patient.name}"');
    } catch (e) {
      debugPrint('[MedicationReminders] Failed to load patient name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: Column(
          children: [
            _buildTopAppBar(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientContext(isMobile),
                      const SizedBox(height: 24),
                      _buildReminderList(isMobile),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(),
        backgroundColor: ColorConstants.primary,
        foregroundColor: ColorConstants.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────
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
              debugPrint('[MedicationReminders] Back pressed');
              Get.back();
            },
            icon: const Icon(Icons.arrow_back, color: ColorConstants.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Medication Reminders',
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

  // ── Patient context ─────────────────────────────────────────────────────
  Widget _buildPatientContext(bool isMobile) {
    // The "active" pill can be wide; on narrow screens place it below the
    // patient name (via LayoutBuilder) to avoid flex overflow.
    final activePill = Obx(() {
      final active = _controller.reminders.where((r) => r.isActive).length;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorConstants.tertiary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$active active',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ColorConstants.tertiary,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackPill = constraints.maxWidth < 360;

          final avatar = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorConstants.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: ColorConstants.primary,
              size: 24,
            ),
          );

          final info = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName.isEmpty ? 'Patient' : _patientName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: #$_patientId',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );

          if (stackPill) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [avatar, const SizedBox(width: 16), info]),
                const SizedBox(height: 12),
                activePill,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              info,
              const SizedBox(width: 16),
              activePill,
            ],
          );
        },
      ),
    );
  }

  // ── Reminder list ───────────────────────────────────────────────────────
  Widget _buildReminderList(bool isMobile) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.reminders.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_controller.error.value != null && _controller.reminders.isEmpty) {
        return AppErrorWidget(
          message: _controller.error.value!,
          onRetry: () => _controller.load(_patientId),
        );
      }

      if (_controller.reminders.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.medication,
          title: 'No Reminders',
          message:
              'This patient has no medicine reminders. '
              'Tap the button below to create one.',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ALL REMINDERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              Obx(() {
                final total = _controller.reminders.length;
                return Text(
                  '$total total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          ..._controller.reminders.map(
            (reminder) => _ReminderCard(
              reminder: reminder,
              isMobile: isMobile,
              onEdit: () => _openEdit(reminder),
              onToggleActive: () => _toggleActive(reminder),
              onDelete: () => _confirmDelete(reminder),
            ),
          ),
        ],
      );
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _openCreate() {
    debugPrint('[MedicationReminders] Opening create — patientId=$_patientId');
    Get.toNamed(
      RouteNames.medicationEditor,
      arguments: {'patientId': _patientId, 'patientName': _patientName},
    );
  }

  void _openEdit(MedicineReminder reminder) {
    debugPrint('[MedicationReminders] Opening edit — id=${reminder.id}');
    Get.toNamed(
      RouteNames.medicationEditor,
      arguments: {
        'patientId': _patientId,
        'patientName': _patientName,
        'reminderId': reminder.id,
        'reminder': reminder,
      },
    );
  }

  Future<void> _toggleActive(MedicineReminder reminder) async {
    debugPrint(
      '[MedicationReminders] Toggle active — id=${reminder.id} '
      'current=${reminder.isActive}',
    );
    await _controller.toggleActive(reminder.id, !reminder.isActive);
  }

  void _confirmDelete(MedicineReminder reminder) {
    debugPrint('[MedicationReminders] Delete requested — id=${reminder.id}');
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Reminder?',
          style: TextStyle(color: ColorConstants.onSurface),
        ),
        content: Text(
          'This will permanently delete the reminder for '
          '"${reminder.medicineName}" and its intake history.',
          style: const TextStyle(color: ColorConstants.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ColorConstants.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _controller.deleteReminder(reminder.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: ColorConstants.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final MedicineReminder reminder;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.isMobile,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  String _formatTimes() {
    if (reminder.reminderTimes.isEmpty) return '—';
    return reminder.reminderTimes.join(', ');
  }

  String _formatDateRange() {
    final start = reminder.startDate.isNotEmpty
        ? reminder.startDate.substring(0, 10)
        : '?';
    if (reminder.isOngoing) return 'From $start • Ongoing';
    final end = reminder.endDate.substring(0, 10);
    return '$start → $end';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.isActive
              ? ColorConstants.tertiary.withOpacity(0.2)
              : ColorConstants.borderWhite10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Active badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      (reminder.isActive
                              ? ColorConstants.tertiary
                              : ColorConstants.onSurfaceVariant)
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color:
                        (reminder.isActive
                                ? ColorConstants.tertiary
                                : ColorConstants.onSurfaceVariant)
                            .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  reminder.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: reminder.isActive
                        ? ColorConstants.tertiary
                        : ColorConstants.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    if (reminder.dosage.isNotEmpty)
                      Text(
                        reminder.dosage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Deactivate toggle
              IconButton(
                tooltip: reminder.isActive ? 'Deactivate' : 'Activate',
                onPressed: onToggleActive,
                icon: Icon(
                  reminder.isActive
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined,
                  color: reminder.isActive
                      ? ColorConstants.tertiary
                      : ColorConstants.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Times and date
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InlineStat(
                icon: Icons.schedule,
                label: '${reminder.timesPerDay}x/day',
              ),
              if (reminder.reminderTimes.isNotEmpty)
                _InlineStat(icon: Icons.access_time, label: _formatTimes()),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.date_range,
                size: 14,
                color: ColorConstants.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateRange(),
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: ColorConstants.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorConstants.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: ColorConstants.onSurface),
        ),
      ],
    );
  }
}
