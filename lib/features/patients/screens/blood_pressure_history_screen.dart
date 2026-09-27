import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/routes/app_router.dart';
import 'package:admin/core/themes/app_theme.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BloodPressureHistoryScreen extends StatelessWidget {
  final PatientRepository _repository = Get.find();

  @override
  Widget build(BuildContext context) {
    final int patientId = Get.arguments['patientId'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Pressure History'),
        backgroundColor: ColorConstants.primary,
        elevation: 0,
      ),
      body: Obx(() {
        final controller = Get.find<BloodPressureHistoryController>();
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!));
        }
        return ListView.builder(
          itemCount: controller.history.length,
          itemBuilder: (context, index) {
            final entry = controller.history[index];
            final systolic = entry['systolic']?.toString() ?? '—';
            final diastolic = entry['diastolic']?.toString() ?? '—';
            final date = DateTime.tryParse(
              entry['recorded_at']?.toString() ?? '',
            );

            final double? systolicValue = (entry['systolic'] as num?)
                ?.toDouble();
            final double? diastolicValue = (entry['diastolic'] as num?)
                ?.toDouble();

            final String category = _getBPCategory(
              systolicValue ?? 0,
              diastolicValue ?? 0,
            );
            final Color categoryColor = _getCategoryColor(category);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerLow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      '$systolic/$diastolic',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'mmHg',
                      style: AppTheme.bodySmall.copyWith(
                        color: ColorConstants.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  category,
                  style: AppTheme.bodySmall.copyWith(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  _formatDate(date),
                  style: AppTheme.labelMedium.copyWith(
                    color: ColorConstants.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _getBPCategory(double systolic, double diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return 'High';
    } else if (systolic >= 120 || diastolic >= 80) {
      return 'Elevated';
    } else {
      return 'Normal';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'High':
        return Colors.red;
      case 'Elevated':
        return Colors.orange;
      case 'Normal':
      default:
        return ColorConstants.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'High':
        return Icons.warning_rounded;
      case 'Elevated':
        return Icons.trending_up_rounded;
      case 'Normal':
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class BloodPressureHistoryController extends GetxController {
  final PatientRepository _repository;
  final int patientId;

  BloodPressureHistoryController(this._repository, this.patientId);

  final RxList<dynamic> history = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repository.getBloodPressureHistory(patientId);
      history.assignAll(result);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
