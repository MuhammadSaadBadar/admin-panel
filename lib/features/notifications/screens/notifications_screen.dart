import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/notification_controller.dart';
import '../models/notification.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Admin Notifications inbox.
///
/// Integrates:
/// - `GET /api/v1/notifications/` — own inbox, newest first (paginated)
/// - `POST /api/v1/notifications/mark-all-read/` — mark all as read
///
/// Displays an unread count pill, filter tabs (All / Unread / Broadcasts /
/// Alerts), a live list of notifications with type-based icons & colors, and a
/// FAB to compose a new broadcast. Tapping a notification opens its detail
/// screen.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final NotificationController _controller;

  static const List<String> _tabs = ['All', 'Unread', 'Broadcasts', 'Alerts'];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NotificationController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Refresh inbox whenever the screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[NotificationsScreen] refreshing notifications on init');
      _controller.refresh();
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
              currentRoute: RouteNames.notifications,
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
      floatingActionButton: _buildFab(isMobile),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      {'icon': Icons.emergency, 'label': 'SOS Requests', 'selected': false},
      {'icon': Icons.notifications, 'label': 'Notifications', 'selected': true},
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
                            Get.toNamed(RouteNames.sos);
                            break;
                          case 6:
                            Get.toNamed(RouteNames.settings);
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
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            color: ColorConstants.primary,
            backgroundColor: ColorConstants.cardBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildActionRow(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildFilterTabs(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildNotificationList(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Notifications',
      showBackButton: isMobile,
      actions: [
        IconButton(
          onPressed: () => _controller.refresh(),
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
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          'Broadcasts, appointment updates, and system alerts.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(bool isMobile) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Unread pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorConstants.notifPinkSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ColorConstants.notifPink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_controller.unreadCount} Unread',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.notifPink,
                  ),
                ),
              ],
            ),
          ),

          // Mark all read
          if (!_controller.isMarkingAllRead.value)
            GestureDetector(
              onTap: _controller.notifications.isEmpty
                  ? null
                  : () => _confirmMarkAllRead(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withOpacity(0.2),
                  border: Border.all(color: ColorConstants.primary, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: _controller.notifications.isEmpty
                        ? Colors.white
                        : Colors.white,
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorConstants.primary,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildFilterTabs(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            return Obx(() {
              final selected = _controller.selectedFilter.value == tab;
              return GestureDetector(
                onTap: () => _controller.setFilter(tab),
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
                    tab,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                      color: selected ? ColorConstants.primary : Colors.black,
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

  Widget _buildNotificationList(bool isMobile) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.notifications.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
        );
      }

      if (_controller.error.value != null &&
          _controller.notifications.isEmpty) {
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
                  'Failed to load notifications',
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
                  onPressed: _controller.loadNotifications,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final notifications = _controller.filteredNotifications;

      if (notifications.isEmpty) {
        return _buildEmptyState(isMobile, _controller.selectedFilter.value);
      }

      return Column(
        children: notifications.map((n) {
          return _NotificationTile(
            notification: n,
            isMobile: isMobile,
            controller: _controller,
          );
        }).toList(),
      );
    });
  }

  Widget _buildEmptyState(bool isMobile, String filter) {
    final bool hasInboxItems = _controller.notifications.isNotEmpty;
    final String title;
    final String subtitle;

    if (hasInboxItems) {
      switch (filter) {
        case 'Unread':
          title = 'No unread notifications';
          subtitle = 'All caught up in this tab.';
          break;
        case 'Broadcasts':
          title = 'No broadcasts';
          subtitle = 'No broadcast notifications in your inbox.';
          break;
        case 'Alerts':
          title = 'No alerts';
          subtitle = 'No urgent or emergency notifications right now.';
          break;
        default:
          title = 'No notifications';
          subtitle = "You're all caught up!";
      }
    } else {
      title = 'No notifications';
      subtitle = "You're all caught up!";
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
        child: Column(
          children: [
            Icon(
              Icons.notifications_off,
              color: Colors.black,
              size: isMobile ? 40 : 48,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 12 : 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(bool isMobile) {
    return FloatingActionButton.extended(
      onPressed: () async {
        debugPrint('[NotificationsScreen] navigating to compose broadcast');
        await Get.toNamed(RouteNames.notificationBroadcast);
        _controller.refresh();
      },
      backgroundColor: ColorConstants.primaryContainer,
      foregroundColor: ColorConstants.onPrimaryContainer,
      icon: const Icon(Icons.campaign, size: 20),
      label: Text(
        'New Broadcast',
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 12 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _confirmMarkAllRead() {
    final unread = _controller.unreadCount;
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark all as read?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          unread > 0
              ? 'Mark $unread unread notification(s) as read?'
              : 'You have no unread notifications.',
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
            onPressed: unread > 0
                ? () {
                    Get.back();
                    _controller.markAllRead();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.onPrimaryContainer,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mark all read',
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
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isMobile;
  final NotificationController controller;

  const _NotificationTile({
    required this.notification,
    required this.isMobile,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = notification.typeColor;
    final softColor = color.withOpacity(0.14);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? ColorConstants.borderWhite10
              : color.withOpacity(0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          debugPrint(
            '[NotificationsScreen] navigating to detail for id=${notification.id}',
          );
          await Get.toNamed(
            RouteNames.notificationDetail,
            arguments: {'notificationId': notification.id},
          );
          controller.refresh();
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: isMobile ? 40 : 48,
                height: isMobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notification.typeIcon, color: color, size: 20),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: ColorConstants.onSurface,
                            ),
                          ),
                        ),
                        if (notification.isRead) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: ColorConstants.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      notification.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 8 : 10),
                    Row(
                      children: [
                        _buildTypeTag(color),
                        const Spacer(),
                        Text(
                          _formatTime(notification.createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.onSurfaceVariant.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTag(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        notification.typeLabel,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _formatTime(String raw) {
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
    return '${months[local.month - 1]} ${local.day} • $h:$minute $ampm';
  }
}
