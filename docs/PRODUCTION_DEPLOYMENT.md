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
                               └─────────────┬─────────────┘
                                             │
                                   TLS (Mongoose / SRV)
                                (Render Outbound IP CIDRs)
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
| **Backend API** | Node.js (v18+) / Express / Mongoose | **Render** | HTTPS (TLS 1.3) | `0.0.0.0:$PORT` |
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
Compile the Flutter Web client targeting the Render production API:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://<YOUR-RENDER-SERVICE-NAME>.onrender.com/api
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

### 3.1 Why Render
Render provides production-ready Web Services with native Node.js runtime support, automated TLS certificates, zero-downtime deploys, health check verification, and static outbound IP addresses for regional clusters at **zero extra cost**, completely avoiding the need for an expensive hosting plan upgrade solely for database firewall allowlisting.

### 3.2 Service Configuration
1. Log in to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** and select **Web Service**.
3. Choose **Build and deploy from a Git repository**.
4. Select or connect repository: **`Preetham-sai-1/uniflow`**.
5. Configure the Web Service settings:
   - **Name:** `uniflow-api` (or preferred name, yielding `https://<name>.onrender.com`)
   - **Region:** Select the region closest to your MongoDB Atlas cluster (e.g., `Oregon (US West)`, `Ohio (US East)`, `Frankfurt (EU Central)`, or `Singapore (Southeast Asia)`).
   - **Branch:** `master`
   - **Root Directory:** `backend/node_api`
   - **Runtime:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start` *(or `node src/server.js` — `npm start` resolves to `node src/server.js` in `package.json`)*
   - **Instance Type:**
     - **Free:** $0/month (512 MB RAM, 0.1 CPU; spins down after 15 min of inactivity; static outbound IPs still available).
     - **Starter:** $7/month (512 MB RAM, 0.5 CPU; always-on, zero cold-starts, recommended for live production).
6. Under **Advanced Settings**:
   - **Health Check Path:** `/api/health`
   - **Auto-Deploy:** `Yes` (deploys on push to `master`, or `No` for manual trigger).

### 3.3 Networking & Process Binding
- In `backend/node_api/src/server.js`, the Express server binds explicitly to `0.0.0.0` and listens on `process.env.PORT` (automatically injected by Render, typically port 10000 or dynamic).
- The health check endpoint is at `GET /api/health` and returns HTTP 200 with `{ "success": true, "data": { "status": "operational" } }`. Render polls this endpoint during builds and deploys to ensure the application is completely healthy before switching ingress traffic.
- Seeds do **not** run automatically on startup. The database seeding script (`scripts/seed.js`) is an explicit administrative utility only.

---

## 4. Production Environment Variables Audit

All environment variables are validated at backend startup via Zod in `backend/node_api/src/config/env.js`. The server will fail fast if any variable is missing or invalid.

### 4.1 Production Environment Inventory

| Variable Name | Required | Example Production Value | Purpose / Constraints |
|---|---|---|---|
| `PORT` | Auto | *(Injected by Render, e.g. 10000)* | Port assigned dynamically by Render container runner. |
| `NODE_ENV` | Yes | `production` | Enables production caching, disables verbose morgan logs, activates strict CORS origin filtering. |
| `MONGO_URI` | Yes | `mongodb+srv://uniflow_prod_svc:<secret>@cluster0.abcde.mongodb.net/uniflow?retryWrites=true&w=majority` | Authenticated MongoDB Atlas SRV connection string with TLS encryption. |
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
Render publishes and displays dedicated outbound IP addresses for all services by region at no extra cost:

1. In the Render Dashboard, open your `uniflow-api` Web Service.
2. Click **Connect** (located at the top right of the service overview).
3. Select the **Outbound** tab.
4. Render displays the exact list of static outbound IPv4 addresses and CIDR blocks for your service's region (for example, regional blocks such as `52.xx.xx.xx/28`, `44.xx.xx.xx/32`, etc.).
5. Copy these addresses/CIDRs for allowlisting in MongoDB Atlas.

### 5.2 Atlas IP Whitelisting Procedure (CIDR Entries)
1. Log in to [MongoDB Atlas Console](https://cloud.mongodb.com/).
2. Select your Project and navigate to **Security** > **Network Access**.
3. Under the **IP Access List** tab, click **Add IP Address**.
4. Enter each Render outbound IP / CIDR block individually:
   - Paste the IP or CIDR (e.g., `52.203.24.12/32` or regional CIDR `44.229.231.0/24`).
   - Add a descriptive comment (e.g., `Render Oregon Outbound Node 1`).
   - Click **Confirm**.
5. Repeat for all outbound addresses listed in Render's Outbound panel.
6. Verify that `0.0.0.0/0` (Allow Access from Anywhere) is **NOT** present. If present, delete it immediately.

### 5.3 Database User Least-Privilege Role Scoping
Do not use administrative or unrestricted database credentials in production:
1. In MongoDB Atlas, go to **Security** > **Database Access**.
2. Click **Add New Database User**.
3. Authentication Method: **Password** (generate a cryptographically secure password with 32+ characters).
4. Under **Database User Privileges**:
   - Select **Built-in Role** or **Specific Privileges**.
   - Assign the **`readWrite`** role scoped **strictly to the `uniflow` database** (`readWrite@uniflow`).
   - Do **NOT** assign `atlasAdmin`, `readWriteAnyDatabase`, or `clusterMonitor`.
5. Under **Restrictions**: Optionally restrict user connection exclusively to the UniFlow production cluster.
6. Click **Add User**.
7. Formulate the production connection string:
   ```
   mongodb+srv://<username>:<password>@<cluster-host>/uniflow?retryWrites=true&w=majority
   ```
   Provide this value only inside Render's Environment Variables dashboard.

### 5.4 Post-Deployment Connectivity Test
Once Render initiates the deployment:
1. Review Render deployment logs for: `MongoDB connected: <cluster-host>`.
2. Send a request to `GET https://<your-render-app>.onrender.com/api/health`.
3. Confirm that healthcheck returns HTTP 200 with status `"operational"`.

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
- Render terminates TLS at the edge with automated Let's Encrypt certificates and auto-renews them.
- Firebase Hosting provisions TLS automatically across Google's edge CDN.
- Security headers are applied by Express via `helmet()` (`HSTS`, `X-Content-Type-Options`, `Content-Security-Policy`).

### 6.3 Android Network Security Configuration
- The file `android/app/src/main/res/xml/network_security_config.xml` includes `<base-config cleartextTrafficPermitted="false" />`, blocking cleartext HTTP for any domain not explicitly listed.
- For production releases, all API calls target `https://<YOUR-RENDER-APP>.onrender.com/api`. Android rejects cleartext HTTP attempts automatically.

---

## 7. Production Android Release APK Build

To generate the final production Android APK pointing to the Render API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<YOUR-RENDER-APP>.onrender.com/api
```

- **Output:** `build/app/outputs/flutter-apk/app-release.apk`
- **Application ID:** `com.uniflow.app`
- **Version:** `1.0.0`
- **Keystore / Signing:** For Google Play deployment, configure `android/key.properties` with an institutional upload keystore as documented in official Flutter documentation.

---

## 8. Production Smoke-Test Checklist

After completing deployment of both Firebase Hosting and Render, execute this verification runbook:

1. **API Health Check:**
   - Execute: `curl -s https://<YOUR-RENDER-APP>.onrender.com/api/health | jq .`
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

### 9.2 Render Backend Rollback
1. Open the Render project dashboard.
2. Select the `uniflow-api` service > **Events** (or **Deploys**).
3. Locate the previous verified deployment.
4. Click the three dots (...) and select **Rollback to this deploy**.
5. Render immediately restores and routes ingress traffic to the previous deployment image without rebuild delay.

### 9.3 Database Rollback
- MongoDB Atlas provides continuous point-in-time cloud backups on M10+ tiers.
- In the Atlas Console: Select Cluster > **Backup** > **Restore** > Choose point-in-time snapshot.

---

## 10. Cost & Billing Summary

| Service | Tier / Plan | Monthly Cost | Static Outbound IP Included? |
|---|---|---|---|
| **Render Web Service (API)** | Free Tier *(Evaluation / Staging)* | **$0.00** | **Yes** (Free in regional cluster) |
| **Render Web Service (API)** | Starter Tier *(Recommended Production)* | **$7.00 / mo** | **Yes** (Always-on, no cold starts) |
| **Firebase Hosting (Web UI)** | Spark Plan (Free) | **$0.00** | N/A (Global Google Edge CDN) |
| **MongoDB Atlas (Database)** | Shared / M10+ Tier | Free / ~$57 / mo | N/A (Secured via Render CIDR whitelist) |

**Cost Optimization:**
Switching from Railway to Render eliminates the requirement for Railway's Pro plan ($20/month base subscription), saving ongoing hosting fees while preserving strict CIDR-level firewall protection in MongoDB Atlas.
