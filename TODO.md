# TODO — Navigation Architecture: Drawer-only (remove Bottom Nav Bar)

## Approved Plan
Remove the duplicate **Bottom Navigation Bar** so the **Navigation Drawer** is the sole primary navigation on mobile. This removes redundant navigation paths and matches mobile-first Admin Panel best practices.

## Steps
### 1. Remove `bottomNavigationBar:` from the 4 top-level screens
- [ ] `lib/features/dashboard/screens/dashboard_screen.dart`
- [ ] `lib/features/doctors/screens/doctor_dashboard_screen.dart`
- [ ] `lib/features/patients/screens/patient_dashboard_screen.dart`
- [ ] `lib/features/appointments/screens/appointments_dashboard_screen.dart`

### 2. Remove now-unused imports
- [ ] Remove `app_bottom_nav_bar.dart` imports from the 4 screens.

### 3. Delete the unused widget
- [ ] Delete `lib/core/widgets/app_bottom_nav_bar.dart`.

## Follow-up
- [ ] Run `flutter analyze` to confirm no errors (unused-import warnings should be gone).
