# GymApp — Run Guide, Architecture, & Troubleshooting

One document covering three things: **how to get it running**, **how all four
phases connect to each other**, and **how to fix it when something breaks**.

---

# PART 1 — How to Run It (Zero to Working App)

This assumes the Windows-only workflow (Codemagic CI, no Mac). Do these in order — each part depends on the one before it.

## 1.1 Firebase Project (10 min)

1. [console.firebase.google.com](https://console.firebase.google.com) → **Create a project**
2. **Build → Firestore Database → Create database** → start in **test mode**
3. **Build → Authentication → Get started → Email/Password → Enable**
4. **Project settings (gear icon) → General → Add app → iOS**
   - Bundle ID: something like `com.yourname.gymapp` — write this down, you'll need it in Xcode and Codemagic later
   - Download **`GoogleService-Info.plist`** — keep this file safe, it goes in your Xcode project
5. **Project settings → Usage and billing → Modify plan → Blaze (pay-as-you-go)**
   — required for Cloud Functions to deploy at all. Free tier covers a single gym easily; you're just enabling the option to pay if you exceed it.

## 1.2 Deploy Cloud Functions (15 min — runs from Windows, no Mac needed)

```bash
# Install Node.js LTS from nodejs.org first, then:
npm install -g firebase-tools
firebase login

cd GymApp/functions
npm install
```

Sign up at [twilio.com](https://twilio.com) (free trial gives test credits), get from your Twilio console:
- Account SID
- Auth Token
- A WhatsApp-enabled number (Twilio gives you a free sandbox number for testing)
- An SMS-capable number

```bash
firebase functions:secrets:set TWILIO_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_WHATSAPP_FROM
firebase functions:secrets:set TWILIO_SMS_FROM
# (each command will prompt you to paste the value — it's stored encrypted, not in your code)

firebase deploy --only functions
```

**You'll know this worked** when the terminal shows 4 function names with green checkmarks:
`sendExpiryReminders`, `sendBirthdayAnniversaryMessages`, `sendManualReminder`, `createStaffAccount`.

## 1.3 Get the Code Building (via Codemagic — 20 min)

```bash
cd GymApp
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/gymapp.git
git push -u origin main
```

1. [codemagic.io](https://codemagic.io) → sign up free → **Add application** → connect GitHub → select your repo
2. Codemagic auto-detects `codemagic.yaml` in the repo root
3. **Team settings → Code signing identities → iOS** → connect your Apple ID for automatic signing
4. **App settings → Environment variables** → confirm `BUNDLE_ID` matches what you set in Firebase (Step 1.1)
5. Add `GoogleService-Info.plist` as an **encrypted file** in Codemagic (App settings → Environment variables → toggle "Secure" → upload the file) — don't commit this file to a public GitHub repo since it contains project identifiers
6. Trigger a build (push to `main`, or click "Start new build" in Codemagic)

**You'll know this worked** when Codemagic shows a green "Build successful" and produces a downloadable `.ipa` or auto-uploads to TestFlight (if configured).

## 1.4 Get It On Your iPhone

Easiest path — TestFlight:
1. In `codemagic.yaml`, uncomment the `app_store_connect` publishing block
2. Set up an App Store Connect API key (Codemagic has a guided setup for this under Team settings → Codemagic API)
3. Push again — the build now auto-uploads to TestFlight
4. Install **TestFlight** from the App Store on your iPhone → accept your own invite → install

## 1.5 First Launch Checklist

1. Open the app → **"First time setup? Create owner account"** → sign up (this is your admin login going forward)
2. **More → Load sample categories & plans** (or skip and add your own real gym categories/plans)
3. **Members → +** → add a real member, assign a category/plan (watch the expiry date and due amount auto-fill)
4. **More → Manage Staff** → add a trainer/staff account if needed
5. Open the member → **Record Payment** → confirm the due amount drops and it shows on the Dashboard's Today's Collection
6. Same member → **Send SMS Reminder** → confirm you get a success message (this proves Part 1.2's Cloud Functions are wired correctly end-to-end)
7. **More → Reports** → generate a Balance Sheet PDF → confirm it opens/shares correctly

If all 7 steps work, every phase is confirmed functioning together.

---

# PART 2 — How the Phases Integrate

The four phases aren't separate modules bolted together — they share the same
Member record and build on each other. Here's the actual dependency graph.

## 2.1 The core dependency: everything revolves around `Member`

```
Member (Phase 1)
  │
  ├─ categoryId / planId  ──→  Category, Plan (Phase 1: CategoryPlanService)
  │                              Picking a plan in AddEditMemberView auto-calculates
  │                              expiryDate and dueAmount — this is why Phase 1's
  │                              form has an .onChange(of: selectedPlanId) block.
  │
  ├─ dueAmount  ──→  Payment (Phase 1/2: PaymentService)
  │                     RecordPaymentView writes a Payment doc AND decrements
  │                     the member's dueAmount in the SAME atomic Firestore batch
  │                     (see PaymentService.recordPayment — this prevents the
  │                     due amount ever drifting out of sync with actual payments)
  │
  ├─ expiryDate  ──→  Cloud Functions (Phase 3: functions/index.js)
  │                     sendExpiryReminders queries members directly by expiryDate
  │                     range — it reads the SAME field the iOS app's
  │                     Member.expiryBucket computed property uses, just from
  │                     the server side instead of on-device
  │
  ├─ id (as memberId)  ──→  Attendance (Phase 2), Referral (Phase 4),
  │                          DietPlan (Phase 4), Payment (Phase 1)
  │                          All of these are separate Firestore collections
  │                          that reference back to a member by ID — never
  │                          embedded inside the Member document itself, so
  │                          the Member doc stays small and fast to sync
  │
  └─ dateOfBirth / joinDate  ──→  isBirthdayToday / isAnniversaryToday
                                    (computed on Member itself) — used by
                                    BOTH the Dashboard (Phase 1, on-device)
                                    AND sendBirthdayAnniversaryMessages
                                    (Phase 3, server-side) — same logic,
                                    two places, so keep them in sync if you
                                    ever change the birthday matching rule
```

## 2.2 Why some things run on-device vs. server-side

This is the single most important architectural decision in the app, so it's
worth understanding explicitly:

| Runs on iOS (client) | Runs on Cloud Functions (server) | Why |
|---|---|---|
| Expiry bucket calculation (`Member.daysUntilExpiry`) | Daily scheduled expiry scan (`sendExpiryReminders`) | The app needs instant UI feedback (no network round-trip to show "3 days left"). But *sending* a WhatsApp message needs a Twilio API key, which can never ship inside an iOS app binary — anyone could extract it and rack up charges on your account. |
| Local notifications (`NotificationService`) | Twilio WhatsApp/SMS (`functions/index.js`) | Local notifications only fire if the app was opened recently (iOS platform limit) — fine for reminding *you*, the admin. Member-facing reminders need to work even if you never open the app that day, so those must be server-scheduled. |
| Creating your own owner account (`AuthService.signUp`) | Creating staff/trainer accounts (`createStaffAccount` function) | Client-side `createUser()` automatically signs in as the new user — fine for your first signup, but disastrous if an owner adding a trainer got logged out of their own session. The Cloud Function uses the Admin SDK to create the account without touching the caller's session. |
| PDF report generation (`ReportService`, PDFKit) | — (none needed) | No sensitive keys involved, and doing it on-device means it works instantly, even offline, and can be shared directly via the iOS share sheet. |

## 2.3 The full user flow, phase by phase

Walking through what actually happens when you use the app end to end:

1. **Login** (Phase 1: `AuthService`) → Firebase Auth issues a session → `AuthService.currentUser` populates → app fetches the matching `Admin` doc for role info
2. **Add a member** (Phase 1: `MemberService` + `CategoryPlanService`) → picking a plan auto-fills `expiryDate`/`dueAmount` → write to `members` collection
3. **Member checks in** (Phase 2: `AttendanceService`) → writes to `attendance` collection, keyed by `memberId` + today's date, blocks duplicate check-ins
4. **Member pays** (Phase 1/2: `PaymentService`) → atomic batch write: new `Payment` doc + decremented `member.dueAmount` → `PaymentsView`'s Today's Collection updates in real time via the Firestore listener
5. **Someone enquires about joining** (Phase 3: `EnquiryService`) → logged with a `followUpDate` → surfaces on the Dashboard's "Follow-ups due today" if that date is today
6. **3 days before a member's plan expires** (Phase 3: Cloud Function, server-side, no app interaction needed) → `sendExpiryReminders` runs automatically at 9 AM → WhatsApp + SMS sent via Twilio → logged to `reminderLogs`
7. **Staff manually nudges a specific member** (Phase 3: `ReminderService` → `sendManualReminder` function) → same Twilio path, triggered on-demand from `MemberDetailView`
8. **Member refers a friend** (Phase 4: `ReferralService`) → logged against the referring `memberId`, reward status tracked separately from the member record
9. **Trainer assigns a diet plan** (Phase 4: `DietPlanService`) → free-text plan tied to `memberId`, viewable from the member's detail screen
10. **Owner runs month-end reporting** (Phase 4: `ReportService`) → pulls `Payment` docs for the date range, renders a PDF balance sheet on-device via PDFKit

## 2.4 Firestore collections — the shared "database" every phase reads/writes

```
members        ← Phase 1 (core), read by Phase 2/3/4 via memberId references
categories     ← Phase 1
plans          ← Phase 1
payments       ← Phase 1/2
admins         ← Phase 1 (auth), Phase 4 (staff management)
attendance     ← Phase 2
enquiries      ← Phase 3
reminderLogs   ← Phase 3 (written only by Cloud Functions, read-only in-app if you build a log viewer later)
referrals      ← Phase 4
dietPlans      ← Phase 4
```

Every phase after Phase 1 is really just: **a new Firestore collection + a
Service class that reads/writes it + a View that displays it**, following the
exact same pattern as `MemberService`/`MembersListView`. That's intentional —
once you understand the Phase 1 pattern, every other phase is the same shape.

---

# PART 3 — Troubleshooting

Organized by where the error shows up.

## 3.1 Xcode / SwiftUI build errors

**"Cannot find 'Member' in scope" (or any model/service/view type)**
- Cause: the file wasn't actually added to the Xcode target.
- Fix: select the file in Xcode's navigator → File Inspector (right panel) → under "Target Membership," make sure `GymApp` is checked.

**"No such module 'FirebaseFirestore'" (or FirebaseAuth/FirebaseFunctions)**
- Cause: Firebase SDK not added, or not all needed sub-packages selected.
- Fix: File → Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk` → make sure you selected `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreSwift`, `FirebaseFunctions`, and `FirebaseMessaging`. If you only selected some initially, re-open Package Dependencies in the project settings and add the missing ones.

**"Missing GoogleService-Info.plist" / crash on launch mentioning FirebaseApp.configure()**
- Cause: the plist file isn't in the project, or isn't in the correct target.
- Fix: drag `GoogleService-Info.plist` into the Xcode project root (not a subfolder), confirm "Copy items if needed" and target membership are checked.

**SwiftUI preview crashes but the app itself would probably run fine**
- Cause: Previews try to initialize Firebase-backed `@StateObject`s without a real Firebase connection.
- Fix: this is a known limitation of previewing Firebase-connected views — ignore preview crashes for Firebase-dependent screens and test via Codemagic/TestFlight instead. (This is also *why* the Windows/no-Mac workflow's live-preview loss matters less than it sounds — Firebase-heavy screens don't preview well even with a Mac.)

## 3.2 Codemagic / CI build errors

**Build fails at "Install CocoaPods dependencies" step**
- Cause: this project uses Swift Package Manager, not CocoaPods — the script in `codemagic.yaml` checks for a `Podfile` and skips if absent, so this usually isn't the real error. Check the full log above this step.

**Build fails with a code signing error**
- Cause: Apple Developer account not connected, or bundle ID mismatch between Xcode project, Firebase, and Codemagic.
- Fix: Codemagic → Team settings → Code signing identities → reconnect your Apple ID. Double check the `BUNDLE_ID` in `codemagic.yaml`'s environment variables exactly matches your Xcode project's bundle identifier AND the iOS app you registered in Firebase.

**Build succeeds but the app crashes immediately on the device/TestFlight**
- Cause: almost always the missing/misconfigured `GoogleService-Info.plist` (see 3.1), or it wasn't included as a secure file in the Codemagic build.
- Fix: Codemagic → App settings → Environment variables → confirm the encrypted `GoogleService-Info.plist` file is attached and referenced in a script step that copies it into place before building (add a script step: `cp $CM_GOOGLE_SERVICE_INFO_PLIST GymApp/GoogleService-Info.plist` — path depends on how you named the secure file).

**"No profiles for 'com.yourname.gymapp' were found"**
- Cause: automatic signing hasn't generated a provisioning profile yet, usually because the bundle ID hasn't been registered on your Apple Developer account.
- Fix: manually visit developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → register the bundle ID once, then retry the Codemagic build.

## 3.3 Firebase / Firestore errors (visible in-app as `errorMessage` on the Services)

**"Missing or insufficient permissions"**
- Cause: Firestore security rules (still in test mode, or already locked down and rejecting a legitimate request).
- Fix: Firebase Console → Firestore Database → Rules tab. In test mode this shouldn't happen; if you've since locked down rules, make sure authenticated admins have read/write on all the collections listed in Part 2.4.

**Data isn't appearing / list stays empty despite adding records**
- Cause 1: `startListening()` was never called (check the view's `.onAppear`).
- Cause 2: Firestore composite index missing — this specifically affects `AttendanceService`'s query (filters by date range + orders by date) and any `.whereField(...).order(by:...)` combo.
- Fix for Cause 2: run the app, trigger the query, then check Xcode's console output — Firestore prints a direct link to auto-create the missing index when this happens. Click it, wait ~1 minute for the index to build, retry.

**Member's `dueAmount` looks wrong after a payment**
- Cause: this should be structurally impossible since `PaymentService.recordPayment` uses an atomic Firestore batch — but if you ever bypass that method and write to `payments` or `members` directly (e.g., manually in the Firebase Console), they'll drift out of sync.
- Fix: always go through `recordPayment()`. If you need to manually correct a due amount, edit it via `AddEditMemberView`, not the Firebase Console directly.

## 3.4 Cloud Functions / Twilio errors

**Deploy fails with "Billing account not configured"**
- Cause: Blaze plan not enabled (see Part 1.1, step 5).
- Fix: Firebase Console → Usage and billing → upgrade to Blaze.

**Functions deploy successfully but reminders never send**
- Check the logs: `firebase functions:log` (from the `functions` folder) — this shows the actual Twilio error.
- Common cause: Twilio trial accounts can only send WhatsApp/SMS to phone numbers you've manually verified in the Twilio console. Verify the test member's phone number there, or upgrade from trial.
- Common cause: phone numbers in Firestore aren't in E.164 format (e.g., `+919876543210`, not `9876543210`). Twilio will reject malformed numbers.

**"Send SMS Reminder" button in the app shows an error**
- Check `ReminderService`'s error message shown in the UI — it surfaces the raw Cloud Function error.
- Common cause: `sendManualReminder` requires the caller to be authenticated (`request.auth` check in `functions/index.js`) — if you're testing while somehow signed out, you'll get an "unauthenticated" error. This shouldn't happen in normal use since the button is only reachable after login.

**`createStaffAccount` fails with "permission-denied"**
- Cause: this function deliberately checks that the caller's `admins` doc has `role == "owner"` before allowing staff creation.
- Fix: confirm you're signed in as the account that used "Create Owner Account" at first launch, not a staff/trainer account.

## 3.5 General debugging approach

1. **Check the in-app error message first** — every Service class (`MemberService`, `PaymentService`, etc.) has an `@Published var errorMessage`, and views like `MembersListView` should surface it. If a screen looks stuck loading with no error shown, that's a UI gap worth adding a `Text(service.errorMessage ?? "")` for while debugging.
2. **Check Firestore data directly** — Firebase Console → Firestore Database → browse collections. Fastest way to confirm whether an issue is "data never got written" (a Service/write bug) vs. "data's there but not displaying" (a View bug).
3. **Check Cloud Functions logs** — `firebase functions:log` for anything server-side.
4. **Check Codemagic build logs** — full stdout/stderr from the actual `xcodebuild` run is available in the Codemagic dashboard for every build, including ones that fail.

---

*If you hit an error not covered here, paste the exact error message/screenshot and I'll help you trace it to the specific file and line.*
