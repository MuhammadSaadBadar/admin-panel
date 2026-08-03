import 'package:get/get.dart';
import '../models/doctor.dart';
import '../repositories/doctor_repository.dart';

class DoctorListController extends GetxController {
  final DoctorRepository _repository;

  DoctorListController(this._repository);

  final RxList<Doctor> doctors = <Doctor>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _repository.getDoctors();
      doctors.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDoctor(int id) async {
    try {
      await _repository.deleteDoctor(id);
      doctors.removeWhere((d) => d.id == id);
    } catch (e) {
      error.value = e.toString();
    }
  }
}
