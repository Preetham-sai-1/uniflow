# UniFlow — Production Deployment & Configuration Guide

> **Preparation Document Only** — This document details the exact configuration, prerequisites, commands, and security requirements to deploy the UniFlow system to production. No public deployments have been executed during this preparation phase.

---

## 1. Production Architecture Overview

The UniFlow production architecture follows a separation of concerns across enterprise-grade hosting platforms:

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
                               │     Railway Web Service   │
                               │  (Node.js / Express API)  │
                               └─────────────┬─────────────┘
                                             │
                                   TLS (Mongoose / SRV)
                                (Railway Static Outbound IPs)
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │       MongoDB Atlas       │
                               │   (M10+ Replica Cluster)  │
                               └───────────────────────────┘
```

| Component | Technology | Target Platform | Inbound Protocol | Port / Binding |
|---|---|---|---|---|
| **Web Portal** | Flutter Web (HTML5/Wasm/CanvasKit) | **Firebase Hosting** | HTTPS (TLS 1.3) | Default CDN |
| **Backend API** | Node.js (v18+) / Express / Mongoose | **Railway** | HTTPS (TLS 1.3) | `0.0.0.0:$PORT` |
| **Database** | MongoDB (v7+) Replica Set | **MongoDB Atlas** | TLS / TCP | Default (27017) |
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
Compile the Flutter Web client targeting the Railway production API:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://<YOUR-RAILWAY-SERVICE-NAME>.up.railway.app/api
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

## 3. Railway Backend Deployment (Node.js API)

### 3.1 Modern Railway Architecture (Railpack)
Current Railway platform standards use **Railpack** as the default zero-config builder for Node.js services. Legacy Config as Code (`railway.json` / `NIXPACKS`) has been retired. Configure the service directly in the Railway dashboard as outlined below.

### 3.2 Service Settings
1. Log in to [Railway](https://railway.app).
2. Create a **New Project** and select **Deploy from GitHub repo**.
3. Select repository: **`Preetham-sai-1/uniflow`**.
4. In the service **Settings** panel, configure:
   - **Root Directory:** `/backend/node_api`
   - **Builder:** `Railpack` (default)
   - **Build Command:** *(Leave default — Railpack detects `package.json` and runs `npm install`)*
   - **Start Command:** `node src/server.js`
   - **Watch Paths:** `/backend/node_api/**`
   - **Healthcheck Path:** `/api/health`
   - **Healthcheck Timeout:** `100` seconds
   - **Restart Policy:** On Failure (Max retries: 10)

### 3.3 Networking & Process Binding
- In `backend/node_api/src/server.js`, the Express server binds explicitly to `0.0.0.0` and listens on `process.env.PORT` (automatically allocated by Railway).
- The health check endpoint is at `GET /api/health` and returns HTTP 200 with `{ "success": true, "data": { "status": "operational" } }`. Railway verifies this endpoint before cutting over traffic.
- Seeds do **not** run automatically on startup. The database seeding script (`scripts/seed.js`) is an explicit administrative utility only.

---

## 4. Production Environment Variables Audit

All environment variables are validated at backend startup via Zod in `backend/node_api/src/config/env.js`. The server will fail fast if any variable is missing or invalid.

### 4.1 Production Environment Inventory

| Variable Name | Required | Example Production Value | Purpose / Constraints |
|---|---|---|---|
| `PORT` | Auto | *(Injected by Railway)* | Port assigned dynamically by Railway container runner. |
| `NODE_ENV` | Yes | `production` | Enables production caching, disables verbose morgan logs, activates strict CORS origin filtering. |
| `MONGO_URI` | Yes | `mongodb+srv://uniflow_app:<secret>@cluster0.abcde.mongodb.net/uniflow?retryWrites=true&w=majority` | Authenticated MongoDB Atlas SRV connection string with TLS encryption. |
| `JWT_SECRET` | Yes | *(64-byte random hex)* | Cryptographic HMAC secret for signing and verifying tokens. Minimum 32 characters. Generate with `openssl rand -hex 64`. |
| `JWT_EXPIRES_IN`| No | `7d` | Token validity duration. |
| `FRONTEND_URL` | Yes | `https://uniflow-c3334.web.app` | Canonical production Firebase Hosting origin allowed to make CORS requests. |
| `FLUTTER_WEB_URL`| Yes | `https://uniflow-c3334.firebaseapp.com` | Secondary production Firebase Hosting domain or custom domain. |
| `BCRYPT_SALT_ROUNDS`| No| `10` | Password hashing work factor (default 10). |

> [!CAUTION]
> **Secret Hygiene Rules:**
> 1. Never commit `.env` or paste real connection strings into markdown or source code.
> 2. Use Railway's **Variables** dashboard tab to set production values.
> 3. Never reuse development database passwords or development JWT secrets in production.

---

## 5. MongoDB Atlas Network Access Configuration

To adhere to the principle of least privilege, **do not allow universal access (`0.0.0.0/0`)** to MongoDB Atlas.

### 5.1 Railway Static Outbound IPs Setup
1. In the Railway project dashboard, upgrade the workspace to a plan that supports **Static Outbound IPs** (e.g., Railway Pro).
2. Go to your backend service **Settings** > **Networking**.
3. Toggle **Enable Static Outbound IP**.
4. Railway will display a list of dedicated IPv4 addresses (typically 2 to 4 IP addresses), for example:
   - `34.xxx.xxx.12`
   - `34.xxx.xxx.15`

### 5.2 Atlas IP Whitelisting Procedure
1. Log in to [MongoDB Atlas](https://cloud.mongodb.com/).
2. Navigate to **Security** > **Network Access**.
3. Click **Add IP Address**.
4. Enter each Railway static outbound IP address individually with a comment (e.g., `Railway API Node 1`, `Railway API Node 2`).
5. Ensure IP whitelist entry `0.0.0.0/0` is deleted or absent.
6. Verify database user permissions:
   - Create a dedicated production user (e.g., `uniflow_prod_svc`) with `readWrite` role scoped strictly to the `uniflow` database.

### 5.3 Post-Deployment Connectivity Test
Once Railway deploys:
1. Review Railway deployment logs for: `✅ MongoDB connected: cluster0-shard-00-00.abcde.mongodb.net`.
2. Send a request to `GET https://<your-railway-app>.up.railway.app/api/health`.

---

## 6. Production CORS & Security Controls

### 6.1 Backend CORS Enforcement
In `backend/node_api/src/app.js`:
- In `NODE_ENV=production`, development origins (`localhost`, `127.0.0.1`, ephemeral development ports) are excluded.
- The CORS allowlist strictly permits `env.FRONTEND_URL` and `env.FLUTTER_WEB_URL`.
- Non-browser clients (such as the native Android mobile app or server-to-server health probes) send no `Origin` header and are permitted through JWT verification.
- Wildcards (`*`) are disallowed.

### 6.2 HTTPS & TLS Requirements
- All API communication in production must use `https://`.
- Railway terminates TLS at the edge with automated Let's Encrypt certificates.
- Firebase Hosting provisions TLS automatically.
- Security headers are applied by Express via `helmet()` (`HSTS`, `X-Content-Type-Options`, `Content-Security-Policy`).

### 6.3 Android Network Security Configuration
- The file `android/app/src/main/res/xml/network_security_config.xml` includes `<base-config cleartextTrafficPermitted="false" />`, blocking cleartext HTTP for any domain not explicitly listed.
- For production releases, all API calls target `https://<YOUR-RAILWAY-APP>.up.railway.app/api`. Android rejects cleartext HTTP attempts automatically.

---

## 7. Production Android Release APK Build

To generate the final production Android APK pointing to the Railway API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<YOUR-RAILWAY-APP>.up.railway.app/api
```

- **Output:** `build/app/outputs/flutter-apk/app-release.apk`
- **Application ID:** `com.uniflow.app`
- **Version:** `1.0.0`
- **Keystore / Signing:** For Google Play deployment, configure `android/key.properties` with an institutional upload keystore as documented in official Flutter documentation.

---

## 8. Production Smoke-Test Checklist

After completing deployment of both Firebase Hosting and Railway, execute this verification runbook:

1. **API Health Check:**
   - Execute: `curl -s https://<RAILWAY-DOMAIN>/api/health | jq .`
   - Expect: HTTP 200, `"status": "operational"`.
2. **Web Portal Access:**
   - Open `https://<FIREBASE-DOMAIN>` in a clean browser session.
   - Verify UniFlow logo and branding render cleanly without CORS errors.
3. **Login Form Validation:**
   - Verify fields start blank.
   - Verify zero role selectors appear.
4. **Student Workflow:**
   - Sign in with student credentials.
   - Verify automatic redirection to Student Dashboard (`Active Journeys`).
   - Submit a test Bonafide Request.
   - Verify request appears in `My Requests` timeline.
5. **Staff Workflow:**
   - Sign in with staff credentials in an incognito window.
   - Verify automatic redirection to `Staff Review Queue`.
   - Verify submitted student request appears in the review list.
   - Approve step with comment.
6. **Administrator Workflow:**
   - Sign in with admin credentials.
   - Verify automatic redirection to `Administrative Executive Portal`.
   - Verify metrics reflect live database counts.
   - Action final step approval.
7. **Session Restoration & Logout:**
   - Refresh the browser while logged in; verify session restores seamlessly without returning to login.
   - Click Sign Out; verify token is deleted and user is returned to the clean login screen.

---

## 9. Rollback Procedures

If an anomaly is detected post-deployment:

### 9.1 Firebase Hosting Rollback
Firebase stores historical deployment versions:
```bash
# List historical releases
firebase hosting:channel:list

# Instant rollback via Firebase Console or CLI
firebase hosting:rollback
```
Rollback takes effect globally within seconds.

### 9.2 Railway Backend Rollback
1. Open the Railway project dashboard.
2. Select the backend service > **Deployments**.
3. Click the three dots on the previous working deployment and select **Rollback**.
4. Railway restarts the previous container image immediately.

### 9.3 Database Rollback
- MongoDB Atlas provides continuous point-in-time cloud backups on M10+ tiers.
- In the Atlas Console: Select Cluster > **Backup** > **Restore** > Choose point-in-time snapshot.

