# UniFlow — Flutter Frontend to Express/MongoDB Backend Integration Specification

> **Document Status:** Authoritative API Contract & Architecture Integration Reference  
> **Target Version:** UniFlow Backend API v1.0.0 (Node.js/Express/MongoDB)  
> **Frontend Target:** UniFlow Flutter Client (iOS, Android, Web, Desktop)  
> **Audit Date:** October 2026  
> **Rule Compliance:** Strictly conforms to `AGENTS.md` and `docs/API_CONTRACT.md`.

---

## Table of Contents

1. [Executive Summary & Architectural Scope](#1-executive-summary--architectural-scope)
2. [Existing Backend API Endpoint Inventory](#2-existing-backend-api-endpoint-inventory)
3. [Authentication, Token Handling & Authorization](#3-authentication-token-handling--authorization)
4. [Request Lifecycle & Workflow State Machine](#4-request-lifecycle--workflow-state-machine)
5. [Standard Envelopes & Error Response Format](#5-standard-envelopes--error-response-format)
6. [Flutter-to-Backend Domain Model & Field Mapping](#6-flutter-to-backend-domain-model--field-mapping)
7. [Screen-by-Screen Integration Requirements](#7-screen-by-screen-integration-requirements)
   - 7.1 [Authentication & Profile](#71-authentication--profile)
   - 7.2 [Student Catalogue & Submission](#72-student-catalogue--submission)
   - 7.3 [Student Request History & Real-Time Tracking](#73-student-request-history--real-time-tracking)
   - 7.4 [Staff Review Queue & Step Actioning](#74-staff-review-queue--step-actioning)
   - 7.5 [Administrator Dashboard & Analytics](#75-administrator-dashboard--analytics)
8. [Gap Analysis & Missing Backend Functionality](#8-gap-analysis--missing-backend-functionality)
9. [CORS, Networking & Environment Configuration](#9-cors-networking--environment-configuration)
10. [Recommended Phased Implementation Order](#10-recommended-phased-implementation-order)

---

## 1. Executive Summary & Architectural Scope

The UniFlow application system connects students, academic staff, and administrators through a streamlined, multi-step campus workflow engine. The frontend presentation layer has two clients:
1. **React Web Portal** (`frontend/react_app`) — Desktop-centric single-page app.
2. **Flutter Multiplatform Client** (`lib/`) — Native mobile (Android/iOS) and responsive web/desktop application.

Both client applications communicate with a **single Node.js / Express backend** (`backend/node_api`) supported by **MongoDB** via Mongoose.

```
┌─────────────────────────────────┐      ┌─────────────────────────────────┐
│     UniFlow Flutter Client      │      │       UniFlow React App         │
│  (Android / iOS / Web / Win)   │      │         (Vite Web SPA)          │
└────────────────┬────────────────┘      └────────────────┬────────────────┘
                 │                                        │
                 │ JSON / REST API (Bearer JWT)           │
                 ▼                                        ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                   UniFlow Express API Server (:3001)                     │
│  - Authentication & Zod Validators                                       │
│  - Role Middleware (Student, Staff, Admin)                               │
│  - Workflow State Machine Service (`request.service.js`)                 │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
                                     ▼ Mongoose ODM
┌──────────────────────────────────────────────────────────────────────────┐
│                          MongoDB Database                                │
│  Collections: users, institutions, departments, services,                │
│               workflows, requests, notifications                         │
└──────────────────────────────────────────────────────────────────────────┘
```

### Critical Architectural Invariants (`AGENTS.md`)
- **Single API Contract**: The backend exposes one contract (`/api/*`). Flutter must consume the identical endpoints used by React.
- **Backend Owns State**: All workflow validation, permissions, and status transitions reside on the backend.
- **No Self-Approval (Rule 5)**: When a request is actioned, the backend enforces `req.user.id !== request.studentId`.
- **Stateless Authentication**: Pure Bearer JWT tokens in the `Authorization` header. No session cookies.

---

## 2. Existing Backend API Endpoint Inventory

Every endpoint below is verified to exist in `backend/node_api/src/routes/` and is covered by automated backend tests in `tests/workflow.test.js`.

### 2.1 Health Check
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | Public | Returns service liveness, version, and environment. |

### 2.2 Authentication & Identity
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Public | Registers a new student account. Returns JWT and sanitized user. |
| `POST` | `/api/auth/login` | Public | Authenticates credentials. Returns JWT and sanitized user. |
| `GET` | `/api/auth/me` | Authenticated | Fetches profile of the authenticated user. |

### 2.3 Departments
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/departments` | Public / Auth | Lists active departments (`id`, `name`, `code`, `institution`). |

### 2.4 Service Catalogue
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/services` | Authenticated | Lists all active campus services with categories and estimated days. |
| `GET` | `/api/services/:id` | Authenticated | Details of a service by ObjectId or slug, including form fields and steps. |
| `POST` | `/api/services` | Role: `admin` | Creates a new service offering and associated workflow steps. |

### 2.5 Workflow Requests & Step Actions
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/requests` | Role: `student` | Submits a new workflow request. Generates `requestNumber` and runtime steps. |
| `GET` | `/api/requests` | Authenticated | Lists requests. Students receive only their own; staff/admin receive paginated list. |
| `GET` | `/api/requests/:id` | Authenticated | Returns full request details including `runtimeSteps`, student profile, and audit log. |
| `PATCH` | `/api/requests/:id/steps/:stepIndex/approve` | Role: `staff`, `admin` | Approves active step, advancing workflow or marking it `COMPLETED`. |
| `PATCH` | `/api/requests/:id/steps/:stepIndex/reject` | Role: `staff`, `admin` | Rejects active step with mandatory comment, marking status `REJECTED`. |
| `PATCH` | `/api/requests/:id/payment` | Role: `student` | Confirms simulated replacement fee payment when status is `PAYMENT_REQUIRED`. |

### 2.6 Staff Review Queue
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/staff/queue` | Role: `staff`, `admin` | Retrieves queue of requests awaiting staff action with calculated `waitingHours`. |
| `PATCH` | `/api/staff/requests/:id/steps/:stepIndex/approve` | Role: `staff`, `admin` | Alias for step approval from staff queue route. |
| `PATCH` | `/api/staff/requests/:id/steps/:stepIndex/reject` | Role: `staff`, `admin` | Alias for step rejection from staff queue route. |

### 2.7 Administrator Oversight
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/admin/stats` | Role: `admin` | Aggregates campus totals, pending counts, and breakdowns by service. |
| `GET` | `/api/admin/requests` | Role: `admin` | Lists all institutional requests with status and service filters. |

### 2.8 Notifications
| Method | Endpoint | Access | Summary |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/notifications` | Authenticated | Lists in-app notifications for the active user (`?unread=true` filterable). |
| `PATCH` | `/api/notifications/:id/read` | Authenticated | Marks a single notification as read. |
| `PATCH` | `/api/notifications/read-all` | Authenticated | Marks all notifications for user as read. |

---

## 3. Authentication, Token Handling & Authorization

### 3.1 JWT Mechanism
- **Algorithm**: HMAC-SHA256 (`HS256`).
- **Secret**: Loaded via `JWT_SECRET` environment variable (minimum 32 characters).
- **Expiration**: Loaded via `JWT_EXPIRES_IN` (configured default: `7d`).
- **Token Delivery**: Client must include the token in the HTTP `Authorization` header:
  ```http
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  ```

### 3.2 Token Payload Shape
```json
{
  "userId": "64a1b2c3d4e5f6a7b8c9d001",
  "role": "student",
  "email": "student@uniflow.edu",
  "iat": 1729000000,
  "exp": 1729604800
}
```

### 3.3 Default Demo Credentials (Seed Data)
For testing and development with local MongoDB instance (`npm run seed`):
- **Student**: `student@uniflow.edu` / `Demo@1234` (Arjun Sharma, Roll: `CS2021001`)
- **Staff**: `staff@uniflow.edu` / `Demo@1234` (Priya Nair, Computer Science Dept)
- **Admin**: `admin@uniflow.edu` / `Demo@1234` (Dr. Ramesh Kumar, Administration Dept)

### 3.4 Authorization Policies
1. **Public Self-Registration**: Only `role: "student"` is allowed via `POST /api/auth/register`. Supplying `role: "staff"` or `role: "admin"` returns HTTP 400 `VALIDATION_ERROR` to prevent privilege escalation.
2. **Role Middleware**: `requireRole(...)` verifies `req.user.role`. Non-permitted roles receive HTTP 403 `FORBIDDEN`.
3. **Student Request Privacy**: When `req.user.role === 'student'`, `GET /api/requests/:id` checks `request.student._id.toString() === req.user.id`. Violations return HTTP 403 `FORBIDDEN`.
4. **Anti-Self-Approval**: In `actionStep(...)`, the backend verifies:
   ```javascript
   if (request.student.toString() === actorUser.id) {
     throw AppError.forbidden('A student cannot approve or action their own request.');
   }
   ```

---

## 4. Request Lifecycle & Workflow State Machine

### 4.1 Permitted Transitions & Status Values

```
                                  [ POST /api/requests ]
                                             │
                                             ▼
                                  ┌────────────────────┐
                          ┌───────┤     SUBMITTED      ├───────┐
                          │       └──────────┬─────────┘       │
        (Bonafide)        │                  │ (ID Card)       │ (Equipment)
                          ▼                  ▼                 ▼
             ┌────────────────────────┐ ┌────────────────────────┐ ┌────────────────────────┐
             │ DEPARTMENT_VERIFICATION│ │    SECURITY_REVIEW     │ │     STAFF_REVIEW       │
             │        PENDING         │ │        PENDING         │ │        PENDING         │
             └───────────┬────────────┘ └───────────┬────────────┘ └───────────┬────────────┘
                         │ Staff Approve            │ Security Approve         │ Staff Approve
                         ▼                          ▼                          ▼
             ┌────────────────────────┐ ┌────────────────────────┐ ┌────────────────────────┐
             │     ADMIN_APPROVAL     │ │    PAYMENT_REQUIRED    │ │   BOOKING_CONFIRMED    │
             │        PENDING         │ └───────────┬────────────┘ │       (Terminal)       │
             └───────────┬────────────┘             │ Student Pay  └────────────────────────┘
                         │ Admin Approve            ▼
                         │              ┌────────────────────────┐
                         │              │     ADMIN_APPROVAL     │
                         │              │        PENDING         │
                         │              └───────────┬────────────┘
                         │                          │ Admin Approve
                         ▼                          ▼
             ┌───────────────────────────────────────────────────┐
             │                     COMPLETED                     │
             │                    (Terminal)                     │
             └───────────────────────────────────────────────────┘

         * Rejection at ANY step by Staff/Admin (with mandatory comment) ──► [ REJECTED (Terminal) ]
```

### 4.2 Status Code Matrix

| Backend `status` String | Meaning | Next Valid Action | Permitted Actor |
| :--- | :--- | :--- | :--- |
| `SUBMITTED` | Initial creation state | Automated router transition | System |
| `DEPARTMENT_VERIFICATION_PENDING` | Enrolment verification | Approve or Reject | `staff` (Assigned Dept) |
| `SECURITY_REVIEW_PENDING` | Security identity check | Approve or Reject | `staff` (Security Dept) |
| `PAYMENT_REQUIRED` | Fee payment clearance | Confirm Payment | `student` (Owner only) |
| `ADMIN_APPROVAL_PENDING` | Final institutional authorization | Approve or Reject | `admin` |
| `STAFF_REVIEW_PENDING` | Equipment custodian review | Approve or Reject | `staff` (Facilities Dept) |
| `COMPLETED` | Service fulfilled (Terminal) | None | Terminal |
| `BOOKING_CONFIRMED` | Equipment reserved (Terminal) | None | Terminal |
| `REJECTED` | Request turned down (Terminal) | None | Terminal |

---

## 5. Standard Envelopes & Error Response Format

The backend enforces strict envelope consistency across all responses.

### 5.1 Success Envelope (Single Item or Action)
```json
{
  "success": true,
  "data": {
    "id": "6722a4b8c9d0e1f2a3b4c5d6",
    "requestNumber": "UF-20261030-XYZ123",
    "status": "DEPARTMENT_VERIFICATION_PENDING"
  }
}
```

### 5.2 Success Envelope (Paginated List)
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "pages": 3
  }
}
```

### 5.3 Error Envelope
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data validation failed.",
    "details": [
      {
        "field": "comment",
        "message": "Comment is required when rejecting a step."
      }
    ]
  }
}
```

### 5.4 Error Code Glossary
- `VALIDATION_ERROR` (HTTP 400): Request body failed schema validation. Includes `details` array.
- `INVALID_TRANSITION` (HTTP 400): Workflow state transition rejected (e.g. attempting to action a completed request).
- `MISSING_TOKEN` (HTTP 401): No `Authorization: Bearer <token>` header supplied.
- `INVALID_TOKEN` (HTTP 401): JWT expired, malformed, or signature mismatch.
- `FORBIDDEN` (HTTP 403): User role unauthorized, account deactivated, or student attempting self-approval.
- `NOT_FOUND` (HTTP 404): Requested entity does not exist in the database.
- `CONFLICT` (HTTP 409): Duplicate email or resource key conflict.
- `INTERNAL_ERROR` (HTTP 500/503): Server error or unseeded institution.

---

## 6. Flutter-to-Backend Domain Model & Field Mapping

The table below defines how the Flutter client data types map to the MongoDB/Mongoose schemas.

### 6.1 User / Profile Mapping

| Flutter `UserProfile` Field | Backend Mongoose `User` Field | Translation Notes |
| :--- | :--- | :--- |
| `id` (`String`) | `_id` (`ObjectId`) | MongoDB 24-character hexadecimal ID string. |
| `name` (`String`) | `name` (`String`) | Exact match. |
| `email` (`String`) | `email` (`String`) | Exact match (stored lowercase). |
| `role` (`UserRole` enum) | `role` (`String` enum) | Flutter: `student`, `staff`, `admin`. Backend: `'student'`, `'staff'`, `'admin'`. |
| `department` (`String`) | `department` (`ObjectId` populated) | Backend returns populated object `{ _id, name, code }`. Flutter maps `department.name`. |
| `identifier` (`String`) | `studentId` (`String`) | Roll number for students (e.g., `CS2021001`). Staff employee IDs currently optional in seed. |

### 6.2 Service Mapping

| Flutter `CampusServiceItem` Field | Backend Mongoose `Service` Field | Translation Notes |
| :--- | :--- | :--- |
| `type` (`ServiceType` enum) | `slug` (`String`) | `bonafide` ↔ `'bonafide-certificate'`<br>`idCard` ↔ `'id-card-replacement'`<br>`equipment` ↔ `'equipment-booking'` |
| `title` (`String`) | `name` (`String`) | Display name of service. |
| `category` (`String`) | `category` (`String`) | Backend enum: `'Academic'`, `'Identity'`, `'Resources'`, `'Finance'`, `'Other'`. |
| `description` (`String`) | `description` (`String`) | Detailed overview text. |
| `sla` (`String`) | `estimatedDays` (`Number`) | Backend provides numeric days; Flutter renders `'3-5 Days'`. |
| N/A | `_id` (`ObjectId`) | **Crucial**: Flutter must retain `_id` to submit `POST /api/requests` with `{ serviceId }`. |
| N/A | `formFields` (`Array`) | Dynamic form field definitions returned from backend `GET /api/services/:id`. |

### 6.3 Journey / Request Mapping

| Flutter `JourneyRequest` Field | Backend Mongoose `Request` Field | Translation Notes |
| :--- | :--- | :--- |
| `id` (`String`) | `requestNumber` (`String`) | E.g. `UF-20261030-ABC123`. Shown in UI titles and badges. |
| `backendId` (NEW) | `_id` (`ObjectId`) | **Required for API calls**: Step actions and payment endpoints require `_id`. |
| `status` (`JourneyStatus` enum) | `status` (`String`) | See Status Mapping Table below. |
| `submittedAt` (`DateTime`) | `createdAt` (`ISODate`) | Converted via `DateTime.parse()`. |
| `updatedAt` (`DateTime`) | `updatedAt` (`ISODate`) | Converted via `DateTime.parse()`. |
| `formData` (`Map<String, String>`) | `formData` (`Object` / Mixed) | Dynamic form inputs key-value dictionary. |
| `timeline` (`List<TimelineStep>`) | `runtimeSteps` + `auditLog` | Synthesized from `runtimeSteps` and `auditLog` arrays. |
| `feeAmount` (`double`) | Derived / Configured | For ID Card Replacement, ₹200 fee is configured on payment step. |
| `rejectionReason` (`String?`) | Derived from `auditLog` | Extracted from last audit entry where `action == 'REJECTED'`. |

### 6.4 Status Enum Conversion Table

| Flutter `JourneyStatus` | Backend Mongoose `status` | Notes |
| :--- | :--- | :--- |
| `JourneyStatus.submitted` | `SUBMITTED` | Initial state. |
| `JourneyStatus.departmentReview` | `DEPARTMENT_VERIFICATION_PENDING` | Staff enrolment check. |
| `JourneyStatus.securityReview` | `SECURITY_REVIEW_PENDING` | Security ID card check. |
| `JourneyStatus.paymentRequired` | `PAYMENT_REQUIRED` | Student fee payment step. |
| `JourneyStatus.adminApproval` | `ADMIN_APPROVAL_PENDING` | Admin final sign-off. |
| `JourneyStatus.approved` | `COMPLETED` or `BOOKING_CONFIRMED` | Successful terminal state. |
| `JourneyStatus.rejected` | `REJECTED` | Unsuccessful terminal state. |

---

## 7. Screen-by-Screen Integration Requirements

### 7.1 Authentication & Profile
- **View**: `LoginView` & `ProfileView`
- **Endpoints**:
  - `POST /api/auth/login` (Body: `{ email, password }`)
  - `GET /api/auth/me` (Header: `Authorization: Bearer <token>`)
- **Integration Flow**:
  1. On login button tap, Flutter sends credentials to `POST /api/auth/login`.
  2. Parse `response.data.token` and store securely in Flutter client secure storage (or shared preferences during development).
  3. Parse `response.data.user` into `UserProfile` and update `AppState.currentUser` and `AppState.currentRole`.
  4. Direct user to `AppShell`.

### 7.2 Student Catalogue & Submission
- **Views**: `ServicesCatalogueView` & `RequestFormView`
- **Endpoints**:
  - `GET /api/services`
  - `GET /api/services/:id`
  - `POST /api/requests`
- **Submission Payload Specification**:
  ```json
  POST /api/requests
  Authorization: Bearer <student_token>
  Content-Type: application/json

  {
    "serviceId": "6722a4b8c9d0e1f2a3b4c5d6",
    "formData": {
      "purpose": "Scholarship",
      "copies": 2,
      "additionalDetails": "Need by Friday for embassy filing"
    }
  }
  ```
- **Integration Flow**:
  1. `ServicesCatalogueView` fetches services from `GET /api/services`.
  2. Clicking "Start Request" passes service `_id` and field schema to `RequestFormView`.
  3. On submit, validated form fields are posted to `POST /api/requests`.
  4. Created request is returned with HTTP 201; Flutter appends it to student request state and navigates to `RequestDetailView`.

### 7.3 Student Request History & Real-Time Tracking
- **Views**: `StudentDashboardView`, `MyRequestsView`, `RequestDetailView`
- **Endpoints**:
  - `GET /api/requests` (Returns student's own requests)
  - `GET /api/requests/:id` (Returns full details with populated steps and audit log)
  - `PATCH /api/requests/:id/payment` (Confirm payment)
- **Simulated Payment Action**:
  ```http
  PATCH /api/requests/6722a4b8c9d0e1f2a3b4c5d6/payment
  Authorization: Bearer <student_token>
  ```
  Transitions request from `PAYMENT_REQUIRED` to `ADMIN_APPROVAL_PENDING`.

### 7.4 Staff Review Queue & Step Actioning
- **Views**: `StaffQueueView` & `ReviewDecisionDialog`
- **Endpoints**:
  - `GET /api/staff/queue`
  - `PATCH /api/staff/requests/:id/steps/:stepIndex/approve`
  - `PATCH /api/staff/requests/:id/steps/:stepIndex/reject`
- **Step Approval Action**:
  ```json
  PATCH /api/staff/requests/6722a4b8c9d0e1f2a3b4c5d6/steps/0/approve
  Authorization: Bearer <staff_token>
  Content-Type: application/json

  {
    "comment": "Enrolment verified and in good standing."
  }
  ```
- **Step Rejection Action**:
  ```json
  PATCH /api/staff/requests/6722a4b8c9d0e1f2a3b4c5d6/steps/0/reject
  Authorization: Bearer <staff_token>
  Content-Type: application/json

  {
    "comment": "Student has overdue fee block with Finance office."
  }
  ```
  *Note: `comment` is mandatory for rejections; empty string triggers HTTP 400 `VALIDATION_ERROR`.*

### 7.5 Administrator Dashboard & Analytics
- **Views**: `AdminDashboardView` & `AdminAnalyticsView`
- **Endpoints**:
  - `GET /api/admin/stats`
  - `GET /api/admin/requests`
- **Admin Stats Response Structure**:
  ```json
  {
    "success": true,
    "data": {
      "requests": {
        "total": 142,
        "pending": 23,
        "completed": 105,
        "rejected": 14
      },
      "bookings": {
        "total": 38,
        "pending": 5,
        "confirmed": 30,
        "rejected": 3
      },
      "byService": [
        { "serviceName": "Bonafide Certificate", "total": 87, "pending": 12 },
        { "serviceName": "ID Card Replacement", "total": 31, "pending": 8 },
        { "serviceName": "Equipment Booking", "total": 24, "pending": 3 }
      ]
    }
  }
  ```

---

## 8. Gap Analysis & Missing Backend Functionality

The audit revealed the following discrepancies between current frontend UI features and existing backend capabilities:

### 8.1 Existing Backend vs. Flutter Gaps

| Capability | Existing Backend State | Flutter Client UI State | Resolution Recommendation |
| :--- | :--- | :--- | :--- |
| **Department SLA Metrics** | Not implemented. Backend does not calculate per-department turnaround times. | `AdminAnalyticsView` displays hardcoded department SLA badges (e.g., `98.5% On-Time`). | In Phase 1 integration, calculate SLA adherence in client or add aggregated SLA endpoint in Phase 2. |
| **Numeric Fee in Request Model** | Backend tracks `isPaymentStep: true` on workflow steps, but has no explicit `feeAmount: Number` on the `Request` schema. | Flutter displays `₹200` fee explicitly in payment callout card. | Client can supply/display ₹200 fee based on service type (`id-card-replacement`). Backend does not validate monetary values because payment is simulated. |
| **Public Staff / Admin Registration** | Public registration (`POST /api/auth/register`) intentionally rejects non-student roles to prevent escalation. | Flutter `LoginView` currently has quick switch demo buttons for Student, Staff, Admin. | Maintain demo logins using seeded credentials (`student@uniflow.edu`, `staff@uniflow.edu`, `admin@uniflow.edu`). |
| **Notifications Push / Polling** | Backend provides polling endpoints (`GET /api/notifications`). | Flutter has no active background polling loop. | Implement periodic timer or pull-to-refresh on notifications screen. |
| **Dedicated `/api/equipment` Endpoints** | Planned in `API_CONTRACT.md` but not built. Equipment bookings run via generic `/api/requests`. | Flutter models equipment booking as a `ServiceType` submitted through `/api/requests`. | **No backend change needed**: The Flutter implementation already aligns with the generic workflow architecture! |

---

## 9. CORS, Networking & Environment Configuration

### 9.1 Backend CORS Setup (`backend/node_api/src/app.js`)
Currently, the backend enforces:
```javascript
app.use(
  cors({
    origin: env.FRONTEND_URL, // defaults to http://localhost:5173 (React Vite)
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);
```

> [!IMPORTANT]
> **Flutter Client Network Access Requirements**:
> - **Flutter Web**: Running on `http://localhost:<random_port>` or `http://localhost:8080` will be blocked by CORS unless `FRONTEND_URL` in `.env` is adjusted, or CORS is expanded in development.
> - **Android Emulator**: Cannot reach `localhost` directly; must use host loopback `http://10.0.2.2:3001/api`.
> - **Physical Device / Desktop**: Requires the host machine's LAN IP (e.g. `http://192.168.1.x:3001/api`) or `http://localhost:3001/api` for Windows desktop app.

### 9.2 Recommended Backend CORS Update (Preparation Only — Do not edit yet)
When preparing backend integration, `app.js` CORS should support an array of allowed origins in development or allow dynamic reflection for local loopback interfaces (`localhost`, `10.0.2.2`, `127.0.0.1`).

---

## 10. Implementation Progress & Phase Deliverables

### Phase 1: Flutter Backend Authentication Integration [COMPLETED]

The foundational client networking, secure session persistence, role mapping, and backend authentication integration are fully implemented:

1. **Centralized Networking Layer (`lib/core/api/`)**:
   - `ApiConfig`: Platform-aware base URL resolution (`http://10.0.2.2:3001/api` for Android emulator, `http://localhost:3001/api` for Web & Desktop), configurable via `--dart-define=API_BASE_URL=...` and runtime overrides.
   - `ApiEndpoints`: Authoritative endpoint paths conforming to `API_CONTRACT.md`.
   - `ApiException`, `NetworkException`, `ApiTimeoutException`: Standardized exception envelopes extracting backend error codes (`INVALID_TOKEN`, `VALIDATION_ERROR`, `FORBIDDEN`, etc.).
   - `ApiResponse`: Standard `{ success, data, error, pagination }` response envelope parser.
   - `ApiClient`: Reusable HTTP client injecting `Authorization: Bearer <token>`, handling JSON encoding/decoding, and managing connection timeouts.

2. **Secure Token Storage & Persistence (`lib/core/auth/token_storage.dart`)**:
   - `TokenStorage`: Abstract storage interface.
   - `SecureTokenStorage`: Concrete implementation using `FlutterSecureStorage` with `encryptedSharedPreferences` on Android and web secure storage on Web, plus fallback handling for desktop/test runners.
   - `InMemoryTokenStorage`: In-memory storage adapter for unit test isolation.

3. **Authentication Service & Role Mapping (`lib/core/auth/auth_service.dart`, `lib/models/role.dart`)**:
   - `AuthService`: Direct consumer of `POST /api/auth/login` and `GET /api/auth/me`.
   - `UserProfile.fromJson`: Maps real backend user documents into typed `UserProfile` and `UserRole` (`student`, `staff`, `admin`).
   - Server-authoritative role resolution (client cannot escalate privileges).

4. **Session State Architecture (`lib/core/state/app_state.dart`, `lib/main.dart`)**:
   - Seamless startup session restoration (`appState.initializeSession()`).
   - Automatic routing: unauthenticated users navigate to `LoginView`; authenticated users land on their role dashboard via `AppShell`.
   - Logout clears JWT storage and returns safely to `LoginView`.
   - `LoginView`: Input validation, inline field errors, server error banner, submission debounce, and quick-fill demo buttons (`student@uniflow.edu`, `staff@uniflow.edu`, `admin@uniflow.edu`).

5. **Backend CORS Support (`backend/node_api/src/app.js`, `env.js`)**:
   - Explicit allowlist supporting React development (`http://localhost:5173`, `http://127.0.0.1:5173`) and Flutter Web development (`http://localhost:7357`, `http://127.0.0.1:7357`, and `FLUTTER_WEB_URL`).
   - Non-browser native mobile requests pass through without CORS restrictions.

6. **Phase 1 Automated Verification**:
   - Flutter tests: 28/28 tests passing (`test/auth_integration_test.dart`, `test/widget_test.dart`, `test/responsiveness_test.dart`).
   - Backend tests: 84/84 tests passing (`tests/*.test.js`).
   - React frontend tests: 27/27 tests passing (`frontend/react_app/src/test/*.jsx`).

### 10.2 Phase 2 Implemented: Student Services Catalogue & Request Submission

1. **Domain Model Extensions (`lib/models/service_item.dart`, `lib/models/journey_request.dart`)**:
   - `CampusServiceItem`: Extended with `id`, `slug`, `estimatedDays`, `requiredDocuments`, `responsibleDepartment`, and `workflowStepCount`.
   - `ServiceType.fromSlug(String? slug)`: Bidirectional slug-to-enum mapper supporting `bonafide-certificate`, `id-card-replacement`, `equipment-booking`.
   - `CampusServiceItem.fromJson(Map<String, dynamic> json)`: Authoritative deserializer for backend `GET /api/services` responses.
   - `JourneyStatus.fromBackendString(String? status)`: State machine mapper converting backend runtime status strings (e.g., `DEPARTMENT_VERIFICATION_PENDING`, `SECURITY_REVIEW_PENDING`, `STAFF_REVIEW_PENDING`, `PAYMENT_REQUIRED`, `COMPLETED`, `REJECTED`) into typed enum values.
   - `JourneyRequest.fromJson(Map<String, dynamic> json)`: Comprehensive deserializer for backend request models including runtime steps, student attributes, and audit timestamps.

2. **Student Workflow Service (`lib/core/services/student_workflow_service.dart`)**:
   - `StudentWorkflowService`: Communicates with backend using shared `ApiClient` and authenticated JWT Bearer headers.
   - `fetchServices({String? category})`: Fetches service catalogue from `GET /api/services` with optional category query filtering.
   - `submitRequest({required String serviceId, required Map<String, dynamic> formData})`: Posts new student requests to `POST /api/requests` with `{ serviceId, formData }` payload, returning a typed `SubmissionResult`.

3. **Application State Integration (`lib/core/state/app_state.dart`)**:
   - `loadServices({bool forceRefresh = false})`: Caches catalogue in memory to eliminate redundant network roundtrips; exposes `isLoadingServices`, `hasLoadedServices`, and `servicesError`.
   - `submitStudentRequest({required String serviceId, required Map<String, dynamic> formData})`: Submits request to backend, records `lastSubmissionResult`, and immediately prepends the parsed `JourneyRequest` to the client's request list for real-time dashboard reflection.
   - `logout()`: Clears cached services and submission state upon user sign-out.

4. **Service Catalogue Presentation (`lib/views/student/services_catalogue_view.dart`)**:
   - Loads services dynamically on initialization with M3 loading spinner.
   - Displays friendly empty state when no services match or are available.
   - Displays clear error banner with "Retry Connection" button on network/server failures.
   - Preserves search filtering and dynamic category chips based on backend service categories.

5. **Request Forms & Submission UX (`lib/views/student/request_form_view.dart`)**:
   - Integrates the three campus request forms:
     - **Bonafide Certificate**: `purpose`, `copies` (integer >= 1), `academicSemester`, `urgentProcessing`, `additionalDetails`.
     - **ID Card Replacement**: Maps user reason to backend enum (`Lost`, `Damaged`, `Stolen`), enforces required police complaint reference when stolen, validates contact phone, and captures pickup location.
     - **Equipment Booking**: Maps equipment category, purpose, designated timeslot, supervisor, and calculates ISO-8601 `startTime` and `endTime`.
   - Submission state management: debounce protection, disabled button, and loading spinner during submission.
   - Surfaces backend validation error messages in an inline error banner and toast snackbar.
   - Displays `_SuccessConfirmationDialog` presenting the generated tracking number (e.g., `UF-20261031-XYZ`), initial status, service title, and guidance for next steps.

6. **Automated Verification**:
   - Flutter tests: 39/39 tests passing (`test/student_services_test.dart`, `test/auth_integration_test.dart`, `test/widget_test.dart`, `test/responsiveness_test.dart`).
   - Backend tests: 84/84 tests passing (`tests/*.test.js`).
   - React frontend tests: 27/27 tests passing (`frontend/react_app/src/test/*.jsx`).
   - React production build: Zero errors (`vite build` in 15.29s).
   - Flutter analyzer: Zero issues (`flutter analyze --no-pub`).

---

## 11. Recommended Phased Implementation Order

To ensure zero regressions to the existing React web application and preserve all 84 passing backend tests, the integration must proceed in 5 sequential stages:

```
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 1: Network & Client Foundation (Flutter)                         │
│  - Add `http` package to pubspec.yaml                                   │
│  - Create `ApiClient` with baseUrl configuration & JWT interceptor     │
│  - Implement `AuthService` with secure token persistence               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 2: Authentication & Profile Integration                          │
│  - Wire `LoginView` to `POST /api/auth/login`                          │
│  - Replace hardcoded `UserProfile` with live `GET /api/auth/me`        │
│  - Connect `AppShell` sign-out and profile display                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 3: Student Journey Integration                                   │
│  - Fetch catalogue from `GET /api/services`                            │
│  - Submit requests to `POST /api/requests`                             │
│  - Fetch student list from `GET /api/requests`                         │
│  - Fetch live stepper timeline from `GET /api/requests/:id`            │
│  - Wire simulated fee payment to `PATCH /api/requests/:id/payment`     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 4: Staff Review Queue & Actioning                                │
│  - Connect `StaffQueueView` to `GET /api/staff/queue`                  │
│  - Wire approval to `PATCH /api/requests/:id/steps/:index/approve`     │
│  - Wire rejection with mandatory note to `.../steps/:index/reject`     │
│  - Verify real-time queue eviction and status advancement              │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 5: Administrator Oversight & Multiplatform Verification          │
│  - Connect `AdminDashboardView` to `GET /api/admin/stats`              │
│  - Connect full audit list to `GET /api/admin/requests`                │
│  - Verify end-to-end flow across Android, Windows Desktop, and Web     │
│  - Run complete Flutter & Node.js test suites                          │
└────────────────────────────────────────────────────────────────────────┘
```

---

*Specification compiled and cross-verified against `backend/node_api/src/` and `docs/API_CONTRACT.md`.*
