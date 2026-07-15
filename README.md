# GymApp — Complete Gym Membership Management App (iOS)

All 4 phases from the original spec are now built. This is a real, working
SwiftUI + Firebase app — not pseudocode. Below is what's included, the
complete file map, and exact steps to get it running (written for a
Windows-only workflow, per your setup).

---

## What's built, phase by phase

### Phase 1 — Core (Members, Auth, Billing)
- Email/password login + first-run owner account creation
- Member CRUD with Category → Plan → Assignment (auto-calculates expiry date & due amount from the plan)
- Live / Total / Expired / Expiring (1-3, 4-7, 8-15 day) filtered lists
- Payment recording that atomically updates member due amount
- Dashboard with live stat cards

### Phase 2 — Operations (Attendance, Collections)
- Daily check-in / attendance tracking, searchable
- Today's Collection + Total Collection with monthly filter
- Balance sheet (payment history list)

### Phase 3 — Engagement (Enquiries, Reminders)
- Enquiries/leads: add, filter by status (new/contacted/converted/lost), follow-up scheduling, "today's follow-ups" surfaced on the list
- Local (on-device) admin reminders for birthdays and upcoming expiries
- **Automated member-facing reminders** (WhatsApp + SMS) via Cloud Functions — runs daily on Firebase's servers, matching the "3-day payment WhatsApp" note. This is the one part that genuinely can't run inside the iOS app (API keys can't ship client-side), so it's a separate deployable function — see `/functions`.

### Phase 4 — Growth & Admin
- Refer & Earn: log referrals, track reward status (pending → referred joined → reward given)
- Diet plans: assign per member, view/delete
- Reports: generate a branded, themed **Balance Sheet PDF** on-device (PDFKit) and share/save it
- Manage Staff: owner-only screen to add staff/trainer accounts with role-based access (uses a Cloud Function so adding staff doesn't sign the owner out)

---

## Complete file map

```
GymApp/
├── GymApp.swift                    # App entry, login gate, tab navigation
├── SETUP.md                        # Xcode + Firebase setup (client app)
├── WINDOWS_BUILD_GUIDE.md          # Building/deploying from Windows via Codemagic
├── codemagic.yaml                  # CI config — builds the iOS app without a Mac
│
├── Models/
│   ├── Member.swift                 # Core model + expiry bucket logic
│   └── SupportingModels.swift       # Category, Plan, Payment, Admin, Attendance, Enquiry
│
├── Services/                        # All Firestore/Firebase logic (MVVM-ish)
│   ├── AuthService.swift
│   ├── MemberService.swift
│   ├── CategoryPlanService.swift
│   ├── PaymentService.swift
│   ├── AttendanceService.swift
│   ├── EnquiryService.swift
│   ├── NotificationService.swift    # Local (on-device) reminders
│   ├── ReferralService.swift
│   ├── DietPlanService.swift
│   ├── ReportService.swift          # PDF generation (PDFKit)
│   └── AdminService.swift           # Staff management (calls Cloud Function)
│
├── Views/
│   ├── LoginView.swift
│   ├── DashboardView.swift
│   ├── MembersListView.swift
│   ├── AddEditMemberView.swift
│   ├── MemberDetailView.swift
│   ├── RecordPaymentView.swift
│   ├── PaymentsView.swift
│   ├── AttendanceView.swift
│   ├── EnquiriesView.swift
│   ├── AddEditEnquiryView.swift
│   ├── ReferralsView.swift
│   ├── DietPlansView.swift
│   ├── ReportsView.swift
│   ├── ManageStaffView.swift
│   └── SettingsView.swift           # "More" tab — navigation hub for everything above
│
└── functions/                       # Cloud Functions (Node.js) — deployed separately to Firebase
    ├── package.json
    └── index.js                     # Scheduled WhatsApp/SMS reminders, birthday messages,
                                      # manual reminder trigger, staff account creation
```

---

## Full setup — from zero to running app (Windows workflow)

### Part A: Firebase project setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Create a project**
2. **Build → Firestore Database → Create database** (start in test mode for development)
3. **Build → Authentication → Get started → Email/Password → Enable**
4. **Project settings → Add app → iOS** → enter a bundle ID (e.g. `com.yourname.gymapp`) → download `GoogleService-Info.plist` (you'll add this to Xcode/your repo)
5. Upgrade to the **Blaze (pay-as-you-go) plan** — required for Cloud Functions. It has a generous free tier; for a single gym's usage you'll likely stay within free limits, but Google requires billing enabled to use Functions at all.

### Part B: Deploy the Cloud Functions (the WhatsApp/SMS + staff creation logic)

This is the one part of the build that needs a one-time Node.js setup — but it
runs entirely on your Windows machine, no Mac needed (Cloud Functions are
JavaScript, not Swift).

1. Install [Node.js](https://nodejs.org) (LTS version) on Windows
2. Install the Firebase CLI:
   ```
   npm install -g firebase-tools
   ```
3. Log in:
   ```
   firebase login
   ```
4. From the `GymApp` project folder:
   ```
   cd functions
   npm install
   ```
5. Sign up for [Twilio](https://twilio.com) (free trial available) and get:
   - Account SID
   - Auth Token
   - A WhatsApp-enabled sender (Twilio provides a sandbox number for testing)
   - An SMS-capable phone number
6. Set the secrets (Firebase will prompt you to store these securely):
   ```
   firebase functions:secrets:set TWILIO_SID
   firebase functions:secrets:set TWILIO_AUTH_TOKEN
   firebase functions:secrets:set TWILIO_WHATSAPP_FROM
   firebase functions:secrets:set TWILIO_SMS_FROM
   ```
7. Deploy:
   ```
   firebase deploy --only functions
   ```

Once deployed, `sendExpiryReminders` and `sendBirthdayAnniversaryMessages` run
automatically every day — you never have to trigger them manually.

### Part C: Build the iOS app (from Windows, via Codemagic)

Follow `WINDOWS_BUILD_GUIDE.md` in full. Summary:

1. Write/edit code in VS Code on Windows
2. Push the `GymApp` folder to a GitHub repo (include `GoogleService-Info.plist` from Part A — or better, keep it out of git and add it as a Codemagic encrypted file/environment asset, since it contains project identifiers)
3. Sign up at [codemagic.io](https://codemagic.io), connect the repo
4. Codemagic reads `codemagic.yaml` and builds automatically on every push
5. Set up code signing in Codemagic (automatic signing via your Apple ID — no manual certificate handling)
6. Get an **Apple Developer account** ($99/year) — required by Apple for any real-device install or App Store distribution, independent of how you build
7. Configure TestFlight publishing (uncomment the block in `codemagic.yaml`) to get builds straight onto your iPhone

### Part D: First launch checklist

1. Open the app → tap "First time setup? Create owner account" → sign up
2. Go to **More → Load sample categories & plans** (or add your own real ones)
3. Go to **Members → +** → add your first real member
4. Go to **More → Manage Staff** to add trainers/staff (owner only)
5. Record a payment, mark attendance, log an enquiry — confirm everything reflects on the Dashboard
6. Open a member's detail screen → try **Send SMS Reminder** / **Send WhatsApp Reminder** — these call the deployed `sendManualReminder` Cloud Function directly (only works after Part B is deployed and Twilio secrets are set)

---

## Known limitations / what's intentionally left for you to extend

- **Local notifications** (birthdays/expiry reminders shown to the admin on-device) only fire reliably if the app has been opened recently — this is an iOS platform constraint, not a bug. The Cloud Functions (Part B) don't have this limitation since they run server-side.
- **Firestore security rules** are left at "test mode" defaults in this guide — before real use, lock these down (e.g. only authenticated admins can read/write `members`, `payments`, etc.). This is a few lines in the Firebase Console's Rules tab; ask me if you want these written out.
- **Twilio costs** — WhatsApp/SMS messages cost a small fee per message beyond the free trial credits. Budget a few dollars a month depending on member count.
- **PDF reports** are functional but basic-styled — easy to extend with your gym's logo/colors in `ReportService.swift` if you want a more branded look.

---

## If you want to keep extending

Natural next additions, roughly in priority order:
1. Firestore security rules (protect your data)
2. Push notifications via FCM (upgrade from local notifications, so admin reminders work even if the app hasn't been opened)
3. Photo upload for member profiles (Firebase Storage)
4. Analytics dashboard (charts for growth trends, using Swift Charts)

Let me know if you'd like any of these built out next, or if you hit issues during setup — happy to debug with you.
"# Skyfittness" 
"# Skyfittness" 
