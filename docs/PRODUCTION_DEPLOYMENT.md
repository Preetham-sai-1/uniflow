# UniFlow — Production Deployment & Configuration Guide

> **Preparation Document Only** — This document details the exact configuration, prerequisites, commands, and security requirements to deploy the UniFlow system to production. No public deployments have been executed during this preparation phase.

---

## 1. Production Architecture Overview

The UniFlow production architecture follows a strict separation of concerns across enterprise-grade hosting platforms:

```
                      ┌──────────────────────────────────────────────┐
                      │              End Users / Clients             │
                      └───────┬──────────────────────────────┬───────┘
                              │                              │
                   HTTPS (Web Browser)              HTTPS (Mobile App)
                              │                              │
                              ▼                              ▼
                 ┌─────────────────────────┐   ┌───────────────────────────┐
                 │     Firebase Hosting    │   │  Android Production APK   │
                 │   (Flutter Web Assets)  │   │   (Keystore Signed APK)   │
                 └────────────┬────────────┘   └─────────────┬─────────────┘
                              │                              │
                              │   HTTPS API Requests         │
                              └──────────────┬───────────────┘
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │    Render Web Service     │
                               │  (Node.js / Express API)  │
                               │  uniflow-jiiw.onrender    │
                               └─────────────┬─────────────┘
                                             │
                                   TLS (Mongoose / SRV)
                                (Render Outbound IP CIDRs)
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │       MongoDB Atlas       │
                               │      (uniflow_prod)       │
                               └───────────────────────────┘
```

| Component | Technology | Target Platform | Inbound Protocol | Port / Binding |
|---|---|---|---|---|
| **Web Portal** | Flutter Web (HTML5/Wasm/CanvasKit) | **Firebase Hosting** | HTTPS (TLS 1.3) | Default CDN |
| **Backend API** | Node.js (v18+) / Express / Mongoose | **Render** (`uniflow-jiiw`) | HTTPS (TLS 1.3) | `0.0.0.0:$PORT` |
| **Database** | MongoDB (v7+) Replica Set | **MongoDB Atlas** (`uniflow_prod`) | TLS / TCP | Default (27017) |
| **Mobile App** | Flutter Native Release APK | **Android Device** | HTTPS (TLS 1.3) | Native Mobile |

---

## 2. Firebase Hosting Setup (Flutter Web)

### 2.1 Prerequisites
1. Install the Firebase CLI on your administrative workstation:
   ```bash
   npm install -g firebase-tools
   ```
2. Log in with your institutional or project Google account:
   ```bash
   firebase login
   ```
   *(Ensure token credentials are stored securely and never printed to console logs).*

### 2.2 Project Configuration
1. The Firebase project is configured:
   - **Project ID:** `uniflow-c3334`
   - **Alias:** `production` (and `default`)
2. The project alias configuration is committed in `.firebaserc`:
   ```json
   {
     "projects": {
       "default": "uniflow-c3334",
       "production": "uniflow-c3334"
     }
   }
   ```
3. The root configuration file `firebase.json` defines hosting parameters:
   - **Public Directory:** `build/web`
   - **SPA Rewrites:** All paths `**` redirect to `/index.html`
   - **Cache Headers:**
     - `/index.html` → `no-cache, no-store, must-revalidate` (guarantees instant deployment updates).
     - `**/*.@(js|css|wasm)` → `public, max-age=31536000, immutable` (optimal CDN performance for cache-busted Flutter bundles).
     - Security Headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, `Strict-Transport-Security: max-age=31536000`.

### 2.3 Flutter Web Release Build Command
Compile the Flutter Web client targeting the Render production API:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://uniflow-jiiw.onrender.com/api
```

### 2.4 Firebase Deployment Command
Deploy static web assets to Firebase Hosting:
```bash
firebase deploy --only hosting -P production
```
Hosting URLs will be available at:
- `https://uniflow-c3334.web.app`
- `https://uniflow-c3334.firebaseapp.com`

---

## 3. Render Backend Deployment (Node.js API)

### 3.1 Service Overview
The Express API is hosted as a Render Web Service (`https://uniflow-jiiw.onrender.com`) connected to the GitHub repository.

### 3.2 Service Configuration
- **Repository:** `Preetham-sai-1/uniflow`
- **Branch:** `master`
- **Root Directory:** `backend/node_api`
- **Runtime:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start` *(resolves to `node src/server.js`)*
- **Health Check Path:** `/api/health`
- **Auto-Deploy:** `Yes`
- **Instance Type:** Starter ($7/mo) recommended for live production (always-on, no cold starts).

### 3.3 Networking & Process Binding
- Express binds explicitly to `0.0.0.0` and listens on `process.env.PORT` injected by Render.
- Health check endpoint `GET /api/health` returns HTTP 200 with `{ "success": true, "data": { "status": "operational" } }`. Render polls this before routing traffic.
- Database seeds do **not** run automatically on startup.

---

## 4. Production Environment Variables Audit

All environment variables are validated at backend startup via Zod in `backend/node_api/src/config/env.js`. The server fails fast if any variable is missing or invalid.

### 4.1 Production Environment Inventory

| Variable Name | Required | Example Production Value | Purpose / Constraints |
|---|---|---|---|
| `PORT` | Auto | *(Injected by Render, e.g. 10000)* | Port assigned dynamically by Render container runner. |
| `NODE_ENV` | Yes | `production` | Enables production caching, disables verbose morgan logs, activates strict CORS origin filtering. |
| `MONGO_URI` | Yes | `mongodb+srv://uniflow_prod_svc:<secret>@cluster0.abcde.mongodb.net/uniflow_prod?retryWrites=true&w=majority` | Authenticated MongoDB Atlas SRV connection string targeting `uniflow_prod` with TLS encryption. |
| `JWT_SECRET` | Yes | *(64-byte random hex)* | Cryptographic HMAC secret for signing and verifying tokens. Minimum 32 characters. Generate with `openssl rand -hex 64`. |
| `JWT_EXPIRES_IN`| No | `7d` | Token validity duration. |
| `FRONTEND_URL` | Yes | `https://uniflow-c3334.web.app` | Canonical production Firebase Hosting origin allowed to make CORS requests. |
| `FLUTTER_WEB_URL`| Yes | `https://uniflow-c3334.firebaseapp.com` | Secondary production Firebase Hosting domain or custom domain. |
| `BCRYPT_SALT_ROUNDS`| No| `10` | Password hashing work factor (default 10). |

> [!CAUTION]
> **Secret Hygiene Rules:**
> 1. Never commit `.env` or paste real connection strings into markdown or source code.
> 2. Use Render's **Environment** dashboard tab to add production key-value pairs securely.
> 3. Never reuse development database passwords or development JWT secrets in production.

---

## 5. MongoDB Atlas Network Access & Least Privilege

To adhere to strict zero-trust security principles, **universal database access (`0.0.0.0/0`) is strictly prohibited**. Only Render's designated outbound IP ranges may be whitelisted.

### 5.1 Retrieving Render Outbound IP Ranges
1. In the Render Dashboard, open your Web Service.
2. Click **Connect** (located at the top right of the service overview).
3. Select the **Outbound** tab.
4. Render displays the dedicated static outbound IPv4 addresses and CIDR blocks for your service's region.
5. Copy these addresses/CIDRs for allowlisting in MongoDB Atlas.

### 5.2 Atlas IP Whitelisting Procedure (CIDR Entries)
1. Log in to [MongoDB Atlas Console](https://cloud.mongodb.com/).
2. Select your Project and navigate to **Security** > **Network Access**.
3. Under the **IP Access List** tab, click **Add IP Address**.
4. Enter each Render outbound IP / CIDR block individually with a descriptive comment (e.g. `Render Outbound Node 1`).
5. Ensure `0.0.0.0/0` is **NOT** present.

### 5.3 Database User Least-Privilege Role Scoping
Do not use administrative or unrestricted database credentials in production:
1. In MongoDB Atlas, go to **Security** > **Database Access**.
2. Click **Add New Database User**.
3. Authentication Method: **Password** (generate a cryptographically secure password with 32+ characters).
4. Under **Database User Privileges**:
   - Assign the **`readWrite`** role scoped **strictly to the `uniflow_prod` database** (`readWrite@uniflow_prod`).
   - Do **NOT** assign `atlasAdmin`, `readWriteAnyDatabase`, or `clusterMonitor`.
5. Under **Restrictions**: Optionally restrict user connection exclusively to the UniFlow production cluster.
6. Click **Add User**.
7. Formulate the production connection string:
   ```
   mongodb+srv://<username>:<password>@<cluster-host>/uniflow_prod?retryWrites=true&w=majority
   ```

---

## 6. Production Database Initialization & Administrator Provisioning

The production database (`uniflow_prod`) is completely separated from the local development database (`uniflow`). Demo student accounts, demo staff accounts, and test requests must **never** be populated in production.

### 6.1 Database State & Initial Verification
Inspect the target database collections before running initialization:
- `institutions`: 0 records
- `departments`: 0 records
- `services`: 0 records
- `workflows`: 0 records
- `users`: 0 records
- `requests`: 0 records
- `notifications`: 0 records

### 6.2 Idempotent Production Initialization
The script `backend/node_api/scripts/init-prod.js` seeds the essential structural foundation:

```bash
# Execute against the production database:
cd backend/node_api
MONGO_URI="<production-atlas-uri>" npm run init:prod
```

**What it creates:**
1. **Institution:** `UniFlow Campus` (code: `UFC`, slug: `uniflow-campus`, configurable via `INSTITUTION_NAME`, `INSTITUTION_CODE`, `INSTITUTION_SLUG`).
2. **Departments:** Administration (`ADMIN`), Computer Science (`CS`), Security (`SEC`), Facilities (`FAC`).
3. **Services:**
   - *Bonafide Certificate* (Academic, responsible: ADMIN)
   - *ID Card Replacement* (Identity, responsible: SEC, with payment step)
   - *Equipment Booking* (Resources, responsible: FAC)
4. **Workflows:** Multi-step approval templates linked to each service.
5. **Index Synchronization:** Automatically synchronizes all unique and compound indexes across all 7 collections.

**Production Safety Guarantees:**
- **Zero Demo Accounts:** No student, staff, or demo accounts are created.
- **Zero Mock Requests:** No fake requests, test transactions, or notifications are generated.
- **Idempotency:** Checks existence by unique slugs/codes before inserting. Existing custom records are preserved without overwrite.
- **Credential Safety:** Never logs or outputs connection strings or credentials.

### 6.3 Secure Administrator Provisioning
Public registration (`POST /api/auth/register`) enforces `role: 'student'`. Staff and Administrator accounts cannot register publicly. Provision the initial administrator account using `scripts/create-admin.js`.

#### Method A: Interactive CLI Prompt (Recommended)
```bash
cd backend/node_api
MONGO_URI="<production-atlas-uri>" npm run create-admin
```
The script prompts interactively for:
1. `Administrator Full Name`
2. `Administrator Email`
3. `Administrator Password` (masked input with `*`, min 8 characters)

#### Method B: Environment Variables (Automated / Container)
```bash
cd backend/node_api
ADMIN_NAME="Dr. Sarah Johnson" \
ADMIN_EMAIL="admin@uniflow.edu" \
ADMIN_PASSWORD="<YourStrongRandomPassword>" \
MONGO_URI="<production-atlas-uri>" \
node scripts/create-admin.js
```

**Provisioning Security Guarantees:**
- Passwords are encrypted with `bcrypt` (using configured salt rounds). Plaintext is never stored in MongoDB.
- Passwords are never committed to Git or printed in console logs.
- Re-run protection: Aborts immediately if an account with that email already exists.
- The administrator is assigned `role: 'admin'`, associated with the active institution, and assigned to the `ADMIN` department.

### 6.4 Safe Repeat Execution
Both `init:prod` and `create-admin` are safe to re-execute:
- Running `init:prod` on an already-initialized database logs `ℹ Existing <record> preserved` and makes zero destructive modifications.
- Running `create-admin` with an existing administrator email logs an abort message and leaves the account untouched.

### 6.5 Recovery & Rollback
- If an initialization error occurs before completion, re-running `npm run init:prod` resumes from the missing record.
- In the event of data corruption, restore the cluster from a MongoDB Atlas point-in-time cloud backup (Cluster > **Backup** > **Restore**).

---

## 7. Production CORS & Security Controls

### 7.1 Backend CORS Enforcement
In `backend/node_api/src/app.js`:
- In `NODE_ENV=production`, development origins (`localhost`, `127.0.0.1`, ephemeral development ports) are excluded.
- The CORS allowlist strictly permits `env.FRONTEND_URL` and `env.FLUTTER_WEB_URL`.
- Non-browser clients (such as the native Android mobile app or server-to-server health probes) send no `Origin` header and are permitted through JWT verification.
- Wildcards (`*`) are disallowed.

### 7.2 HTTPS & TLS Requirements
- All API communication in production must use `https://`.
- Render terminates TLS at the edge with automated Let's Encrypt certificates and auto-renews them.
- Firebase Hosting provisions TLS automatically across Google's edge CDN.
- Security headers are applied by Express via `helmet()` (`HSTS`, `X-Content-Type-Options`, `Content-Security-Policy`).

### 7.3 Android Network Security Configuration
- The file `android/app/src/main/res/xml/network_security_config.xml` includes `<base-config cleartextTrafficPermitted="false" />`, blocking cleartext HTTP for any domain not explicitly listed.
- For production releases, all API calls target `https://uniflow-jiiw.onrender.com/api`. Android rejects cleartext HTTP attempts automatically.

---

## 8. Production Android Release APK Build

To generate the final production Android APK pointing to the Render API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://uniflow-jiiw.onrender.com/api
```

- **Output:** `build/app/outputs/flutter-apk/app-release.apk`
- **Application ID:** `com.uniflow.app`
- **Version:** `1.0.0`
- **Keystore / Signing:** For Google Play deployment, configure `android/key.properties` with an institutional upload keystore as documented in official Flutter documentation.

---

## 9. Production Smoke-Test Checklist

After completing deployment of both Firebase Hosting and Render, execute this verification runbook:

1. **API Health Check:**
   - Execute: `curl -s https://uniflow-jiiw.onrender.com/api/health | jq .`
   - Expect: HTTP 200, `"status": "operational"`.
2. **Web Portal Access:**
   - Open `https://uniflow-c3334.web.app` in a clean browser session.
   - Verify UniFlow logo and branding render cleanly without CORS errors.
3. **Login Form Validation:**
   - Verify fields start blank.
   - Verify zero role selectors appear.
4. **Primary Administrator Access:**
   - Sign in with the provisioned administrator credentials.
   - Verify automatic redirection to `Administrative Executive Portal`.
   - Verify metrics reflect live database counts (0 active requests initially).
5. **Session Restoration & Logout:**
   - Refresh the browser while logged in; verify session restores seamlessly without returning to login.
   - Click Sign Out; verify token is deleted and user is returned to the clean login screen.

---

## 10. Rollback Procedures

If an anomaly is detected post-deployment:

### 10.1 Firebase Hosting Rollback
Firebase stores historical deployment versions:
```bash
# List historical releases
firebase hosting:channel:list

# Instant rollback via Firebase Console or CLI
firebase hosting:rollback
```
Rollback takes effect globally within seconds.

### 10.2 Render Backend Rollback
1. Open the Render project dashboard.
2. Select the `uniflow-api` service > **Events** (or **Deploys**).
3. Locate the previous verified deployment.
4. Click the three dots (...) and select **Rollback to this deploy**.
5. Render immediately restores and routes ingress traffic to the previous deployment image without rebuild delay.

### 10.3 Database Rollback
- MongoDB Atlas provides continuous point-in-time cloud backups on M10+ tiers.
- In the Atlas Console: Select Cluster > **Backup** > **Restore** > Choose point-in-time snapshot.

---

## 11. Cost & Billing Summary

| Service | Tier / Plan | Monthly Cost | Static Outbound IP Included? |
|---|---|---|---|
| **Render Web Service (API)** | Free Tier *(Evaluation / Staging)* | **$0.00** | **Yes** (Free in regional cluster) |
| **Render Web Service (API)** | Starter Tier *(Recommended Production)* | **$7.00 / mo** | **Yes** (Always-on, no cold starts) |
| **Firebase Hosting (Web UI)** | Spark Plan (Free) | **$0.00** | N/A (Global Google Edge CDN) |
| **MongoDB Atlas (Database)** | Shared / M10+ Tier | Free / ~$57 / mo | N/A (Secured via Render CIDR whitelist) |

**Cost Optimization:**
Switching from Railway to Render eliminates the requirement for Railway's Pro plan ($20/month base subscription), saving ongoing hosting fees while preserving strict CIDR-level firewall protection in MongoDB Atlas.
