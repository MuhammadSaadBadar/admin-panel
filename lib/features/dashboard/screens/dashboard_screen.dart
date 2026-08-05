import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/chart_widget.dart';
import '../widgets/recent_activities.dart';
import '../widgets/stats_grid.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late DashboardController _controller;
  late AnimationController _animationController;
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'isActive': true},
    {
      'icon': Icons.medical_services_rounded,
      'label': 'Doctor Management',
      'isActive': false,
    },
    {
      'icon': Icons.people_alt_rounded,
      'label': 'Patient Management',
      'isActive': false,
    },
    {'icon': Icons.event_rounded, 'label': 'Appointments', 'isActive': false},
    {
      'icon': Icons.notifications_rounded,
      'label': 'Notifications',
      'isActive': false,
    },
    {
      'icon': Icons.description_rounded,
      'label': 'Content Management',
      'isActive': false,
    },
    {
      'icon': Icons.emergency_rounded,
      'label': 'SOS Requests',
      'isActive': false,
    },
    {'icon': Icons.settings_rounded, 'label': 'Settings', 'isActive': false},
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<DashboardController>();
    debugPrint('[DashboardScreen] initState');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[DashboardScreen] requesting dashboard stats load');
      _controller.loadStats();
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
      // Mobile drawer (hamburger + swipe). Desktop keeps the inline sidebar.
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.dashboard,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                Get.toNamed(route);
              },
            )
          : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (!isMobile) _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(isMobile),
                Expanded(
                  child: Obx(() {
                    final stats = _controller.stats.value;
                    final isLoading = _controller.isLoading.value;
                    final error = _controller.error.value;

                    debugPrint(
                      '[DashboardScreen] render state loading=$isLoading hasStats=${stats != null} error=${error ?? 'none'}',
                    );

                    if (isLoading && stats == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: ColorConstants.primary,
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (error != null && stats == null) {
                      return _DashboardErrorState(
                        message: error,
                        onRetry: () {
                          debugPrint('[DashboardScreen] retry requested');
                          _controller.loadStats();
                        },
                      );
                    }

                    if (stats == null) {
                      return Center(
                        child: Text(
                          'No dashboard data available.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _controller.refresh,
                      color: ColorConstants.primary,
                      backgroundColor: ColorConstants.cardBackground,
                      child: SingleChildScrollView(
                        // AlwaysScrollableScrollPhysics ensures the
                        // pull-to-refresh gesture fires even when the
                        // content fits within the viewport.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: FadeTransition(
                          opacity: _animationController,
                          child: Column(
                            children: [
                              StatsGrid(stats: stats),
                              const SizedBox(height: 20),
                              ChartWidget(stats: stats),
                              const SizedBox(height: 20),
                              _LowerSection(stats: stats),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        border: Border(right: BorderSide(color: ColorConstants.borderWhite10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorConstants.primary,
                        ColorConstants.primary.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mama Health',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: ColorConstants.primary,
                      ),
                    ),
                    Text(
                      'ADMIN PANEL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: ColorConstants.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = item['isActive'] as bool;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          for (int i = 0; i < _navItems.length; i++) {
                            _navItems[i]['isActive'] = i == index;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isActive
                              ? ColorConstants.secondaryContainer
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 3,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? ColorConstants.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Icon(
                              item['icon'] as IconData,
                              color: isActive
                                  ? ColorConstants.onSecondaryContainer
                                  : ColorConstants.onSurfaceVariant,
                              size: 21,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? ColorConstants.onSecondaryContainer
                                      : ColorConstants.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: ColorConstants.borderWhite10),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: ColorConstants.surfaceContainerHigh,
                border: Border.all(color: ColorConstants.borderWhite10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorConstants.primary.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: ColorConstants.primary.withOpacity(0.2),
                      backgroundImage: const NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAE6o_O4DxXcFSHNFjr8A8WXukC9PdVVVjGPCTDGne5McL4NRLnvC6uhqNP_7AZlwUD_tm6vvs93LOza9RZV6JyWFDCC9pw9kORSSHSEWmd0cy3P14lv7sHJFBGCbB77hB7952pzk4pmk3oZrt_cfI9TXwr99M_U77Osesr5cmXAfoGHoEo6TiQ8xcCiLtpqiz1c_dwVnyBWrVOG4HJhPAf4N4kkKl6wTi_AvVh5r42_-zCRg-WVtgN',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Mama Health',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            color: ColorConstants.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ColorConstants.onSurfaceVariant.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Welcome Admin',
      showMenuButton: isMobile,
      actions: [
        _topBarIconButton(icon: Icons.search_rounded, onPressed: () {}),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _topBarIconButton(
              icon: Icons.notifications_rounded,
              onPressed: () {},
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstants.surfaceContainerLow,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _topBarIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: ColorConstants.onSurfaceVariant, size: 20),
        splashRadius: 20,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lower section extracted as a const stateless widget
// ─────────────────────────────────────────────

class _LowerSection extends StatelessWidget {
  final DashboardStats stats;

  const _LowerSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) {
      return Column(
        children: [
          RecentActivities(stats: stats),
          SizedBox(height: 16),
          _QuickActions(),
          SizedBox(height: 16),
          _SystemHealth(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: RecentActivities(stats: stats)),
        SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [_QuickActions(), SizedBox(height: 24), _SystemHealth()],
          ),
        ),
      ],
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.error.withOpacity(0.1),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: ColorConstants.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load dashboard data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _RecentActivity and _ActivityItem were removed.
// The live RecentActivities widget (widgets/recent_activities.dart)
// receives DashboardStats from the API and renders real data.

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.borderWhite10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 17,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: ColorConstants.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_rounded, size: 19),
              label: Text(
                'Add Doctor',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: ColorConstants.primary.withOpacity(0.35),
                  width: 1.4,
                ),
              ),
              icon: const Icon(Icons.campaign_rounded, size: 19),
              label: Text(
                'Broadcast Message',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.transparent),
                backgroundColor: ColorConstants.surfaceContainerHighest,
              ),
              icon: const Icon(Icons.file_download_rounded, size: 19),
              label: Text(
                'Export Report',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemHealth extends StatelessWidget {
  const _SystemHealth();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.borderWhite10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.tertiary.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ColorConstants.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEM HEALTH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ColorConstants.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Response Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '180ms',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.92,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: ColorConstants.tertiary,
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}
