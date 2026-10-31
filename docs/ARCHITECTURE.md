# UniFlow — System Architecture

> **Audience:** Developers, technical reviewers, and future contributors.
> **Purpose:** Define the system's structural boundaries, module responsibilities,
> data flow, and architectural decisions so that the codebase can be understood,
> extended, and debugged without tribal knowledge.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Layer Responsibilities](#3-layer-responsibilities)
4. [Folder Structure Reference](#4-folder-structure-reference)
5. [Authentication Boundary](#5-authentication-boundary)
6. [Request Lifecycle](#6-request-lifecycle)
7. [Workflow State Machine](#7-workflow-state-machine)
8. [Role-Based Access Control](#8-role-based-access-control)
9. [Error Handling Strategy](#9-error-handling-strategy)
10. [Configuration and Environment](#10-configuration-and-environment)
11. [Module Dependency Rules](#11-module-dependency-rules)
12. [Database Design Principles](#12-database-design-principles)
13. [Frontend Architecture](#13-frontend-architecture)
14. [CORS and Network Boundary](#14-cors-and-network-boundary)
15. [Deployment Model](#15-deployment-model)

---

## 1. System Overview

UniFlow is a **modular monolith** web application.

- One React frontend (built with Vite) serves all user roles from a single codebase.
- One Node.js/Express backend handles all business logic, authentication, and workflow transitions.
- One MongoDB database (accessed via Mongoose) stores all application data.

There are no microservices. There are no separate backends for the student and admin portals.
All communication between the browser and the server is over HTTP REST.

**Do not introduce additional backend services without an explicit architectural review.**

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser / Client                         │
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐    │
│   │              React Application (Vite)                  │    │
│   │                                                        │    │
│   │   ┌──────────────┐        ┌─────────────────────┐     │    │
│   │   │ Student       │        │ Staff / Admin        │     │    │
│   │   │ Portal Pages  │        │ Portal Pages         │     │    │
│   │   └──────┬───────┘        └──────────┬──────────┘     │    │
│   │          │                           │                 │    │
│   │          └───────────┬───────────────┘                 │    │
│   │                      │                                 │    │
│   │              ┌───────▼───────┐                         │    │
│   │              │   API Client  │  (axios / fetch)        │    │
│   │              │  + Auth Header│                         │    │
│   │              └───────┬───────┘                         │    │
│   └──────────────────────┼─────────────────────────────────┘   │
└──────────────────────────┼──────────────────────────────────────┘
                           │  HTTP REST  (JSON over HTTPS)
                           │  Authorization: Bearer <JWT>
┌──────────────────────────▼──────────────────────────────────────┐
│                    Node.js / Express API                         │
│                    backend/node_api/                             │
│                                                                  │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────────┐    │
│  │  Auth      │  │  Role Guard  │  │  Input Validation    │    │
│  │  Middleware│  │  Middleware  │  │  Middleware           │    │
│  └─────┬──────┘  └──────┬───────┘  └──────────┬───────────┘   │
│        └─────────────────┼──────────────────────┘              │
│                          │                                       │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │                       Routes                              │  │
│  │  /api/health /api/auth   /api/services  /api/requests     │  │
│  │  /api/staff  /api/admin  /api/departments /api/notifications │
│  └───────────────────────┬──────────────────────────────────┘  │
│                          │                                       │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │                    Controllers                            │  │
│  │  (parse request, call service, format response)          │  │
│  └───────────────────────┬──────────────────────────────────┘  │
│                          │                                       │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │                     Services                              │  │
│  │  (business logic, workflow transitions, validation)      │  │
│  └───────────────────────┬──────────────────────────────────┘  │
│                          │                                       │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │                 Mongoose Models                           │  │
│  │  Institution Department User Service Workflow Request     │  │
│  │  Notification                                             │  │
│  └───────────────────────┬──────────────────────────────────┘  │
└──────────────────────────┼──────────────────────────────────────┘
                           │  MongoDB Wire Protocol
┌──────────────────────────▼──────────────────────────────────────┐
│                    MongoDB Database                              │
│          (Local Community Edition or MongoDB Atlas)             │
│                                                                  │
│   Collections: institutions departments users services          │
│                workflows requests notifications                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Layer Responsibilities

### 3.1 React Frontend (`frontend/react_app/`)

**Owns:**
- All visual presentation and user interaction.
- Client-side routing (React Router) and navigation guards.
- Authentication state (stores JWT, reads role from decoded token).
- Form rendering, validation feedback, and user-friendly error messages.
- Calling the backend API through a centralized API client module.

**Does not own:**
- Business logic or workflow rules.
- Authorization decisions (these are enforced on the backend).
- Direct database access.
- JWT signing or verification.

### 3.2 Express Backend (`backend/node_api/`)

**Owns:**
- All business logic, including workflow state transition rules.
- JWT issuance (on login) and verification (on every protected request).
- Role-based access control enforcement.
- Input sanitisation and validation.
- Constructing responses in a consistent format.
- Communicating with MongoDB via Mongoose models.

**Does not own:**
- UI rendering or HTML generation.
- Client-side state.

**Internal layer breakdown:**

| Layer | File location | Responsibility |
|---|---|---|
| **Routes** | `routes/*.routes.js` | Map HTTP verb + path to a controller function |
| **Middleware** | `middleware/*.middleware.js` | Auth verification, role check, input validation — run before controllers |
| **Controllers** | `controllers/*.controller.js` | Extract request data, call the appropriate service, send response |
| **Services** | `services/*.service.js` | Business logic, workflow transitions, complex queries |
| **Models** | `models/*.js` | Mongoose schemas; define shape, validation, and indexes |
| **Config** | `config/` | Database connection, environment variable loading |
| **Scripts** | `scripts/` | One-off utility scripts (seed data, migrations) |

**Rule:** Controllers must be thin. If a function in a controller is doing more than
parsing the request, calling one service method, and sending a response, the logic
belongs in a service.

### 3.3 MongoDB (`database/`)

**Owns:**
- Persistent storage of all application data.
- Indexes for query performance.
- Document-level validation (enforced additionally by Mongoose).

**Does not own:**
- Business rules (these live in the Express service layer).
- Authentication (the database stores password hashes, not plaintext; verification happens in Express).

---

## 4. Folder Structure Reference

backend/node_api/
├── package.json
├── .env.example
├── README.md
├── scripts/
│   └── seed.js               ← Create demo institution, departments, users, services, workflows; idempotent
├── src/
│   ├── server.js             ← App entry: connectDB, listen, handle SIGTERM/SIGINT graceful shutdown
│   ├── app.js                ← Express app factory: configure middleware, routes, error handling
│   ├── config/
│   │   ├── env.js            ← Zod-validated environment config
│   │   └── database.js       ← Mongoose connection & graceful shutdown
│   ├── models/
│   │   ├── Institution.js    ← name, slug, code, isActive
│   │   ├── Department.js     ← name, code, institution, isActive
│   │   ├── User.js           ← name, email, passwordHash, role, institution, department, studentId
│   │   ├── Service.js        ← name, slug, description, category, formFields, responsibleDepartment, workflow
│   │   ├── Workflow.js       ← name, service, steps[] (stepOrder, name, assignedRole, pendingStatus, isPaymentStep)
│   │   ├── Request.js        ← requestNumber, student, service, status, runtimeSteps[], formData, auditLog[]
│   │   └── Notification.js   ← recipient, request, title, message, type, isRead
│   ├── routes/
│   │   ├── index.js          ← Central API router (/api mount)
│   │   ├── health.routes.js  ← GET /api/health
│   │   ├── auth.routes.js    ← POST /api/auth/register, POST /api/auth/login, GET /api/auth/me
│   │   ├── service.routes.js ← GET /api/services, GET /api/services/:id
│   │   ├── request.routes.js ← POST /api/requests, GET /api/requests, GET /api/requests/:id
│   │   ├── staff.routes.js   ← GET /api/staff/queue, PATCH /api/staff/requests/:id/steps/:stepId
│   │   ├── admin.routes.js   ← GET /api/admin/stats, GET /api/admin/requests
│   │   ├── department.routes.js ← GET /api/departments
│   │   └── notification.routes.js ← GET /api/notifications, PATCH /api/notifications/:id/read
│   ├── controllers/
│   │   ├── health.controller.js
│   │   ├── auth.controller.js
│   │   ├── service.controller.js
│   │   ├── request.controller.js
│   │   ├── staff.controller.js
│   │   ├── admin.controller.js
│   │   ├── department.controller.js
│   │   └── notification.controller.js
│   ├── services/
│   │   ├── auth.service.js       ← User lookup, password verification, JWT creation
│   │   ├── service.service.js    ← Service catalogue queries
│   │   ├── request.service.js    ← State machine transitions, runtime steps, audit log
│   │   ├── staff.service.js      ← Role-based queue filtering & step actions
│   │   ├── admin.service.js      ← Cross-department stats & management
│   │   └── notification.service.js ← In-app notification creation and reads
│   ├── middleware/
│   │   ├── auth.middleware.js    ← Verify JWT; attach req.user = { id, role, email }
│   │   ├── role.middleware.js    ← requireRole(...roles) factory; returns 403 if unauthorized
│   │   ├── validate.middleware.js← Zod schema validation middleware
│   │   └── error.middleware.js   ← Global error handler and 404 handler
│   ├── validators/
│   │   ├── auth.validators.js
│   │   └── request.validators.js
│   └── utils/
│       ├── AppError.js           ← Standardized operational error class
│       └── asyncHandler.js       ← Async route exception wrapper
└── tests/
    ├── .env.test
    ├── app.test.js
    ├── health.test.js
    ├── models.test.js
    └── auth.test.js

frontend/react_app/
├── index.html
├── vite.config.js
├── package.json
├── .env.example
├── README.md
└── src/
    ├── main.jsx              ← React root, mounts App inside React.StrictMode
    ├── App.jsx               ← BrowserRouter, AuthProvider, top-level AppRoutes
    ├── api/
    │   ├── httpClient.js     ← Axios instance; base URL from env; JWT request & 401 response interceptors
    │   ├── authApi.js        ← login, registerStudent, getCurrentUser, getDepartments
    │   └── index.js          ← API re-exports
    ├── context/
    │   └── AuthContext.jsx   ← Auth state, session persistence, login/register/logout methods
    ├── components/
    │   ├── common/
    │   │   ├── Button.jsx    ← Button with loading spinner
    │   │   ├── Input.jsx     ← Form input with validation & password visibility toggle
    │   │   ├── Alert.jsx     ← Error/warning/success banners
    │   │   └── Components.jsx← Badge, Card, Spinner
    │   └── navigation/
    │       └── Navbar.jsx    ← Role-aware navbar with brand, portal links, user badge & logout
    ├── layouts/
    │   ├── AuthLayout.jsx    ← Centered card layout for login and registration
    │   └── AppLayouts.jsx    ← StudentLayout and StaffAdminLayout with Navbar
    ├── pages/
    │   ├── auth/
    │   │   ├── Login.jsx     ← Login page with validation & role-aware redirect
    │   │   └── Register.jsx  ← Student registration page (locked to student role)
    │   ├── student/
    │   │   └── StudentDashboard.jsx ← Student portal shell with service preview
    │   ├── staff/
    │   │   └── StaffQueue.jsx       ← Staff review queue shell
    │   ├── admin/
    │   │   └── AdminDashboard.jsx   ← Institutional admin dashboard shell
    │   ├── Unauthorized.jsx         ← 403 Forbidden page
    │   └── NotFound.jsx             ← 404 Not Found page
    ├── routes/
    │   ├── AppRoutes.jsx            ← Route tree with role guards
    │   ├── ProtectedRoute.jsx       ← Authentication barrier
    │   └── RoleRoute.jsx            ← Role-based access barrier
    ├── styles/
    │   └── index.css                ← Unified UniFlow design system styles
    └── test/
        ├── setup.js                 ← Vitest DOM matchers setup
        ├── auth.test.jsx            ← Auth form validation & API integration tests
        └── routes.test.jsx          ← Route guard & RBAC enforcement tests
```

---

## 5. Authentication Boundary

### Token Flow

```
1. User submits credentials (email + password) to POST /api/auth/login
2. Server:
   a. Looks up user by email
   b. Compares submitted password with stored bcrypt hash
   c. On match: signs a JWT containing { userId, role, email }
   d. Returns { token, user: { id, name, role } }
3. React stores the token (localStorage or memory)
4. React includes the token in every subsequent request:
   Authorization: Bearer <token>
5. Server middleware (auth.middleware.js) on every protected route:
   a. Extracts the token from the Authorization header
   b. Verifies signature using JWT_SECRET from .env
   c. Decodes payload; attaches req.user = { id, role, email }
   d. If token is missing or invalid: returns 401 Unauthorized
6. Role middleware (role.middleware.js) on role-restricted routes:
   a. Reads req.user.role
   b. If role does not match requirement: returns 403 Forbidden
```

### JWT Configuration

| Parameter | Value |
|---|---|
| Algorithm | HS256 (HMAC-SHA256) |
| Secret | `JWT_SECRET` environment variable — never hard-coded |
| Expiry | `JWT_EXPIRES_IN` environment variable (e.g., `"7d"`) |
| Payload | `{ userId, role, email, iat, exp }` |

### Password Storage

Passwords are **never** stored in plaintext. bcryptjs is used to hash passwords before
saving to the database. The salt rounds value is configurable (default: 10).

---

## 6. Request Lifecycle

A typical protected API request follows this path:

```
Browser
  │
  ▼
React API client (axios)
  │  Adds Authorization: Bearer <JWT> header
  │
  ▼
Express server.js
  │  cors() middleware — allows requests from VITE_ORIGIN
  │  express.json() — parse JSON body
  │
  ▼
Route match (e.g., PATCH /api/staff/requests/:id/steps/:stepId → staff.routes.js)
  │
  ▼
auth.middleware.js
  │  Verify JWT → attach req.user
  │  If invalid → 401 response (stops here)
  │
  ▼
role.middleware.js  (if route is role-restricted)
  │  Check req.user.role against required role
  │  If forbidden → 403 response (stops here)
  │
  ▼
staff.controller.js
  │  Extract params, body, req.user
  │  Call request.service.actionStep(...)
  │
  ▼
request.service.js
  │  Validate transition is allowed by state machine
  │  Update Request and runtimeSteps subdocument in MongoDB
  │  Append entry to auditLog
  │  Return updated request
  │
  ▼
staff.controller.js
  │  Format response: { success: true, data: request }
  │
  ▼
HTTP 200 response to browser
```

---

## 7. Workflow State Machine

Each Request has a `status` string. Only specific transitions are valid.
The service layer enforces the state machine; the API returns 400 Bad Request
for invalid transitions.

### Bonafide Certificate Statuses

```
SUBMITTED
    │ Staff approves
    ▼
DEPARTMENT_VERIFICATION_PENDING
    │ Staff approves
    ▼
ADMIN_APPROVAL_PENDING
    │ Admin approves
    ▼
COMPLETED

Any status → REJECTED  (on staff or admin rejection)
```

### ID Card Replacement Statuses

```
SUBMITTED
    │ Security staff approves
    ▼
SECURITY_REVIEW_PENDING
    │ Staff approves
    ▼
PAYMENT_REQUIRED
    │ Student clicks Pay
    ▼
ADMIN_APPROVAL_PENDING
    │ Admin approves
    ▼
COMPLETED

Any active status → REJECTED  (on staff or admin rejection)
```

### Equipment Booking Statuses

```
SUBMITTED
    │ Staff reviews
    ▼
STAFF_REVIEW_PENDING
    │ Staff approves
    ▼
BOOKING_CONFIRMED

STAFF_REVIEW_PENDING → REJECTED  (on staff rejection)
```

### Rules (enforced in service layer)

1. Status transitions must follow the defined paths above.
2. A request in `COMPLETED` or `REJECTED` status cannot be advanced.
3. Only the role assigned to a step can transition that step.
4. A student cannot approve their own request at any step.
5. Every transition records: actorId (who did it), comment (required for rejection), timestamp.

---

## 8. Role-Based Access Control

| Operation | Student | Staff | Admin |
|---|:---:|:---:|:---:|
| View own requests | ✅ | — | — |
| Submit new request | ✅ | — | — |
| Simulate payment step | ✅ | — | — |
| View staff review queue | — | ✅ | ✅ |
| Approve/reject step (non-final) | — | ✅ | ✅ |
| Final admin approval | — | — | ✅ |
| View all requests (admin dashboard) | — | — | ✅ |
| View service catalogue | ✅ | ✅ | ✅ |
| Manage services (create/edit) | — | — | ✅ |

**Implementation:** The `requireRole(...roles)` middleware factory in `role.middleware.js`
generates a middleware function for role strings. Routes combine `authenticate` and
`requireRole` as a middleware chain.

```js
// Example route definition
router.patch(
  '/requests/:id/steps/:stepId',
  authenticate,          // verify JWT → req.user
  requireRole('staff', 'admin'),  // 403 if role is not authorized
  staffController.actionStep
);
```

---

## 9. Error Handling Strategy

### Standard Error Response Format

All API errors return a consistent JSON body:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description of the error.",
    "details": [
      { "field": "email", "message": "Email is required." }
    ]
  }
}
```

`details` is only present for validation errors. It is omitted for auth and server errors.

### HTTP Status Code Usage

| Status | Meaning | Used for |
|---|---|---|
| 200 | OK | Successful GET, PATCH |
| 201 | Created | Successful POST (resource created) |
| 400 | Bad Request | Validation errors, invalid transitions |
| 401 | Unauthorized | Missing or invalid JWT |
| 403 | Forbidden | Valid JWT but insufficient role |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Duplicate resource (e.g., email already registered) |
| 500 | Internal Server Error | Unexpected server error |

### Global Error Handler

Express registers a global error-handling middleware (4 arguments: `err, req, res, next`)
as the last middleware in `server.js`. It:
- Catches any error passed via `next(err)`.
- Logs the error (to console in development; to a log file in production).
- Returns a sanitised error response (never exposes stack traces to the client in production).

---

## 10. Configuration and Environment

### Backend `.env` variables

| Variable | Required | Description |
|---|:---:|---|
| `PORT` | Yes | Port the Express server listens on (default: 3001) |
| `MONGO_URI` | Yes | Full MongoDB connection string (Atlas or local) |
| `JWT_SECRET` | Yes | Secret key for signing JWTs — must be long and random |
| `JWT_EXPIRES_IN` | Yes | Token expiry duration (e.g., `"7d"`, `"24h"`) |
| `NODE_ENV` | No | `"development"` or `"production"` (affects error verbosity) |
| `CORS_ORIGIN` | No | Allowed CORS origin (default: `http://localhost:5173`) |

### Frontend `.env` variables

| Variable | Required | Description |
|---|:---:|---|
| `VITE_API_BASE_URL` | Yes | Base URL of the Express API (e.g., `http://localhost:3001`) |

### Rules

- `.env` files are **never committed to version control** (enforced by `.gitignore`).
- `.env.example` files list every required key with placeholder values and are committed.
- The backend reads all config at startup via `dotenv`. If a required variable is missing,
  the server should log a clear error and exit — not silently run with a broken config.

---

## 11. Module Dependency Rules

To keep the codebase maintainable, the following dependency direction is enforced:

```
Routes → Controllers → Services → Models
                    ↑
               Middleware (injects req.user)
```

- Routes may import controllers and middleware only.
- Controllers may import services only.
- Services may import models and other services only.
- Models are leaf nodes — they import nothing from the application layer.
- Circular imports are forbidden.

---

## 12. Database Design Principles

### Collections

| Collection | Purpose |
|---|---|
| `institutions` | Institution records (one per university/college) |
| `departments` | Departments within an institution |
| `users` | All user accounts regardless of role |
| `services` | Campus service definitions and their form field templates |
| `workflows` | Ordered step definition templates (one per service) |
| `requests` | Runtime workflow instances — one per student submission |
| `notifications` | In-app notification messages for users |

### Key Design Decisions

1. **Roles in one collection:** Students, staff, and admins all live in the `users`
   collection. The `role` field distinguishes them.

2. **Runtime steps embedded in Request:** Workflow step instances are stored as
   embedded subdocuments (`Request.runtimeSteps`) rather than separate documents.
   This allows the full audit trail to be retrieved in a single document fetch.
   An append-only `auditLog` array captures every transition with actor, comment, and timestamps.

3. **Workflow definitions separate from runtime:** `Workflow` stores the step template;
   `Request` stores the runtime copy (`runtimeSteps`) plus a `workflowVersion` snapshot
   so historical requests are unaffected by workflow updates.

4. **Requests store submitted form data:** The `formData` field on a Request is a
   flexible Mixed type that holds the student's submitted form. Different services
   have different form fields without requiring schema changes.

5. **Soft deletes:** Services, workflows, users, and departments can be deactivated
   (`isActive: false`) rather than deleted, preserving referential integrity.

6. **All documents include `createdAt` and `updatedAt`:** Mongoose `timestamps: true`
   option is used on all schemas.

7. **requestNumber:** Generated by a Mongoose pre-save hook in format `UF-YYYYMMDD-XXXXXX`.
   Human-readable and suitable for reference in support communications.

---

## 13. Frontend Architecture

### Routing and Role Guards

React Router manages all client-side navigation. A `ProtectedRoute` component wraps
routes that require authentication. An additional `RoleRoute` component wraps routes
that require a specific role. These components redirect to `/login` or `/unauthorised`
as appropriate.

```
/                    → redirects to /student/dashboard or /staff/queue based on role
/login               → public
/register            → public
/student/*           → requires role: student
/staff/*             → requires role: staff or admin
/admin/*             → requires role: admin
```

### Auth Context

A React Context (`AuthContext`) holds the current user's authentication state:
`{ user, token, login(), logout() }`. It is provided at the root of the app
(`App.jsx`) and consumed by any component that needs the current user.

### API Client

A single Axios instance (`src/api/client.js`) is used for all API calls.
It is configured with:
- `baseURL` from `VITE_API_BASE_URL` environment variable.
- A request interceptor that automatically adds the `Authorization: Bearer <token>` header.
- A response interceptor that catches 401 responses and triggers logout.

Individual API modules (e.g., `src/api/requests.js`) export named functions
that call the Axios instance. Components never call Axios directly.

### State Management

The MVP uses local component state and React Context. Redux or other global state
libraries are not introduced. This keeps the application simple.
If state management becomes complex in future phases, Zustand is the preferred lightweight option.

---

## 14. CORS and Network Boundary

During development:
- React Vite dev server: `http://localhost:5173`
- Express API server: `http://localhost:3001`

These are different origins. The Express server must include the `cors` middleware
with explicit configuration to allow requests from `http://localhost:5173`.

```js
// In server.js
import cors from 'cors';
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

In production, `CORS_ORIGIN` must be set to the actual deployed frontend URL.

---

## 15. Deployment Model

**MVP target: Local development only.**

Both servers run locally on the developer's machine. No CI/CD pipeline, containerisation,
or cloud deployment is configured in the MVP.

**Future deployment notes (for planning only):**

| Component | Simple Deployment Target |
|---|---|
| React Frontend | Vercel, Netlify, or any static host (after `npm run build`) |
| Express Backend | Render, Railway, Fly.io, or a VPS |
| MongoDB | MongoDB Atlas (already recommended for dev) |

---

*Last updated: Phase 1 — Backend Foundation*
*Next update: Phase 2 — Backend Workflow APIs*
