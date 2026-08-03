import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
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
  int _selectedIndex = 0;
  late AnimationController _animationController;
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'isActive': true},
    {
      'icon': Icons.medical_services,
      'label': 'Doctor Management',
      'isActive': false,
    },
    {'icon': Icons.person, 'label': 'Patient Management', 'isActive': false},
    {'icon': Icons.event, 'label': 'Appointments', 'isActive': false},
    {'icon': Icons.notifications, 'label': 'Notifications', 'isActive': false},
    {
      'icon': Icons.description,
      'label': 'Content Management',
      'isActive': false,
    },
    {'icon': Icons.emergency, 'label': 'SOS Requests', 'isActive': false},
    {'icon': Icons.settings, 'label': 'Settings', 'isActive': false},
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
      body: Row(
        children: [
          // Desktop Sidebar
          if (!isMobile) _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: Obx(() {
                    final stats = _controller.stats.value;
                    final isLoading = _controller.isLoading.value;
                    final error = _controller.error.value;

                    debugPrint(
                      '[DashboardScreen] render state loading=$isLoading hasStats=${stats != null} error=${error ?? 'none'}',
                    );

                    if (isLoading && stats == null) {
                      return const Center(child: CircularProgressIndicator());
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
                      return const Center(
                        child: Text('No dashboard data available.'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _controller.refresh,
                      child: SingleChildScrollView(
                        // AlwaysScrollableScrollPhysics ensures the
                        // pull-to-refresh gesture fires even when the
                        // content fits within the viewport.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: FadeTransition(
                          opacity: _animationController,
                          child: Column(
                            children: [
                              StatsGrid(stats: stats),
                              const SizedBox(height: 16),
                              ChartWidget(stats: stats),
                              const SizedBox(height: 16),
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
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
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
                }
              },
            )
          : null,
    );
  }

  Widget _buildSidebar() {
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
                Text(
                  'Admin Panel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: ColorConstants.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = item['isActive'] as bool;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isActive
                          ? ColorConstants.secondaryContainer
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isActive
                            ? ColorConstants.onSecondaryContainer
                            : ColorConstants.onSurfaceVariant,
                        size: 24,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isActive
                              ? ColorConstants.onSecondaryContainer
                              : ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      hoverColor: ColorConstants.surfaceVariant.withOpacity(
                        0.5,
                      ),
                      onTap: () {
                        setState(() {
                          for (int i = 0; i < _navItems.length; i++) {
                            _navItems[i]['isActive'] = i == index;
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: ColorConstants.borderWhite10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: ColorConstants.surfaceContainerHigh,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorConstants.primary.withOpacity(0.2),
                    backgroundImage: const NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAE6o_O4DxXcFSHNFjr8A8WXukC9PdVVVjGPCTDGne5McL4NRLnvC6uhqNP_7AZlwUD_tm6vvs93LOza9RZV6JyWFDCC9pw9kORSSHSEWmd0cy3P14lv7sHJFBGCbB77hB7952pzk4pmk3oZrt_cfI9TXwr99M_U77Osesr5cmXAfoGHoEo6TiQ8xcCiLtpqiz1c_dwVnyBWrVOG4HJhPAf4N4kkKl6wTi_AvVh5r42_-zCRg-WVtgN',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Mama Health',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            color: ColorConstants.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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

  Widget _buildTopAppBar() {
    return CustomAppBar(
      title: 'Welcome Admin',
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.search, color: ColorConstants.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: ColorConstants.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load dashboard data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle, size: 20),
              label: Text(
                'Add Doctor',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                  color: ColorConstants.primary.withOpacity(0.4),
                ),
              ),
              icon: const Icon(Icons.campaign, size: 20),
              label: Text(
                'Broadcast Message',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
              icon: const Icon(Icons.file_download, size: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.tertiary.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: ColorConstants.tertiary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Response Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.92,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: ColorConstants.tertiary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
