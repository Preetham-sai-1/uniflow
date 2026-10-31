# UniFlow — Campus Journey Engine

> "Students don't navigate departments. They navigate journeys."

UniFlow is a campus journey engine that streamlines multi-department university processes into unified, guided workflows for students, staff, and administrators.

---

## Repository Structure

```
uniflow/
├── lib/                     # Flutter mobile / multi-platform client
├── test/                    # Flutter unit and widget tests
├── android/                 # Android native runner
├── windows/                 # Windows native runner
├── web/                     # Flutter Web runner
├── frontend/
│   └── react_app/           # React 18 + Vite Web portal (Student, Staff, Admin)
├── backend/
│   └── node_api/            # Node.js + Express REST API (Auth, Requests, Workflows)
└── docs/                    # Architecture, API Contract, and Integration guides
```

---

## 1. Flutter Client (Repository Root)

### Run
1. Install the [Flutter SDK](https://flutter.dev/docs/get-started/install).
2. Open this folder in VS Code or Android Studio.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

### UI Features Included
- Responsive login with role selection (Student, Staff, Admin)
- Named routes and role-specific navigation
- Student home, campus services catalogue, request form, request list, and journey timeline
- Staff request overview, review dialog, and history
- Admin analytics and metrics dashboard
- Profile view and sign out
- Material 3 styling, responsive NavigationBar/NavigationRail, and animated page transitions

### Tests
```bash
flutter test
flutter analyze
```

---

## 2. Backend API (`backend/node_api`)

Node.js and Express REST API powering authentication, service catalogues, request state machines, and notifications.

### Setup & Run
1. Navigate to the backend directory:
   ```bash
   cd backend/node_api
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment:
   ```bash
   copy .env.example .env
   ```
   Configure `.env` with your `MONGO_URI`, `JWT_SECRET`, and `FRONTEND_URL`. Refer to [`backend/node_api/README.md`](backend/node_api/README.md) for details.
4. Seed demo data:
   ```bash
   npm run seed
   ```
5. Start the development server:
   ```bash
   npm run dev
   ```

### Tests
```bash
npm test
```

---

## 3. React Frontend (`frontend/react_app`)

Web portal for students, staff queue management, and administration built with React 18 and Vite.

### Setup & Run
1. Navigate to the frontend directory:
   ```bash
   cd frontend/react_app
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment:
   ```bash
   copy .env.example .env
   ```
   Set `VITE_API_BASE_URL` (default: `http://localhost:3001/api`).
4. Start the development server:
   ```bash
   npm run dev
   ```

### Tests & Build
```bash
npm test
npm run build
```

---

## Documentation

Detailed architectural and API documentation is available in the [`docs/`](docs/) directory:
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — System architecture, state machine, and data models
- [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — Complete REST API contract and endpoint specifications
- [`docs/FLUTTER_BACKEND_INTEGRATION.md`](docs/FLUTTER_BACKEND_INTEGRATION.md) — Integration guide connecting Flutter to the Express backend
- [`docs/DEVELOPMENT_PROGRESS.md`](docs/DEVELOPMENT_PROGRESS.md) — Phase deliverables and implementation tracking
- [`docs/PROJECT_MEMORY.md`](docs/PROJECT_MEMORY.md) — Core project guidelines and scope definitions
