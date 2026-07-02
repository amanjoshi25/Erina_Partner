# Erina Assistance — Driver & Vehicle Subscription Platform

This is the unified workspace for the Erina Assistance Driver & Vehicle Subscription Platform, which manages roadside assistance (RSA) subscriptions, vehicle documentation, technician dispatch, and fleet analytics.

---

## 🗺️ Project Architecture

```
Erina Project 2/
├── backend/            # FastAPI (Python 3.12) backend with PostgreSQL
├── admin-portal/       # Next.js Web App for Administrator Operations
├── fleet-portal/       # Next.js Web App for Fleet Owners & Operators
├── driver_mobile/      # Flutter App for Drivers (Onboarding, Subscription, RSA)
├── partner_mobile/     # Flutter App for Partners (Referrals, Commisions)
└── docker-compose.yml  # Local PostgreSQL & PgAdmin services
```

---

## 🛠️ Tech Stack & Services

* **Backend**: FastAPI (Python 3.12)
* **Database**: PostgreSQL 16 (Operational database)
* **Mobile Applications**: Flutter 3.22.x (Dart 3.x)
* **Web Portals**: Next.js 15+ (React 19+, TypeScript, Tailwind CSS, Lucide icons)
* **Authentication**: Firebase Authentication (OTP verification)
* **Push Notifications**: Firebase Cloud Messaging (FCM)
* **Payments**: Razorpay Node/Python SDKs
* **Maps**: Google Maps API

---

## 🚀 Local Development Setup

### 1. Database (PostgreSQL)
Ensure you have Docker running, then start the database service:
```bash
docker compose up -d
```
* **PostgreSQL Endpoint**: `localhost:5432` (User: `erina_admin`, Db: `erina_db`)
* **PgAdmin Web UI**: `http://localhost:5050` (Email: `admin@erina.in`, Password: `admin_secure_pass`)

### 2. Backend (FastAPI)
Navigate to the backend directory, set up virtual environment, and run:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
* **API Documentation**: `http://localhost:8000/docs`

### 3. Web Portals (Admin & Fleet)
Run the admin or fleet portals in separate terminals:
```bash
# Admin Portal
cd admin-portal
npm install
npm run dev

# Fleet Portal
cd fleet-portal
npm install
npm run dev
```

### 4. Mobile Apps (Flutter)
For both `driver_mobile` and `partner_mobile`:
```bash
cd driver_mobile
flutter pub get
flutter run
```

---

## 🔒 Environment Variables (`.env`)
Refer to the `.env.example` in each component folder for configuring secrets (Razorpay, Firebase credentials, Database URLs).
