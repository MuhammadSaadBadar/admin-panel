import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../controllers/sos_detail_controller.dart';
import '../models/sos_event.dart';
import '../repositories/sos_repository.dart';

/// Emergency SOS — detailed single-event view.
///
/// Integrates:
///   GET /api/v1/emergency/sos/{id}/             (event detail)
///   POST /api/v1/emergency/sos/{id}/resolve/    (resolve / false-alarm)
///
/// Shows live data from the backend: patient, status, coordinates, timestamps
/// and notes. Only data the API actually provides is displayed — no fabricated
/// vitals / risk factors / medications / emergency contacts.
class EmergencySosDetailScreen extends StatefulWidget {
  const EmergencySosDetailScreen({super.key});

  @override
  State<EmergencySosDetailScreen> createState() =>
      _EmergencySosDetailScreenState();
}

class _EmergencySosDetailScreenState extends State<EmergencySosDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final SosDetailController _controller;
  int _sosId = 0;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SosRepository>()) {
      Get.put(SosRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<SosDetailController>()) {
      Get.put(SosDetailController(Get.find<SosRepository>()));
    }
    _controller = Get.find<SosDetailController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['sosId'] != null) {
        _sosId = args['sosId'] as int;
        debugPrint('[EmergencySosDetail] loading SOS id=$_sosId');
        _controller.loadEvent(_sosId);
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.sos,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                Get.toNamed(route);
              },
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: isMobile
              ? _buildMain(isMobile)
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildMain(isMobile)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard', 'selected': false},
      {
        'icon': Icons.medical_services,
        'label': 'Doctor Management',
        'selected': false,
      },
      {'icon': Icons.person, 'label': 'Patient Management', 'selected': false},
      {'icon': Icons.event, 'label': 'Appointments', 'selected': false},
      {'icon': Icons.emergency, 'label': 'SOS Requests', 'selected': true},
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'selected': false,
      },
      {'icon': Icons.settings, 'label': 'Settings', 'selected': false},
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainer,
        border: Border(
          right: BorderSide(color: ColorConstants.onPrimary.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mama Health',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMIN CONSOLE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.05,
                    color: ColorConstants.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = item['selected'] as bool;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? ColorConstants.secondaryContainer
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? ColorConstants.onSecondaryContainer
                            : ColorConstants.onPrimary.withOpacity(0.7),
                        size: 24,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? ColorConstants.onSecondaryContainer
                              : ColorConstants.onPrimary.withOpacity(0.7),
                        ),
                      ),
                      onTap: () {
                        switch (index) {
                          case 0:
                            Get.toNamed(RouteNames.dashboard);
                            break;
                          case 1:
                            Get.toNamed(RouteNames.doctors);
                            break;
                          case 2:
                            Get.toNamed(RouteNames.patients);
                            break;
                          case 3:
                            Get.toNamed(RouteNames.appointments);
                            break;
                          case 4:
                            break;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain(bool isMobile) {
    return Column(
      children: [
        _buildTopAppBar(isMobile),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              );
            }
            if (_controller.error.value != null &&
                _controller.event.value == null) {
              return _buildError(isMobile);
            }
            final event = _controller.event.value;
            if (event == null) {
              return _buildError(isMobile);
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildStatusPill(event),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildPatientCard(event, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildLocationCard(event, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildMetadataCard(event, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildActionsCard(event, isMobile),
                    SizedBox(height: isMobile ? 80 : 100),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'SOS Details',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
    );
  }

  Widget _buildError(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: ColorConstants.error,
              size: isMobile ? 48 : 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load SOS event',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'No SOS event data available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onPrimary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _controller.loadEvent(_sosId),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(SosEvent event) {
    final color = _statusColor(event);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              event.statusLabel.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(SosEvent event, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Patient',
      icon: Icons.person,
      iconColor: ColorConstants.onPrimary,
      child: Column(
        children: [
          Row(
            children: [
              _avatar(event.patientName ?? '?', isMobile),
              SizedBox(width: isMobile ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.patientName ?? 'Unknown Patient',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                    if (event.patientEmail != null &&
                        event.patientEmail!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.patientEmail!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w500,
                          color: ColorConstants.onPrimary.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.onPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstants.onPrimary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'ID #${event.id}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onPrimary.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          if (event.patientId != null) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: ColorConstants.onPrimary.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Patient ID',
              value: '${event.patientId}',
              isMobile: isMobile,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(SosEvent event, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Location',
      icon: Icons.location_on_outlined,
      iconColor: ColorConstants.onPrimary,
      child: Column(
        children: [
          if (event.hasCoordinates) ...[
            _InfoRow(
              icon: Icons.my_location,
              label: 'Coordinates',
              value: '${event.latitude}, ${event.longitude}',
              isMobile: isMobile,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyCoordinates(event),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Coordinates'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.onPrimary,
                  backgroundColor: ColorConstants.onPrimary.withOpacity(0.1),
                  side: BorderSide(
                    color: ColorConstants.onPrimary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'No coordinates available for this event.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: ColorConstants.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataCard(SosEvent event, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Details',
      icon: Icons.info_outline,
      iconColor: ColorConstants.onPrimary.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.schedule,
            label: 'Triggered At',
            value: _formatDateTime(event.createdAt),
            isMobile: isMobile,
          ),
          if (event.resolvedAt != null && event.resolvedAt!.isNotEmpty)
            _InfoRow(
              icon: Icons.event_available,
              label: 'Resolved At',
              value: _formatDateTime(event.resolvedAt!),
              isMobile: isMobile,
            ),
          const SizedBox(height: 12),
          Text(
            'NOTES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: ColorConstants.onPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.notes.isNotEmpty ? event.notes : 'No notes provided.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w400,
              fontStyle: event.notes.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: event.notes.isEmpty
                  ? ColorConstants.onPrimary.withOpacity(0.7)
                  : ColorConstants.onPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(SosEvent event, bool isMobile) {
    final List<Widget> actions = [];

    if (event.isActive) {
      actions.add(
        _ActionButton(
          label: 'Resolve Incident',
          icon: Icons.check_circle_outline,
          color: ColorConstants.success,
          isMobile: isMobile,
          onPressed: () => _confirmResolve(event),
        ),
      );
      actions.add(
        _ActionButton(
          label: 'Mark as False Alarm',
          icon: Icons.help_outline,
          color: Colors.orange.shade400,
          isMobile: isMobile,
          onPressed: () => _confirmFalseAlarm(event),
        ),
      );
    }

    return _SectionCard(
      isMobile: isMobile,
      title: 'Actions',
      icon: Icons.tune,
      iconColor: ColorConstants.onPrimary,
      child: Obx(() {
        if (_controller.isResolving.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                color: ColorConstants.onPrimary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (actions.isEmpty) {
          return Text(
            'This event has already been handled.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: ColorConstants.onPrimary.withOpacity(0.7),
            ),
          );
        }
        return Wrap(spacing: 8, runSpacing: 8, children: actions);
      }),
    );
  }

  void _confirmResolve(SosEvent event) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Resolve Incident',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onPrimary,
          ),
        ),
        content: Text(
          'Mark SOS event #${event.id} as resolved?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onPrimary.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimary.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.resolveEvent(event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Resolve',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFalseAlarm(SosEvent event) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark as False Alarm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onPrimary,
          ),
        ),
        content: Text(
          'Mark SOS event #${event.id} as a false alarm?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onPrimary.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimary.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.markFalseAlarm(event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mark False Alarm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCoordinates(SosEvent event) async {
    if (!event.hasCoordinates) return;
    final coords = '${event.latitude}, ${event.longitude}';
    debugPrint('[EmergencySosDetail] copying coordinates: $coords');
    await Clipboard.setData(ClipboardData(text: coords));
    if (mounted) {
      Get.snackbar(
        'Copied',
        'Coordinates copied to clipboard.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: ColorConstants.primaryContainer,
        colorText: ColorConstants.onPrimary,
      );
    }
  }

  Color _statusColor(SosEvent event) {
    if (event.isActive) return ColorConstants.error;
    if (event.isResolved) return ColorConstants.success;
    return Colors.orange.shade400;
  }

  Widget _avatar(String fullName, bool isMobile) {
    final initials = _initials(fullName);
    return Container(
      width: isMobile ? 50 : 58,
      height: isMobile ? 50 : 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.secondaryContainer,
        border: Border.all(color: ColorConstants.secondary, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
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

class _SectionCard extends StatelessWidget {
  final bool isMobile;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.isMobile,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainer, // Full opacity (1.0)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: isMobile ? 20 : 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMobile;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorConstants.onPrimary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorConstants.onPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorConstants.onPrimary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: ColorConstants.onPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isMobile;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isMobile,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isMobile ? 15 : 16),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.12),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
    );
  }
}
