import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../controllers/sos_controller.dart';
import '../models/sos_event.dart';
import '../repositories/sos_repository.dart';

/// Emergency SOS — admin overview of all patient SOS events.
///
/// Integrates:
///   GET /api/v1/emergency/sos/             (list all, role-scoped for admin)
///   POST /api/v1/emergency/sos/{id}/resolve/ (resolve / false-alarm)
///
/// Displays metric cards (Active / Resolved / False Alarm), filter tabs,
/// and a live list of SOS events with inline resolve actions. Tapping a card
/// navigates to the SOS detail screen.
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final SosController _controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SosRepository>()) {
      Get.put(SosRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<SosController>()) {
      Get.put(SosController(Get.find<SosRepository>()));
    }
    _controller = Get.find<SosController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Load events on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.events.isEmpty) {
        debugPrint('[EmergencySosScreen] loading events on init');
        _controller.loadEvents();
      }
    });
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
        color: ColorConstants.surfaceContainerLow,
        border: Border(right: BorderSide(color: ColorConstants.borderWhite10)),
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
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMIN CONSOLE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.05,
                    color: ColorConstants.onSurfaceVariant,
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
                            : ColorConstants.onSurfaceVariant,
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
                              : ColorConstants.onSurfaceVariant,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildMetricCards(isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildFilterTabs(isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildEventList(isMobile),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Emergency SOS',
      showBackButton: isMobile,
      actions: [
        const NotificationBell(),
        IconButton(
          onPressed: () => _controller.loadEvents(),
          icon: Icon(
            Icons.refresh,
            color: ColorConstants.primary,
            size: isMobile ? 20 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOS Requests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          'Monitor and respond to patient emergency alerts.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards(bool isMobile) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: 'Active',
              value: _controller.activeCount,
              icon: Icons.warning_amber_rounded,
              color: ColorConstants.error,
              isMobile: isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: _MetricCard(
              label: 'Resolved',
              value: _controller.resolvedCount,
              icon: Icons.check_circle_rounded,
              color: ColorConstants.success,
              isMobile: isMobile,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'False Alarms',
                value: _controller.falseAlarmCount,
                icon: Icons.help_rounded,
                color: Colors.orange.shade400,
                isMobile: isMobile,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildFilterTabs(bool isMobile) {
    final filters = ['All', 'Active', 'Resolved', 'False Alarm'];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Obx(() {
              final selected = _controller.selectedFilter.value == filter;
              return GestureDetector(
                onTap: () => _controller.setFilter(filter),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 16,
                    horizontal: 4,
                  ),
                  margin: EdgeInsets.only(right: isMobile ? 20 : 32),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? ColorConstants.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                      color: selected
                          ? ColorConstants.primary
                          : ColorConstants.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            });
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEventList(bool isMobile) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.events.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
        );
      }

      if (_controller.error.value != null && _controller.events.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: ColorConstants.error,
                  size: isMobile ? 40 : 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load SOS events',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _controller.error.value!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _controller.loadEvents,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final events = _controller.filteredEvents;
      debugPrint(
        '[EmergencySosScreen] rendering ${events.length} events '
        '(filter=${_controller.selectedFilter.value})',
      );

      if (events.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
            child: Column(
              children: [
                Icon(
                  Icons.emergency,
                  color: ColorConstants.onSurfaceVariant,
                  size: isMobile ? 40 : 48,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'No SOS events found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: events.map((event) {
          return _SosEventTile(
            event: event,
            isMobile: isMobile,
            controller: _controller,
          );
        }).toList(),
      );
    });
  }

  Color _statusColor(SosEvent event) {
    if (event.isActive) return ColorConstants.error;
    if (event.isResolved) return ColorConstants.success;
    return Colors.orange.shade400;
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SosEventTile extends StatelessWidget {
  final SosEvent event;
  final bool isMobile;
  final SosController controller;

  const _SosEventTile({
    required this.event,
    required this.isMobile,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(event);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          debugPrint(
            '[EmergencySosScreen] navigating to detail for id=${event.id}',
          );
          Get.toNamed(RouteNames.sosDetail, arguments: {'sosId': event.id});
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusIcon(statusColor),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.patientName ?? 'Unknown Patient',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onPrimary,
                          ),
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text(
                          'SOS #${event.id}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(statusColor),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Divider(height: 1, color: ColorConstants.borderWhite5),
              SizedBox(height: isMobile ? 12 : 16),
              _buildDetailRow(
                Icons.access_time,
                'Triggered',
                _formatDateTime(event.createdAt),
                isMobile,
              ),
              const SizedBox(height: 8),
              if (event.hasCoordinates)
                _buildDetailRow(
                  Icons.location_on_outlined,
                  'Coordinates',
                  '${event.latitude}, ${event.longitude}',
                  isMobile,
                ),
              if (event.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.notes, 'Notes', event.notes, isMobile),
              ],
              SizedBox(height: isMobile ? 12 : 16),
              Divider(height: 1, color: ColorConstants.borderWhite5),
              SizedBox(height: isMobile ? 12 : 16),
              _buildStatusActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Color color) {
    return Container(
      width: isMobile ? 40 : 48,
      height: isMobile ? 40 : 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        event.isActive ? Icons.warning_amber_rounded : Icons.emergency,
        color: color,
        size: isMobile ? 20 : 24,
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            event.statusLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              color: ColorConstants.onPrimary,
              size: isMobile ? 16 : 18,
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusActions() {
    if (event.isResolved || event.isFalseAlarm) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'This event has already been handled.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: ColorConstants.onPrimary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          label: 'Resolve',
          icon: Icons.check_circle_outline,
          color: ColorConstants.success,
          isMobile: isMobile,
          onPressed: () => _confirmResolve(),
        ),
        _ActionButton(
          label: 'False Alarm',
          icon: Icons.help_outline,
          color: Colors.orange.shade400,
          isMobile: isMobile,
          onPressed: () => _confirmFalseAlarm(),
        ),
      ],
    );
  }

  void _confirmResolve() {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Resolve Incident',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Mark SOS event #${event.id} as resolved?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurfaceVariant,
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
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resolveEvent(event.id);
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFalseAlarm() {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark as False Alarm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Mark SOS event #${event.id} as a false alarm?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurfaceVariant,
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
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markFalseAlarm(event.id);
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SosEvent event) {
    if (event.isActive) return ColorConstants.error;
    if (event.isResolved) return ColorConstants.success;
    return Colors.orange.shade400;
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
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withOpacity(0.4)),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }
}
