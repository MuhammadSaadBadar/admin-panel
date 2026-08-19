// Diet Plan Management screen — fully API-backed.
//
// Fetches via `DietPlanController`:
//   - the patient's full diet-plan history (`GET /api/v1/diet/plans/?patient_id=`),
//   - the current active plan (`GET /api/v1/diet/plans/active/?patient_id=`).
//
// Supports create (`POST` via the create-route), edit (`PATCH`), and delete
// (`DELETE`), all through the same controller/repository used elsewhere.
// No placeholder/static data remains — every section renders live API state.

import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/routes/route_names.dart';
import 'package:admin/core/widgets/empty_state_widget.dart';
import 'package:admin/core/widgets/error_widget.dart';
import 'package:admin/features/patients/controllers/diet_plan_controller.dart';
import 'package:admin/features/patients/models/diet_plan.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import '../../../core/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DietPlanManagementScreen extends StatefulWidget {
  const DietPlanManagementScreen({super.key});

  @override
  State<DietPlanManagementScreen> createState() =>
      _DietPlanManagementScreenState();
}

class _DietPlanManagementScreenState extends State<DietPlanManagementScreen>
    with SingleTickerProviderStateMixin {
  late final DietPlanController _controller;
  int _patientId = 0;
  String _patientName = '';

  /// Guards against re-triggering the initial load on rebuilds.
  bool _hasLoaded = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<DietPlanController>()) {
      Get.put(DietPlanController(Get.find<PatientRepository>()));
    }
    _controller = Get.find<DietPlanController>();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Resolve navigation arguments and kick off the data load exactly once,
    // after the first frame (so Get.arguments is available). Never inside
    // build() — that caused an infinite reload loop via Obx rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveArgsAndLoad();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resolveArgsAndLoad() {
    if (_hasLoaded) {
      debugPrint('[DietPlanManagement] Already loaded, skip');
      return;
    }
    final args = Get.arguments as Map<String, dynamic>?;
    _patientId = (args?['patientId'] as num?)?.toInt() ?? 0;
    _patientName = args?['patientName'] as String? ?? '';
    debugPrint(
      '[DietPlanManagement] Resolved args — patientId=$_patientId '
      'patientName="$_patientName"',
    );
    if (_patientId != 0) {
      _hasLoaded = true;
      if (_patientName.isEmpty) {
        _loadPatientName();
      }
      _controller.load(_patientId);
    }
  }

  Future<void> _loadPatientName() async {
    try {
      final repo = Get.find<PatientRepository>();
      final patient = await repo.getPatient(_patientId);
      if (mounted) {
        setState(() => _patientName = patient.name);
      }
      debugPrint('[DietPlanManagement] Loaded patient name="${patient.name}"');
    } catch (e) {
      debugPrint('[DietPlanManagement] Failed to load patient name: $e');
    }
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPatientContext(isMobile),
                          const SizedBox(height: 24),
                          _buildActivePlanSection(isMobile),
                          const SizedBox(height: 24),
                          _buildHistorySection(isMobile),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(isMobile),
    );
  }

  // ── Floating Action Button ─────────────────────────────────────────────
  Widget _buildFAB(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardPink, ColorConstants.dashboardPink2],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardPink.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _openCreate(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isMobile ? 'New Plan' : 'New Diet Plan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────
  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel.withOpacity(0.60),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              debugPrint('[DietPlanManagement] Back pressed');
              Get.back();
            },
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back,
              color: ColorConstants.dashboardInk,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Diet Plans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
          const Spacer(),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ColorConstants.dashboardTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MANAGE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.dashboardTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Patient context ─────────────────────────────────────────────────────
  Widget _buildPatientContext(bool isMobile) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.dashboardPink2,
                  ColorConstants.dashboardPink,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName.isEmpty ? 'Patient' : _patientName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: #$_patientId',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: Obx-driven state ──────────────────────────────────────────────
  Widget _buildActivePlanSection(bool isMobile) {
    return Obx(() {
      // Loading state.
      if (_controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(
              color: ColorConstants.dashboardPink,
            ),
          ),
        );
      }

      // Error state.
      if (_controller.error.value != null) {
        return AppErrorWidget(
          message: _controller.error.value!,
          onRetry: () => _controller.load(_patientId),
        );
      }

      final activePlan = _controller.activePlan.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.star,
            title: 'Current Active Plan',
            color: ColorConstants.dashboardPink,
          ),
          const SizedBox(height: 12),
          if (activePlan == null)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardPanel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorConstants.dashboardLine,
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
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: ColorConstants.dashboardInkSoft.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Active Diet Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.dashboardInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This patient does not have an active diet plan yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.dashboardInkSoft,
                    ),
                  ),
                ],
              ),
            )
          else
            _ActivePlanCard(
              plan: activePlan,
              onEdit: () => _openEdit(activePlan),
            ),
        ],
      );
    });
  }

  Widget _buildHistorySection(bool isMobile) {
    return Obx(() {
      final plans = List<DietPlan>.from(_controller.plans);
      // Exclude the currently active plan from the "historical" list.
      final activeId = _controller.activePlan.value?.id;
      final history = plans.where((p) => p.id != activeId).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.history,
            title: 'Historical Plans',
            color: ColorConstants.dashboardInkSoft,
          ),
          const SizedBox(height: 12),
          if (!_controller.isLoading.value && history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardPanel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorConstants.dashboardLine,
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
              child: Center(
                child: Text(
                  'No historical diet plans.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
              ),
            )
          else
            ...history.map(
              (plan) => _HistoryPlanCard(
                plan: plan,
                isMobile: isMobile,
                onEdit: () => _openEdit(plan),
                onDelete: () => _confirmDelete(plan),
                onView: () => _showPlanDetail(plan),
              ),
            ),
        ],
      );
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _openCreate() {
    debugPrint(
      '[DietPlanManagement] Opening create plan — patientId=$_patientId',
    );
    Get.toNamed(
      RouteNames.dietPlansCreate,
      arguments: {'patientId': _patientId, 'patientName': _patientName},
    );
  }

  void _openEdit(DietPlan plan) {
    debugPrint(
      '[DietPlanManagement] Opening edit plan — id=${plan.id} patientId=$_patientId',
    );
    Get.toNamed(
      RouteNames.dietPlansCreate,
      arguments: {
        'patientId': _patientId,
        'patientName': _patientName,
        'planId': plan.id,
        'plan': plan,
      },
    );
  }

  void _confirmDelete(DietPlan plan) {
    debugPrint('[DietPlanManagement] Delete requested — id=${plan.id}');
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.dashboardPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Diet Plan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardInk,
          ),
        ),
        content: Text(
          'This will permanently delete the diet plan. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.dashboardInkSoft,
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
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.error,
                  ColorConstants.error.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await _controller.deleteDietPlan(plan.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanDetail(DietPlan plan) {
    Get.bottomSheet(
      _PlanDetailSheet(plan: plan),
      backgroundColor: ColorConstants.dashboardPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardInk,
          ),
        ),
      ],
    );
  }
}

// ── Active plan card ──────────────────────────────────────────────────────
class _ActivePlanCard extends StatelessWidget {
  final DietPlan plan;
  final VoidCallback onEdit;

  const _ActivePlanCard({required this.plan, required this.onEdit});

  String _formatHydration() {
    final ml = plan.hydrationRecommendationMl;
    if (ml > 0 && ml % 1000 == 0) {
      return '${(ml / 1000).toStringAsFixed(0)} L/day';
    }
    return '$ml ml/day';
  }

  @override
  Widget build(BuildContext context) {
    final authorName = plan.createdBy?.name ?? 'Unknown';
    final dateLabel = plan.createdAt.isNotEmpty
        ? plan.createdAt.substring(0, 10)
        : 'Unknown date';
    final metrics = [
      (
        icon: Icons.water_drop,
        color: ColorConstants.dashboardTeal,
        label: 'Hydration',
        value: _formatHydration(),
      ),
      (
        icon: Icons.restaurant,
        color: ColorConstants.dashboardAmber,
        label: 'Meals',
        value: '${plan.meals.length} scheduled',
      ),
      (
        icon: Icons.do_not_disturb,
        color: ColorConstants.error,
        label: 'Restricted Foods',
        value: '${plan.foodsToAvoid.length} listed',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.dashboardPink.withOpacity(0.05),
            ColorConstants.dashboardPink2.withOpacity(0.02),
          ],
        ),
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _ActiveBadge(),
              Container(
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: ColorConstants.dashboardPink,
                  ),
                  label: Text(
                    'Edit Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.dashboardPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: ColorConstants.dashboardInkSoft,
              ),
              const SizedBox(width: 4),
              Text(
                'Prescribed by $authorName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today,
                size: 12,
                color: ColorConstants.dashboardInkSoft,
              ),
              const SizedBox(width: 4),
              Text(
                dateLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics grid — derive column width from the card's real available
          // width (via LayoutBuilder) so it adapts across screen sizes.
          LayoutBuilder(
            builder: (context, constraints) {
              final double available = constraints.maxWidth;
              // 2 columns on narrow cards, 3 on wider ones.
              const int columns = 3;
              final double boxWidth =
                  (available - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics
                    .map(
                      (m) => SizedBox(
                        width: boxWidth,
                        child: _MetricBox(
                          icon: m.icon,
                          color: m.color,
                          label: m.label,
                          value: m.value,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

          if (plan.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: ColorConstants.dashboardLine),
            const SizedBox(height: 12),
            Text(
              'CLINICAL NOTES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInkSoft,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardCream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                plan.notes,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.4,
                  color: ColorConstants.dashboardInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.dashboardTeal, ColorConstants.dashboardTeal2],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardTeal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ACTIVE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Historical plan card ──────────────────────────────────────────────────
class _HistoryPlanCard extends StatelessWidget {
  final DietPlan plan;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _HistoryPlanCard({
    required this.plan,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  String _formatHydration() {
    final ml = plan.hydrationRecommendationMl;
    if (ml == 0) return '—';
    if (ml % 1000 == 0) return '${(ml / 1000).toStringAsFixed(0)} L';
    return '$ml ml';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardInkSoft.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: ColorConstants.dashboardInkSoft.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'INACTIVE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInkSoft,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.createdBy?.name ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.dashboardInk,
                      ),
                    ),
                    Text(
                      plan.createdAt.isNotEmpty
                          ? plan.createdAt.substring(0, 10)
                          : 'Unknown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: ColorConstants.dashboardInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Summary info
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _InlineStat(label: 'Hydration', value: _formatHydration()),
              _InlineStat(label: 'Meals', value: '${plan.meals.length}'),
              _InlineStat(
                label: 'Restricted',
                value: '${plan.foodsToAvoid.length}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: ColorConstants.dashboardLine),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'View',
                onPressed: onView,
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.dashboardPanel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.visibility,
                  size: 20,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.dashboardPink.withOpacity(
                    0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: ColorConstants.dashboardPink,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: ColorConstants.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _InlineStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorConstants.dashboardInkSoft,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────
class _PlanDetailSheet extends StatelessWidget {
  final DietPlan plan;

  const _PlanDetailSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final hydration = plan.hydrationRecommendationMl;
    final hydrationLabel = hydration == 0
        ? '—'
        : hydration % 1000 == 0
        ? '${(hydration / 1000).toStringAsFixed(0)} L/day'
        : '$hydration ml/day';

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: ColorConstants.dashboardPanel,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ColorConstants.dashboardInkSoft.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorConstants.dashboardPink,
                              ColorConstants.dashboardPink2,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diet Plan #${plan.id}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.dashboardInk,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: plan.isActive
                                    ? ColorConstants.dashboardTeal.withOpacity(
                                        0.12,
                                      )
                                    : ColorConstants.dashboardInkSoft
                                          .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                plan.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: plan.isActive
                                      ? ColorConstants.dashboardTeal
                                      : ColorConstants.dashboardInkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _detailMetric('Hydration Target', hydrationLabel),
                  const SizedBox(height: 16),
                  if (plan.notes.isNotEmpty) ...[
                    _detailLabel('Clinical Notes'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColorConstants.dashboardCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plan.notes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: ColorConstants.dashboardInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _detailLabel('Meals'),
                  const SizedBox(height: 8),
                  if (plan.meals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorConstants.dashboardCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No meals listed.',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorConstants.dashboardInkSoft,
                        ),
                      ),
                    )
                  else
                    ...plan.meals.map(
                      (m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ColorConstants.dashboardPanel,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorConstants.dashboardLine,
                            width: 1,
                          ),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ColorConstants.dashboardAmber
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                size: 18,
                                color: ColorConstants.dashboardAmber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cap(m.mealType),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.dashboardInk,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.description.isEmpty
                                        ? 'No description'
                                        : m.description,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: ColorConstants.dashboardInkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _detailLabel('Foods to Avoid'),
                  const SizedBox(height: 8),
                  if (plan.foodsToAvoid.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorConstants.dashboardCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No restricted foods listed.',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorConstants.dashboardInkSoft,
                        ),
                      ),
                    )
                  else
                    ...plan.foodsToAvoid.map(
                      (f) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ColorConstants.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorConstants.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ColorConstants.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.do_not_disturb,
                                size: 18,
                                color: ColorConstants.error,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.foodName.isEmpty
                                        ? 'Unknown food'
                                        : f.foodName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.error,
                                    ),
                                  ),
                                  if (f.reason.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      f.reason,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: ColorConstants.dashboardInkSoft,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailMetric(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.dashboardTeal.withOpacity(0.08),
            ColorConstants.dashboardTeal2.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorConstants.dashboardTeal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardTeal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ColorConstants.dashboardInkSoft,
        letterSpacing: 0.5,
      ),
    );
  }

  String _cap(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
