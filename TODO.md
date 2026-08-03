# Patient Detail API Integration — Implementation Steps

## Task
Integrate `GET /accounts/patients/{id}/` (already present) + `PATCH /accounts/patients/{id}/` (account status management) into the Patient Detail screen.

## Steps

- [ ] **Step 1:** Update `lib/features/patients/models/patient.dart`
  - Add `address` field to `PatientProfile` model and parse from JSON.
- [ ] **Step 2:** Update `lib/features/patients/repositories/patient_repository.dart`
  - Add `updatePatientStatus(int id, bool isActive)` method using `PATCH /accounts/patients/{id}/`.
  - Add debug logging (request URL, body, response status, response body, parsed result).
- [ ] **Step 3:** Update `lib/features/patients/controllers/patient_detail_controller.dart`
  - Add `isUpdatingStatus` and `statusUpdateError` reactives.
  - Add `updateAccountStatus(bool isActive)` method with error handling and debug logging.
- [ ] **Step 4:** Update `lib/features/patients/screens/patient_detail_screen.dart`
  - Add Active/Inactive status badge in profile header driven by `patient.isActive`.
  - Wire "Suspend" button to `updateAccountStatus(false)`; show "Activate" when inactive.
  - Show loading state on the button during status update.
  - Show SnackBar feedback on success/error.
  - Update Address row to use `patient.patientProfile?.address`.
- [ ] **Step 5:** Run `flutter analyze` to verify no compilation errors.
- [ ] **Step 6:** Update this TODO file marking completed steps.
