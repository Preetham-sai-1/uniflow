# AGENTS.md — UniFlow Development Rules

> These rules apply permanently to all contributors, sessions, and AI agents working
> on the UniFlow codebase. They are not suggestions. Do not deviate from them without
> an explicit architectural review documented in `docs/ARCHITECTURE.md`.

---

## 1. Architectural Boundaries

**React owns presentation and client-side interaction.**
- React components render UI and manage local form state.
- React calls the backend API; it does not contain business logic.
- React enforces role-based UI visibility as a convenience — not as a security boundary.

**Node.js / Express owns business logic and workflow transitions.**
- All workflow state machine logic lives in Express service modules.
- All input validation and sanitisation happens in Express middleware or service layer.
- No business rules may live in the frontend.

**MongoDB owns persistent application data.**
- All application state that must survive a page refresh is stored in MongoDB via Mongoose.
- Mongoose schemas define the authoritative shape and validation rules for all documents.

**Rule:** If you are unsure which layer owns a piece of logic, the answer is almost
always the backend. Move logic towards the backend, not away from it.

---

## 2. Single Backend, Single API Contract

Both the student portal and the staff/admin portal use **one backend server** and **one API**.

- Do not create a separate Express server for the admin portal.
- Do not duplicate routes with different access controls in separate files.
- Use role-based middleware to restrict access to specific routes.
- `docs/API_CONTRACT.md` is the single source of truth for all endpoints.

---

## 3. Secrets and Environment Variables

**Never hard-code secrets or database credentials in source code.**

This includes (but is not limited to):
- MongoDB connection strings (`MONGO_URI`)
- JWT secret keys (`JWT_SECRET`)
- API keys for any third-party service

All such values must:
1. Be stored in a `.env` file at runtime.
2. Have their key listed (without value) in a `.env.example` file.
3. Be loaded via the `dotenv` package in the backend entry point.
4. Be loaded via Vite's built-in env handling in the frontend (prefix `VITE_`).

**Never commit `.env` files.** The root `.gitignore` must always exclude them.
If a secret is accidentally committed, treat it as compromised and rotate it immediately.

---

## 4. Input Validation

**Validate all user-supplied input on the backend.**

- Client-side validation is a UX feature, not a security guarantee.
- The backend must validate and sanitise all request body fields, path parameters, and query strings.
- Validation errors must return HTTP 400 with the `VALIDATION_ERROR` error code and a `details` array.
- The format is defined in `docs/API_CONTRACT.md`.

---

## 5. Role-Based Authorization

**Use role-based authorization for all protected operations.**

- Every route that is not public must apply the `authenticate` middleware.
- Every route that is role-restricted must apply the `requireRole(role)` middleware after `authenticate`.
- Role checks happen in middleware — not in controllers or services.
- Never trust the client's claim of its own role. The JWT payload is the authoritative source.

**A student must never be able to approve their own requests.**

This is enforced at the service layer:
- When a workflow step is actioned, the backend verifies that `req.user.id !== journey.studentId`.
- If they match, return 403 Forbidden.

---

## 6. Workflow State Machine

**Only valid status transitions are allowed.**

The permitted workflow transitions are defined in `docs/ARCHITECTURE.md` (Section 7).

- The service layer enforces the state machine.
- Any request to transition a journey to an invalid next status returns HTTP 400 with `INVALID_TRANSITION`.
- Completed and rejected journeys are terminal — they cannot be reactivated through the normal API.
- Every transition records: actor ID, comment (mandatory for rejections), and timestamp.

---

## 7. Documentation Discipline

**Update documentation when architecture or API contracts change.**

- If you add, modify, or remove an endpoint, update `docs/API_CONTRACT.md` in the same commit.
- If you change a folder structure or layer boundary, update `docs/ARCHITECTURE.md`.
- If you complete a phase deliverable, update `docs/DEVELOPMENT_PROGRESS.md`.
- Never let documentation describe a system that no longer matches the code.

**Do not claim tests passed unless they were actually run.**

- An endpoint is ✅ IMPLEMENTED in `API_CONTRACT.md` only after it has been built
  **and** manually verified (or covered by an automated test that was actually executed).
- Do not pre-emptively mark deliverables as complete.

---

## 8. Preserving Working Functionality

**Preserve existing working functionality in every phase.**

Before modifying any working code:
1. Understand what it does and why it works.
2. Confirm the change is necessary.
3. Verify the existing behaviour is preserved after the change.

Do not refactor code that is working correctly unless the refactor is specifically approved.
Do not delete files that contain working functionality without explicit approval.

---

## 9. Code Simplicity

**Prefer simple, maintainable implementations over unnecessary abstraction.**

- If a function is under 30 lines and does one thing, it does not need to be split.
- If a pattern solves the problem in a straightforward way, do not invent a pattern that
  is more generic but harder to read.
- Do not introduce design patterns (factories, decorators, strategy objects) speculatively.
  Introduce them when the code actually needs them.
- The project is a modular monolith. Do not introduce microservice patterns.

---

## 10. MVP Scope

**Do not add unapproved features outside the MVP.**

The MVP scope is defined in `docs/PROJECT_MEMORY.md` (Section 7).
The explicit exclusions list must be respected.

Features not in the MVP scope must not be built, even if building them seems easy.
If a feature is genuinely needed, document the case and get explicit approval before building it.

---

## 11. Error Handling

**All API errors must use the standard error format.**

The format is defined in `docs/API_CONTRACT.md` (Section 5).

- Never expose stack traces to the client in production.
- Never return an unhandled Express error (500 with an HTML error page).
- All `async` route handlers must be wrapped in `try/catch` or use an async error wrapper.
- Errors are passed to Express's global error handler via `next(err)`.

---

## 12. No Unnecessary Dependencies

**Install only packages that are needed and justified.**

Before adding a new npm package:
1. Confirm the functionality cannot reasonably be implemented without it.
2. Check that it is actively maintained and widely used.
3. Note it in the relevant `package.json` with a clear understanding of why it was added.

Do not install testing frameworks, ORMs, or infrastructure tools that are not part of the approved stack.

---

## 13. Git and Version Control

- The `.gitignore` at the repository root must always exclude: `node_modules/`, `.env`, build output, editor settings, OS files.
- Commit messages must be descriptive (e.g., `feat: add journey submit endpoint` not `update`).
- Do not force-push to the main branch.
- Do not commit commented-out code. Remove it or leave a clear TODO comment with a GitHub issue reference.

---

*This file does not change during normal development. Propose amendments through
an architectural review. Document the decision in `docs/ARCHITECTURE.md` if approved.*
