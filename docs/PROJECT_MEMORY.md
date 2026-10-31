# UniFlow — Project Memory

> **Read this first.** This document is the single source of truth for the UniFlow project.
> It is written so that any team member who returns to the project after a long absence
> can reconstruct what the system does, why it was built this way, and where it is going —
> without needing to ask anyone.

---

## Table of Contents

1. [What is UniFlow?](#1-what-is-uniflow)
2. [The Real-World Problem](#2-the-real-world-problem)
3. [Target Users and Roles](#3-target-users-and-roles)
4. [The Three Mandatory MVP Workflows](#4-the-three-mandatory-mvp-workflows)
5. [Technology Stack and Rationale](#5-technology-stack-and-rationale)
6. [Alternatives Considered](#6-alternatives-considered)
7. [MVP Scope and Explicit Exclusions](#7-mvp-scope-and-explicit-exclusions)
8. [Future Scope](#8-future-scope)
9. [Folder Structure](#9-folder-structure)
10. [Development Commands](#10-development-commands)
11. [Important Design Decisions](#11-important-design-decisions)
12. [Terminology Glossary](#12-terminology-glossary)

---

## 1. What is UniFlow?

UniFlow is a **campus service-navigation and workflow platform**. It converts institutional
services — bureaucratic multi-step processes that normally require physical visits, paper
forms, and guesswork — into guided digital journeys that students can initiate, track, and
complete entirely through a web browser.

The name reflects the goal: a single, unified flow for every campus administrative service.

UniFlow is a **web application**, not a mobile application. It is designed to be
responsive so that it works on a desktop browser and on a mobile browser, but it is
not distributed through app stores and does not use native mobile frameworks.

---

## 2. The Real-World Problem

University administrative processes are opaque and frustrating for students. A typical
scenario looks like this:

1. A student needs a bonafide certificate (an official letter confirming enrolment).
2. They do not know which office handles it — the department office, the registrar, or the
   administrative block?
3. They visit the wrong counter and are redirected.
4. They fill a paper form that requires their department head's signature.
5. They return the next day to collect it, only to find it has not been processed yet.
6. They have no way to track the status of their request.
7. The process may take days or weeks, with zero visibility.

This problem repeats for every administrative service: ID card replacements, equipment
borrowing, library clearances, fee receipts, and so on.

UniFlow solves this by:

- Making every service discoverable from a single dashboard.
- Guiding the student through each required step.
- Routing the request automatically to the correct person for approval.
- Giving the student real-time status updates without requiring them to visit any office.
- Giving institutional staff a clean queue-based interface for reviewing and approving requests.

---

## 3. Target Users and Roles

UniFlow has three distinct roles. Every user belongs to exactly one role.

### 3.1 Student

A currently enrolled student at the institution.

**What they can do:**
- Browse available campus services.
- Submit requests for services (bonafide certificates, ID card replacements, equipment bookings, etc.).
- Track the status of each request through its workflow stages.
- Receive status notifications when a step is approved, rejected, or requires their attention.
- Download completed documents (future scope).

**What they cannot do:**
- Approve requests (including their own).
- See other students' requests.
- Access the staff review queue.
- Modify or delete an in-progress request (cancel only, if the workflow permits it at that stage).

### 3.2 Staff (Departmental/Functional Staff)

A member of institutional staff responsible for the first or intermediate review step in
one or more workflows. Examples: department secretary, equipment custodian, security desk officer.

**What they can do:**
- View the queue of pending requests assigned to their department.
- Approve or reject individual workflow steps, with a mandatory reason/comment.
- Escalate a request to an administrator if required.

**What they cannot do:**
- Submit service requests as a student.
- Perform the final administrative approval (that belongs to the admin role).
- Create or modify workflow definitions.

### 3.3 Administrator (Admin)

A senior institutional administrator, such as the registrar or dean of students.

**What they can do:**
- Perform final approval on any workflow.
- View all requests across all departments.
- Manage (create, edit, deactivate) workflow definitions and service catalogue entries.
- View dashboard statistics (number of pending, approved, rejected requests per service).
- Create and manage user accounts (future scope — currently users self-register).

**What they cannot do:**
- Submit service requests on behalf of students (in MVP; future scope may allow proxy submission).

---

## 4. The Three Mandatory MVP Workflows

A **workflow** is a predefined sequence of steps that a service request passes through
from submission to completion. Each step is assigned to a specific role. A step can
be approved or rejected. Rejection terminates the workflow and notifies the student.

### 4.1 Bonafide Certificate Request

**Purpose:** A student requests an official letter from the institution confirming that they
are a currently enrolled student. This is commonly required for bank accounts, visa
applications, and scholarship forms.

**Complete user journey:**

```
1. Student logs in and navigates to "Services > Bonafide Certificate".
2. Student fills the request form:
   - Purpose of the certificate (scholarship / bank / visa / other)
   - Number of copies required
   - Any specific details to be included
3. Student submits the request.
4. System creates a Journey record with status "Department Verification Pending".
5. Staff (Department Secretary) receives the request in their review queue.
6. Staff verifies student enrolment records and approves or rejects with a comment.
   - If rejected: student is notified with the reason. Workflow ends.
   - If approved: workflow advances to next step.
7. System updates status to "Administrative Approval Pending".
8. Administrator reviews the verified request and gives final approval.
   - If rejected: student is notified. Workflow ends.
   - If approved: workflow advances.
9. System updates status to "Completed — Certificate Issued".
10. Student sees the completed status on their dashboard and can download the certificate
    (download is future scope; in MVP the status update is the confirmation).
```

**Roles involved:** Student (submit) → Staff/Department (verify) → Admin (approve) → Student (view)

**Estimated steps:** 2 workflow steps (verify → approve)

---

### 4.2 ID Card Replacement

**Purpose:** A student whose ID card has been lost, stolen or damaged requests a
replacement. This workflow includes a simulated payment step because replacement cards
carry a nominal fee.

**Complete user journey:**

```
1. Student logs in and navigates to "Services > ID Card Replacement".
2. Student fills the request form:
   - Reason for replacement (lost / stolen / damaged)
   - If stolen: police complaint reference number (optional)
   - Current contact details for card delivery confirmation
3. Student submits the request.
4. System creates a Journey record with status "Security Review Pending".
5. Staff (Security Desk Officer) reviews the request.
   - They verify the student's identity and confirm there are no flags on the account.
   - They approve or reject with a mandatory comment.
   - If rejected: student is notified. Workflow ends.
   - If approved: workflow advances.
6. System updates status to "Payment Required".
7. Student sees a payment prompt on their journey detail page.
   - In MVP: this is a simulated payment (a "Pay Now" button that marks payment as complete
     without connecting to a real payment gateway).
   - Student clicks "Pay Now" and payment is recorded as completed.
8. System updates status to "Administrative Approval Pending".
9. Administrator reviews the security-approved, payment-completed request.
   - If approved: workflow advances.
   - If rejected (rare): student is notified.
10. System updates status to "Completed — Card Being Printed".
11. Student sees the completed status. Physical card delivery is out of scope for MVP.
```

**Roles involved:** Student (submit) → Staff/Security (review) → Student (pay) → Admin (approve) → Student (view)

**Estimated steps:** 3 workflow steps (security-review → payment-confirmation → admin-approve)

**Important note on payment:** The payment step is simulated. No real money is processed.
No payment gateway (Stripe, Razorpay, etc.) is integrated in MVP. The "Pay" action simply
sets a flag in the database. A real payment integration is planned for future scope.

---

### 4.3 Equipment Booking

**Purpose:** A student wants to borrow or temporarily use institutional equipment (projector,
camera, lab equipment, sports equipment, etc.) for a specified date and time slot.

**Complete user journey:**

```
1. Student logs in and navigates to "Services > Equipment Booking".
2. Student selects equipment from the catalogue:
   - Equipment category and specific item
   - Intended use / purpose description
   - Requested date and time slot (start time → end time)
   - Return date
3. Student submits the booking request.
4. System creates a Booking record with status "Staff Review Pending".
5. Staff (Equipment Custodian) receives the booking in their queue.
   - They verify the equipment is available for that slot.
   - They approve the request (equipment is now reserved) or reject it (provide reason).
   - If rejected: student is notified with the reason. The time slot is freed.
   - If approved: booking is confirmed.
6. System updates status to "Booking Confirmed".
7. Student sees the confirmed booking on their dashboard.
   - Reminder notifications are out of scope for MVP.
8. After the booking period, staff marks the equipment as returned (future scope).
```

**Roles involved:** Student (submit) → Staff/Custodian (review/approve) → Student (view)

**Estimated steps:** 1 workflow step (staff-approve)

**Note on conflict checking:** In MVP, the staff member manually verifies availability.
Automated slot conflict detection (preventing double-bookings) is a future scope feature.

---

## 5. Technology Stack and Rationale

### 5.1 Frontend — React with Vite

**What it is:** React is a JavaScript library for building component-based user interfaces.
Vite is a build tool and development server that provides extremely fast hot-module
replacement (HMR), replacing the older Create React App toolchain.

**Why React:**
- Component model maps naturally to UniFlow's reusable UI elements (journey cards,
  status badges, approval forms, step timelines).
- Large ecosystem, wide community familiarity.
- React Router enables client-side routing without full page reloads, giving the app
  a fast, app-like feel.
- Role-aware rendering: components can conditionally show student or staff/admin UI
  based on the authenticated user's role, within a single codebase.

**Why Vite over Create React App:**
- Significantly faster cold start and hot reload.
- Modern ES module support out of the box.
- Simpler configuration for the project's scale.

**Why a web application (not Flutter):**
- The project specification explicitly requires a responsive web application.
- Web applications are accessible from any device with a browser, with no installation.
- A single React codebase serves all roles; no separate apps are needed.
- Web apps are simpler to deploy and maintain than native or cross-platform mobile apps
  for this type of institutional service tool.

### 5.2 Backend — Node.js with Express

**What it is:** Node.js is a server-side JavaScript runtime. Express is a minimal web
framework for Node.js that provides routing, middleware, and request/response handling.

**Why Node.js + Express:**
- JavaScript across the full stack reduces context switching for developers.
- Express is lightweight and does not impose an opinionated structure — this lets the team
  choose a clean layered architecture (routes → controllers → services → models).
- Large middleware ecosystem (cors, helmet, jsonwebtoken, express-validator, etc.).
- Node.js handles the I/O-bound nature of an API that primarily reads and writes to a
  database very efficiently.

**Single backend, dual portals:**
Both the student portal and the staff/admin portal consume the same Express API.
There is one backend server. Role-based access control (enforced in Express middleware)
determines what each authenticated user can see and do.
This decision keeps the codebase simple and prevents data inconsistency that would arise
from maintaining two separate backend services.

### 5.3 Database — MongoDB with Mongoose

**What it is:** MongoDB is a document-oriented NoSQL database. Documents are stored in
BSON format (Binary JSON). Mongoose is an ODM (Object Data Modelling) library that
provides schema definitions, validation, and query helpers on top of the MongoDB Node.js driver.

**Why MongoDB:**
- Workflow data (journey steps, metadata, approval history) has a naturally hierarchical
  and variable structure that fits a document model better than a rigid relational schema.
- Schema flexibility allows workflow step definitions to evolve without requiring database
  migrations for every small change.
- Mongoose provides schema-level validation and type safety while retaining flexibility.
- MongoDB Atlas provides a free-tier hosted cluster, removing the need for local database
  installation during development.

**Why Mongoose:**
- Enforces schemas at the application layer, preventing unexpected document shapes.
- Provides lifecycle hooks (pre-save, post-save) useful for audit trails.
- Simplifies population of references between documents (similar to SQL JOINs but for documents).

---

## 6. Alternatives Considered

### 6.1 Flutter (Rejected)

Flutter was considered because it supports cross-platform development from a single
codebase. It was rejected because:
- The project requires a responsive **web application**, not a mobile application.
- Flutter Web exists but produces large bundle sizes and does not integrate naturally
  with institutional web environments.
- HTML/CSS/React provides far more control over accessibility and SEO for a web app.

### 6.2 Next.js (Not selected for MVP)

Next.js (React with server-side rendering) was considered. It was not selected for
the initial build because:
- Server-side rendering adds complexity (server/client boundary, hydration) that is
  not needed for an authenticated internal tool.
- Vite + React is simpler and faster to set up for the team's current scale.
- Next.js remains an option for a future public-facing marketing site or SSR-enhanced version.

### 6.3 PostgreSQL / MySQL (Rejected in favour of MongoDB)

Relational databases were considered. MongoDB was chosen because:
- Workflow step definitions vary by service; a relational schema would require complex
  joins or JSON columns to accommodate this variation.
- MongoDB Atlas cloud hosting is simpler for the team at this stage.
- The team's familiarity with the Mongoose/Node.js combination is higher.

### 6.4 Microservices (Rejected)

Splitting the backend into separate services (auth service, workflow service, notification
service) was considered. This was rejected because:
- The team is small and the application scope is limited.
- Microservices add operational complexity (service discovery, inter-service auth,
  distributed tracing) that is not justified at this scale.
- A **modular monolith** (single Express server with clearly separated modules) achieves
  the same code organisation benefits without the operational overhead.

### 6.5 Real Payment Gateway (Deferred to future scope)

Integrating Razorpay, Stripe, or a UPI gateway for the ID Card Replacement fee was
considered. This was deferred because:
- Payment integration requires merchant accounts, security reviews, and PCI compliance work.
- A simulated payment step proves the workflow structure without the overhead.
- Real payment integration is explicitly listed in future scope.

---

## 7. MVP Scope and Explicit Exclusions

### 7.1 In MVP Scope

- User authentication: registration, login, logout (JWT-based).
- Role-based access control: student, staff, admin.
- Service catalogue: discoverable list of available services.
- **Bonafide Certificate** workflow: end-to-end (submit → verify → approve → complete).
- **ID Card Replacement** workflow: end-to-end (submit → security review → simulated payment → admin approve → complete).
- **Equipment Booking** workflow: end-to-end (submit → staff review → approve/reject → confirmed/rejected).
- Student dashboard: list of active and completed journeys with status.
- Staff review queue: list of pending steps with approve/reject actions.
- Admin dashboard: cross-workflow visibility, final approval actions.
- Status notifications: in-app status display (not email or push notifications).
- Responsive web UI: works on desktop and mobile browsers.
- Demo seed data: sample users (one per role), services and sample journeys.

### 7.2 Explicit Exclusions from MVP

The following features are intentionally excluded from the initial build and must not
be implemented without explicit approval:

| Excluded Feature | Reason |
|---|---|
| Email or SMS notifications | Requires third-party service integration (SMTP, Twilio, etc.) |
| Real payment gateway | Requires merchant accounts and PCI compliance |
| Document upload / download | File storage (S3, GridFS) adds infrastructure complexity |
| Automated slot conflict detection for bookings | Adds scheduling complexity beyond MVP |
| Bulk approval / batch operations | Not needed for initial scale |
| Reporting and analytics dashboards | Out of MVP scope |
| Password reset via email | Requires email integration |
| OAuth / SSO / institutional LDAP login | Requires institutional IT coordination |
| Multi-institution support | Out of MVP scope |
| Native mobile application | The product is a web application only |
| Audit log / immutable event log | Desirable but deferred |
| Automated testing suite | Important but deferred — not blocking MVP |

---

## 8. Future Scope

Features planned after the MVP is stable and verified:

1. **Email notifications** — Send email updates at each workflow step transition.
2. **Real payment integration** — Replace simulated payment with a real gateway.
3. **Document management** — Allow students to upload supporting documents; allow admins to attach output documents (e.g., the actual bonafide certificate PDF).
4. **Additional workflow types** — Library clearance, fee receipts, hostel allocation, etc.
5. **Slot conflict detection** — Prevent double-bookings for equipment.
6. **Audit trail** — Immutable event log of every status change, with actor and timestamp.
7. **Reporting** — Dashboard charts showing service load, average processing times, rejection rates.
8. **Password reset** — Self-service via email OTP.
9. **SSO integration** — SAML or OAuth integration with the institution's identity provider.
10. **Admin user management** — Admins can create, deactivate and re-assign staff accounts.
11. **Dark mode** — Theme switching in the UI.
12. **Offline capability / PWA** — Service Worker caching for poor-connectivity environments.

---

## 9. Folder Structure

```
uniflow/                          ← Repository root
│
├── .gitignore                    ← Git exclusions (node_modules, .env, build output, etc.)
├── README.md                     ← Project overview and quick-start guide
├── AGENTS.md                     ← Permanent development rules for all contributors
│
├── docs/                         ← All project documentation
│   ├── PROJECT_MEMORY.md         ← THIS FILE — single source of truth
│   ├── ARCHITECTURE.md           ← System architecture, boundaries, data flow
│   ├── API_CONTRACT.md           ← All API endpoints, formats, conventions
│   └── DEVELOPMENT_PROGRESS.md  ← Phase progress, completed work, next steps
│
├── frontend/
│   └── react_app/                ← Vite + React project
│       ├── index.html
│       ├── vite.config.js
│       ├── package.json
│       ├── .env.example          ← Template: VITE_API_BASE_URL=http://localhost:3001
│       └── src/
│           ├── main.jsx          ← React entry point
│           ├── App.jsx           ← Root component with router
│           ├── api/              ← All backend API calls (fetch wrappers)
│           ├── components/       ← Reusable UI components
│           ├── pages/            ← Full pages by role
│           │   ├── auth/         ← Login, Register
│           │   ├── student/      ← Student-facing pages
│           │   └── staff/        ← Staff and admin pages
│           └── router/           ← Route definitions and guards
│
├── backend/
│   └── node_api/                 ← Express project
│       ├── server.js             ← Entry point: creates and starts the Express app
│       ├── package.json
│       ├── .env.example          ← Template: PORT, MONGO_URI, JWT_SECRET, JWT_EXPIRES_IN
│       ├── config/               ← Database connection, environment config
│       ├── models/               ← Mongoose schemas and models
│       ├── routes/               ← Express route definitions
│       ├── controllers/          ← Request handlers (thin: delegate to services)
│       ├── services/             ← Business logic and workflow transitions
│       ├── middleware/           ← Auth (JWT verify) and role guard middleware
│       └── scripts/              ← Seed script for demo data
│
└── database/
    ├── docs/                     ← Schema design documentation
    └── seed/                     ← Seed data JSON files
```

---

## 10. Development Commands

> **Note:** These commands will be valid once Phase 1 (Backend Foundation) is complete.
> They are documented here for planning purposes.

### Prerequisites

- Node.js v18 or higher (v24.14.0 confirmed available)
- npm v9 or higher
- A running MongoDB instance, either:
  - **Local:** MongoDB Community Edition 7.x (install from mongodb.com)
  - **Cloud:** MongoDB Atlas free tier (create at cloud.mongodb.com)

### Backend

```bash
# Move into the backend directory
cd backend/node_api

# Install dependencies (first time, or after pulling new changes)
npm install

# Copy the environment template
cp .env.example .env
# Then edit .env and fill in real values (MONGO_URI, JWT_SECRET, etc.)

# Populate the database with demo data
node scripts/seed.js

# Start the development server (auto-restarts on file changes)
npm run dev

# The API will be available at:
# http://localhost:3001
```

### Frontend

```bash
# Move into the frontend directory
cd frontend/react_app

# Install dependencies
npm install

# Copy the environment template
cp .env.example .env
# Then edit .env: set VITE_API_BASE_URL=http://localhost:3001

# Start the Vite development server
npm run dev

# The app will be available at:
# http://localhost:5173
```

### Running Both Together

Open two terminal windows:

```
Terminal 1: cd backend/node_api  && npm run dev
Terminal 2: cd frontend/react_app && npm run dev
```

---

## 11. Important Design Decisions

### 11.1 One Backend, Two Portals

The React application contains both the student experience and the staff/admin experience.
They are separated by client-side routing and role-based component rendering, but they
consume the **same backend API**.

There is intentionally only one Express server and one MongoDB database.
Do not create a separate backend for the admin portal.

### 11.2 JWT Authentication

Authentication uses JSON Web Tokens (JWT). On login, the server issues a signed token.
The React app stores this token (localStorage or httpOnly cookie) and includes it in the
`Authorization: Bearer <token>` header of every protected API request. The server verifies
the token's signature and extracts the user's role before processing the request.

### 11.3 Role Enforcement on the Backend

The React UI may hide buttons or redirect routes for roles that do not have access.
However, this client-side logic is a UI convenience only — it is not a security boundary.
**All role checks are enforced server-side** in Express middleware. A student who manually
calls an admin endpoint will receive a 403 Forbidden response regardless of what the UI shows.

### 11.4 Workflow State Machine

Every Journey (a running instance of a workflow) has a `status` field. The set of valid
statuses and the allowed transitions between them are defined in the backend service layer.
The backend enforces that only valid transitions can occur (e.g., you cannot move a
journey from "Completed" back to "Pending" through the normal API).

### 11.5 Simulated Payment

The ID Card Replacement workflow includes a payment step. This is implemented as a
database flag (`paymentCompleted: true/false`) that is set by a protected API endpoint.
No real money moves. The UI shows a "Pay Now" button that calls this endpoint.
This design deliberately mimics the real payment integration pattern so that a real
gateway can be connected in future scope without changing the workflow structure.

### 11.6 Environment Variables

All secrets (database credentials, JWT secret key) and environment-specific configuration
(port numbers, API base URLs) are stored in `.env` files that are never committed to
version control. The repository contains `.env.example` files with every required key
listed (with placeholder values) so that new developers know exactly what to configure.

### 11.7 Modular Monolith

The backend is structured as a modular monolith: one Express server with clearly
separated internal modules (routes, controllers, services, models). This gives the
organisational benefits of clean architecture without the operational complexity of
microservices. If the system ever needs to scale to a microservices architecture, the
module boundaries are already in place.

---

## 12. Terminology Glossary

| Term | Definition |
|---|---|
| **Journey** | A running instance of a workflow for a specific student request. The Journey holds the current status, all step records, and the submitted form data. |
| **Workflow** | A template that defines the ordered sequence of steps a service request passes through. Workflows are defined in the database and associated with a Service. |
| **Step** | One stage in a workflow, assigned to a specific role (staff or admin). A step can be approved, rejected, or (in the case of the payment step) confirmed by the student. |
| **Service** | A campus administrative offering listed in the service catalogue (e.g., "Bonafide Certificate"). A service is linked to a workflow definition. |
| **Booking** | A specific record type for the Equipment Booking service. A booking has a date/time slot and an equipment item reference, in addition to the standard workflow status. |
| **Bonafide Certificate** | An official letter issued by the institution confirming that a named student is currently enrolled. |
| **JWT** | JSON Web Token — a compact, signed token used for stateless authentication. The token carries the user's ID and role. |
| **ODM** | Object Data Modelling — the MongoDB equivalent of an ORM (Object Relational Mapping). Mongoose is the ODM used in this project. |
| **Seed data / Seed script** | Demo data and the script that populates it. Run once to create sample users, services, and journeys so the application can be demonstrated without manual data entry. |
| **MVP** | Minimum Viable Product — the smallest working version of the application that demonstrates all three core workflows end-to-end. |
| **Modular monolith** | A single deployable application internally organized into well-separated modules. Contrasted with microservices (separate deployed services) and a "big ball of mud" (no internal structure). |
| **CORS** | Cross-Origin Resource Sharing — a browser security mechanism. The Express server must explicitly allow requests from the React dev server's origin (http://localhost:5173) during development. |
| **HMR** | Hot Module Replacement — Vite's ability to update the browser without a full page reload when a source file changes, making development very fast. |

---

*Last updated: Phase 0 — Repository and Architecture Foundation*
*Next update: Phase 1 — Backend Foundation (after implementation)*
