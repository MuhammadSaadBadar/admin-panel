import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../controllers/medication_controller.dart';
import '../models/medicine_reminder.dart';
import '../repositories/patient_repository.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Medication intake-history screen — fully API-backed.
///
/// Fetches via [MedicationController] the patient's medicine intake logs
/// (`GET /api/v1/medicines/intake-logs/?patient_id=`), with client-side
/// filtering by status. Logs are grouped by day (from `scheduled_for`), newest
/// first. Tapping a log opens [MedicationIntakeDetailScreen].
///
/// No placeholder/static data remains.
class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({super.key});

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  late final MedicationController _controller;
  int _patientId = 0;
  String _patientName = '';

  /// Guard against re-triggering the initial load on rebuilds.
  bool _hasLoaded = false;

  /// Status filter; a null value means "All statuses".
  MedicineIntakeStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    debugPrint('[MedicationHistory] initState');
    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<MedicationController>()) {
      Get.put(MedicationController(Get.find<PatientRepository>()));
    }
    _controller = Get.find<MedicationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveArgsAndLoad();
    });
  }

  void _resolveArgsAndLoad() {
    if (_hasLoaded) {
      debugPrint('[MedicationHistory] Already loaded, skip');
      return;
    }
    final args = Get.arguments as Map<String, dynamic>?;
    _patientId = (args?['patientId'] as num?)?.toInt() ?? 0;
    _patientName = args?['patientName'] as String? ?? '';
    debugPrint(
      '[MedicationHistory] Resolved args — patientId=$_patientId '
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
      debugPrint('[MedicationHistory] Loaded patient name="${patient.name}"');
    } catch (e) {
      debugPrint('[MedicationHistory] Failed to load patient name: $e');
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
              child: RefreshIndicator(
                onRefresh: () => _controller.refresh(),
                color: ColorConstants.primary,
                backgroundColor: ColorConstants.cardBackground,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientContext(isMobile),
                        const SizedBox(height: 16),
                        _buildFilters(isMobile),
                        const SizedBox(height: 16),
                        _buildLogList(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
              debugPrint('[MedicationHistory] Back pressed');
              Get.back();
            },
            icon: const Icon(Icons.arrow_back, color: ColorConstants.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Medication History',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: ColorConstants.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              debugPrint('[MedicationHistory] Refresh pressed');
              _controller.refresh();
            },
            icon: Icon(
              Icons.refresh,
              color: ColorConstants.primary,
              size: isMobile ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientContext(bool isMobile) {
    // The count-pill summary can be wide; on narrow screens place it below
    // the patient name (via LayoutBuilder) to avoid flex overflow.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackPills = constraints.maxWidth < 420;

          final info = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName.isEmpty ? 'Patient' : _patientName,
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

          // The summary-count pills.
          final counts = Obx(() {
            final logs = _controller.intakeLogs;
            final taken = logs
                .where((l) => l.status == MedicineIntakeStatus.taken)
                .length;
            final skipped = logs
                .where((l) => l.status == MedicineIntakeStatus.skipped)
                .length;
            final pending = logs
                .where((l) => l.status == MedicineIntakeStatus.pending)
                .length;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _CountPill(
                  label: '$taken taken',
                  color: ColorConstants.success,
                ),
                _CountPill(
                  label: '$skipped skipped',
                  color: ColorConstants.error,
                ),
                if (pending > 0)
                  _CountPill(
                    label: '$pending pending',
                    color: ColorConstants.warning,
                  ),
              ],
            );
          });

          if (stackPills) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
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
                    ),
                    const SizedBox(width: 16),
                    info,
                  ],
                ),
                const SizedBox(height: 12),
                counts,
              ],
            );
          }

          return Row(
            children: [
              Container(
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
              ),
              const SizedBox(width: 16),
              info,
              const SizedBox(width: 16),
              counts,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Status filter
        Container(
          width: isMobile ? double.infinity : 260,
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MedicineIntakeStatus?>(
              value: _statusFilter,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more,
                color: ColorConstants.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              dropdownColor: ColorConstants.surfaceContainer,
              hint: const Text(
                'All statuses',
                style: TextStyle(color: ColorConstants.onSurfaceVariant),
              ),
              items: [
                const DropdownMenuItem<MedicineIntakeStatus?>(
                  value: null,
                  child: Text('All statuses'),
                ),
                DropdownMenuItem<MedicineIntakeStatus?>(
                  value: MedicineIntakeStatus.taken,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ColorConstants.success,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Taken'),
                    ],
                  ),
                ),
                DropdownMenuItem<MedicineIntakeStatus?>(
                  value: MedicineIntakeStatus.skipped,
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: ColorConstants.error, size: 18),
                      SizedBox(width: 8),
                      Text('Skipped'),
                    ],
                  ),
                ),
                DropdownMenuItem<MedicineIntakeStatus?>(
                  value: MedicineIntakeStatus.pending,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: ColorConstants.warning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Pending'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                debugPrint(
                  '[MedicationHistory] Status filter set to '
                  '${value?.name ?? "all"}',
                );
                setState(() => _statusFilter = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  List<MedicineIntakeLog> get _filteredLogs {
    return _controller.intakeLogs.where((log) {
      if (_statusFilter != null && log.status != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Groups logs by date (the date portion of `scheduled_for`), newest first.
  Map<String, List<MedicineIntakeLog>> get _logsByDay {
    final map = <String, List<MedicineIntakeLog>>{};
    for (final log in _filteredLogs) {
      final day = _dayKey(log.scheduledFor);
      map.putIfAbsent(day, () => []).add(log);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  Widget _buildLogList(bool isMobile) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.intakeLogs.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_controller.error.value != null && _controller.intakeLogs.isEmpty) {
        return AppErrorWidget(
          message: _controller.error.value!,
          onRetry: () => _controller.load(_patientId),
        );
      }

      final logs = _filteredLogs;
      if (logs.isEmpty) {
        return _hasLoaded
            ? const EmptyStateWidget(
                icon: Icons.medication_liquid,
                title: 'No Intake Records',
                message:
                    'No medication intake logs were found for this patient.',
              )
            : const SizedBox.shrink();
      }

      final grouped = _logsByDay;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INTAKE HISTORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${logs.length} record(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayHeader(entry.key),
                const SizedBox(height: 8),
                ...entry.value.map(
                  (log) => _LogCard(
                    log: log,
                    isMobile: isMobile,
                    onTap: () => _openDetail(log),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      );
    });
  }

  Widget _buildDayHeader(String dayKey) {
    final suffix = dayKey == _todayKey() ? '  (Today)' : '';
    return Text(
      '${_formatDayHeader(dayKey)}$suffix',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ColorConstants.onSurface,
      ),
    );
  }

  void _openDetail(MedicineIntakeLog log) {
    debugPrint('[MedicationHistory] Opening intake detail — id=${log.id}');
    Get.toNamed(
      RouteNames.medicationIntakeDetail,
      arguments: {'log': log, 'patientName': _patientName},
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _dayKey(String raw) {
    if (raw.isEmpty) return 'unknown';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDayHeader(String dayKey) {
    final dt = DateTime.tryParse(dayKey);
    if (dt == null) return dayKey;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final year = dt.year.toString();
    final monthDay = '${months[dt.month - 1]} ${dt.day}';
    // If the date is in the past, show the year too; otherwise omit it.
    if (dt.year == DateTime.now().year) return monthDay;
    return '$monthDay, $year';
  }
}

/// A small count pill used in the patient-context summary.
class _CountPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CountPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A single intake-log row/card.
class _LogCard extends StatelessWidget {
  final MedicineIntakeLog log;
  final bool isMobile;
  final VoidCallback onTap;

  const _LogCard({
    required this.log,
    required this.isMobile,
    required this.onTap,
  });

  Color get _statusColor {
    switch (log.status) {
      case MedicineIntakeStatus.taken:
        return ColorConstants.success;
      case MedicineIntakeStatus.skipped:
        return ColorConstants.error;
      case MedicineIntakeStatus.pending:
        return ColorConstants.warning;
    }
  }

  IconData get _statusIcon {
    switch (log.status) {
      case MedicineIntakeStatus.taken:
        return Icons.check_circle;
      case MedicineIntakeStatus.skipped:
        return Icons.cancel;
      case MedicineIntakeStatus.pending:
        return Icons.schedule;
    }
  }

  String get _statusLabel {
    switch (log.status) {
      case MedicineIntakeStatus.taken:
        return 'Taken';
      case MedicineIntakeStatus.skipped:
        return 'Skipped';
      case MedicineIntakeStatus.pending:
        return 'Pending';
    }
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '$h:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: ColorConstants.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: color, width: 4),
            top: BorderSide(color: ColorConstants.borderWhite5),
            bottom: BorderSide(color: ColorConstants.borderWhite5),
            right: BorderSide(color: ColorConstants.borderWhite5),
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: isMobile ? 38 : 42,
              height: isMobile ? 38 : 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon, color: color, size: 22),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log #${log.id}',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InlineDetail(
                        icon: Icons.schedule,
                        text: 'Scheduled ${_formatTime(log.scheduledFor)}',
                      ),
                      if (log.takenAt.isNotEmpty)
                        _InlineDetail(
                          icon: Icons.done_all,
                          text: 'Taken ${_formatTime(log.takenAt)}',
                          tint: ColorConstants.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? tint;

  const _InlineDetail({required this.icon, required this.text, this.tint});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tint ?? ColorConstants.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: tint ?? ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
