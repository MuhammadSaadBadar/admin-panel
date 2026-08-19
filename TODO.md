# Backend-Driven Payment Workflow + Dashboard API Integration

## Phase 1 — API Foundation
- [x] Add 6 new API constants to `api_constants.dart`
- [x] Fix indentation on existing constants
- [x] Verify analyzer clean

## Phase 2 — Payment Methods
- [x] Create `lib/features/appointments/models/payment_methods.dart` (PaymentMethods model)
- [x] Add `getPaymentMethods()` to AppointmentRepository

## Phase 3 — Payment-State Model + Patient Mark-Paid
- [x] Add `PaymentState` enum + `AppointmentPaymentInfo` to `appointment.dart`
- [x] Add patient `markPaid()` to AppointmentRepository / AppointmentDetailController / AppointmentDetailsScreen

## Phase 4 — Verification / Confirm
- [x] Add doctor/admin `verifyPayment()` → confirms payment + appointment
- [x] Wire verification UI in AppointmentDetailsScreen

## Phase 5 — Admin "Mark Paid"
- [x] Add `markPatientPaid()` to PatientRepository / PatientDetailController
- [x] Add "Mark Paid" button + `_showMarkPaidDialog` (optional amount/reference) to patient_detail_screen
- [x] Analyzer verified

## Phase 6 — Dashboard Integration
- [x] Add `totalRevenueCollected` / `revenueThisMonth` to `dashboard_stats.dart` (null-safe `_asDecimal`)
- [x] Update `_buildRevenueOverview()` to use real revenue (null → Rs. 0), remove hardcoded `_consultationRevenue`/`_commission`/`_lifetimeRevenue`
- [x] Keep ad-revenue mini-card static (no backend endpoint)
- [x] Reuse existing admin notification unread-count bell (NOT doctor endpoint)

## Phase 7 — UI/State Refinement
- [x] Error/loading states everywhere (never stuck loading)
- [x] No duplicate payment-state logic; centralized via `PaymentState` enum
- [x] No API calls in widgets; Screen→Controller→Repository→ApiClient→ApiConstants preserved
- [x] Run final `flutter analyze` to confirm no errors (user confirmed app runs clean)

---
# Dashboard Layout & Quick Action Button Responsiveness

## Steps

- [x] Analyze dashboard_screen.dart and identify the two sections to modify
- [x] Confirm plan with user

## 1. Ads Revenue & Live Monitoring — vertical column layout
- [x] Convert `_buildTwoColumnCards()` from a `Row` to a `Column` with full-width stretch and spacing
- [x] Remove `Expanded` wrapper in `_buildMiniCard()` and `_buildLiveMiniCard()`

## 2 & 3. Quick Action buttons — taller with multi-line text wrapping
- [x] Lower `childAspectRatio` in the Quick Actions `GridView.count` from 3.5 to 2.0
- [x] Add `maxLines: 2` and `textAlign: TextAlign.center` to the Quick Action label `Text`

## 4. Verification
- [x] Run `flutter analyze` to confirm no errors

---
# Doctor Status Toggle After Deactivation

## Steps

- [x] Analyze doctor model, repository, and controllers to identify root cause
- [x] Confirm plan with user

## Fix
- [x] Add `copyWith` method to `Doctor` model
- [x] Preserve correct doctor ID in `DoctorRepository.toggleDoctorActive` when PATCH response omits `id`

## Verification
- [ ] Run `flutter analyze` to confirm no errors

---
# Assign Doctor Card Text Visibility

## Steps

- [x] Analyze Assign Doctor screen card styling and color constants
- [x] Confirm plan with user

## Fix
- [x] Doctor name (mobile) color `primary` → `onSurface` (dark, high contrast)
- [x] Specialization color `tertiary`/`primary` → `onSurfaceVariant` (mobile + desktop)

## Verification
- [ ] Run `flutter analyze` to confirm no errors
