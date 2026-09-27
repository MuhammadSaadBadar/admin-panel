import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../controllers/appointment_detail_controller.dart';
import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Appointment Details — comprehensive single-appointment view.
///
/// Integrates the remaining appointment APIs:
///   GET   /api/v1/appointments/{id}/              (fetch detail)
///   POST  /api/v1/appointments/{id}/status/       (status state machine)
///   PATCH /api/v1/appointments/{id}/reschedule/   (reschedule)
///   PATCH /api/v1/appointments/{id}/doctor-notes/ (doctor notes)
///
/// All data is live from the backend; no static/placeholder content.
class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final AppointmentDetailController _controller;
  int _appointmentId = 0;

  /// Set to `true` as soon as any mutating action on this screen (status
  /// change, payment verify, reschedule, doctor notes) writes a new
  /// `Appointment` to the controller. Used by [PopScope] below to ship
  /// the latest snapshot back to the caller via `Get.back(result:)`.
  bool _dirty = false;

  /// Worker that flips [_dirty] whenever the controller's appointment
  /// changes after the initial load.
  Worker? _dirtyWorker;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AppointmentRepository>()) {
      Get.put(AppointmentRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<AppointmentDetailController>()) {
      Get.put(AppointmentDetailController(Get.find<AppointmentRepository>()));
    }
    _controller = Get.find<AppointmentDetailController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['appointmentId'] != null) {
        _appointmentId = args['appointmentId'] as int;
        debugPrint(
          '[AppointmentDetails] loading appointment id=$_appointmentId',
        );
        _controller.loadAppointment(_appointmentId);
      }
    });

    // Mark the screen dirty on every controller-level change to the
    // appointment snapshot. The Worker is attached AFTER the initial
    // loadAppointment call so the very first assignment (which mirrors
    // whatever the caller already had) doesn't count as a mutation.
    _dirtyWorker = ever<Appointment?>(
      _controller.appointment,
      _onAppointmentChanged,
    );

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

  void _onAppointmentChanged(Appointment? next) {
    if (next == null) return;
    // Only mark dirty once we have a non-null snapshot loaded; the first
    // load fires here too, so we additionally require that the id matches
    // the screen's target id (the very first emission is the one we
    // triggered in initState).
    if (next.id == _appointmentId && _controller.hasLoadedOnce) {
      _dirty = true;
      debugPrint(
        '[AppointmentDetails] dirty=true after appointment update id=${next.id}',
      );
    }
  }

  @override
  void dispose() {
    _dirtyWorker?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    // We control the pop ourselves so that we can attach the latest
    // appointment snapshot as the route's `result` — which the dashboard
    // tile awaits to keep its list in sync with whatever mutation the
    // user made on this screen.
    return PopScope<Appointment?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final snapshot = _dirty ? _controller.appointment.value : null;
        debugPrint(
          '[AppointmentDetails] pop intercepted — shipping result '
          'dirty=$_dirty id=${snapshot?.id} status=${snapshot?.status.displayLabel ?? 'n/a'}',
        );
        Navigator.of(context).pop<Appointment?>(snapshot);
      },
      child: Scaffold(
        backgroundColor: ColorConstants.scaffoldBackground,
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
        bottomNavigationBar: null,
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
                _controller.appointment.value == null) {
              return _buildError(isMobile);
            }
            final appointment = _controller.appointment.value;
            if (appointment == null) {
              return _buildError(isMobile);
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildStatusPill(appointment),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildPatientCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildDoctorCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildScheduleCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildReasonAndNotesCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildMetadataCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildActionsCard(appointment, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildPaymentCard(appointment, isMobile),
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
      title: 'Appointment Details',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications,
            color: ColorConstants.primary,
            size: isMobile ? 20 : 24,
          ),
        ),
      ],
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
              'Failed to load appointment',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'No appointment data available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _controller.loadAppointment(_appointmentId),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(Appointment appointment) {
    final color = _statusColor(appointment.status);
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
              appointment.status.displayLabel.toUpperCase(),
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

  Widget _buildPatientCard(Appointment appointment, bool isMobile) {
    return _SectionCardforDP(
      isMobile: isMobile,
      title: 'Patient',
      icon: Icons.person,
      iconColor: ColorConstants.secondary,
      child: Row(
        children: [
          _avatar(appointment.patient.fullName, isMobile),
          SizedBox(width: isMobile ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patient.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.patient.email.isNotEmpty
                      ? appointment.patient.email
                      : 'No email on file',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Text(
              'ID #${appointment.id}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Appointment appointment, bool isMobile) {
    return _SectionCardforDP(
      isMobile: isMobile,
      title: 'Doctor',
      icon: Icons.medical_services,
      iconColor: ColorConstants.secondary,
      child: Row(
        children: [
          _avatar(appointment.doctor.fullName, isMobile),
          SizedBox(width: isMobile ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctor.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.doctor.email.isNotEmpty
                      ? appointment.doctor.email
                      : 'No email on file',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
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

  Widget _buildScheduleCard(Appointment appointment, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Schedule',
      icon: Icons.event,
      iconColor: ColorConstants.tertiary,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date & Time',
            value: _formatDateTime(appointment.scheduledAt),
            isMobile: isMobile,
          ),
          _InfoRow(
            icon: Icons.timer,
            label: 'Duration',
            value:
                '${appointment.durationMinutes > 0 ? appointment.durationMinutes : '—'} minutes',
            isMobile: isMobile,
          ),
          _InfoRow(
            icon: Icons.meeting_room_outlined,
            label: 'Visit Type',
            value: appointment.appointmentType.displayLabel,
            isMobile: isMobile,
          ),
          _InfoRow(
            icon: Icons.videocam,
            label: 'Meeting Link',
            value: appointment.meetingLink.isNotEmpty
                ? appointment.meetingLink
                : 'Not available',
            isMobile: isMobile,
            isLink: appointment.meetingLink.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildReasonAndNotesCard(Appointment appointment, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Reason & Notes',
      icon: Icons.notes,
      iconColor: ColorConstants.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REASON',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appointment.reason.isNotEmpty
                ? appointment.reason
                : 'No reason provided.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOCTOR NOTES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              if (appointment.status != AppointmentStatus.unknown)
                TextButton.icon(
                  onPressed: () => _editNotes(appointment),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            appointment.doctorNotes.isNotEmpty
                ? appointment.doctorNotes
                : 'No doctor notes yet.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w400,
              fontStyle: appointment.doctorNotes.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: appointment.doctorNotes.isEmpty
                  ? ColorConstants.onSurfaceVariant
                  : ColorConstants.onSurface,
              height: 1.6,
            ),
          ),
          if (appointment.cancellationReason.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: ColorConstants.borderWhite5),
            const SizedBox(height: 16),
            Text(
              'CANCELLATION REASON',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
                color: ColorConstants.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.cancellationReason,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: ColorConstants.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(Appointment appointment, bool isMobile) {
    final status = appointment.status;
    final List<Widget> actions = [];

    // pending -> confirmed | cancelled
    if (status == AppointmentStatus.pending) {
      // The top-level "Confirm" chip is only valid when there is NO payment
      // attached (free consultation). When a payment is attached the backend
      // rejects `pending → confirmed` on /status/ with a 400 — the correct
      // path is `POST .../payment/confirm/` from the Payment section below.
      if (appointment.canConfirmFreely) {
        actions.add(
          _ActionChip(
            label: 'Confirm (Free Consultation)',
            icon: Icons.check,
            color: ColorConstants.tertiary,
            isMobile: isMobile,
            onPressed: () => _controller.confirmAppointment(),
          ),
        );
      }
      actions.add(
        _ActionChip(
          label: 'Cancel',
          icon: Icons.close,
          color: ColorConstants.error,
          isMobile: isMobile,
          onPressed: () => _confirmCancel(appointment),
        ),
      );
    }
    // confirmed -> completed | cancelled | no_show
    if (status == AppointmentStatus.confirmed) {
      actions.add(
        _ActionChip(
          label: 'Complete',
          icon: Icons.check_circle_outline,
          color: ColorConstants.success,
          isMobile: isMobile,
          onPressed: () => _controller.completeAppointment(),
        ),
      );
      actions.add(
        _ActionChip(
          label: 'No-show',
          icon: Icons.person_off,
          color: Colors.orange.shade400,
          isMobile: isMobile,
          onPressed: () => _controller.markNoShow(),
        ),
      );
      actions.add(
        _ActionChip(
          label: 'Cancel',
          icon: Icons.close,
          color: ColorConstants.error,
          isMobile: isMobile,
          onPressed: () => _confirmCancel(appointment),
        ),
      );
    }

    // Reschedule is valid while pending or confirmed
    final canReschedule =
        status == AppointmentStatus.pending ||
        status == AppointmentStatus.confirmed;

    return _SectionCard(
      isMobile: isMobile,
      title: 'Actions',
      icon: Icons.tune,
      iconColor: ColorConstants.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canReschedule) ...[
            _ActionChip(
              label: 'Reschedule',
              icon: Icons.event_repeat,
              color: ColorConstants.secondary,
              isMobile: isMobile,
              onPressed: () => _reschedule(appointment),
            ),
            const SizedBox(height: 8),
          ],
          if (actions.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ] else if (!canReschedule) ...[
            Text(
              'No actions available for this appointment.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ],
          if (status == AppointmentStatus.pending && !appointment.canConfirmFreely)
            _buildPaymentBlockedBanner(appointment, isMobile),
        ],
      ),
    );
  }

  /// Visible warning banner shown in the Actions card when the appointment
  /// cannot be confirmed because the consultation fee has not been verified.
  Widget _buildPaymentBlockedBanner(Appointment appointment, bool isMobile) {
    final paymentState = appointment.payment?.status ?? PaymentState.none;

    final Color bannerColor;
    final IconData bannerIcon;
    final String title;
    final String message;

    switch (paymentState) {
      case PaymentState.pending:
        bannerColor = Colors.orange.shade600;
        bannerIcon = Icons.payments_outlined;
        title = 'Awaiting Patient Payment';
        message =
            'The patient has not yet submitted payment for this consultation. '
            'This appointment cannot be confirmed until the patient marks '
            'the fee as paid and you verify it in the Payment section below.';
        break;
      case PaymentState.awaitingVerification:
        bannerColor = Colors.amber.shade700;
        bannerIcon = Icons.pending_actions;
        title = 'Payment Awaiting Verification';
        message =
            'The patient has submitted payment. Please verify the receipt '
            'in the Payment section below to confirm this appointment.';
        break;
      case PaymentState.rejected:
        bannerColor = ColorConstants.error;
        bannerIcon = Icons.cancel_outlined;
        title = 'Payment Rejected';
        message =
            'This payment was previously rejected. The patient must resubmit '
            'payment before this appointment can be confirmed.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bannerColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bannerColor.withOpacity(0.3)),
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(bannerIcon, color: bannerColor, size: isMobile ? 18 : 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: bannerColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w400,
                      color: bannerColor.withOpacity(0.85),
                      height: 1.5,
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

  Widget _buildPaymentCard(Appointment appointment, bool isMobile) {
    final payment = appointment.payment;
    final hasPayment = appointment.hasPayment;

    return _SectionCard(
      isMobile: isMobile,
      title: 'Payment',
      icon: Icons.payments_outlined,
      iconColor: ColorConstants.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasPayment) ...[
            Text(
              'No payment required for this appointment.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ] else ...[
            _InfoRow(
              icon: Icons.payments,
              label: 'Status',
              value: payment!.status.displayLabel,
              isMobile: isMobile,
            ),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Doctor Fee',
              value: 'Rs. ${payment.doctorFee}',
              isMobile: isMobile,
            ),
            _InfoRow(
              icon: Icons.percent,
              label: 'Admin Commission',
              value:
                  '${payment.commissionPercentage}% (Rs. ${payment.commissionAmount})',
              isMobile: isMobile,
            ),
            _InfoRow(
              icon: Icons.account_balance_wallet,
              label: 'Total Payable',
              value: 'Rs. ${payment.totalAmount}',
              isMobile: isMobile,
            ),
            if (payment.patientMarkedPaidAt != null)
              _InfoRow(
                icon: Icons.hourglass_top,
                label: 'Marked Paid',
                value: _formatDateTime(payment.patientMarkedPaidAt),
                isMobile: isMobile,
              ),
            if (payment.confirmedAt != null)
              _InfoRow(
                icon: Icons.verified,
                label: 'Confirmed At',
                value: _formatDateTime(payment.confirmedAt),
                isMobile: isMobile,
              ),
            if (payment.paymentReference.isNotEmpty)
              _InfoRow(
                icon: Icons.receipt_long,
                label: 'Reference',
                value: payment.paymentReference,
                isMobile: isMobile,
              ),
            const SizedBox(height: 12),
            Obx(() {
              final isProcessing = _controller.isProcessingAction.value;
              if (appointment.canVerifyPayment) {
                return _ActionChip(
                  label: isProcessing
                      ? 'Verifying...'
                      : 'Verify Payment & Confirm',
                  icon: Icons.verified_user,
                  color: ColorConstants.success,
                  isMobile: isMobile,
                  onPressed: () {
                    if (isProcessing) return;
                    _controller.verifyPayment();
                  },
                );
              }
              if (appointment.patientCanMarkPaid) {
                return _ActionChip(
                  label: isProcessing ? 'Recording...' : 'I Have Paid',
                  icon: Icons.check_circle_outline,
                  color: ColorConstants.tertiary,
                  isMobile: isMobile,
                  onPressed: () {
                    if (isProcessing) return;
                    _controller.markPaid();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ],
      ),
    );
  }

  void _reschedule(Appointment appointment) {
    debugPrint(
      '[AppointmentDetails] opening reschedule for id=${appointment.id}',
    );
    final dateController = TextEditingController(
      text: _formatDate(appointment.scheduledAt),
    );
    final timeController = TextEditingController(
      text: _formatTime(appointment.scheduledAt),
    );
    DateTime? newDate;
    TimeOfDay? newTime;

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reschedule Appointment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: appointment.scheduledAt ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  newDate = picked;
                  dateController.text = _formatDate(picked);
                }
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: _inputDecoration('Date'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              readOnly: true,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null && mounted) {
                  newTime = picked;
                  timeController.text = picked.format(context);
                }
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: _inputDecoration('Time'),
            ),
          ],
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
              if (newDate == null || newTime == null) {
                Get.snackbar(
                  'Missing selection',
                  'Please pick both a new date and time.',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
                return;
              }
              Get.back();
              final combined = DateTime(
                newDate!.year,
                newDate!.month,
                newDate!.day,
                newTime!.hour,
                newTime!.minute,
              );
              debugPrint('[AppointmentDetails] rescheduling to $combined');
              _controller.rescheduleAppointment(
                combined,
                durationMinutes: appointment.durationMinutes,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reschedule',
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

  void _confirmCancel(Appointment appointment) {
    final reasonController = TextEditingController(
      text: appointment.cancellationReason,
    );
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
              'Are you sure you want to cancel this appointment?',
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
              decoration: _inputDecoration('Reason (optional)'),
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
              _controller.cancelAppointment(
                reason: reasonController.text.trim(),
              );
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
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
    );
  }

  Widget _buildMetadataCard(Appointment appointment, bool isMobile) {
    return _SectionCard(
      isMobile: isMobile,
      title: 'Metadata',
      icon: Icons.info_outline,
      iconColor: ColorConstants.onSurfaceVariant,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.schedule,
            label: 'Created',
            value: _formatDateTime(appointment.createdAt),
            isMobile: isMobile,
          ),
          _InfoRow(
            icon: Icons.update,
            label: 'Updated',
            value: _formatDateTime(appointment.updatedAt),
            isMobile: isMobile,
          ),
        ],
      ),
    );
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

  void _editNotes(Appointment appointment) {
    final notesController = TextEditingController(
      text: appointment.doctorNotes,
    );
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Doctor Notes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter consultation notes...',
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
              _controller.updateDoctorNotes(notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
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
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '$h:$minute $ampm';
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _SectionCardforDP extends StatelessWidget {
  final bool isMobile;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCardforDP({
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
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
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
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
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
                  color: ColorConstants.onSurface,
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
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isMobile,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorConstants.primary, size: 16),
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
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isLink
                        ? ColorConstants.tertiary
                        : ColorConstants.onSurface,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
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

/// A compact action chip/button used in the Actions card.
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isMobile;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isMobile,
    required this.onPressed,
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
