import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/color_constants.dart';
import '../models/medicine_reminder.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Detail view for a single medicine intake-log record.
///
/// The backend exposes `GET /api/v1/medicines/intake-logs/` (read-only) and
/// `GET /api/v1/medicines/intake-logs/{id}/`. The list endpoint already returns
/// the full `MedicineIntakeLog` object, so we pass the parsed record through
/// navigation arguments (no extra fetch needed) and render it here.
///
/// This screen is read-only; intake logs are never edited/deleted from the
/// admin console (the spec marks them read-only: `taken_at` is auto-set only
/// when `status=taken`, and only the patient can self-report via `/log-intake/`).
class MedicationIntakeDetailScreen extends StatelessWidget {
  const MedicationIntakeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    // Resolve the log from navigation arguments (defensive parsing).
    final args = Get.arguments as Map<String, dynamic>?;
    final log = args?['log'] as MedicineIntakeLog?;
    final patientName = args?['patientName'] as String? ?? '';

    debugPrint(
      '[MedicationIntakeDetail] build — log=${log?.id} status=${log?.status}',
    );

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: Column(
          children: [
            _buildTopAppBar(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: log == null
                        ? _buildMissingState(isMobile)
                        : _buildDetailCard(isMobile, log, patientName),
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
              debugPrint('[MedicationIntakeDetail] Back pressed');
              Get.back();
            },
            icon: const Icon(Icons.arrow_back, color: ColorConstants.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Intake Record',
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

  Widget _buildMissingState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medication_liquid,
              size: 56,
              color: ColorConstants.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No intake record selected',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    bool isMobile,
    MedicineIntakeLog log,
    String patientName,
  ) {
    final statusColor = _statusColor(log.status);
    final statusLabel = _statusLabel(log.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(log.status),
                  color: statusColor,
                  size: 26,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intake Log #${log.id}',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    if (patientName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildStatusBadge(statusLabel, statusColor),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 24),
          Divider(height: 1, color: ColorConstants.borderWhite10),
          SizedBox(height: isMobile ? 16 : 24),

          // Details
          _buildDetailRow(
            Icons.medication,
            'Reminder ID',
            '${log.reminderId}',
            isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildDetailRow(
            Icons.schedule,
            'Scheduled For',
            _formatDateTime(log.scheduledFor),
            isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildDetailRow(
            Icons.done_all,
            'Status',
            statusLabel,
            isMobile,
            valueColor: statusColor,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildDetailRow(
            Icons.event_available,
            'Taken At',
            log.takenAt.isNotEmpty ? _formatDateTime(log.takenAt) : '—',
            isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildDetailRow(
            Icons.event_note,
            'Logged At',
            log.loggedAt.isNotEmpty ? _formatDateTime(log.loggedAt) : '—',
            isMobile,
          ),

          SizedBox(height: isMobile ? 16 : 24),
          Divider(height: 1, color: ColorConstants.borderWhite10),
          SizedBox(height: isMobile ? 16 : 24),

          // Summary note
          Text(
            _statusHint(log.status),
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              height: 1.5,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isMobile, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 18 : 20,
          color: ColorConstants.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ColorConstants.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Color _statusColor(MedicineIntakeStatus status) {
    switch (status) {
      case MedicineIntakeStatus.taken:
        return ColorConstants.success;
      case MedicineIntakeStatus.skipped:
        return ColorConstants.error;
      case MedicineIntakeStatus.pending:
        return ColorConstants.warning;
    }
  }

  IconData _statusIcon(MedicineIntakeStatus status) {
    switch (status) {
      case MedicineIntakeStatus.taken:
        return Icons.check_circle;
      case MedicineIntakeStatus.skipped:
        return Icons.cancel;
      case MedicineIntakeStatus.pending:
        return Icons.schedule;
    }
  }

  String _statusLabel(MedicineIntakeStatus status) {
    switch (status) {
      case MedicineIntakeStatus.taken:
        return 'Taken';
      case MedicineIntakeStatus.skipped:
        return 'Skipped';
      case MedicineIntakeStatus.pending:
        return 'Pending';
    }
  }

  String _statusHint(MedicineIntakeStatus status) {
    switch (status) {
      case MedicineIntakeStatus.taken:
        return 'This dose was confirmed as taken by the patient.';
      case MedicineIntakeStatus.skipped:
        return 'This dose was marked as skipped by the patient.';
      case MedicineIntakeStatus.pending:
        return 'This dose is still pending — the patient has not yet confirmed it.';
    }
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • '
        '$h:$minute $ampm';
  }
}
