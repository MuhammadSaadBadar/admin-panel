import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/patients/controllers/diet_plan_controller.dart';
import 'package:admin/features/patients/models/diet_plan.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/dashboard_background.dart';

/// Create / Edit Diet Plan screen.
///
/// For **create** (no `planId` arg) it POSTs a new plan via
/// `POST /api/v1/diet/plans/`. For **edit** (`planId` + `plan` args) it
/// pre-fills the form and PATCHes via `PATCH /api/v1/diet/plans/{id}/`.
///
/// All fields map 1:1 to the `DietPlanRequest` schema:
/// `hydration_recommendation_ml`, `notes`, `meals[]`, `foods_to_avoid[]`.
class CreateDietPlanScreen extends StatefulWidget {
  const CreateDietPlanScreen({super.key});

  @override
  State<CreateDietPlanScreen> createState() => _CreateDietPlanScreenState();
}

class _CreateDietPlanScreenState extends State<CreateDietPlanScreen> {
  late final DietPlanController _controller;
  int _patientId = 0;
  String _patientName = '';
  int? _planId;
  DietPlan? _existingPlan;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hydrationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<MealEditorItem> _meals = [];
  final List<FoodEditorItem> _foodsToAvoid = [];

  bool get _isEditing => _planId != null;

  @override
  void initState() {
    super.initState();
    debugPrint('[CreateDietPlanScreen] initState');

    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<DietPlanController>()) {
      Get.put(DietPlanController(Get.find<PatientRepository>()));
    }
    _controller = Get.find<DietPlanController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      _patientId = args?['patientId'] as int? ?? 0;
      _patientName = args?['patientName'] as String? ?? '';
      _planId = args?['planId'] as int?;
      _existingPlan = args?['plan'] as DietPlan?;
      debugPrint(
        '[CreateDietPlanScreen] patientId=$_patientId planId=$_planId '
        'editing=$_isEditing',
      );
      if (_isEditing && _existingPlan != null) {
        _hydrateFromPlan(_existingPlan!);
      } else {
        _hydrationController.text = '2500';
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _hydrationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrateFromPlan(DietPlan plan) {
    debugPrint(
      '[CreateDietPlanScreen] Pre-filling form from plan #${plan.id} '
      'hydration=${plan.hydrationRecommendationMl} '
      'meals=${plan.meals.length} foods=${plan.foodsToAvoid.length}',
    );
    _hydrationController.text = plan.hydrationRecommendationMl.toString();
    _notesController.text = plan.notes;
    _meals
      ..clear()
      ..addAll(
        plan.meals
            .map(
              (m) => MealEditorItem(
                type: _capFirst(m.mealType),
                description: m.description,
              ),
            )
            .toList(),
      );
    _foodsToAvoid
      ..clear()
      ..addAll(
        plan.foodsToAvoid
            .map((f) => FoodEditorItem(foodName: f.foodName, reason: f.reason))
            .toList(),
      );
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
              _buildAppBar(isMobile),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPatientHeader(isMobile),
                          const SizedBox(height: 16),
                          _buildHydrationField(),
                          const SizedBox(height: 16),
                          _buildNotesField(),
                          const SizedBox(height: 16),
                          _buildMealsSection(),
                          const SizedBox(height: 16),
                          _buildFoodsSection(),
                          const SizedBox(height: 16),
                          _buildSummaryCard(),
                          const SizedBox(height: 16),
                          _buildWarning(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                          const SizedBox(height: 24),
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
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar(bool isMobile) {
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
              debugPrint('[CreateDietPlanScreen] Back pressed');
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
            _isEditing ? 'Edit Diet Plan' : 'Create Diet Plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
          const Spacer(),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isEditing
                    ? ColorConstants.dashboardPink.withOpacity(0.12)
                    : ColorConstants.dashboardTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isEditing
                          ? ColorConstants.dashboardPink
                          : ColorConstants.dashboardTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isEditing ? 'EDITING' : 'NEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isEditing
                          ? ColorConstants.dashboardPink
                          : ColorConstants.dashboardTeal,
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

  // ==================== PATIENT HEADER ====================
  Widget _buildPatientHeader(bool isMobile) {
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName.isNotEmpty ? _patientName : 'Patient',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
                Text(
                  'Patient ID: #${_patientId == 0 ? '?' : _patientId}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.dashboardInkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing && isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardPink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'EDIT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.dashboardPink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== HYDRATION FIELD ====================
  Widget _buildHydrationField() {
    return _sectionCard(
      icon: Icons.water_drop,
      color: ColorConstants.dashboardTeal,
      title: 'Hydration Target',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Intake (ml/day)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorConstants.dashboardInkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hydrationController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2500',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.dashboardInkSoft,
                    ),
                    filled: true,
                    fillColor: ColorConstants.dashboardCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                  ),
                  validator: (v) {
                    final val = int.tryParse(v ?? '');
                    if (val == null || val <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final val = int.tryParse(_hydrationController.text) ?? 0;
                  if (val > 0) {
                    _hydrationController.text = (val - 100).toString();
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.dashboardPanel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.remove,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
              IconButton(
                onPressed: () {
                  final val = int.tryParse(_hydrationController.text) ?? 0;
                  _hydrationController.text = (val + 100).toString();
                },
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.dashboardPanel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== NOTES FIELD ====================
  Widget _buildNotesField() {
    return _sectionCard(
      icon: Icons.medical_information,
      color: ColorConstants.dashboardPink,
      title: 'Clinical Notes',
      child: TextFormField(
        controller: _notesController,
        maxLines: 4,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: ColorConstants.dashboardInk,
        ),
        decoration: InputDecoration(
          hintText: 'General instructions, dietary restrictions, allergies…',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: ColorConstants.dashboardInkSoft,
          ),
          filled: true,
          fillColor: ColorConstants.dashboardCream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
        ),
      ),
    );
  }

  // ==================== MEALS SECTION ====================
  Widget _buildMealsSection() {
    return _sectionCard(
      icon: Icons.restaurant,
      color: ColorConstants.dashboardAmber,
      title: 'Meal Builder',
      trailing: TextButton.icon(
        onPressed: () => _addMeal(),
        icon: const Icon(
          Icons.add,
          size: 18,
          color: ColorConstants.dashboardPink,
        ),
        label: Text(
          'Add Meal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardPink,
          ),
        ),
      ),
      child: _meals.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No meals added yet.',
                style: GoogleFonts.plusJakartaSans(
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            )
          : Column(
              children: _meals.map((meal) {
                return _buildMealRow(meal);
              }).toList(),
            ),
    );
  }

  Widget _buildMealRow(MealEditorItem meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.dashboardLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stack = constraints.maxWidth < 460;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: meal.type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: ColorConstants.dashboardInk,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: ColorConstants.dashboardCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.dashboardLine,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.dashboardPink,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: ColorConstants.dashboardPanel,
                        items: const [
                          DropdownMenuItem(
                            value: 'Breakfast',
                            child: Text('Breakfast'),
                          ),
                          DropdownMenuItem(
                            value: 'Lunch',
                            child: Text('Lunch'),
                          ),
                          DropdownMenuItem(
                            value: 'Dinner',
                            child: Text('Dinner'),
                          ),
                          DropdownMenuItem(
                            value: 'Snack',
                            child: Text('Snack'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => meal.type = v ?? 'Breakfast'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _meals.remove(meal)),
                      style: IconButton.styleFrom(
                        backgroundColor: ColorConstants.error.withOpacity(0.08),
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: ColorConstants.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: meal.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. Oatmeal with berries',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.dashboardInkSoft,
                    ),
                    filled: true,
                    fillColor: ColorConstants.dashboardCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => meal.description = v,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: meal.type,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: ColorConstants.dashboardCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: ColorConstants.dashboardPanel,
                  items: const [
                    DropdownMenuItem(
                      value: 'Breakfast',
                      child: Text('Breakfast'),
                    ),
                    DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                  ],
                  onChanged: (v) =>
                      setState(() => meal.type = v ?? 'Breakfast'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: meal.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. Oatmeal with berries',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.dashboardInkSoft,
                    ),
                    filled: true,
                    fillColor: ColorConstants.dashboardCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => meal.description = v,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _meals.remove(meal)),
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.error.withOpacity(0.08),
                ),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: ColorConstants.error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== FOODS TO AVOID SECTION ====================
  Widget _buildFoodsSection() {
    return _sectionCard(
      icon: Icons.do_not_disturb,
      color: ColorConstants.error,
      title: 'Foods to Avoid',
      trailing: TextButton.icon(
        onPressed: () => _addFood(),
        icon: const Icon(
          Icons.add,
          size: 18,
          color: ColorConstants.dashboardPink,
        ),
        label: Text(
          'Add Food',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ColorConstants.dashboardPink,
          ),
        ),
      ),
      child: _foodsToAvoid.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No restricted foods listed.',
                style: GoogleFonts.plusJakartaSans(
                  color: ColorConstants.dashboardInkSoft,
                ),
              ),
            )
          : Column(
              children: _foodsToAvoid.map((food) {
                return _buildFoodRow(food);
              }).toList(),
            ),
    );
  }

  Widget _buildFoodRow(FoodEditorItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorConstants.error.withOpacity(0.2),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stack = constraints.maxWidth < 460;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: food.foodName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: ColorConstants.dashboardInk,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Food Name',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: ColorConstants.error,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.dashboardLine,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.dashboardPink,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) => food.foodName = v,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _foodsToAvoid.remove(food)),
                      style: IconButton.styleFrom(
                        backgroundColor: ColorConstants.error.withOpacity(0.08),
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: ColorConstants.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: food.reason,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Reason (e.g. Medication interaction)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.dashboardInkSoft,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => food.reason = v,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: food.foodName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Food Name',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.error,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => food.foodName = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: food.reason,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: ColorConstants.dashboardInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Reason (e.g. Medication interaction)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: ColorConstants.dashboardInkSoft,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.dashboardPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => food.reason = v,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _foodsToAvoid.remove(food)),
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.error.withOpacity(0.08),
                ),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: ColorConstants.error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _buildSummaryCard() {
    final hydration = int.tryParse(_hydrationController.text) ?? 0;
    final liters = (hydration / 1000).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'PLAN SUMMARY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardPink,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Meals',
                  '${_meals.length}',
                  ColorConstants.dashboardAmber,
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  'Hydration',
                  '$liters L',
                  ColorConstants.dashboardTeal,
                  Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryItem(
            'Restricted Foods',
            '${_foodsToAvoid.length}',
            ColorConstants.error,
            Icons.do_not_disturb,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WARNING ====================
  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorConstants.dashboardAmber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorConstants.dashboardAmber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: ColorConstants.dashboardAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Saving will deactivate the current active plan for this patient.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.dashboardInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SUBMIT BUTTON ====================
  Widget _buildSubmitButton() {
    return Obx(() {
      final saving = _controller.isSaving.value;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.dashboardPink,
              ColorConstants.dashboardPink2,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.dashboardPink.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withOpacity(0.6),
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _isEditing ? Icons.save : Icons.add_circle_outline,
                  size: 22,
                ),
          label: Text(
            saving
                ? 'Saving…'
                : (_isEditing ? 'Update Diet Plan' : 'Create Diet Plan'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }

  // ==================== SECTION CARD ====================
  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.dashboardInk,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Building / validation ───────────────────────────────────────────────
  List<DietPlanMealInput> _buildMealInputs() {
    return _meals
        .where((m) => m.description.trim().isNotEmpty)
        .map(
          (m) => DietPlanMealInput(
            mealType: m.type.toLowerCase(),
            description: m.description.trim(),
          ),
        )
        .toList();
  }

  List<DietFoodAvoidInput> _buildFoodInputs() {
    return _foodsToAvoid
        .where((f) => f.foodName.trim().isNotEmpty)
        .map(
          (f) => DietFoodAvoidInput(
            foodName: f.foodName.trim(),
            reason: f.reason.trim().isEmpty
                ? 'No reason provided'
                : f.reason.trim(),
          ),
        )
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('[CreateDietPlanScreen] Validation failed');
      return;
    }
    if (_patientId == 0) {
      Get.snackbar(
        'Error',
        'Missing patient context. Please go back and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final request = DietPlanRequest(
      patientId: _patientId,
      hydrationRecommendationMl: int.tryParse(_hydrationController.text) ?? 0,
      notes: _notesController.text.trim(),
      meals: _buildMealInputs(),
      foodsToAvoid: _buildFoodInputs(),
    );

    debugPrint(
      '[CreateDietPlanScreen] _save — editing=$_isEditing '
      'hydration=${request.hydrationRecommendationMl} '
      'meals=${request.meals.length} foods=${request.foodsToAvoid.length}',
    );

    final bool success;
    if (_isEditing) {
      final updated = await _controller.updateDietPlan(_planId!, request);
      success = updated != null;
    } else {
      final created = await _controller.createDietPlan(request);
      success = created != null;
    }

    if (success) {
      debugPrint('[CreateDietPlanScreen] Save success — navigating back');
      Get.back();
    } else {
      debugPrint('[CreateDietPlanScreen] Save failed — staying on screen');
    }
  }

  // ── Item factories ──────────────────────────────────────────────────────
  void _addMeal() {
    setState(() {
      _meals.add(MealEditorItem(type: 'Breakfast', description: ''));
    });
  }

  void _addFood() {
    setState(() {
      _foodsToAvoid.add(FoodEditorItem(foodName: '', reason: ''));
    });
  }

  String _capFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ── Editor models ─────────────────────────────────────────────────────────
class MealEditorItem {
  String type;
  String description;

  MealEditorItem({required this.type, required this.description});
}

class FoodEditorItem {
  String foodName;
  String reason;

  FoodEditorItem({required this.foodName, required this.reason});
}
