import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../controllers/notification_controller.dart';

/// A reusable AppBar bell icon that shows a live unread-notification badge.
///
/// It reads the shared [NotificationController.unreadCount] (an [Rx], so it
/// stays in sync across the app as notifications are loaded/marked read) and
/// navigates to the Notifications module (`/notifications`) when tapped.
///
/// Add it to any screen's `CustomAppBar` `actions` list:
/// ```dart
/// actions: [const NotificationBell()],
/// ```
class NotificationBell extends StatelessWidget {
  /// Whether to force-load notifications on first build. When added to a
  /// screen that appears before the inbox has been loaded, set this to `true`
  /// so the badge is populated immediately.
  final bool loadOnInit;

  const NotificationBell({super.key, this.loadOnInit = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    // If requested, fetch the dedicated unread count so the badge is accurate
    // without needing the full inbox loaded.
    if (loadOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchUnreadCount();
      });
    }

    return Obx(() {
      final unread = controller.unreadCountValue.value;
      return IconButton(
        tooltip: 'Notifications',
        onPressed: () => Get.toNamed(RouteNames.notifications),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: ColorConstants.primary,
            ),
            if (unread > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: ColorConstants.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorConstants.background,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.onError,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
