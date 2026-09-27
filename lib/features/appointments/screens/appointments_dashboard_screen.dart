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
import '../controllers/appointment_controller.dart';
import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Appointments Dashboard — overview of all appointments.
///
/// Integrates:
///   GET  /api/v1/appointments/             (list, paginated)
///   POST /api/v1/appointments/{id}/status/ (status state machine)
///
/// Displays a ListTile-based list with patient / doctor / date-time / type /
/// status, provides status actions, and navigates to the Appointment Details
/// screen on tap.
class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final AppointmentController _controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AppointmentRepository>()) {
      Get.put(AppointmentRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<AppointmentController>()) {
      Get.put(AppointmentController(Get.find<AppointmentRepository>()));
    }
    _controller = Get.find<AppointmentController>();

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
              currentRoute: RouteNames.appointments,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                Get.toNamed(route);
              },
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: isMobile
              ? _buildMobileLayout(isMobile)
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildMobileLayout(isMobile)),
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
      {'icon': Icons.event, 'label': 'Appointments', 'selected': true},
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'selected': false,
      },
      {
        'icon': Icons.description,
        'label': 'Content Management',
        'selected': false,
      },
      {'icon': Icons.emergency, 'label': 'SOS Requests', 'selected': false},
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

  Widget _buildMobileLayout(bool isMobile) {
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
                  _buildTabs(isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildAppointmentList(isMobile),
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
      title: 'Appointments',
      showBackButton: isMobile,
      actions: const [NotificationBell()],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          'Review, filter, and manage patient appointments.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isMobile) {
    final tabs = <({int id, String label})>[
      (id: 0, label: 'Upcoming'),
      (id: 1, label: 'Unpaid'),
      (id: 2, label: 'Past'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            return Obx(() {
              final selected = _controller.selectedTabIndex.value == tab.id;
              return GestureDetector(
                onTap: () => _controller.switchTab(tab.id),
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
                    tab.label,
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

  Widget _buildAppointmentList(bool isMobile) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.appointments.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
        );
      }

      if (_controller.error.value != null && _controller.appointments.isEmpty) {
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
                  'Failed to load appointments',
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
                  onPressed: _controller.loadAppointments,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final appointments = _controller.filteredAppointments;
      debugPrint(
        '[AppointmentDashboard] rendering ${appointments.length} appointments '
        '(loading=${_controller.isLoading.value})',
      );

      if (appointments.isEmpty) {
        final String emptyMessage;
        switch (_controller.selectedTabIndex.value) {
          case 0:
            emptyMessage = 'No upcoming appointments found';
            break;
          case 1:
            emptyMessage = 'No unpaid appointments found';
            break;
          case 2:
            emptyMessage = 'No past appointments found';
            break;
          default:
            emptyMessage = 'No appointments found';
        }
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  color: ColorConstants.onSurfaceVariant,
                  size: isMobile ? 40 : 48,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  emptyMessage,
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
        children: appointments.map((appointment) {
          return _AppointmentTile(
            appointment: appointment,
            isMobile: isMobile,
            controller: _controller,
          );
        }).toList(),
      );
    });
  }
}

/// A single ListTile-based appointment row.
class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isMobile;
  final AppointmentController controller;

  const _AppointmentTile({
    required this.appointment,
    required this.isMobile,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    final scheduledLabel = _formatScheduled(appointment.scheduledAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          debugPrint(
            '[AppointmentDashboard] navigating to details for id=${appointment.id}',
          );
          final updated = await Get.toNamed<Appointment?>(
            RouteNames.appointmentDetail,
            arguments: {'appointmentId': appointment.id},
          );
          if (updated != null) {
            debugPrint(
              '[AppointmentDashboard] details returned updated appointment — '
              'merging into list id=${updated.id} status=${updated.status.displayLabel}',
            );
            controller.applyExternalUpdate(updated);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patient.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text(
                          'ID #${appointment.id}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.onSurfaceVariant,
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
                Icons.medical_services,
                'Doctor',
                appointment.doctor.fullName,
                isMobile,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.event,
                'Date & Time',
                scheduledLabel,
                isMobile,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.meeting_room_outlined,
                'Type',
                appointment.appointmentType.displayLabel,
                isMobile,
              ),
              if (appointment.hasPayment) ...[
                const SizedBox(height: 8),
                _buildPaymentStatusRow(isMobile),
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

  Widget _buildAvatar() {
    final initials = _initials(appointment.patient.fullName);
    return Container(
      width: isMobile ? 40 : 48,
      height: isMobile ? 40 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.secondaryContainer,
        border: Border.all(color: ColorConstants.secondary, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSecondaryContainer,
          ),
        ),
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
            appointment.status.displayLabel,
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

  Widget _buildPaymentStatusRow(bool isMobile) {
    final payment = appointment.payment!;
    final Color paymentColor;
    final IconData paymentIcon;
    switch (payment.status) {
      case PaymentState.pending:
        paymentColor = Colors.orange.shade600;
        paymentIcon = Icons.hourglass_empty;
        break;
      case PaymentState.awaitingVerification:
        paymentColor = Colors.amber.shade700;
        paymentIcon = Icons.pending_actions;
        break;
      case PaymentState.verified:
        paymentColor = ColorConstants.success;
        paymentIcon = Icons.verified;
        break;
      case PaymentState.rejected:
        paymentColor = ColorConstants.error;
        paymentIcon = Icons.cancel;
        break;
      case PaymentState.none:
        return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(paymentIcon, color: paymentColor, size: isMobile ? 16 : 18),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              payment.status.displayLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: paymentColor,
              ),
            ),
          ],
        ),
      ],
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
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: ColorConstants.primary, size: isMobile ? 16 : 18),
            SizedBox(width: isMobile ? 4 : 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurface,
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
    final status = appointment.status;
    final List<Widget> actions = [];

    // pending -> confirmed | cancelled
    if (status == AppointmentStatus.pending) {
      if (appointment.canConfirmFreely) {
        actions.add(
          _ActionButton(
            label: 'Confirm (Free Consultation)',
            icon: Icons.check,
            color: ColorConstants.tertiary,
            isMobile: isMobile,
            onPressed: () => controller.confirmAppointment(appointment.id),
          ),
        );
      } else {
        actions.add(
          Obx(() {
            final isProcessing = controller.isProcessingAction.value;
            return _ActionButton(
              label: isProcessing ? 'Verifying...' : 'Verify Payment & Confirm',
              icon: Icons.verified_user,
              color: ColorConstants.success,
              isMobile: isMobile,
              onPressed: () {
                if (isProcessing) return;
                controller.confirmAppointment(appointment.id);
              },
            );
          }),
        );
      }
      actions.add(
        _ActionButton(
          label: 'Cancel',
          icon: Icons.close,
          color: ColorConstants.error,
          isMobile: isMobile,
          onPressed: () => _confirmCancel(),
        ),
      );
    }
    // confirmed -> completed | cancelled | no_show
    if (status == AppointmentStatus.confirmed) {
      actions.add(
        _ActionButton(
          label: 'Complete',
          icon: Icons.check_circle_outline,
          color: ColorConstants.success,
          isMobile: isMobile,
          onPressed: () => controller.completeAppointment(appointment.id),
        ),
      );
      actions.add(
        _ActionButton(
          label: 'No-show',
          icon: Icons.person_off,
          color: Colors.orange.shade400,
          isMobile: isMobile,
          onPressed: () => controller.markNoShow(appointment.id),
        ),
      );
      actions.add(
        _ActionButton(
          label: 'Cancel',
          icon: Icons.close,
          color: ColorConstants.error,
          isMobile: isMobile,
          onPressed: () => _confirmCancel(),
        ),
      );
    }

    if (actions.isEmpty) {
      return Center(
        child: Text(
          'No actions available for this status.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  void _confirmCancel() {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this appointment with '
              '${appointment.patient.fullName}?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why is this being cancelled?',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConstants.borderWhite10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConstants.borderWhite10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConstants.primary),
                ),
                filled: true,
                fillColor: ColorConstants.surfaceContainer,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Keep',
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
              final reason = reasonController.text.trim();
              controller.cancelAppointment(appointment.id, reason: reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: ColorConstants.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes, Cancel',
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

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange.shade400;
      case AppointmentStatus.confirmed:
        return ColorConstants.tertiary;
      case AppointmentStatus.completed:
        return ColorConstants.success;
      case AppointmentStatus.cancelled:
        return ColorConstants.error;
      case AppointmentStatus.noShow:
        return ColorConstants.onSurfaceVariant;
      case AppointmentStatus.unknown:
        return ColorConstants.onSurfaceVariant;
    }
  }

  String _formatScheduled(DateTime? scheduledAt) {
    if (scheduledAt == null) return 'Not scheduled';
    final local = scheduledAt.toLocal();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
    return '${weekdays[local.weekday - 1]}, ${months[local.month - 1]} '
        '${local.day}, ${local.year} • $h:$minute $ampm';
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
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
