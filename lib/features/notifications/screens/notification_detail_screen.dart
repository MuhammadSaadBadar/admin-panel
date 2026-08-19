import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/notification_controller.dart';
import '../controllers/notification_detail_controller.dart';
import '../models/notification.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Notification detail screen.
///
/// Integrates:
/// - `GET /api/v1/notifications/{id}/` — single notification
/// - `POST /api/v1/notifications/{id}/mark-read/` — mark as read
///
/// Shows the full notification (title, body, type, deep-link `data`, channel
/// delivery status, timestamp) and a "Mark as read" action. Also syncs the
/// read state back to the inbox controller so the badge stays correct on
/// return.
class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final NotificationDetailController _controller;
  int _notificationId = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NotificationDetailController>();

    // Extract the notification ID from navigation arguments.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['notificationId'] != null) {
        _notificationId = args['notificationId'] as int;
      }
      debugPrint(
        '[NotificationDetailScreen] received notificationId=$_notificationId',
      );
      if (_notificationId > 0) {
        _controller.load(_notificationId);
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
      body: DashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(isMobile),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primary,
                      ),
                    );
                  }

                  if (_controller.error.value != null) {
                    return _buildErrorState(isMobile);
                  }

                  final notification = _controller.notification.value;
                  if (notification == null) {
                    return _buildNoNotificationState(isMobile);
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _buildDetailCard(isMobile, notification),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Notification',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
    );
  }

  Widget _buildErrorState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ColorConstants.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load this notification',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _controller.load(_notificationId),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNotificationState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off,
              color: ColorConstants.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No notification selected',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(bool isMobile, AppNotification notification) {
    final color = notification.typeColor;
    final softColor = color.withOpacity(0.14);

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
                  color: softColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notification.typeIcon, color: color, size: 26),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag('${notification.typeLabel}', color),
                        _buildTag(
                          notification.isRead ? 'READ' : 'UNREAD',
                          notification.isRead
                              ? ColorConstants.onSurfaceVariant
                              : ColorConstants.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 24),
          Divider(height: 1, color: ColorConstants.borderWhite10),
          SizedBox(height: isMobile ? 16 : 24),

          // Body
          Text(
            notification.body.isNotEmpty ? notification.body : 'No body.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onSurface.withOpacity(0.9),
              height: 1.6,
            ),
          ),

          if (notification.data.isNotEmpty) ...[
            SizedBox(height: isMobile ? 16 : 24),
            _buildDataSection(isMobile, notification.data),
          ],

          SizedBox(height: isMobile ? 16 : 24),
          Divider(height: 1, color: ColorConstants.borderWhite10),
          SizedBox(height: isMobile ? 16 : 24),

          // Delivery status
          _buildDeliveryRow(
            Icons.smartphone,
            'Push notification',
            notification.channelPushSent,
            isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildDeliveryRow(
            Icons.chat,
            'WhatsApp message',
            notification.channelWhatsappSent,
            isMobile,
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Timestamp
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: ColorConstants.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(notification.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 20 : 28),

          // Mark as read action
          if (!notification.isRead) _buildMarkReadButton(isMobile),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDataSection(bool isMobile, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAILS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _labelForKey(entry.key),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _stringifyValue(entry.value),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryRow(
    IconData icon,
    String label,
    bool sent,
    bool isMobile,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorConstants.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          sent ? 'Sent' : 'Not sent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: sent
                ? ColorConstants.success
                : ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkReadButton(bool isMobile) {
    return Obx(() {
      if (_controller.isMarkingRead.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorConstants.primary,
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final success = await _controller.markRead();
            if (success) {
              // Sync the read state back to the inbox controller so the
              // unread badge stays correct when returning.
              if (Get.isRegistered<NotificationController>()) {
                Get.find<NotificationController>().markOneReadLocally(
                  _notificationId,
                );
              }
            }
          },
          icon: const Icon(Icons.mark_email_read, size: 18),
          label: Text(
            'Mark as read',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primary,
            foregroundColor: ColorConstants.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _labelForKey(String key) {
    // Convert snake/camel keys to a readable label.
    final spaced = key.replaceAll('_', ' ');
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _stringifyValue(dynamic value) {
    if (value == null) return '—';
    if (value is Map || value is List) return value.toString();
    return value.toString();
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
