# UniFlow — React Frontend

> Web client for **UniFlow — The Campus Journey Engine**.
> "Students don't navigate departments. They navigate journeys."

---

## 1. Technology Stack

- **Framework:** React 18 with Vite
- **Routing:** React Router v6
- **HTTP Client:** Axios with centralized interceptors
- **State Management:** React Context API (`AuthContext`)
- **Icons:** `lucide-react`
- **Testing:** Vitest + React Testing Library + JSDOM

---

## 2. Directory Structure

```
frontend/react_app/
├── index.html
├── vite.config.js
├── package.json
├── .env.example
├── README.md
├── src/
│   ├── main.jsx                     ← React root entry point
│   ├── App.jsx                      ← Root wrapper (BrowserRouter + AuthProvider)
│   ├── api/
│   │   ├── httpClient.js            ← Centralized Axios instance with auth interceptors
│   │   ├── authApi.js               ← Authentication API methods
│   │   ├── servicesApi.js           ← Campus Services Catalogue API client
│   │   ├── requestsApi.js           ← Student Requests & Payment API client
│   │   ├── staffApi.js              ← Staff Review Queue API client
│   │   ├── adminApi.js              ← Admin Statistics & Oversight API client
│   │   └── index.js                 ← Unified API exports
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.jsx           ← Reusable button with loading spinner
│   │   │   ├── Input.jsx            ← Form input with validation & password toggle
│   │   │   ├── Alert.jsx            ← Error / warning / success banners
│   │   │   └── Components.jsx       ← Badge, StatusBadge, Card, Spinner components
│   │   └── navigation/
│   │       └── Navbar.jsx           ← Responsive, role-aware navigation header
│   ├── context/
│   │   └── AuthContext.jsx          ← Auth state, session persistence, login/register/logout
│   ├── layouts/
│   │   ├── AuthLayout.jsx           ← Centered layout for auth pages
│   │   └── AppLayouts.jsx           ← StudentLayout & StaffAdminLayout
│   ├── pages/
│   │   ├── auth/
│   │   │   ├── Login.jsx            ← Login form with validation & role redirection
│   │   │   └── Register.jsx         ← Student-only registration form
│   │   ├── student/
│   │   │   ├── StudentDashboard.jsx ← Student dashboard with active journeys table & metrics
│   │   │   ├── ServiceCatalogue.jsx ← Campus service directory with category filtering
│   │   │   ├── RequestForm.jsx      ← Guided workflow request forms for MVP services
│   │   │   └── RequestDetail.jsx    ← Live journey stepper timeline & payment simulation
│   │   ├── staff/
│   │   │   └── StaffQueue.jsx       ← Staff review queue with approval/rejection modal
│   │   ├── admin/
│   │   │   └── AdminDashboard.jsx   ← Institutional control center with live analytics
│   │   ├── Unauthorized.jsx         ← 403 Access Denied page
│   │   └── NotFound.jsx             ← 404 Not Found page
│   ├── routes/
│   │   ├── AppRoutes.jsx            ← Route tree with role guards
│   │   ├── ProtectedRoute.jsx       ← Authentication barrier
│   │   └── RoleRoute.jsx            ← Role-based access barrier
│   ├── styles/
│   │   └── index.css                ← Unified UniFlow design system
│   └── test/
│       ├── setup.js                 ← Vitest DOM matchers setup
│       ├── auth.test.jsx            ← Auth form validation & API integration tests
│       ├── routes.test.jsx          ← Route guard & RBAC enforcement tests
│       └── workflows.test.jsx       ← Phase 4 workflow UI & interaction tests
```

---

## 3. Environment Configuration

Copy the example environment file:

```powershell
copy .env.example .env
```

| Variable | Default Value | Description |
|---|---|---|
| `VITE_API_BASE_URL` | `http://localhost:3001/api` | Base URL for backend Express REST API |

> **Security Note:** Secrets like `JWT_SECRET` or database credentials must **never** be placed in the frontend `.env` file. Vite bundles `VITE_` variables directly into client-side JavaScript.

---

## 4. Development & Testing Commands

All commands run from `frontend/react_app/`:

```powershell
# Install dependencies
npm install

# Start Vite development server (http://localhost:5173)
npm run dev

# Run automated unit and integration tests (Vitest)
npm test

# Run tests once without watch mode
npm run test:run

# Build production bundle to dist/
npm run build

# Preview production build locally
npm run preview
```

---

## 5. Completed Workflows & Verification

### The Three MVP Workflows (Phase 4):

1. **Bonafide Certificate:**
   - Student selects purpose, copies, and additional notes in guided form.
   - Submits request to `POST /api/requests`.
   - Department verification step appears in Staff Queue (`GET /api/staff/queue`).
   - Staff approves step (`PATCH /api/staff/requests/:id/steps/0/approve`).
   - Admin approves step (`PATCH /api/requests/:id/steps/1/approve`).
   - Journey reaches terminal `COMPLETED` status with green completion banner.

2. **ID Card Replacement:**
   - Student selects reason (Lost, Stolen, Damaged), provides contact number, and police report ref if stolen.
   - Security officer verifies and approves step 0.
   - Status transitions to `PAYMENT_REQUIRED`.
   - Student sees prominent Payment Card on Journey Detail page with "Pay Now (Simulate)" button.
   - Clicking "Pay Now" calls `PATCH /api/requests/:id/payment` -> updates status to `ADMIN_APPROVAL_PENDING`.
   - Admin approves final step -> status transitions to `COMPLETED`.

3. **Equipment Booking:**
   - Student chooses equipment (camera, projector), purpose, start date/time, and end date/time.
   - Facility staff reviews in Staff Queue.
   - Staff approves -> status transitions to `BOOKING_CONFIRMED`.
   - Rejections at any point require a mandatory reason, terminating the request with `REJECTED` and logging the audit comment.

---

## 6. Automated Test Suite Results

```
Test Files:  3 passed (3)
Tests:       27 passed (27)
Duration:    ~5.4s
```

All 27 automated tests pass:
- Auth validation, login flow, student registration lock: 7 tests passed.
- Route guards, unauthenticated redirects, role RBAC: 12 tests passed.
- Service catalogue, workflow forms, live stepper timeline, simulated payment, staff review modal, admin metrics: 8 tests passed.
