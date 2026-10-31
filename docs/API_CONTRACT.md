# UniFlow — API Contract

> **Status key used throughout this document:**
> - ✅ **IMPLEMENTED** — endpoint is built and covered by automated tests.
> - 🔲 **PLANNED** — endpoint is agreed and documented but not yet implemented.
>
> **Current state (Phase 5):**
> - Health, Auth, Services, Requests, Step Actions, Staff Queue, Admin Stats/Requests, Departments, and Notifications: ✅ IMPLEMENTED & COVERED BY AUTOMATED TESTS
>
> This document must be updated to ✅ IMPLEMENTED only after an endpoint is built
> **and** its behaviour is manually verified or covered by an automated test.

---

## Table of Contents

1. [Conventions](#1-conventions)
2. [Base URL](#2-base-url)
3. [Authentication](#3-authentication)
4. [Standard Response Envelopes](#4-standard-response-envelopes)
5. [Error Format](#5-error-format)
6. [API Groups](#6-api-groups)
   - 6.0 [Health](#60-health)
   - 6.1 [Authentication Endpoints](#61-authentication-endpoints)
   - 6.2 [Services (Catalogue)](#62-services-catalogue)
   - 6.3 [Requests (Workflow Instances)](#63-requests-workflow-instances)
   - 6.4 [Request Step Actions](#64-request-step-actions)
   - 6.5 [Equipment Bookings](#65-equipment-bookings)
   - 6.6 [Staff Review Queue](#66-staff-review-queue)
   - 6.7 [Admin Dashboard](#67-admin-dashboard)
   - 6.8 [Departments](#68-departments)
   - 6.9 [Notifications](#69-notifications)
7. [Role Access Matrix](#7-role-access-matrix)
8. [Workflow Status Values](#8-workflow-status-values)
9. [Changelog](#9-changelog)

---

## 1. Conventions

### HTTP Methods

| Method | Semantics |
|---|---|
| `GET` | Read a resource or list of resources. Never mutates state. |
| `POST` | Create a new resource. Returns 201 on success. |
| `PATCH` | Partially update a resource. Returns 200 on success. |
| `DELETE` | Soft-delete a resource (mark inactive). Returns 200 on success. |

### Path Conventions

- All paths are prefixed with `/api/`.
- Resource names are **plural nouns** (e.g., `/api/journeys`, not `/api/journey`).
- Path parameters use `:id` notation (e.g., `/api/journeys/:id`).
- Nested resources use `/api/journeys/:id/steps` style paths for sub-resources.

### Request Format

- All request bodies are JSON.
- Content-Type header: `application/json`.

### Date Format

All dates and times are ISO 8601 strings in UTC: `"2025-07-14T10:30:00.000Z"`.

### Pagination

List endpoints that may return many results support optional query parameters:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | integer | 1 | Page number (1-indexed) |
| `limit` | integer | 20 | Items per page (max: 100) |

Paginated responses include a `pagination` object in the response envelope.

---

## 2. Base URL

| Environment | Base URL |
|---|---|
| Development | `http://localhost:3001` |
| Production | TBD — set per deployment |

All endpoint paths below are relative to the base URL.

---

## 3. Authentication

Protected endpoints require a valid JWT in the `Authorization` header:

```
Authorization: Bearer <token>
```

The token is obtained from the login endpoint (`POST /api/auth/login`).

Tokens expire after the duration configured in `JWT_EXPIRES_IN` (backend `.env`).
There is no refresh token mechanism in MVP — users must re-login when the token expires.

Endpoints that do not require authentication are marked **[PUBLIC]**.
All other endpoints require authentication. Role restrictions are noted per endpoint.

---

## 4. Standard Response Envelopes

### Success Response

```json
{
  "success": true,
  "data": { }
}
```

For list responses:

```json
{
  "success": true,
  "data": [ ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 47,
    "pages": 3
  }
}
```

### Created Response (HTTP 201)

```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d0e1",
    "...": "..."
  }
}
```

---

## 5. Error Format

All errors return a consistent JSON body:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE_IN_SCREAMING_SNAKE_CASE",
    "message": "A human-readable description of what went wrong.",
    "details": [
      {
        "field": "email",
        "message": "Email address is required."
      }
    ]
  }
}
```

`details` is only included for `VALIDATION_ERROR`. It is omitted for all other error codes.

### Error Code Reference

| HTTP Status | Error Code | Meaning |
|---|---|---|
| 400 | `VALIDATION_ERROR` | One or more request fields failed validation |
| 400 | `INVALID_TRANSITION` | The requested workflow status change is not allowed |
| 401 | `MISSING_TOKEN` | No Authorization header was provided |
| 401 | `INVALID_TOKEN` | JWT is malformed, expired, or has an invalid signature |
| 403 | `FORBIDDEN` | Authenticated user's role does not permit this operation |
| 404 | `NOT_FOUND` | The requested resource does not exist |
| 409 | `CONFLICT` | Resource already exists (e.g., email already registered) |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

---

## 6. API Groups

---

### 6.0 Health

#### `GET /api/health` ✅ IMPLEMENTED [PUBLIC]

Server liveness check. Does not verify database connectivity.

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "status": "operational",
    "service": "uniflow-api",
    "version": "1.0.0",
    "environment": "development",
    "timestamp": "2025-10-14T04:21:00.000Z"
  }
}
```

---

### 6.1 Authentication Endpoints

#### `POST /api/auth/register` ✅ IMPLEMENTED [PUBLIC]

Register a new student account.

> **Approval Policy:** All new public account registrations are created with role `student` and `approvalStatus: 'PENDING'`. No active JWT session token is issued at registration. Accounts must be reviewed and approved by an administrator before signing in.

**Request Body:**
```json
{
  "name": "Arjun Sharma",
  "email": "arjun.sharma@college.edu",
  "password": "SecurePassword123!",
  "role": "student",
  "departmentId": "64a1b2c3d4e5f6a7b8c9d0e8",
  "studentId": "CS2021001"
}
```

| Field | Type | Required | Notes |
|---|---|:---:|---|
| `name` | string | Yes | Min 2 chars, max 100 chars |
| `email` | string | Yes | Must be a valid email; normalized to lowercase; unique across database |
| `password` | string | Yes | Min 8 chars |
| `role` | string | No | Public registration is restricted to `"student"` |
| `departmentId` | ObjectId | No | ObjectId of the department (use `GET /api/departments`) |
| `studentId` | string | No | Student roll number (unique across database) |

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a1b2c3d4e5f6a7b8c9d0e1",
      "name": "Arjun Sharma",
      "email": "arjun.sharma@college.edu",
      "role": "student",
      "department": "64a1b2c3d4e5f6a7b8c9d0e8",
      "studentId": "CS2021001",
      "approvalStatus": "PENDING",
      "rejectionReason": null,
      "isActive": true,
      "createdAt": "2026-10-31T22:00:00.000Z"
    },
    "message": "Registration submitted successfully. Your account is pending administrator approval."
  }
}
```

**Possible errors:** `VALIDATION_ERROR`, `CONFLICT` (email or studentId already registered)

---

#### `POST /api/auth/login` ✅ IMPLEMENTED [PUBLIC]

Authenticate an existing user. Only accounts with `approvalStatus: 'APPROVED'` can log in.

**Possible errors:**
- `VALIDATION_ERROR` (400)
- `INVALID_TOKEN` (401 - Invalid email or password)
- `ACCOUNT_PENDING_APPROVAL` (403 - Account registration is pending administrator approval)
- `ACCOUNT_REJECTED` (403 - Account registration was rejected by administrator)
- `FORBIDDEN` (403 - Deactivated account)

**Request Body:**
```json
{
  "email": "arjun.sharma@college.edu",
  "password": "SecurePassword123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "64a1b2c3d4e5f6a7b8c9d0e1",
      "name": "Arjun Sharma",
      "email": "arjun.sharma@college.edu",
      "role": "student",
      "department": null
    }
  }
}
```

**Possible errors:** `VALIDATION_ERROR`, `INVALID_TOKEN` (wrong credentials → 401)

---

#### `GET /api/auth/me` ✅ IMPLEMENTED [Authenticated]

Get the currently authenticated user's profile.

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d0e1",
    "name": "Arjun Sharma",
    "email": "arjun.sharma@college.edu",
    "role": "student",
    "department": null,
    "createdAt": "2025-07-14T10:30:00.000Z"
  }
}
```

---

### 6.2 Services (Catalogue)

#### `GET /api/services` ✅ IMPLEMENTED [Authenticated]

List all active campus services available to the authenticated user.

**Query Parameters:** `category`, `institutionId`

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "64a1b2c3d4e5f6a7b8c9d0e2",
      "name": "Bonafide Certificate",
      "description": "Official enrolment confirmation letter for external use.",
      "category": "Academic",
      "estimatedDays": 3,
      "workflowStepCount": 2,
      "isActive": true
    },
    {
      "id": "64a1b2c3d4e5f6a7b8c9d0e3",
      "name": "ID Card Replacement",
      "description": "Request a replacement for a lost, stolen or damaged ID card.",
      "category": "Identity",
      "estimatedDays": 5,
      "workflowStepCount": 3,
      "isActive": true
    },
    {
      "id": "64a1b2c3d4e5f6a7b8c9d0e4",
      "name": "Equipment Booking",
      "description": "Borrow institutional equipment for a specified date and time.",
      "category": "Resources",
      "estimatedDays": 1,
      "workflowStepCount": 1,
      "isActive": true
    }
  ]
}
```

---

#### `GET /api/services/:id` ✅ IMPLEMENTED [Authenticated]

Get detailed information about a specific service, including its workflow step definitions (accepts ObjectId or slug).

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d0e2",
    "name": "Bonafide Certificate",
    "description": "Official enrolment confirmation letter for external use.",
    "category": "Academic",
    "estimatedDays": 3,
    "formFields": [
      { "name": "purpose", "label": "Purpose of Certificate", "type": "select",
        "options": ["scholarship", "bank", "visa", "other"], "required": true },
      { "name": "copies", "label": "Number of Copies", "type": "number", "required": true },
      { "name": "additionalDetails", "label": "Additional Details", "type": "textarea", "required": false }
    ],
    "workflowSteps": [
      { "index": 0, "name": "Department Verification", "assignedRole": "staff",
        "description": "Department secretary verifies enrolment." },
      { "index": 1, "name": "Administrative Approval", "assignedRole": "admin",
        "description": "Administrator grants final approval." }
    ],
    "isActive": true
  }
}
```

---

#### `POST /api/services` ✅ IMPLEMENTED [Role: admin]

Create a new service in the catalogue.

**Request Body:**
```json
{
  "name": "Library Clearance",
  "description": "Clearance certificate confirming no outstanding library dues.",
  "category": "Academic",
  "estimatedDays": 1,
  "formFields": [],
  "workflowSteps": [
    { "index": 0, "name": "Library Verification", "assignedRole": "staff",
      "description": "Library staff confirms no outstanding dues." },
    { "index": 1, "name": "Admin Approval", "assignedRole": "admin",
      "description": "Administrator grants clearance." }
  ]
}
```

**Success Response (201):** Returns the created service object.

---

#### `PATCH /api/services/:id` 🔲 PLANNED [Role: admin]

Update an existing service (e.g., change description, toggle active status).

**Request Body:** Any subset of the service fields.

---

### 6.3 Requests (Workflow Instances)

> **Naming note (Phase 1):** The runtime workflow instance was renamed from
> **Journey** to **Request** to better reflect institutional terminology and align
> with the Mongoose model names. API paths remain `/api/requests/*`.
> The `JourneyStep` model is replaced by embedded `runtimeSteps` in the Request document.

A Request is the runtime instance of a workflow for a specific student's service submission.

#### `POST /api/requests` ✅ IMPLEMENTED [Role: student]

Submit a new service request.

**Request Body:**
```json
{
  "serviceId": "64a1b2c3d4e5f6a7b8c9d0e2",
  "formData": {
    "purpose": "scholarship",
    "copies": 2,
    "additionalDetails": "Please include CGPA."
  }
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d0e5",
    "requestNumber": "UF-20251014-ABCDEF",
    "service": "64a1b2c3d4e5f6a7b8c9d0e2",
    "student": "64a1b2c3d4e5f6a7b8c9d0e1",
    "status": "DEPARTMENT_VERIFICATION_PENDING",
    "currentStepIndex": 0,
    "formData": { "purpose": "scholarship", "copies": 2, "additionalDetails": "Please include CGPA." },
    "runtimeSteps": [],
    "createdAt": "2025-07-14T10:30:00.000Z",
    "updatedAt": "2025-07-14T10:30:00.000Z"
  }
}
```

---

#### `GET /api/requests` ✅ IMPLEMENTED [Authenticated]

List requests. For students, returns their own requests. For staff and admin, returns requests filtered by query params.

**Query Parameters:** `status` (filter), `serviceId`, `page`, `limit`

**Success Response (200):** Array of request objects with pagination.

---

#### `GET /api/requests/:id` ✅ IMPLEMENTED [Authenticated]

Get full details of a specific request including runtime steps, populated service, student, and audit log.

**Access rule:** Students can only view their own requests. Staff and admin can view any request.

---

### 6.4 Request Step Actions

#### `PATCH /api/requests/:id/steps/:stepIndex/approve` ✅ IMPLEMENTED [Role: staff, admin]

Approve the current step of a request, advancing it to the next step or completing the workflow.
Also available at `PATCH /api/staff/requests/:id/steps/:stepIndex/approve`.

**Request Body:**
```json
{
  "comment": "Verified and approved."
}
```

**Success Response (200):** Returns updated request object with new status.

**Possible errors:** `NOT_FOUND`, `FORBIDDEN` (wrong role for this step or student attempting self-approval), `INVALID_TRANSITION`

---

#### `PATCH /api/requests/:id/steps/:stepIndex/reject` ✅ IMPLEMENTED [Role: staff, admin]

Reject the current step, terminating the workflow with a REJECTED status.
Also available at `PATCH /api/staff/requests/:id/steps/:stepIndex/reject`.

**Request Body:**
```json
{
  "comment": "Student is not currently enrolled. Please verify your student ID."
}
```

`comment` is **required** for rejection. Rejections without a reason return `VALIDATION_ERROR`.

**Success Response (200):** Returns updated request object with status `REJECTED`.

---

#### `PATCH /api/requests/:id/payment` ✅ IMPLEMENTED [Role: student]

Confirm the simulated payment step for the ID Card Replacement workflow.

**Access rule:** Only the student who owns this request can confirm payment. Request must be in `PAYMENT_REQUIRED` status.

**Request Body:** None required (payment is simulated).

**Success Response (200):** Returns updated request object transitioned to next status (`ADMIN_APPROVAL_PENDING`).

**Possible errors:** `INVALID_TRANSITION` (journey is not in `PAYMENT_REQUIRED` status), `FORBIDDEN`

---

### 6.5 Equipment Bookings

Bookings are a specialised resource type for the Equipment Booking workflow.
They have their own endpoints in addition to the shared journey endpoints.

#### `GET /api/equipment` 🔲 PLANNED [Authenticated]

List available equipment items that can be booked.

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "64a1b2c3d4e5f6a7b8c9d0ea",
      "name": "Canon EOS R10 Camera",
      "category": "Photography",
      "description": "Mirrorless camera with 18-45mm kit lens.",
      "isAvailable": true
    },
    {
      "id": "64a1b2c3d4e5f6a7b8c9d0eb",
      "name": "Epson EB-X51 Projector",
      "category": "Presentation",
      "description": "XGA LCD projector, 3800 lumens.",
      "isAvailable": true
    }
  ]
}
```

---

#### `POST /api/bookings` 🔲 PLANNED [Role: student]

Submit a new equipment booking request.

**Request Body:**
```json
{
  "equipmentId": "64a1b2c3d4e5f6a7b8c9d0ea",
  "purpose": "Photography assignment for Media Studies course.",
  "startTime": "2025-07-18T09:00:00.000Z",
  "endTime": "2025-07-18T17:00:00.000Z"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d0ec",
    "studentId": "64a1b2c3d4e5f6a7b8c9d0e1",
    "equipmentId": "64a1b2c3d4e5f6a7b8c9d0ea",
    "equipmentName": "Canon EOS R10 Camera",
    "purpose": "Photography assignment for Media Studies course.",
    "startTime": "2025-07-18T09:00:00.000Z",
    "endTime": "2025-07-18T17:00:00.000Z",
    "status": "STAFF_REVIEW_PENDING",
    "createdAt": "2025-07-14T10:30:00.000Z"
  }
}
```

---

#### `GET /api/bookings` 🔲 PLANNED [Authenticated]

List bookings. Students see their own bookings. Staff/admin see all bookings.

**Query Parameters:** `status`, `page`, `limit`

**Success Response (200):** Array of booking objects.

---

#### `GET /api/bookings/:id` 🔲 PLANNED [Authenticated]

Get a specific booking. Students can only view their own bookings.

**Success Response (200):** Single booking object.

---

#### `PATCH /api/bookings/:id/approve` 🔲 PLANNED [Role: staff, admin]

Approve a pending equipment booking.

**Request Body:**
```json
{
  "comment": "Equipment reserved. Please collect from the equipment room, Block C."
}
```

**Success Response (200):** Returns updated booking with status `BOOKING_CONFIRMED`.

---

#### `PATCH /api/bookings/:id/reject` 🔲 PLANNED [Role: staff, admin]

Reject a pending equipment booking.

**Request Body:**
```json
{
  "comment": "Equipment is already booked for that time slot. Please choose a different date."
}
```

`comment` is required.

**Success Response (200):** Returns updated booking with status `REJECTED`.

---

### 6.6 Staff Review Queue

#### `GET /api/staff/queue` ✅ IMPLEMENTED [Role: staff, admin]

Get all pending workflow steps currently awaiting action from staff or admin.

Staff members see steps assigned to the `staff` role.
Admins see all pending steps (both `staff` and `admin` assigned).

**Query Parameters:** `status` (default: `PENDING`), `page`, `limit`

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "stepId": "64a1b2c3d4e5f6a7b8c9d0e6-0",
      "requestId": "64a1b2c3d4e5f6a7b8c9d0e5",
      "requestNumber": "UF-20251014-ABCDEF",
      "serviceName": "Bonafide Certificate",
      "studentName": "Arjun Sharma",
      "stepName": "Department Verification",
      "assignedRole": "staff",
      "submittedAt": "2025-07-14T10:30:00.000Z",
      "waitingHours": 4
    }
  ]
}
```

---

### 6.7 Admin Dashboard

#### `GET /api/admin/stats` ✅ IMPLEMENTED [Role: admin]

Get summary statistics for the admin dashboard.

**Success Response (200):**
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

#### `GET /api/admin/requests` ✅ IMPLEMENTED [Role: admin]

List all requests across all students. Supports filtering by status, service, and date range.

**Query Parameters:** `status`, `serviceId`, `page`, `limit`

**Success Response (200):** Array of request objects with pagination.

---

#### `GET /api/admin/pending-users` ✅ IMPLEMENTED [Role: admin]

List all pending student registrations awaiting administrator review.

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "64a1b2c3d4e5f6a7b8c9d010",
      "name": "Pooja Verma",
      "email": "pooja.verma@campus.edu",
      "role": "student",
      "studentId": "STU-2024-099",
      "department": {
        "id": "64a1b2c3d4e5f6a7b8c9d004",
        "name": "Computer Science & Engineering",
        "code": "CSE"
      },
      "institution": {
        "id": "64a1b2c3d4e5f6a7b8c9d000",
        "name": "Apex Institute of Technology",
        "code": "AIT"
      },
      "approvalStatus": "PENDING",
      "createdAt": "2026-10-31T22:30:00.000Z"
    }
  ]
}
```

---

#### `PATCH /api/admin/users/:id/approve` ✅ IMPLEMENTED [Role: admin]

Approve a pending student registration. Activates the account and allows immediate login.

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d010",
    "name": "Pooja Verma",
    "email": "pooja.verma@campus.edu",
    "role": "student",
    "approvalStatus": "APPROVED",
    "isActive": true,
    "approvedAt": "2026-10-31T22:45:00.000Z",
    "approvedBy": "64a1b2c3d4e5f6a7b8c9d001"
  }
}
```

---

#### `PATCH /api/admin/users/:id/reject` ✅ IMPLEMENTED [Role: admin]

Reject a pending student registration with an optional or required explanation.

**Request Body:**
```json
{
  "reason": "Invalid student ID documentation provided."
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6a7b8c9d010",
    "name": "Pooja Verma",
    "approvalStatus": "REJECTED",
    "rejectionReason": "Invalid student ID documentation provided.",
    "isActive": false,
    "approvedAt": "2026-10-31T22:45:00.000Z",
    "approvedBy": "64a1b2c3d4e5f6a7b8c9d001"
  }
}
```

---

### 6.8 Departments

#### `GET /api/departments` ✅ IMPLEMENTED [Authenticated / Public]

List all departments in the institution (used when registering staff accounts).

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    { "id": "64a1b2c3d4e5f6a7b8c9d0e8", "name": "Administration", "code": "ADMIN" },
    { "id": "64a1b2c3d4e5f6a7b8c9d0e9", "name": "Computer Science", "code": "CS" },
    { "id": "64a1b2c3d4e5f6a7b8c9d0ea", "name": "Security", "code": "SEC" },
    { "id": "64a1b2c3d4e5f6a7b8c9d0eb", "name": "Facilities", "code": "FAC" }
  ]
}
```

---

### 6.9 Notifications

#### `GET /api/notifications` ✅ IMPLEMENTED [Authenticated]

Get notifications for the authenticated user.

**Query Parameters:** `unread=true` (optional)

**Success Response (200):** Array of notification objects.

---

#### `PATCH /api/notifications/:id/read` ✅ IMPLEMENTED [Authenticated]

Mark a notification as read.

---

#### `PATCH /api/notifications/read-all` ✅ IMPLEMENTED [Authenticated]

Mark all notifications for the authenticated user as read.

---

## 7. Role Access Matrix

| Endpoint | student | staff | admin |
|---|:---:|:---:|:---:|
| POST /api/auth/register | ✓ | ✓ | ✓ |
| POST /api/auth/login | ✓ | ✓ | ✓ |
| GET /api/auth/me | ✓ | ✓ | ✓ |
| GET /api/services | ✓ | ✓ | ✓ |
| GET /api/services/:id | ✓ | ✓ | ✓ |
| POST /api/services | — | — | ✓ |
| PATCH /api/services/:id | — | — | ✓ |
| POST /api/journeys | ✓ | — | — |
| GET /api/journeys (own) | ✓ | — | — |
| GET /api/journeys/:id | own only | ✓ | ✓ |
| PATCH .../approve | — | ✓ | ✓ |
| PATCH .../reject | — | ✓ | ✓ |
| PATCH .../payment | own only | — | — |
| GET /api/equipment | ✓ | ✓ | ✓ |
| POST /api/bookings | ✓ | — | — |
| GET /api/bookings (own) | ✓ | — | — |
| GET /api/bookings (all) | — | ✓ | ✓ |
| PATCH /api/bookings/:id/approve | — | ✓ | ✓ |
| PATCH /api/bookings/:id/reject | — | ✓ | ✓ |
| GET /api/staff/queue | — | ✓ | ✓ |
| GET /api/admin/stats | — | — | ✓ |
| GET /api/admin/journeys | — | — | ✓ |
| GET /api/admin/pending-users | — | — | ✓ |
| PATCH /api/admin/users/:id/approve | — | — | ✓ |
| PATCH /api/admin/users/:id/reject | — | — | ✓ |
| GET /api/departments | ✓ | ✓ | ✓ |
| GET /api/notifications | ✓ | ✓ | ✓ |
| PATCH /api/notifications/:id/read | ✓ | ✓ | ✓ |

---

## 8. Workflow Status Values

### Journey Statuses

| Status | Meaning |
|---|---|
| `SUBMITTED` | Request just submitted; initial state |
| `DEPARTMENT_VERIFICATION_PENDING` | Waiting for staff to verify (Bonafide workflow) |
| `SECURITY_REVIEW_PENDING` | Waiting for security staff to review (ID Card workflow) |
| `PAYMENT_REQUIRED` | Security approved; waiting for student to complete payment |
| `ADMIN_APPROVAL_PENDING` | Waiting for administrator final approval |
| `COMPLETED` | All steps approved; workflow finished |
| `REJECTED` | A step was rejected; workflow terminated |

### Booking Statuses

| Status | Meaning |
|---|---|
| `STAFF_REVIEW_PENDING` | Submitted; waiting for staff to review |
| `BOOKING_CONFIRMED` | Staff approved; booking is active |
| `REJECTED` | Staff rejected the booking request |

### Step Statuses

| Status | Meaning |
|---|---|
| `PENDING` | Not yet actioned |
| `APPROVED` | Actioned with approval |
| `REJECTED` | Actioned with rejection |
| `SKIPPED` | Step was bypassed (not used in MVP) |

---

## 9. Changelog

| Date | Change |
|---|---|
| 2026-10-13 | Initial API contract created. All endpoints marked PLANNED. Phase 0. |

---

*Last updated: Phase 0 — Repository and Architecture Foundation*
*Update this document when endpoints are implemented and verified.*
