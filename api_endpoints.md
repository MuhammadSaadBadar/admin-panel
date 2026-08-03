# Mama Health — Admin REST API Specification

> **Version:** 1.0.0  
> **Base URL:** `https://api.mamahealth.pro/v1`  
> **Auth Scheme:** Bearer Token (JWT)  
> **Content-Type:** `application/json` (unless stated otherwise)  
> **Date Format:** ISO 8601 (`2025-10-24T09:15:00Z`)

---

## Quick Reference — Key Design Decisions

| Concern | Decision |
|---|---|
| Pagination | Cursor-based for lists >100 rows; page-based for admin tables |
| Filtering | Query-param driven on all list endpoints |
| Sorting | `?sort=field&order=asc\|desc` on all list endpoints |
| Search | Dedicated `/search` endpoint + per-resource `?q=` param |
| Caching | Marked per endpoint with 🗄️ |
| Real-time | Marked per endpoint with 📡 (WebSocket/SSE preferred) |
| Batch | Marked per endpoint with 📦 |

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Admin Dashboard](#2-admin-dashboard)
3. [Doctors Management](#3-doctors-management)
4. [Patients Management](#4-patients-management)
5. [Appointments](#5-appointments)
6. [SOS & Emergency Alerts](#6-sos--emergency-alerts)
7. [Notifications](#7-notifications)
8. [Analytics & Reports](#8-analytics--reports)
9. [Content Management](#9-content-management)
10. [File Uploads](#10-file-uploads)
11. [Admin Profile & Settings](#11-admin-profile--settings)
12. [Global Search](#12-global-search)
13. [Missing / Recommended Endpoints](#13-missing--recommended-endpoints)
14. [Real-time Communication Map](#14-real-time-communication-map)
15. [Caching Strategy Summary](#15-caching-strategy-summary)

---

## 1. Authentication

### 1.1 Admin Login

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/auth/login` |
| **Auth Required** | No |
| **Screens** | `LoginScreen` |

**Request Body**
```json
{
  "email": "admin@mamahealth.pro",
  "password": "SecurePass123!",
  "remember_me": true
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "admin": {
      "id": "adm_01",
      "name": "Admin User",
      "email": "admin@mamahealth.pro",
      "role": "super_admin",
      "avatar_url": "https://cdn.mamahealth.pro/avatars/adm_01.jpg"
    }
  }
}
```

**Error Responses**

| Code | Reason |
|---|---|
| `401` | Invalid credentials |
| `403` | Account suspended |
| `429` | Too many login attempts |

**Validation Rules**
- `email`: Required, valid email format
- `password`: Required, min 8 characters

---

### 1.2 Refresh Token

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/auth/refresh` |
| **Auth Required** | No (uses refresh token) |

**Request Body**
```json
{ "refresh_token": "eyJhbGci..." }
```

**Success Response `200`**
```json
{
  "access_token": "eyJhbGci...",
  "expires_in": 3600
}
```

---

### 1.3 Admin Logout

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/auth/logout` |
| **Auth Required** | Yes |

**Request Headers**
```
Authorization: Bearer <access_token>
```

**Success Response `204`** _(No Content)_

---

### 1.4 Forgot Password

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/auth/forgot-password` |
| **Auth Required** | No |
| **Screens** | `ForgotPasswordScreen` |

**Request Body**
```json
{ "email": "admin@mamahealth.pro" }
```

**Success Response `200`**
```json
{ "message": "Password reset link sent to your email." }
```

---

### 1.5 Reset Password

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/auth/reset-password` |
| **Auth Required** | No |

**Request Body**
```json
{
  "token": "reset_token_from_email",
  "password": "NewSecurePass123!",
  "password_confirmation": "NewSecurePass123!"
}
```

**Validation Rules**
- `password`: min 8 chars, at least 1 uppercase, 1 digit, 1 symbol
- `password_confirmation`: must match `password`

---

## 2. Admin Dashboard

> 🗄️ **Cache this endpoint** — 60-second TTL, refreshed on mutation.  
> 📦 **Batch endpoint** — returns all dashboard card data in a single call, avoiding 4–6 separate requests.

### 2.1 Dashboard Summary Stats ⭐

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/dashboard/summary` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Stats Bento Grid — Total Patients, Total Doctors, Appointments Today, Active SOS) |

**Request Headers**
```
Authorization: Bearer <access_token>
```

**Success Response `200`**
```json
{
  "data": {
    "total_patients": 1240,
    "patients_growth_percent": 5.2,
    "total_doctors": 85,
    "doctors_growth_percent": 2.1,
    "appointments_today": 12,
    "active_sos_count": 2,
    "system_response_time_ms": 180,
    "system_health_percent": 92
  }
}
```

---

### 2.2 Patient Growth Chart Data 🗄️

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/dashboard/patient-growth` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (`PatientGrowthChart` widget) |

**Query Parameters**

| Param | Type | Default | Description |
|---|---|---|---|
| `period` | `string` | `6_months` | `6_months` or `1_year` |

**Success Response `200`**
```json
{
  "data": {
    "period": "6_months",
    "chart_data": [
      { "month": "Jun", "value": 40 },
      { "month": "Jul", "value": 55 },
      { "month": "Aug", "value": 45 },
      { "month": "Sep", "value": 70 },
      { "month": "Oct", "value": 85 },
      { "month": "Nov", "value": 30 }
    ]
  }
}
```

---

### 2.3 Trimester Distribution 🗄️

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/dashboard/trimester-distribution` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (`TrimesterDistribution` widget) |

**Success Response `200`**
```json
{
  "data": {
    "active_patients": 1200,
    "trimester_1": { "count": 420, "percent": 35 },
    "trimester_2": { "count": 420, "percent": 35 },
    "trimester_3": { "count": 360, "percent": 30 }
  }
}
```

---

### 2.4 Recent Activity Feed 📡

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/dashboard/activity` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Recent Activity section) |
| **Real-time** | Prefer **SSE** (`/dashboard/activity/stream`) for live push |

**Query Parameters**

| Param | Type | Default |
|---|---|---|
| `limit` | `integer` | `10` |
| `cursor` | `string` | — |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": "act_001",
      "type": "doctor_joined",
      "message": "Dr. Sarah joined the platform",
      "subtitle": "Pediatrics",
      "created_at": "2025-10-24T07:00:00Z"
    },
    {
      "id": "act_002",
      "type": "sos_alert",
      "message": "New SOS from Patient #204",
      "subtitle": "Critical Alert",
      "created_at": "2025-10-24T09:15:00Z",
      "patient_id": 204,
      "is_resolved": false
    },
    {
      "id": "act_003",
      "type": "appointment_confirmed",
      "message": "Appointment #882 confirmed",
      "subtitle": "Obstetrics",
      "created_at": "2025-10-24T05:00:00Z"
    }
  ],
  "next_cursor": "act_003"
}
```

---

## 3. Doctors Management

### 3.1 List Doctors

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/doctors` |
| **Auth Required** | Yes |
| **Screens** | `DoctorManagementScreen` (doctor grid) |
| **Supports** | Pagination ✅ · Filtering ✅ · Sorting ✅ · Search ✅ |

**Query Parameters**

| Param | Type | Example | Description |
|---|---|---|---|
| `page` | `integer` | `1` | Page number |
| `per_page` | `integer` | `20` | Items per page (max 100) |
| `q` | `string` | `sana` | Search by name, email, or specialization |
| `specialization` | `string` | `Gynaecologist` | Filter by specialization |
| `status` | `string` | `active\|inactive\|pending` | Filter by status |
| `sort` | `string` | `name` | Field to sort by |
| `order` | `string` | `asc` | `asc` or `desc` |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Dr. Sana Khan",
      "email": "sana.khan@example.com",
      "phone": "+1 555-0199",
      "specialization": "Gynaecologist",
      "experience_years": 10,
      "profile_image": "https://cdn.mamahealth.pro/doctors/1.jpg",
      "is_active": true,
      "is_pending": false,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 85,
    "last_page": 5
  }
}
```

---

### 3.2 Get Doctor Details

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/doctors/{id}` |
| **Auth Required** | Yes |
| **Screens** | `DoctorDetailsScreen` |

**Path Parameters**

| Param | Type | Description |
|---|---|---|
| `id` | `integer` | Doctor ID |

**Success Response `200`**
```json
{
  "data": {
    "id": 1,
    "name": "Dr. Sarah Jenkins",
    "email": "sarah.jenkins@example.com",
    "phone": "+1 555-0203",
    "specialization": "Senior Gynecologist & Obstetrician",
    "qualification": "MBBS, MD - Obstetrics & Gynecology",
    "institution": "Johns Hopkins School of Medicine",
    "experience_years": 12,
    "experience_description": "Specialized in High-Risk Pregnancy",
    "profile_image": "https://cdn.mamahealth.pro/doctors/1.jpg",
    "is_active": true,
    "is_pending": false,
    "status_badge": "ACTIVE",
    "internal_id": "MH-9021",
    "consultation_fee": 150.00,
    "hospital_affiliation": "City General Hospital",
    "languages": ["English", "Spanish"],
    "working_days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
    "working_hours": { "start": "09:00", "end": "17:00" },
    "total_patients": 240,
    "appointments_this_month": 32,
    "rating": 4.9,
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

**Error Responses**

| Code | Reason |
|---|---|
| `404` | Doctor not found |

---

### 3.3 Create Doctor

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/doctors` |
| **Auth Required** | Yes |
| **Screens** | `AddEditDoctorScreen` |

**Request Body**
```json
{
  "name": "Dr. Sarah Mitchell",
  "email": "sarah.m@mamahealth.pro",
  "phone": "+1 (555) 000-0000",
  "specialization": "Obstetrics & Gynecology",
  "qualification": "MBBS, MD - Gynaecology",
  "experience_years": 10,
  "consultation_fee": 150.00,
  "hospital_affiliation": "City General Hospital",
  "languages": ["English"],
  "working_days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "working_hours": { "start": "09:00", "end": "17:00" },
  "profile_image_url": "https://cdn.mamahealth.pro/uploads/tmp/img_abc123.jpg"
}
```

**Success Response `201`**
```json
{
  "message": "Doctor created successfully.",
  "data": { "id": 6, "name": "Dr. Sarah Mitchell", "internal_id": "MH-9022" }
}
```

**Validation Rules**
- `name`: Required, 3–100 chars
- `email`: Required, valid email, unique in system
- `phone`: Required, E.164 format
- `specialization`: Required, must be in allowed enum list
- `experience_years`: Required, integer 0–60
- `consultation_fee`: Optional, decimal ≥ 0
- `working_hours.start` < `working_hours.end`

---

### 3.4 Update Doctor

| Field | Value |
|---|---|
| **Method** | `PUT` |
| **URL** | `/doctors/{id}` |
| **Auth Required** | Yes |
| **Screens** | `AddEditDoctorScreen` (edit mode) |

**Request Body** _(same shape as Create; all fields optional for partial updates)_

**Success Response `200`**
```json
{ "message": "Doctor updated successfully.", "data": { "id": 1 } }
```

---

### 3.5 Toggle Doctor Active Status

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/doctors/{id}/status` |
| **Auth Required** | Yes |
| **Screens** | `DoctorManagementScreen` (toggle switch on each card) |

**Request Body**
```json
{ "is_active": false }
```

**Success Response `200`**
```json
{ "message": "Doctor status updated.", "data": { "id": 1, "is_active": false } }
```

---

### 3.6 Approve Pending Doctor

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/doctors/{id}/approve` |
| **Auth Required** | Yes |
| **Screens** | `DoctorManagementScreen` ("Review Application" button on pending cards) |

**Request Body**
```json
{ "approved": true, "notes": "Credentials verified." }
```

**Success Response `200`**
```json
{ "message": "Doctor approved and account activated.", "data": { "id": 4, "is_pending": false, "is_active": true } }
```

---

### 3.7 Suspend / Block Doctor

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/doctors/{id}/suspend` |
| **Auth Required** | Yes |
| **Screens** | `DoctorManagementScreen` (block icon button on each card) |

**Request Body**
```json
{ "reason": "Pending license verification." }
```

**Success Response `200`**
```json
{ "message": "Doctor suspended.", "data": { "id": 1, "is_active": false } }
```

---

### 3.8 Delete Doctor

| Field | Value |
|---|---|
| **Method** | `DELETE` |
| **URL** | `/doctors/{id}` |
| **Auth Required** | Yes |

**Success Response `200`**
```json
{ "message": "Doctor removed from the platform." }
```

**Error Responses**

| Code | Reason |
|---|---|
| `409` | Doctor has active appointments — cannot delete |

---

### 3.9 Get Doctor's Appointments

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/doctors/{id}/appointments` |
| **Auth Required** | Yes |
| **Screens** | `DoctorDetailsScreen` (secondary info grid — appointments this month) |
| **Supports** | Pagination ✅ · Filtering by status ✅ |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `status` | `string` | `upcoming\|completed\|cancelled` |
| `from` | `date` | Start date filter |
| `to` | `date` | End date filter |
| `page` | `integer` | — |
| `per_page` | `integer` | — |

---

## 4. Patients Management

### 4.1 List Patients

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/patients` |
| **Auth Required** | Yes |
| **Screens** | `PatientManagementScreen` (patient grid with search & filters) |
| **Supports** | Pagination ✅ · Filtering ✅ · Sorting ✅ · Search ✅ |

**Query Parameters**

| Param | Type | Example | Description |
|---|---|---|---|
| `page` | `integer` | `1` | Page number |
| `per_page` | `integer` | `3` | Items per page (as seen in UI) |
| `q` | `string` | `elena` | Search by name, ID, or phone |
| `trimester` | `string` | `1\|2\|3` | Filter by trimester |
| `risk_level` | `string` | `high\|normal` | Filter by risk level |
| `doctor_id` | `integer` | `5` | Filter by assigned doctor |
| `sort` | `string` | `name` | Sort field |
| `order` | `string` | `asc` | Sort direction |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": 9021,
      "name": "Elena Vance",
      "email": "elena.vance@example.com",
      "phone": "+1 (555) 012-9021",
      "age": 29,
      "profile_image": "https://cdn.mamahealth.pro/patients/9021.jpg",
      "is_active": true,
      "risk_level": "high",
      "trimester": 2,
      "week": 24,
      "doctor": { "id": 5, "name": "Dr. Sarah Chen" },
      "vitals": {
        "water_intake_percent": 85,
        "kicks_per_2hr": "12",
        "blood_pressure": "145/95",
        "is_bp_normal": false
      },
      "created_at": "2025-05-10T00:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 3,
    "total": 248,
    "last_page": 83
  }
}
```

---

### 4.2 Get Patient Details

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/patients/{id}` |
| **Auth Required** | Yes |
| **Screens** | `PatientDetailsScreen` (profile header + bento grid) |

**Path Parameters**

| Param | Type |
|---|---|
| `id` | `integer` |

**Success Response `200`**
```json
{
  "data": {
    "id": 9021,
    "name": "Elena Vance",
    "email": "elena.vance@example.com",
    "phone": "+1 (555) 012-9021",
    "age": 29,
    "blood_group": "O+",
    "profile_image": "https://cdn.mamahealth.pro/patients/9021.jpg",
    "is_active": true,
    "risk_level": "high",
    "pregnancy_stage": "2nd Trimester",
    "weeks_pregnant": 24,
    "due_date": "2026-02-15",
    "doctor": { "id": 5, "name": "Dr. Sarah Chen" },
    "vitals": {
      "water_intake_percent": 85,
      "kicks_per_2hr": "12",
      "blood_pressure": "145/95",
      "is_bp_normal": false,
      "last_recorded_at": "2025-10-24T08:00:00Z"
    },
    "emergency_contact": {
      "name": "John Vance",
      "phone": "+1 (555) 012-9999",
      "relation": "Husband"
    },
    "sos_history_count": 1,
    "created_at": "2025-05-10T00:00:00Z"
  }
}
```

---

### 4.3 Update Patient

| Field | Value |
|---|---|
| **Method** | `PUT` |
| **URL** | `/patients/{id}` |
| **Auth Required** | Yes |
| **Screens** | `PatientDetailsScreen` (edit actions) |

**Request Body**
```json
{
  "name": "Elena Vance",
  "email": "elena.vance@example.com",
  "phone": "+1 (555) 012-9021",
  "blood_group": "O+",
  "doctor_id": 5,
  "emergency_contact": {
    "name": "John Vance",
    "phone": "+1 (555) 012-9999",
    "relation": "Husband"
  }
}
```

---

### 4.4 Toggle Patient Active Status

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/patients/{id}/status` |
| **Auth Required** | Yes |

**Request Body**
```json
{ "is_active": false }
```

---

### 4.5 Get Patient Vitals History 📡

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/patients/{id}/vitals` |
| **Auth Required** | Yes |
| **Screens** | `PatientDetailsScreen` (vitals bento cards) |
| **Real-time** | Prefer **WebSocket** for live vitals monitoring |
| **Supports** | Filtering by date range ✅ |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `from` | `date` | — |
| `to` | `date` | — |
| `limit` | `integer` | Default 30 |

**Success Response `200`**
```json
{
  "data": {
    "patient_id": 9021,
    "current": {
      "water_intake_percent": 85,
      "kicks_per_2hr": "12",
      "blood_pressure": "145/95",
      "is_bp_normal": false,
      "recorded_at": "2025-10-24T08:00:00Z"
    },
    "history": [
      { "date": "2025-10-23", "blood_pressure": "140/90", "water_intake_percent": 70 },
      { "date": "2025-10-22", "blood_pressure": "138/88", "water_intake_percent": 65 }
    ]
  }
}
```

---

### 4.6 Get Patient Reports

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/patients/{id}/reports` |
| **Auth Required** | Yes |
| **Screens** | `PatientReportsScreen` |
| **Supports** | Pagination ✅ · Filtering by type ✅ |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `type` | `string` | `ultrasound\|blood_work\|genetic\|all` |
| `page` | `integer` | — |
| `per_page` | `integer` | — |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": "rpt_001",
      "patient_id": 9021,
      "type": "ultrasound",
      "title": "Week 24 Ultrasound Scan",
      "report_url": "https://cdn.mamahealth.pro/reports/rpt_001.pdf",
      "doctor": { "id": 5, "name": "Dr. Sarah Chen" },
      "notes": "Growth on track. Position normal.",
      "created_at": "2025-10-20T10:00:00Z"
    }
  ],
  "meta": { "total": 12, "page": 1, "per_page": 10 }
}
```

---

### 4.7 Assign Doctor to Patient

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/patients/{id}/assign-doctor` |
| **Auth Required** | Yes |
| **Screens** | `PatientDetailsScreen` |

**Request Body**
```json
{ "doctor_id": 3 }
```

---

## 5. Appointments

### 5.1 List Appointments

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/appointments` |
| **Auth Required** | Yes |
| **Screens** | `AppointmentManagementScreen` (tabbed list: upcoming, completed, cancelled) |
| **Supports** | Pagination ✅ · Filtering by status/date/doctor/patient ✅ · Sorting ✅ |

**Query Parameters**

| Param | Type | Example | Description |
|---|---|---|---|
| `status` | `string` | `upcoming` | `upcoming\|completed\|cancelled\|all` |
| `doctor_id` | `integer` | `1` | Filter by doctor |
| `patient_id` | `integer` | `9021` | Filter by patient |
| `date_from` | `date` | `2025-10-24` | Range start |
| `date_to` | `date` | `2025-10-31` | Range end |
| `type` | `string` | `ultrasound` | Appointment type |
| `page` | `integer` | `1` | — |
| `per_page` | `integer` | `20` | — |
| `sort` | `string` | `date` | Sort field |
| `order` | `string` | `asc` | Sort direction |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": "APT-001",
      "patient": {
        "id": 9021,
        "name": "Sarah Jenkins",
        "image": "https://cdn.mamahealth.pro/patients/9021.jpg"
      },
      "doctor": { "id": 1, "name": "Dr. Elena Rodriguez" },
      "type": "Ultrasound",
      "sub_type": "Routine Scan",
      "date": "2025-10-24",
      "time": "09:15",
      "status": "upcoming",
      "notes": null,
      "created_at": "2025-10-20T00:00:00Z"
    }
  ],
  "meta": { "total": 4, "page": 1, "per_page": 20 }
}
```

---

### 5.2 Get Appointment Details

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/appointments/{id}` |
| **Auth Required** | Yes |
| **Screens** | `AppointmentManagementScreen` (detail view on tap) |

---

### 5.3 Create Appointment

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/appointments` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Quick Actions — implied) |

**Request Body**
```json
{
  "patient_id": 9021,
  "doctor_id": 1,
  "type": "Ultrasound",
  "sub_type": "Routine Scan",
  "date": "2025-10-24",
  "time": "09:15",
  "notes": "Patient is in 2nd trimester, week 24."
}
```

**Validation Rules**
- `date`: Must be today or in the future
- `time`: Must be within doctor's working hours
- Doctor must be active and not pending

---

### 5.4 Update Appointment Status

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/appointments/{id}/status` |
| **Auth Required** | Yes |
| **Screens** | `AppointmentManagementScreen` (tab change triggers status update intent) |

**Request Body**
```json
{ "status": "completed", "notes": "Patient attended. Follow-up in 2 weeks." }
```

**Validation Rules**
- `status` enum: `upcoming`, `completed`, `cancelled`
- Cannot revert `completed` → `upcoming`

---

### 5.5 Cancel Appointment

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/appointments/{id}/cancel` |
| **Auth Required** | Yes |

**Request Body**
```json
{ "reason": "Patient unavailable." }
```

---

### 5.6 Today's Appointment Count ⭐ 🗄️

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/appointments/today/count` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Stats Bento Grid — "Appointments: Today" card) |

**Success Response `200`**
```json
{ "data": { "count": 12, "date": "2025-10-24" } }
```

> ⭐ **Reusable across:** `AdminDashboard`, `DoctorDetailsScreen`

---

## 6. SOS & Emergency Alerts

> 📡 **Real-time critical** — All SOS endpoints should be supplemented by a WebSocket channel (`ws://api.mamahealth.pro/ws/sos`) that pushes new alerts to connected admin clients immediately.

### 6.1 List Active SOS Alerts 📡

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/sos` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (SOS card count), sidebar SOS Requests item |
| **Supports** | Filtering by status ✅ · Pagination ✅ |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `status` | `string` | `active\|resolved\|all` |
| `page` | `integer` | — |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": "sos_001",
      "patient": {
        "id": 204,
        "name": "Chloe Price",
        "phone": "+1 (555) 012-0204",
        "image": "https://cdn.mamahealth.pro/patients/204.jpg"
      },
      "location": { "lat": 40.7128, "lng": -74.0060, "address": "123 Main St, New York" },
      "triggered_at": "2025-10-24T09:00:00Z",
      "status": "active",
      "resolved_at": null
    }
  ],
  "meta": { "active_count": 2, "total": 10 }
}
```

---

### 6.2 Resolve SOS Alert

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/sos/{id}/resolve` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Recent Activity "Resolve" button), SOS Requests screen |

**Request Body**
```json
{
  "resolution_notes": "Patient contacted. Emergency services dispatched.",
  "resolved_by": "adm_01"
}
```

**Success Response `200`**
```json
{ "message": "SOS alert resolved.", "data": { "id": "sos_001", "status": "resolved" } }
```

---

## 7. Notifications

### 7.1 List Admin Notifications

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/notifications` |
| **Auth Required** | Yes |
| **Screens** | Notification bell icon (all screens), Notifications screen |
| **Supports** | Pagination ✅ · Filtering by read/unread ✅ |
| **Real-time** | 📡 Supplement with SSE (`/notifications/stream`) |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `is_read` | `boolean` | Filter read/unread |
| `page` | `integer` | — |
| `per_page` | `integer` | Default 20 |

**Success Response `200`**
```json
{
  "data": [
    {
      "id": "notif_001",
      "type": "sos_alert",
      "title": "New SOS Alert",
      "body": "Patient #204 triggered an SOS alert.",
      "is_read": false,
      "created_at": "2025-10-24T09:00:00Z",
      "action_url": "/sos/sos_001"
    }
  ],
  "meta": { "unread_count": 3, "total": 25 }
}
```

---

### 7.2 Mark Notification as Read

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/notifications/{id}/read` |
| **Auth Required** | Yes |

**Success Response `200`**
```json
{ "message": "Marked as read." }
```

---

### 7.3 Mark All Notifications as Read 📦

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/notifications/read-all` |
| **Auth Required** | Yes |

---

### 7.4 Send Broadcast Message

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/notifications/broadcast` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Quick Actions — "Broadcast Message" button) |

**Request Body**
```json
{
  "title": "App Maintenance",
  "body": "The app will be down for maintenance from 2–4 AM.",
  "target_audience": "all",
  "channels": ["push", "in_app"]
}
```

**Validation Rules**
- `target_audience` enum: `all`, `patients`, `doctors`
- `channels`: at least one required

---

## 8. Analytics & Reports

### 8.1 Dashboard Analytics Overview 🗄️

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/analytics/overview` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (System Health card), sidebar analytics |
| **Cache TTL** | 5 minutes |

**Success Response `200`**
```json
{
  "data": {
    "system": {
      "response_time_ms": 180,
      "uptime_percent": 99.97,
      "active_sessions": 145
    },
    "platform": {
      "new_patients_this_week": 28,
      "new_doctors_this_month": 3,
      "appointments_completed_today": 8,
      "sos_alerts_this_week": 2
    }
  }
}
```

---

### 8.2 Export Report

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/reports/export` |
| **Auth Required** | Yes |
| **Screens** | `AdminDashboard` (Quick Actions — "Export Report" button) |

**Request Body**
```json
{
  "type": "patients",
  "format": "pdf",
  "filters": {
    "from": "2025-01-01",
    "to": "2025-10-24",
    "trimester": null,
    "risk_level": null
  }
}
```

**Success Response `202`** _(Accepted — async generation)_
```json
{
  "message": "Report generation started.",
  "data": {
    "job_id": "job_001",
    "estimated_ready_in_seconds": 15
  }
}
```

---

### 8.3 Download Generated Report

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/reports/export/{job_id}/download` |
| **Auth Required** | Yes |

**Success Response `200`**
```json
{
  "data": {
    "status": "ready",
    "download_url": "https://cdn.mamahealth.pro/exports/job_001.pdf",
    "expires_at": "2025-10-25T12:00:00Z"
  }
}
```

---

## 9. Content Management

### 9.1 List Content Items

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/content` |
| **Auth Required** | Yes |
| **Screens** | Sidebar "Content Management" item |
| **Supports** | Pagination ✅ · Filtering by type ✅ |

**Query Parameters**

| Param | Type | Description |
|---|---|---|
| `type` | `string` | `article\|video\|tip\|faq` |
| `status` | `string` | `published\|draft\|archived` |
| `page` | `integer` | — |

---

### 9.2 Create Content Item

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/content` |
| **Auth Required** | Yes |

**Request Body**
```json
{
  "title": "Nutrition Tips in Third Trimester",
  "type": "article",
  "body": "<html>...<html>",
  "status": "published",
  "target_trimester": 3,
  "thumbnail_url": "https://cdn.mamahealth.pro/uploads/tmp/img_xyz.jpg"
}
```

---

### 9.3 Update / Delete Content Item

| Field | Value |
|---|---|
| **Update Method** | `PUT /content/{id}` |
| **Delete Method** | `DELETE /content/{id}` |
| **Auth Required** | Yes |

---

## 10. File Uploads

### 10.1 Upload Profile Image (Doctor / Admin)

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/uploads/image` |
| **Auth Required** | Yes |
| **Screens** | `AddEditDoctorScreen` (photo upload section) |
| **Content-Type** | `multipart/form-data` |

**Request Body (form-data)**

| Field | Type | Description |
|---|---|---|
| `file` | `File` | Image file |
| `context` | `string` | `doctor_avatar\|patient_avatar\|admin_avatar\|content_thumbnail` |

**Validation Rules**
- `file`: Required, image (JPEG/PNG/WebP), max 5 MB
- Dimensions: min 200×200 px

**Success Response `201`**
```json
{
  "data": {
    "upload_id": "upl_abc123",
    "temp_url": "https://cdn.mamahealth.pro/uploads/tmp/img_abc123.jpg",
    "expires_at": "2025-10-24T12:00:00Z"
  }
}
```

---

### 10.2 Upload Medical Report (PDF)

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/uploads/document` |
| **Auth Required** | Yes |
| **Content-Type** | `multipart/form-data` |

**Request Body (form-data)**

| Field | Type | Description |
|---|---|---|
| `file` | `File` | PDF document |
| `patient_id` | `integer` | Associated patient |
| `type` | `string` | `ultrasound\|blood_work\|genetic\|other` |

**Validation Rules**
- `file`: Required, PDF, max 20 MB

---

## 11. Admin Profile & Settings

### 11.1 Get Admin Profile

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/admin/profile` |
| **Auth Required** | Yes |
| **Screens** | Sidebar admin card (all screens) |
| **Cache TTL** | 🗄️ 10 minutes |

**Success Response `200`**
```json
{
  "data": {
    "id": "adm_01",
    "name": "Admin User",
    "email": "admin@mamahealth.pro",
    "role": "super_admin",
    "avatar_url": "https://cdn.mamahealth.pro/avatars/adm_01.jpg",
    "subscription_plan": "Mama Health",
    "last_login_at": "2025-10-24T06:00:00Z"
  }
}
```

---

### 11.2 Update Admin Profile

| Field | Value |
|---|---|
| **Method** | `PUT` |
| **URL** | `/admin/profile` |
| **Auth Required** | Yes |
| **Screens** | Settings screen |

**Request Body**
```json
{
  "name": "Admin User",
  "avatar_url": "https://cdn.mamahealth.pro/uploads/tmp/img_new.jpg"
}
```

---

### 11.3 Change Password

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | `/admin/change-password` |
| **Auth Required** | Yes |
| **Screens** | Settings screen |

**Request Body**
```json
{
  "current_password": "OldPass123!",
  "new_password": "NewPass456!",
  "new_password_confirmation": "NewPass456!"
}
```

---

### 11.4 Get App Settings

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/settings` |
| **Auth Required** | Yes |
| **Screens** | Settings screen |

**Success Response `200`**
```json
{
  "data": {
    "notifications_enabled": true,
    "sos_alert_sound": true,
    "language": "en",
    "timezone": "America/New_York"
  }
}
```

---

### 11.5 Update App Settings

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **URL** | `/settings` |
| **Auth Required** | Yes |

---

## 12. Global Search

### 12.1 Search Across Resources

| Field | Value |
|---|---|
| **Method** | `GET` |
| **URL** | `/search` |
| **Auth Required** | Yes |
| **Screens** | `PatientManagementScreen` (global search bar), `DoctorManagementScreen` (search input in top bar) |
| **Supports** | Cross-resource search ✅ |

**Query Parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `q` | `string` | Yes | Search term (min 2 chars) |
| `type` | `string` | No | `patients\|doctors\|appointments\|all` |
| `limit` | `integer` | No | Default 10 per resource |

**Success Response `200`**
```json
{
  "data": {
    "patients": [
      { "id": 9021, "name": "Elena Vance", "trimester": 2, "risk_level": "high" }
    ],
    "doctors": [
      { "id": 1, "name": "Dr. Sana Khan", "specialization": "Gynaecologist" }
    ],
    "appointments": [
      { "id": "APT-001", "patient_name": "Sarah Jenkins", "date": "2025-10-24", "status": "upcoming" }
    ]
  },
  "query": "sarah",
  "total_results": 3
}
```

**Validation Rules**
- `q`: Required, min 2 characters, max 100 characters

---

## 13. Missing / Recommended Endpoints

The following endpoints are **not currently implemented in the UI** but are essential for a production-ready application:

| # | Endpoint | Method | Reason |
|---|---|---|---|
| 1 | `POST /auth/register-admin` | `POST` | Onboarding new admin accounts |
| 2 | `GET /doctors/{id}/patients` | `GET` | View all patients under a doctor |
| 3 | `GET /patients/{id}/appointments` | `GET` | Patient's appointment history |
| 4 | `GET /patients/{id}/sos-history` | `GET` | Patient SOS events log |
| 5 | `POST /patients` | `POST` | Admin registration of a new patient |
| 6 | `GET /sos/{id}` | `GET` | SOS detail view |
| 7 | `GET /audit-logs` | `GET` | Admin action audit trail |
| 8 | `GET /appointments/calendar` | `GET` | Calendar view for scheduling |
| 9 | `POST /appointments/{id}/reschedule` | `POST` | Reschedule an existing appointment |
| 10 | `GET /doctors/specializations` | `GET` | Enum list for form dropdown |
| 11 | `GET /patients/risk-summary` | `GET` | Aggregated risk level breakdown |
| 12 | `POST /content/{id}/publish` | `POST` | Publish a draft article |
| 13 | `DELETE /notifications/{id}` | `DELETE` | Remove individual notification |
| 14 | `GET /reports/templates` | `GET` | Available export report types |
| 15 | `GET /admin/admins` | `GET` | List all admin accounts (super-admin only) |

---

## 14. Real-time Communication Map

| Feature | Recommended Protocol | Endpoint / Channel |
|---|---|---|
| **Active SOS Alerts** | WebSocket | `wss://api.mamahealth.pro/ws/sos` |
| **Live Patient Vitals** | WebSocket | `wss://api.mamahealth.pro/ws/vitals/{patient_id}` |
| **Recent Activity Feed** | Server-Sent Events | `GET /dashboard/activity/stream` |
| **Notification Push** | SSE or WebSocket | `GET /notifications/stream` |
| **Appointment Status Changes** | SSE | `GET /appointments/stream` |

> **Why not REST polling?**  
> SOS alerts are life-critical and require sub-second latency. WebSocket ensures the admin receives the alert the instant it is triggered by the patient app, regardless of the polling interval.

---

## 15. Caching Strategy Summary

| Endpoint | Cache Duration | Invalidated By |
|---|---|---|
| `GET /dashboard/summary` | 60 seconds | Any patient/doctor/appointment mutation |
| `GET /dashboard/patient-growth` | 5 minutes | New patient registration |
| `GET /dashboard/trimester-distribution` | 5 minutes | Patient pregnancy stage update |
| `GET /analytics/overview` | 5 minutes | System metrics update |
| `GET /admin/profile` | 10 minutes | `PUT /admin/profile` |
| `GET /doctors` | 30 seconds | Doctor create/update/delete |
| `GET /doctors/{id}` | 2 minutes | `PUT /doctors/{id}` or status change |
| `GET /patients` | 30 seconds | Patient create/update/delete |
| `GET /patients/{id}` | 2 minutes | Patient or vitals update |
| `GET /settings` | 10 minutes | `PATCH /settings` |

---

## Appendix — Standard Error Format

All error responses follow this consistent format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The given data was invalid.",
    "details": {
      "email": ["The email field is required."],
      "phone": ["Phone must be in E.164 format."]
    }
  }
}
```

**Common HTTP Status Codes**

| Code | Meaning |
|---|---|
| `200` | OK |
| `201` | Created |
| `202` | Accepted (async job started) |
| `204` | No Content |
| `400` | Bad Request |
| `401` | Unauthenticated |
| `403` | Forbidden (insufficient role) |
| `404` | Resource Not Found |
| `409` | Conflict (e.g., duplicate email) |
| `422` | Validation Error |
| `429` | Rate Limit Exceeded |
| `500` | Internal Server Error |

---

## Appendix — Authentication Headers (all protected endpoints)

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json
Content-Type: application/json
X-App-Version: 1.0.0
X-Platform: mobile
```

---

*Document generated from analysis of all Flutter screens, navigation flows, models, and UI components in the Mama Health admin application.*  
*Last updated: 2026-08-01*
