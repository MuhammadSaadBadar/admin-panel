import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../doctors/models/doctor.dart';
import '../../patients/models/patient.dart';
import '../controllers/search_controller.dart';
import '../models/search_results.dart';
import '../repositories/search_repository.dart';

/// Global search overlay — a command-palette style, full-area modal that lets
/// an admin search across doctors, patients, and appointments from anywhere.
///
/// On desktop it appears as a centered floating panel; on mobile it expands to
/// a near-full-screen sheet. Results are grouped into categorized sections
/// (Doctors / Patients / Appointments) and each row deep-links to the matching
/// detail screen.
class GlobalSearchOverlay extends StatefulWidget {
  const GlobalSearchOverlay({super.key});

  /// Opens the global search overlay.
  static Future<void> open() {
    return Get.dialog(
      const GlobalSearchOverlay(),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  State<GlobalSearchOverlay> createState() => _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends State<GlobalSearchOverlay> {
  late final SearchController _controller;
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SearchRepository>()) {
      Get.put(SearchRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<SearchController>()) {
      Get.put(SearchController(Get.find<SearchRepository>()));
    }
    _controller = Get.find<SearchController>();
    _textController = TextEditingController(text: _controller.currentQuery);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 48,
        vertical: isMobile ? 12 : 40,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 720,
        constraints: BoxConstraints(
          maxHeight: isMobile
              ? MediaQuery.of(context).size.height * 0.9
              : MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorConstants.borderWhite10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchField(isMobile),
            const Divider(height: 1, color: ColorConstants.borderWhite10),
            Expanded(child: _buildResultsBody(isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 12, 12, 12),
      child: Row(
        children: [
          Icon(Icons.search, color: ColorConstants.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: _controller.onQueryChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ColorConstants.onSurface,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search patients, doctors, appointments…',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: ColorConstants.onSurfaceVariant.withOpacity(0.6),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_controller.currentQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _textController.clear();
                _controller.clear();
              },
              icon: Icon(
                Icons.clear,
                color: ColorConstants.onSurfaceVariant,
                size: 20,
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close,
              color: ColorConstants.onSurfaceVariant,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsBody(bool isMobile) {
    return Obx(() {
      // Idle state — not enough characters yet.
      if (!_controller.hasSearched.value) {
        return _buildIdleState(isMobile);
      }

      // Loading (first search) — show a spinner.
      if (_controller.isSearching.value && _controller.results.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: ColorConstants.primary),
        );
      }

      // Error state.
      if (_controller.error.value != null) {
        return _buildErrorState(isMobile, _controller.error.value!);
      }

      // Empty results.
      final results = _controller.results.value;
      if (results == null || results.isEmpty) {
        return _buildEmptyState(isMobile, _controller.currentQuery);
      }

      // Results — categorized sections.
      return _buildResultsList(isMobile, results);
    });
  }

  Widget _buildIdleState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              color: ColorConstants.primary.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Search across the platform',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type at least 2 characters to search patients, doctors, and appointments.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No patients, doctors, or appointments match "$query".',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ColorConstants.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _controller.onQueryChanged(_textController.text),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isMobile, SearchResults results) {
    return ListView(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 16),
      children: [
        if (results.hasDoctors)
          _SearchSectionHeader(
            icon: Icons.medical_services_rounded,
            label: 'Doctors',
            count: results.doctors.length,
            color: ColorConstants.secondary,
            onViewAll: () => _goToFullList(RouteNames.doctors),
          ),
        if (results.hasDoctors)
          ...results.doctors.map(
            (d) => _DoctorResultTile(doctor: d, onTap: () => _openDoctor(d)),
          ),
        if (results.hasPatients)
          _SearchSectionHeader(
            icon: Icons.people_alt_rounded,
            label: 'Patients',
            count: results.patients.length,
            color: ColorConstants.primary,
            onViewAll: () => _goToFullList(RouteNames.patients),
          ),
        if (results.hasPatients)
          ...results.patients.map(
            (p) => _PatientResultTile(patient: p, onTap: () => _openPatient(p)),
          ),
        if (results.hasAppointments)
          _SearchSectionHeader(
            icon: Icons.event_rounded,
            label: 'Appointments',
            count: results.appointments.length,
            color: ColorConstants.tertiary,
            onViewAll: () => _goToFullList(RouteNames.appointments),
          ),
        if (results.hasAppointments)
          ...results.appointments.map(
            (a) => _AppointmentResultTile(
              hit: a,
              onTap: () => _openAppointment(a),
            ),
          ),
      ],
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  void _openDoctor(Doctor doctor) {
    Get.back(); // close overlay
    Get.toNamed(RouteNames.doctorDetail, arguments: {'doctorId': doctor.id});
  }

  void _openPatient(Patient patient) {
    Get.back(); // close overlay
    Get.toNamed(RouteNames.patientDetail, arguments: {'patientId': patient.id});
  }

  void _openAppointment(AppointmentSearchHit hit) {
    Get.back(); // close overlay
    Get.toNamed(
      RouteNames.appointmentDetail,
      arguments: {'appointmentId': hit.id},
    );
  }

  void _goToFullList(String route) {
    Get.back(); // close overlay
    Get.toNamed(route);
  }
}

// ───────────────────────────────────────────────
// Section header
// ───────────────────────────────────────────────

class _SearchSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onViewAll;

  const _SearchSectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Base result tile
// ───────────────────────────────────────────────

class _ResultTileBase extends StatelessWidget {
  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback onTap;

  const _ResultTileBase({
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: leadingColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadingIcon, color: leadingColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (statusLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (statusColor ?? ColorConstants.onSurfaceVariant)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor ?? ColorConstants.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Doctor result
// ───────────────────────────────────────────────

class _DoctorResultTile extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const _DoctorResultTile({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (doctor.specialization.isNotEmpty) doctor.specialization,
      if (doctor.city.isNotEmpty && doctor.city != 'Unknown') doctor.city,
      if (doctor.email.isNotEmpty) doctor.email,
    ];
    final isPending = doctor.isPending;
    final statusLabel = isPending
        ? 'Pending'
        : (doctor.isActive ? 'Active' : 'Inactive');
    final statusColor = isPending
        ? ColorConstants.warning
        : (doctor.isActive ? ColorConstants.success : ColorConstants.error);

    return _ResultTileBase(
      leadingIcon: Icons.medical_services_rounded,
      leadingColor: ColorConstants.secondary,
      title: doctor.name,
      subtitle: subtitleParts.join(' • '),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: onTap,
    );
  }
}

// ───────────────────────────────────────────────
// Patient result
// ───────────────────────────────────────────────

class _PatientResultTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientResultTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (patient.email.isNotEmpty) patient.email,
      if (patient.phoneNumber.isNotEmpty) patient.phoneNumber,
    ];

    return _ResultTileBase(
      leadingIcon: Icons.people_alt_rounded,
      leadingColor: ColorConstants.primary,
      title: patient.name,
      subtitle: subtitleParts.join(' • '),
      statusLabel: patient.isActive ? 'Active' : 'Inactive',
      statusColor: patient.isActive
          ? ColorConstants.success
          : ColorConstants.error,
      onTap: onTap,
    );
  }
}

// ───────────────────────────────────────────────
// Appointment result
// ───────────────────────────────────────────────

class _AppointmentResultTile extends StatelessWidget {
  final AppointmentSearchHit hit;
  final VoidCallback onTap;

  const _AppointmentResultTile({required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (hit.doctorName.isNotEmpty) hit.doctorName,
      if (hit.scheduledAt.isNotEmpty) hit.scheduledAt,
    ];
    final statusColor = _statusColor(hit.status);

    return _ResultTileBase(
      leadingIcon: Icons.event_rounded,
      leadingColor: ColorConstants.tertiary,
      title: hit.patientName.isNotEmpty
          ? hit.patientName
          : 'Appointment #${hit.id}',
      subtitle: subtitleParts.join(' • '),
      statusLabel: _statusLabel(hit.status),
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No-show';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ColorConstants.warning;
      case 'confirmed':
        return ColorConstants.tertiary;
      case 'completed':
        return ColorConstants.success;
      case 'cancelled':
        return ColorConstants.error;
      case 'no_show':
        return ColorConstants.onSurfaceVariant;
      default:
        return ColorConstants.onSurfaceVariant;
    }
  }
}
