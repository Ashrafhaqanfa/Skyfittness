# Setup Guide — Gym Membership App (Phase 1 MVP)

## What's included in this drop

```
GymApp/
├── GymApp.swift                 # App entry point + tab navigation
├── Models/
│   ├── Member.swift              # Core member model + expiry bucket logic
│   └── SupportingModels.swift    # Category, Plan, Payment, Admin, Attendance, Enquiry
├── Services/
│   └── MemberService.swift       # Firestore CRUD + live listener
└── Views/
    ├── DashboardView.swift       # Home screen stat cards
    ├── MembersListView.swift     # Filterable member list (Live/Expired/Expiring)
    ├── AddEditMemberView.swift   # Add/edit member form
    └── MemberDetailView.swift    # Member profile + actions
```

This is **Phase 1** from the roadmap: Auth scaffold, Member CRUD, and the
Live/Expired/Expiring(1-3, 4-7, 8-15 day) status logic from your notes.

---

## Step 1 — Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Product Name: `GymApp`, Interface: **SwiftUI**, Language: **Swift**
4. Minimum deployment target: **iOS 16.0** (needed for `ContentUnavailableView`, `LabeledContent`, Swift Charts later)

## Step 2 — Add these files

Drag the `Models`, `Services`, and `Views` folders (and `GymApp.swift`, replacing
the auto-generated one) into your Xcode project. Make sure "Copy items if needed"
is checked.

## Step 3 — Add Firebase

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Create a project**
2. Inside the project, click **Add app → iOS**, enter your bundle ID (e.g. `com.yourname.gymapp`)
3. Download the generated **`GoogleService-Info.plist`** and drag it into your Xcode project root
4. In Xcode: **File → Add Package Dependencies** → paste:
   `https://github.com/firebase/firebase-ios-sdk`
5. Select these libraries when prompted:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
   - `FirebaseFunctions` (for staff creation + manual reminder triggers)
   - `FirebaseMessaging` (optional, for future push notification upgrades)

## Step 4 — Enable Firestore

1. In Firebase Console → **Build → Firestore Database → Create database**
2. Start in **test mode** for development (lock down with security rules before launch)
3. Create a `members` collection — you can start empty; the app will populate it as you add members

## Step 5 — Build & run

`Cmd + R`. You should see:
- **Dashboard tab**: stat cards (all zero until you add members)
- **Members tab**: tap the `+` button → fill in the form → save → it appears in the Live filter

---

## What's stubbed out (intentionally, for Phase 2/3)

- **Payments tab** — placeholder. Next build step: `Payment.swift` service + a
  "Record Payment" sheet that writes to a `payments` collection and decrements `dueAmount`.
- **Enquiries tab** — placeholder. Needs an `EnquiryService` + list/detail views, same pattern as Members.
- **WhatsApp/SMS reminder buttons** — UI is in `MemberDetailView`, but they need
  a Firebase Cloud Function that calls Twilio/WhatsApp Business API. This can't run
  client-side (API keys shouldn't ship in the app).
- **Admin roles/login management** — needs `FirebaseAuth` wired up with a real
  sign-in screen (currently the app assumes you're already authenticated).

## Suggested build order from here

1. Wire up a real login screen (Firebase Auth, email/password or Sign in with Apple)
2. Build `PaymentService` + "Record Payment" flow (updates `dueAmount` on the member)
3. Add Firestore security rules so members can only be read/written by authenticated admins
4. Build `EnquiryService` + Enquiries tab (same list/detail pattern as Members)
5. Write a Cloud Function (`onSchedule`, daily) that scans for members in the
   1-3 day expiry bucket and triggers SMS/WhatsApp reminders automatically

---

*Every file above is a real, working starting point — not pseudocode. Copy it in,
add Firebase, and you have a functioning Members module today.*
