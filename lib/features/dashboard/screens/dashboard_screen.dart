// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/routes/route_names.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../../features/notifications/controllers/notification_controller.dart';
import '../controllers/dashboard_controller.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final DashboardController controller;
  late final NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();
    controller.loadStats();

    // Resolve the shared notification controller and fetch the unread count
    // so the bell badge reflects the real backend value.
    notificationController = Get.find<NotificationController>();
    notificationController.fetchUnreadCount();
  }

  // Data
  int _installs = 185420;
  int _activeUsers = 52846;
  int _consultations = 1245;
  int _doctors = 820;
  int _patients = 278510;

  // _patientGrowth field removed — dynamic "new this week" from API.

  // Monthly revenue data
  final List<MonthlyData> _monthlyData = [
    MonthlyData(month: 'Jan', value: 18),
    MonthlyData(month: 'Feb', value: 21),
    MonthlyData(month: 'Mar', value: 19),
    MonthlyData(month: 'Apr', value: 27),
    MonthlyData(month: 'May', value: 24),
    MonthlyData(month: 'Jun', value: 29),
    MonthlyData(month: 'Jul', value: 33),
    MonthlyData(month: 'Aug', value: 45.85),
    MonthlyData(month: 'Sep', value: 38),
    MonthlyData(month: 'Oct', value: 52),
    MonthlyData(month: 'Nov', value: 41),
    MonthlyData(month: 'Dec', value: 36),
  ];

  int _selectedMonth = 7; // August

  // Selected view
  String _currentView = 'dashboard';
  final List<String> _views = [
    'dashboard',
    'analytics',
    'live',
    'earnings',
    'settings',
  ];

  // Date range selection for the header date picker. Selecting a day passes
  // the same day as both inclusive bounds to reports/admin/stats/, which
  // returns the additive `range_stats` overlay for that day.
  DateTime _selectedDate = DateTime.now();
  late final List<DateTime> _dateOptions = _buildDateOptions();

  List<DateTime> _buildDateOptions() {
    final now = DateTime.now();
    return List.generate(5, (index) {
      return DateTime(now.year, now.month, now.day - index);
    });
  }

  String _selectedDateLabel() => _formatDateLabel(_selectedDate);

  // Ad-revenue figures are intentionally static: the backend exposes no
  // endpoint for them (they were explicitly excluded from scope). The
  // consultation/commission/lifetime revenue fields were removed once the
  // Revenue Overview began reading real values from GET /reports/admin/stats/.
  int _adRevenueTotal = 245680;
  int _adRevenueToday = 1250;
  int _adRevenueMonth = 18750;
  double _ecpm = 4.75;

  String _formatDateLabel(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime? _dateFromLabel(String label) {
    for (final date in _dateOptions) {
      if (_formatDateLabel(date) == label) return date;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.dashboardCream,
      body: DashboardBackground(
        child: SafeArea(
          child: Obx(
            () => Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // View content
                        _buildViewContent(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation
                // _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel.withOpacity(0.60),
        // Rounded bottom corners
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        // Soft bottom elevation shadow instead of a harsh line border
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Row
              Row(
                children: [
                  // _buildAvatar(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Welcome, ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.dashboardInkSoft,
                            ),
                          ),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.dashboardInk,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Mama Health',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.dashboardInk,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.dashboardInkSoft,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Actions
              Row(
                children: [
                  _buildLivePill(),
                  const SizedBox(width: 8),
                  _buildBellButton(),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date Picker
          _buildDatePicker(),
        ],
      ),
    );
  }
  // Widget _buildAvatar() {
  //   return Container(
  //     width: 46,
  //     height: 46,
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [ColorConstants.dashboardCoral, ColorConstants.dashboardPink],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Stack(
  //       children: [
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(16),
  //           child: Image.asset(
  //             'assets/images/avatar.png',
  //             fit: BoxFit.cover,
  //             errorBuilder: (context, error, stackTrace) {
  //               return const Center(
  //                 child: Icon(Icons.person, color: Colors.white, size: 24),
  //               );
  //             },
  //           ),
  //         ),
  //         Positioned(
  //           bottom: -2,
  //           right: -2,
  //           child: Container(
  //             width: 12,
  //             height: 12,
  //             decoration: BoxDecoration(
  //               color: ColorConstants.dashboardMint,
  //               shape: BoxShape.circle,
  //               border: Border.all(
  //                 color: ColorConstants.dashboardCream,
  //                 width: 2,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLivePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardMint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: ColorConstants.dashboardMint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardMint,
            ),
          ),
        ],
      ),
    );
  }

  /// Notification bell showing the live unread count from the backend
  /// (`unreadCountValue`). Tapping it navigates to the Notifications screen.
  Widget _buildBellButton() {
    return Obx(() {
      final unread = notificationController.unreadCountValue.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ColorConstants.dashboardPanel,
              shape: BoxShape.circle,
              border: Border.all(color: ColorConstants.dashboardLine, width: 1),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.dashboardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Notifications',
              onPressed: () => Get.toNamed(RouteNames.notifications),
              icon: const Icon(
                Icons.notifications,
                color: ColorConstants.dashboardInk,
                size: 16,
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                height: 17,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardPink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 16,
            color: ColorConstants.dashboardInk,
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDateLabel(),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: ColorConstants.dashboardInk,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInk,
              ),
              dropdownColor: ColorConstants.dashboardPanel,
              items: _dateOptions.map((date) {
                return DropdownMenuItem<String>(
                  value: _formatDateLabel(date),
                  child: Text(_formatDateLabel(date)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                final date = _dateFromLabel(value);
                if (date == null) return;
                setState(() {
                  _selectedDate = date;
                });
                // The reports/admin/stats/ endpoint accepts an inclusive
                // date range (date_from/date_to). Selecting a single day
                // passes the same day for both bounds, which returns the
                // additive `range_stats` overlay for that day.
                controller.loadStats(dateFrom: date, dateTo: date);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VIEW CONTENT ====================
  Widget _buildViewContent() {
    switch (_currentView) {
      case 'analytics':
        return _buildAnalyticsView();
      case 'live':
        return _buildLiveView();
      case 'settings':
        return _buildSettingsView();
      default:
        return _buildDashboardView();
    }
  }

  String _getViewTitle() {
    switch (_currentView) {
      case 'analytics':
        return 'Analytics';
      case 'live':
        return 'Live Monitoring';
      case 'earnings':
        return 'Earnings';
      case 'settings':
        return 'Settings';
      default:
        return 'Admin Dashboard';
    }
  }

  // ==================== DASHBOARD VIEW ====================
  Widget _buildDashboardView() {
    // Loading state while fetching stats for the first time.
    if (controller.isLoading.value && controller.stats.value == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: ColorConstants.dashboardPink),
        ),
      );
    }

    // Error state when no data has been loaded yet.
    if (controller.error.value != null && controller.stats.value == null) {
      return _buildErrorRetry();
    }

    return Column(
      children: [
        // Stat Grid
        _buildStatGrid(),

        const SizedBox(height: 16),

        // Registered Banner
        _buildRegisteredBanner(),

        const SizedBox(height: 16),
        _buildRevenueOverview(),

        const SizedBox(height: 16),
        _buildTwoColumnCards(),

        const SizedBox(height: 16),

        // Analytics Overview
        _buildAnalyticsOverview(),

        const SizedBox(height: 16),

        // Range Stats (only when a date range was requested)
        _buildRangeStats(),

        const SizedBox(height: 16),

        // Quick Actions
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildErrorRetry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off,
              color: ColorConstants.dashboardInkSoft,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              controller.error.value ?? 'Unable to load dashboard data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                controller.loadStats();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.dashboardPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = controller.stats.value;
    final cards = [
      _buildStatCard(
        icon: Icons.download,
        label: 'App Installs',
        value: _installs,
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardPink, ColorConstants.dashboardPink2],
        ),
        sparkline: [18, 14, 16, 9, 11, 4, 7],
      ),
      _buildStatCard(
        icon: Icons.people,
        label: 'Active Users',
        value: stats?.activeUsersLast30Days ?? _activeUsers,
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardPink, ColorConstants.dashboardPink2],
        ),
        sparkline: [10, 15, 8, 12, 6, 10, 3],
      ),
      _buildStatCard(
        icon: Icons.videocam,
        label: 'Consultations',
        value: stats?.todayAppointments ?? _consultations,
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardPink, ColorConstants.dashboardPink2],
        ),
        sparkline: [15, 10, 13, 6, 9, 4, 8],
      ),
      _buildStatCard(
        icon: Icons.medical_services,
        label: 'Total Doctors',
        value: stats?.totalDoctors ?? _doctors,
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardTeal, ColorConstants.dashboardTeal2],
        ),
        sparkline: [12, 16, 9, 13, 7, 11, 5],
      ),
    ];

    // Responsive: 4-across on wide screens, 2-across on narrow screens, so the
    // stat cards never shrink below a usable width and trigger text overflow.
    // mainAxisExtent guarantees enough vertical room for the card content
    // (icon + gap + label + value + footer + padding ≈ 160px) so the cards
    // never overflow regardless of column width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: crossAxisCount == 4 ? 172 : 180,
          ),
          children: cards,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required LinearGradient gradient,
    required List<int> sparkline,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.dashboardShadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(height: 26),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            Text(
              value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}K'
                  : value.toString(),
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              _getStatFooter(label),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatFooter(String label) {
    switch (label) {
      case 'App Installs':
        return 'Total Installs';
      case 'Active Users':
        return 'Users Active';
      case 'Consultations':
        return 'Today';
      case 'Total Doctors':
        return 'Registered';
      default:
        return '';
    }
  }

  /// Custom date-range stats card. Only rendered when the backend returned
  /// `range_stats` (i.e. when a date range was requested via the header
  /// date picker). Since it is absent for the default (unfiltered) view, this
  /// widget returns an empty SizedBox so the layout is unchanged.
  Widget _buildRangeStats() {
    final range = controller.stats.value?.rangeStats;
    if (range == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range Stats',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.dashboardInk,
                ),
              ),
              Text(
                '${_formatRangeDate(range.dateFrom)} – '
                '${_formatRangeDate(range.dateTo)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRangeStatTile(
                label: 'Appointments',
                value: range.appointmentsInRange,
                color: ColorConstants.dashboardPink,
              ),
              const SizedBox(width: 10),
              _buildRangeStatTile(
                label: 'New Patients',
                value: range.newPatientsInRange,
                color: ColorConstants.dashboardTeal,
              ),
              const SizedBox(width: 10),
              _buildRangeStatTile(
                label: 'New Doctors',
                value: range.newDoctorsInRange,
                color: ColorConstants.dashboardViolet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeStatTile({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatComma(value),
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRangeDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildRegisteredBanner() {
    final stats = controller.stats.value;
    final patients = stats?.totalPatients ?? _patients;
    final newThisWeek = stats?.newPatientsThisWeek ?? 0;
    final growth = stats?.newPatientsGrowthPercent;
    final growthLabel = growth != null
        ? '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%'
        : '+$newThisWeek';
    final growthCaption = growth != null ? 'vs last month' : 'new this week';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.dashboardPink2,
                  ColorConstants.dashboardPink,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.family_restroom, color: Colors.white, size: 19),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients Registered',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
                Text(
                  patients >= 1000
                      ? '${(patients / 1000).toStringAsFixed(1)}K'
                      : '$patients',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
                Text(
                  'All Registered Patients',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            height: 44,
            child: CustomPaint(
              painter: SparklinePainter(
                data: [30, 26, 28, 20, 22, 14, 16, 10, 13, 8, 10, 4, 7],
                color: const Color(0xFFF0507E),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                growthLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.dashboardMint,
                ),
              ),
              Text(
                growthCaption,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ColorConstants.dashboardMint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ColorConstants.dashboardInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    final stats = controller.stats.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analytics Overview',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInk,
              ),
            ),
            // TextButton(
            //   onPressed: () {
            //     setState(() {
            //       _currentView = 'analytics';
            //     });
            //   },
            //   style: TextButton.styleFrom(
            //     padding: EdgeInsets.zero,
            //     minimumSize: Size.zero,
            //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //   ),
            //   child: Text(
            //     'View All',
            //     style: TextStyle(
            //       fontSize: 12.5,
            //       fontWeight: FontWeight.w700,
            //       color: ColorConstants.dashboardPink,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAnalyticsCard(
              label: 'Daily Consultations',
              value: _formatComma(stats?.todayAppointments ?? 1245),
              sparkColor: ColorConstants.dashboardCoral,
              sparkData: [22, 17, 19, 10, 13, 4],
            ),
            const SizedBox(width: 10),
            _buildAnalyticsCard(
              label: 'Monthly Appointments',
              value: _formatComma(stats?.appointmentsThisMonth ?? 0),
              sparkColor: ColorConstants.dashboardPink,
              sparkData: [16, 12, 14, 8, 4, 2],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildAnalyticsCard(
              label: 'Total Patients',
              value: _formatComma(stats?.totalPatients ?? 0),
              sparkColor: ColorConstants.dashboardTeal,
              sparkData: [22, 18, 20, 12, 14, 3],
            ),
            const SizedBox(width: 10),
            _buildAnalyticsCard(
              label: 'Total Doctors',
              value: _formatComma(stats?.totalDoctors ?? 0),
              sparkColor: ColorConstants.dashboardViolet,
              sparkData: [10, 18, 8, 20, 6, 12],
            ),
          ],
        ),
      ],
    );
  }

  String _formatComma(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  /// Formats the average doctor rating as e.g. "4.8 ⭐". Falls back to the
  /// static placeholder when the API has not provided a rating yet.
  String _doctorRatingLabel(double? rating) {
    if (rating == null) return '4.8 ⭐';
    return '${rating.toStringAsFixed(1)} ⭐';
  }

  Widget _buildAnalyticsCard({
    required String label,
    required String value,
    required Color sparkColor,
    required List<int> sparkData,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: ColorConstants.dashboardPink,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorConstants.dashboardLine, width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.dashboardShadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ColorConstants.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: CustomPaint(
                painter: SparklinePainter(data: sparkData, color: sparkColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: '🩺',
        label: 'Manage Doctors',
        color: ColorConstants.dashboardCoral,
        route: RouteNames.doctors,
      ),
      _QuickActionItem(
        icon: '🧑‍🤝‍🧑',
        label: 'Manage Patients',
        color: ColorConstants.dashboardPink,
        route: RouteNames.patients,
      ),
      _QuickActionItem(
        icon: '🚨',
        label: 'Manage SOS',
        color: ColorConstants.dashboardViolet,
        route: RouteNames.sos,
      ),
      _QuickActionItem(
        icon: '📅',
        label: 'Manage Appointments',
        color: ColorConstants.dashboardTeal,
        route: RouteNames.appointments,
      ),
      _QuickActionItem(
        icon: '👤',
        label: 'Profile',
        color: const Color(0xFF4285F4),
        route: RouteNames.profile,
      ),

      _QuickActionItem(
        icon: '🔔',
        label: 'Push Notifications',
        color: ColorConstants.dashboardAmber,
        route: RouteNames.notifications,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardInk,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: actions
              .map(
                (item) => _buildQuickAction(
                  icon: item.icon,
                  label: item.label,
                  color: item.color,
                  route: item.route,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required String icon,
    required String label,
    required Color color,
    String? route,
  }) {
    final onTap = route == null ? null : () => Get.toNamed(route!);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ANALYTICS VIEW ====================
  Widget _buildAnalyticsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consultations Trend',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: ColorConstants.dashboardInk,
                    ),
                  ),
                  Text(
                    '${_formatComma(controller.stats.value?.todayAppointments ?? 1245)} today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ColorConstants.dashboardPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _monthlyData.map((data) {
                    final height = (data.value / 52) * 130;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: double.infinity,
                            height: height.clamp(4.0, 130.0),
                            decoration: BoxDecoration(
                              color: ColorConstants.dashboardCoral2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.month,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.dashboardInkSoft,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _buildAnalyticsCard(
              label: 'Retention Rate',
              value: '86%',
              sparkColor: ColorConstants.dashboardCoral,
              sparkData: [10, 15, 8, 12, 6],
            ),
            _buildAnalyticsCard(
              label: 'Avg Session',
              value: '7m 40s',
              sparkColor: ColorConstants.dashboardPink,
              sparkData: [12, 8, 10, 6, 14],
            ),
            _buildAnalyticsCard(
              label: 'Doctor Rating',
              value: _doctorRatingLabel(
                controller.stats.value?.averageDoctorRating,
              ),
              sparkColor: ColorConstants.dashboardTeal,
              sparkData: [8, 12, 6, 10, 14],
            ),
            _buildAnalyticsCard(
              label: 'Churned Users',
              value: '312',
              sparkColor: ColorConstants.dashboardPink,
              sparkData: [14, 10, 12, 8, 6],
            ),
          ],
        ),
      ],
    );
  }

  // ==================== LIVE VIEW ====================
  Widget _buildLiveView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Monitoring',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: ColorConstants.dashboardInk,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.dashboardMint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: ColorConstants.dashboardMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: ColorConstants.dashboardMint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Activity Feed',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.dashboardInk,
                ),
              ),
              const SizedBox(height: 8),
              _buildLiveFeedItem('Dr. Amina Raza started a consultation'),
              _buildLiveFeedItem('New patient registered: Zara Ahmed'),
              _buildLiveFeedItem('Dr. Omar Farooq ended a video call'),
              _buildLiveFeedItem('Payment of \$45 processed'),
              _buildLiveFeedItem('New app install from Lahore, PK'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFeedItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorConstants.dashboardLine, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ColorConstants.dashboardPink.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '●',
                style: TextStyle(
                  fontSize: 10,
                  color: ColorConstants.dashboardPink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawItem(WithdrawItem w) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.dashboardTeal2,
                  ColorConstants.dashboardTeal,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                w.name.split(' ').map((s) => s[0]).join('').substring(0, 2),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
                Text(
                  'Requested ${w.amount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (w.status == 'pending')
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: ColorConstants.dashboardMint,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Approve',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardMint.withOpacity(0.14),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Paid',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.dashboardMint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SETTINGS VIEW ====================
  Widget _buildSettingsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsRow(
                label: 'Dark Mode',
                subtitle: 'Easier on the eyes at night',
                value: false,
                onChanged: (value) {},
              ),
              _buildSettingsRow(
                label: 'Push Notifications',
                subtitle: 'Get alerts for new activity',
                value: true,
                onChanged: (value) {},
              ),
              _buildSettingsRow(
                label: 'Live Monitoring',
                subtitle: 'Auto-refresh live stats',
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorConstants.dashboardPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.dashboardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTextField('Admin Name', 'Admin'),
              const SizedBox(height: 12),
              _buildTextField('App Name', 'Mama Health'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.dashboardCoral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.dashboardInk,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: ColorConstants.dashboardLine, width: 1),
            ),
            child: const Text(
              '📲 Install Mama Health App',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorConstants.dashboardLine, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.dashboardInk,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorConstants.dashboardMint,
            trackColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return ColorConstants.dashboardMint;
              }
              return ColorConstants.dashboardLine;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardInkSoft,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          style: TextStyle(fontSize: 13, color: ColorConstants.dashboardInk),
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorConstants.dashboardCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorConstants.dashboardLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ColorConstants.dashboardLine,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ColorConstants.dashboardPink,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== NOTIFICATIONS ====================
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.dashboardPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardLine,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: ColorConstants.dashboardInk,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.dashboardPink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Expanded(
              //   child: ListView.builder(
              //     itemCount: _notifications.length,
              //     itemBuilder: (context, index) {
              //       final n = _notifications[index];
              //       return Container(
              //         padding: const EdgeInsets.symmetric(vertical: 12),
              //         decoration: BoxDecoration(
              //           border: Border(
              //             bottom: BorderSide(
              //               color: ColorConstants.dashboardLine,
              //               width: 1,
              //             ),
              //           ),
              //         ),
              //         child: Row(
              //           children: [
              //             Container(
              //               width: 8,
              //               height: 8,
              //               decoration: BoxDecoration(
              //                 color: n.isRead
              //                     ? ColorConstants.dashboardLine
              //                     : ColorConstants.dashboardPink,
              //                 shape: BoxShape.circle,
              //               ),
              //             ),
              //             const SizedBox(width: 12),
              //             Expanded(
              //               child: Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 children: [
              //                   Text(
              //                     n.text,
              //                     style: TextStyle(
              //                       fontSize: 12.5,
              //                       fontWeight: FontWeight.w700,
              //                       color: ColorConstants.dashboardInk,
              //                     ),
              //                   ),
              //                   Text(
              //                     n.time,
              //                     style: TextStyle(
              //                       fontSize: 10.5,
              //                       fontWeight: FontWeight.w600,
              //                       color: ColorConstants.dashboardInkSoft,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  // ==================== BOTTOM NAVIGATION ====================
  // Widget _buildBottomNavigation() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: ColorConstants.dashboardPanel,
  //       borderRadius: const BorderRadius.only(
  //         topLeft: Radius.circular(20),
  //         topRight: Radius.circular(20),
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: ColorConstants.dashboardShadow,
  //           blurRadius: 10,
  //           offset: const Offset(0, -4),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildNavItem(Icons.home, 'Dashboard', 'dashboard'),
  //         _buildNavItem(Icons.bar_chart, 'Analytics', 'analytics'),
  //         _buildNavItem(Icons.bolt, 'Live', 'live'),
  //         _buildNavItem(Icons.attach_money, 'Earnings', 'earnings'),
  //         _buildNavItem(Icons.settings, 'Settings', 'settings'),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildNavItem(IconData icon, String label, String view) {
    final isActive = _currentView == view;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.dashboardPink2 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? ColorConstants.dashboardPink
                  : ColorConstants.dashboardInkSoft,
              size: 19,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? ColorConstants.dashboardPink
                    : ColorConstants.dashboardInkSoft,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverview() {
    final stats = controller.stats.value;
    // Real revenue from the backend (`GET /reports/admin/stats/`). Both are
    // the platform's commission summed from confirmed AppointmentPayments and
    // are nullable — the backend returns null (not 0) until at least one
    // payment has been confirmed. We display Rs. 0 for null rather than
    // inventing figures.
    final revenueThisMonth = stats?.revenueThisMonth ?? 0;
    final totalRevenueCollected = stats?.totalRevenueCollected ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revenue Overview',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInk,
              ),
            ),
            // TextButton(
            //   onPressed: () {},
            //   style: TextButton.styleFrom(
            //     padding: EdgeInsets.zero,
            //     minimumSize: Size.zero,
            //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //   ),
            //   child: Text(
            //     'View All',
            //     style: TextStyle(
            //       fontSize: 12.5,
            //       fontWeight: FontWeight.w700,
            //       color: ColorConstants.dashboardPink,
            //     ),
            //   ),
            //),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRevenueCard(
                label: 'Revenue This Month',
                subtitle: 'Commission earned',
                value: _formatMoney(revenueThisMonth),
                emoji: '',
                isHighlighted: false,
              ),
              const SizedBox(width: 10),
              _buildRevenueCard(
                label: 'Total Revenue Collected',
                subtitle: 'All-time commission',
                value: _formatMoney(totalRevenueCollected),
                emoji: '📈',
                isHighlighted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formats a rupee amount from the backend (e.g. `4500.00`) as a compact
  /// "Rs. 4.5K" string. Null revenues are already defaulted to 0 by the
  /// caller so we never show an empty value.
  String _formatMoney(double value) {
    if (value >= 1000000) {
      return 'Rs. ${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return 'Rs. ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs. ${value.floor()}';
  }

  Widget _buildTwoColumnCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildLiveMiniCard()],
    );
  }

  // Widget _buildMiniCard({
  //   required String title,
  //   required List<MiniItem> items,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: ColorConstants.dashboardPanel,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: ColorConstants.dashboardLine, width: 1),
  //       boxShadow: [
  //         BoxShadow(
  //           color: ColorConstants.dashboardShadow,
  //           blurRadius: 8,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               title,
  //               style: TextStyle(
  //                 fontWeight: FontWeight.w800,
  //                 fontSize: 13,
  //                 color: ColorConstants.dashboardInk,
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () {},
  //               style: TextButton.styleFrom(
  //                 padding: EdgeInsets.zero,
  //                 minimumSize: Size.zero,
  //                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //               ),
  //               child: Text(
  //                 'View All',
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.w700,
  //                   color: ColorConstants.dashboardPink,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         ...items
  //             .map(
  //               (item) => Padding(
  //                 padding: const EdgeInsets.symmetric(vertical: 4),
  //                 child: Row(
  //                   children: [
  //                     Container(
  //                       width: 32,
  //                       height: 32,
  //                       decoration: BoxDecoration(
  //                         color: item.iconColor,
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Icon(
  //                         item.icon,
  //                         size: 16,
  //                         color: item.iconColor.withOpacity(
  //                           1,
  //                         ), // Full opacity for the icon
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Text(
  //                         item.label,
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w600,
  //                           color: ColorConstants.dashboardInkSoft,
  //                         ),
  //                       ),
  //                     ),
  //                     Text(
  //                       item.value,
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w800,
  //                         color: ColorConstants.dashboardInk,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             )
  //             .toList(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLiveMiniCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Monitoring',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: ColorConstants.dashboardInk,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardMint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: ColorConstants.dashboardMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: ColorConstants.dashboardMint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => _buildLiveRow(
              '🩺',
              'Online Doctors',
              '${controller.stats.value?.totalDoctors ?? 0}',
            ),
          ),
          Obx(
            () => _buildLiveRow(
              '👥',
              "Today's Consultations",
              '${controller.stats.value?.todayAppointments ?? 0}',
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('💓', style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }

  Widget _buildRevenueCard({
    required String label,
    required String subtitle,
    required String value,
    required String emoji,
    required bool isHighlighted,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFFF4DE)
            : ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? Colors.transparent
              : ColorConstants.dashboardLine,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: ColorConstants.dashboardInkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.dashboardInk,
                ),
              ),
              // Container(
              //   width: 32,
              //   height: 32,
              //   decoration: BoxDecoration(
              //     color: ColorConstants.dashboardAmber.withOpacity(0.18),
              //     shape: BoxShape.circle,
              //   ),
              //   child: Center(
              //     child: Text(emoji, style: const TextStyle(fontSize: 14)),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== DATA MODELS ====================
class _QuickActionItem {
  final String icon;
  final String label;
  final Color color;
  final String? route;

  _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
  });
}

class MonthlyData {
  final String month;
  final double value;

  MonthlyData({required this.month, required this.value});
}

class MiniItem {
  final String label;
  final String value;
  final Color iconColor;
  final IconData icon; // Add this field

  final String? emoji;

  MiniItem({
    required this.label,
    required this.value,
    required this.iconColor,
    this.emoji = '●',
    required this.icon,
  });
}

class DoctorItem {
  final String name;
  final String specialty;
  final String status;

  DoctorItem({
    required this.name,
    required this.specialty,
    required this.status,
  });
}

class PatientItem {
  final String name;
  final String subtitle;
  final String status;

  PatientItem({
    required this.name,
    required this.subtitle,
    required this.status,
  });
}

class WithdrawItem {
  final String name;
  final String amount;
  final String status;

  WithdrawItem({
    required this.name,
    required this.amount,
    required this.status,
  });
}

class NotificationItem {
  final String text;
  final String time;
  final bool isRead;

  NotificationItem({
    required this.text,
    required this.time,
    required this.isRead,
  });
}

// ==================== SPARKLINE PAINTER ====================
class SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = range == 0
          ? size.height / 2
          : size.height -
                ((data[i] - minValue) / range) * size.height * 0.8 -
                4;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
