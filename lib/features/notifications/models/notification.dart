import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';

/// A notification from the admin's own inbox.
///
/// Mapped from the `Notification` schema in `Mama Health API.yaml`:
/// - `GET /api/v1/notifications/` — own inbox, newest first (paginated)
/// - `GET /api/v1/notifications/{id}/` — single notification
/// - `POST /api/v1/notifications/{id}/mark-read/` — mark one read
///
/// Fields: `id`, `notification_type` (`appointment`|`medicine`|`diet`|
/// `doctor_message`|`weekly_update`|`emergency`|`broadcast`), `title`, `body`,
/// `data` (free-form JSON for deep-linking), `is_read`,
/// `channel_push_sent`/`channel_whatsapp_sent`, `created_at`.
///
/// Named `AppNotification` to avoid a clash with Flutter's `Notification`
/// widget base class.
class AppNotification {
  final int id;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool channelPushSent;
  final bool channelWhatsappSent;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    this.channelPushSent = false,
    this.channelWhatsappSent = false,
    this.createdAt = '',
  });

  /// A human-readable label for the notification type.
  String get typeLabel {
    switch (notificationType) {
      case 'appointment':
        return 'Appointment';
      case 'medicine':
        return 'Medicine';
      case 'diet':
        return 'Diet';
      case 'doctor_message':
        return 'Doctor Message';
      case 'weekly_update':
        return 'Weekly Update';
      case 'emergency':
        return 'Emergency';
      case 'broadcast':
        return 'Broadcast';
      default:
        return 'Notification';
    }
  }

  /// An icon representing the notification type.
  IconData get typeIcon {
    switch (notificationType) {
      case 'appointment':
        return Icons.calendar_today;
      case 'medicine':
        return Icons.medication;
      case 'diet':
        return Icons.restaurant;
      case 'doctor_message':
        return Icons.chat;
      case 'weekly_update':
        return Icons.insights;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'broadcast':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  /// The accent color associated with the notification type.
  Color get typeColor {
    switch (notificationType) {
      case 'appointment':
        return ColorConstants.notifBlue;
      case 'medicine':
        return ColorConstants.notifGreen;
      case 'diet':
        return ColorConstants.notifGreen;
      case 'doctor_message':
        return ColorConstants.notifBlue;
      case 'weekly_update':
        return ColorConstants.notifGreen;
      case 'emergency':
        return ColorConstants.notifRed;
      case 'broadcast':
        return ColorConstants.notifPink;
      default:
        return ColorConstants.notifTextMuted;
    }
  }

  /// A soft background tint for the type icon container.
  Color get typeSoftColor => typeColor.withOpacity(0.14);

  /// Whether the notification is a broadcast type.
  bool get isBroadcast => notificationType == 'broadcast';

  /// Whether the notification is urgent (emergency type or unread broadcast).
  bool get isUrgent =>
      notificationType == 'emergency' || (isBroadcast && !isRead);

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      notificationType: (json['notification_type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      data: json['data'] is Map
          ? (json['data'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{},
      isRead: (json['is_read'] as bool?) ?? false,
      channelPushSent: (json['channel_push_sent'] as bool?) ?? false,
      channelWhatsappSent: (json['channel_whatsapp_sent'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }
}
