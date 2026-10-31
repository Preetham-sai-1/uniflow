# UniFlow API — Backend

> Node.js + Express REST API for the UniFlow Campus Journey Engine.

---

## Quick Start

### Prerequisites

- Node.js v18 or higher (v24.x confirmed working)
- A MongoDB URI — either:
  - **MongoDB Atlas** (free tier at [cloud.mongodb.com](https://cloud.mongodb.com)) — recommended
  - **Local MongoDB** — install [Community Edition 7.x](https://www.mongodb.com/try/download/community)

### 1. Install dependencies

```powershell
cd backend\node_api
npm install
```

### 2. Configure environment

```powershell
copy .env.example .env
```

Edit `.env` and fill in:

| Variable | Required | Example |
|---|:---:|---|
| `PORT` | Yes | `3001` |
| `NODE_ENV` | Yes | `development` |
| `MONGO_URI` | ✅ Yes | `mongodb+srv://user:pass@cluster.mongodb.net/uniflow` |
| `JWT_SECRET` | ✅ Yes | (generate: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`) |
| `JWT_EXPIRES_IN` | Yes | `7d` |
| `FRONTEND_URL` | Yes | `http://localhost:5173` |
| `BCRYPT_SALT_ROUNDS` | No | `10` |

### 3. Seed demo data

```powershell
npm run seed
```

This populates the database with:
- 1 demo institution (UniFlow Demo University)
- 4 departments (Administration, Computer Science, Security, Facilities)
- 3 demo users (student, staff, admin)
- 3 services (Bonafide Certificate, ID Card Replacement, Equipment Booking)
- 3 workflow definitions

**Demo credentials (development only):**

| Role | Email | Password |
|---|---|---|
| Student | `student@uniflow.edu` | `Demo@1234` |
| Staff | `staff@uniflow.edu` | `Demo@1234` |
| Admin | `admin@uniflow.edu` | `Demo@1234` |

### 4. Start the development server

```powershell
npm run dev
```

API available at `http://localhost:3001`

### 5. Run tests

```powershell
npm test
```

Tests run without a database connection and use a safe test environment (loaded from `tests/.env.test`).

---

## Available Scripts

| Script | Command | Description |
|---|---|---|
| `npm start` | `node src/server.js` | Production start |
| `npm run dev` | `node --watch src/server.js` | Development with auto-reload |
| `npm run seed` | `node scripts/seed.js` | Populate demo data (idempotent) |
| `npm test` | `node --test ...` | Run all automated tests |

---

## Project Structure

```
backend/node_api/
├── src/
│   ├── app.js              ← Express app factory (no DB connection)
│   ├── server.js           ← Entry point: connects DB, starts listener
│   ├── config/
│   │   ├── env.js          ← Zod-validated environment config
│   │   └── database.js     ← Mongoose connect / disconnect
│   ├── models/             ← 7 Mongoose schemas
│   │   ├── Institution.js
│   │   ├── Department.js
│   │   ├── User.js
│   │   ├── Service.js
│   │   ├── Workflow.js
│   │   ├── Request.js      ← Runtime workflow instance with audit log
│   │   └── Notification.js
│   ├── routes/
│   │   ├── index.js        ← Mounts all route groups
│   │   ├── health.routes.js
│   │   └── auth.routes.js
│   ├── controllers/
│   │   ├── health.controller.js
│   │   └── auth.controller.js
│   ├── services/
│   │   └── auth.service.js ← Password hashing, JWT, user lookup
│   ├── middleware/
│   │   ├── auth.middleware.js    ← JWT verification → req.user
│   │   ├── role.middleware.js    ← requireRole(...roles) factory
│   │   ├── validate.middleware.js ← Zod schema validation
│   │   └── error.middleware.js  ← Global error handler + 404
│   ├── validators/
│   │   └── auth.validators.js   ← Zod schemas for auth endpoints
│   └── utils/
│       ├── AppError.js          ← Structured error class
│       └── asyncHandler.js      ← Async route wrapper
├── scripts/
│   └── seed.js             ← Idempotent demo data seeder
├── tests/
│   ├── .env.test           ← Test-only env values (safe to commit)
│   ├── app.test.js         ← App initialization tests
│   ├── health.test.js      ← Health endpoint + error handling tests
│   ├── models.test.js      ← Schema validation tests (no DB needed)
│   └── auth.test.js        ← Auth validation + token error tests (no DB needed)
├── .env.example            ← Environment variable template
└── package.json
```

---

## Implemented Endpoints (Phase 1 & 2)

| Method | Path | Auth | Access Role | Status |
|---|---|---|---|---|
| GET | `/api/health` | Public | Any | ✅ Implemented |
| POST | `/api/auth/register` | Public | Any | ✅ Implemented |
| POST | `/api/auth/login` | Public | Any | ✅ Implemented |
| GET | `/api/auth/me` | Bearer JWT | Authenticated | ✅ Implemented |
| GET | `/api/departments` | Public / Bearer JWT | Any | ✅ Implemented |
| GET | `/api/services` | Bearer JWT | Authenticated | ✅ Implemented |
| GET | `/api/services/:id` | Bearer JWT | Authenticated | ✅ Implemented |
| POST | `/api/services` | Bearer JWT | `admin` | ✅ Implemented |
| POST | `/api/requests` | Bearer JWT | `student` | ✅ Implemented |
| GET | `/api/requests` | Bearer JWT | Authenticated | ✅ Implemented |
| GET | `/api/requests/:id` | Bearer JWT | Authenticated (student: own only) | ✅ Implemented |
| PATCH | `/api/requests/:id/payment` | Bearer JWT | `student` (own only) | ✅ Implemented |
| PATCH | `/api/requests/:id/steps/:stepIndex/approve` | Bearer JWT | `staff`, `admin` | ✅ Implemented |
| PATCH | `/api/requests/:id/steps/:stepIndex/reject` | Bearer JWT | `staff`, `admin` | ✅ Implemented |
| GET | `/api/staff/queue` | Bearer JWT | `staff`, `admin` | ✅ Implemented |
| GET | `/api/admin/stats` | Bearer JWT | `admin` | ✅ Implemented |
| GET | `/api/admin/requests` | Bearer JWT | `admin` | ✅ Implemented |
| GET | `/api/notifications` | Bearer JWT | Authenticated | ✅ Implemented |
| PATCH | `/api/notifications/:id/read` | Bearer JWT | Authenticated | ✅ Implemented |
| PATCH | `/api/notifications/read-all` | Bearer JWT | Authenticated | ✅ Implemented |

---

## Architecture Notes

- **app.js vs server.js** — The Express app is created in `app.js` without connecting
  to the database. `server.js` connects to MongoDB and then starts the listener.
  This separation allows tests to import the app without a DB connection.

- **Error envelope** — All errors return `{ success: false, error: { code, message, details? } }`.
  See `docs/API_CONTRACT.md` Section 5 for the full specification.

- **Role enforcement** — Roles are read exclusively from the verified JWT payload (`req.user.role`).
  No role claim from any request body is ever trusted.

- **Workflow State Machine** — Managed centrally in `src/services/request.service.js`. Enforces Rule 5
  (students cannot approve their own requests), validates step role authorization, records tamper-evident
  audit log entries, and progresses runtime steps for all three MVP workflows.

- **Password security** — bcrypt with configurable salt rounds (default 10).
  `passwordHash` is excluded from all Mongoose queries by default (`select: false`).

---

## Known Limitations

- Full end-to-end integration tests (register → login → submit request → approve → complete)
  require a live MongoDB connection and are planned for Phase 5.
- The seed script requires a real MongoDB connection.

---

*UniFlow API — Phase 2 & Phase 5 verified (84 automated tests passing)*
