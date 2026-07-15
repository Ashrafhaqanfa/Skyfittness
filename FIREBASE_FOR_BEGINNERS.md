# Firebase for Complete Beginners — Setting Up GymApp's Backend

You don't need to know how to code to do this part. It's all clicking
buttons in a website. This guide assumes you've never touched Firebase before.

---

## What you're about to build (in plain terms)

Think of it like setting up a filing cabinet (the database) and a front-desk
sign-in sheet (the login system) before you can open the gym. You're not
writing any code in this guide — just configuring settings on a website.

---

## Step 1 — Create your Firebase account & project

1. Go to **[console.firebase.google.com](https://console.firebase.google.com)**
2. Sign in with any Google account (a Gmail address works fine)
3. Click the big **"Create a project"** (or "Add project") button
4. Name it something like `gymapp` or `my-gym-manager` — this name is just for you, members never see it
5. It'll ask about Google Analytics — you can **turn this off** (toggle it off), you don't need it for this app
6. Click **Create project**, wait ~30 seconds for it to spin up
7. Click **Continue** when it's ready

You now have a Firebase project. This is your "account" for everything else below.

---

## Step 2 — Turn on the Database (Firestore)

This is the "filing cabinet" that stores every member, payment, and record.

1. On the left sidebar, find **Build** → click **Firestore Database**
2. Click **Create database**
3. It'll ask about location — pick whichever region is closest to you (e.g., `asia-south1` if you're in India) — this just affects speed slightly, not functionality
4. It'll ask "Start in production mode or test mode?" — **choose Test mode** for now (this makes development easier; we'll lock it down before you go live with real member data — more on that later)
5. Click **Enable**

That's it. You now have an empty database. It'll look like an empty table —
totally normal, it fills up automatically once you start using the app and
adding members.

---

## Step 3 — Turn on Login (Authentication)

This is the "sign-in sheet" — lets you and your staff log into the app securely.

1. Left sidebar → **Build** → **Authentication**
2. Click **Get started**
3. You'll see a list of sign-in methods (Google, Email/Password, Phone, etc.)
4. Click **Email/Password**
5. Toggle it **Enabled**
6. Click **Save**

Done. Now the app can create logins with just an email + password — no extra setup needed.

---

## Step 4 — Connect Firebase to your iOS app

This step gives your Swift code a "key" to talk to your Firebase project.

1. Left sidebar → click the **gear icon** (⚙️) next to "Project Overview" at the very top → **Project settings**
2. Scroll down to **"Your apps"** → click the **iOS icon** (looks like an apple)
3. It'll ask for an **"iOS bundle ID"** — this is just a unique name for your app, like a domain name. Type something like `com.yourname.gymapp` (replace "yourname" with anything — just keep it lowercase, no spaces)
4. **Write this bundle ID down somewhere** — you'll type this exact same thing into Xcode and Codemagic later. It must match everywhere.
5. Click **Register app**
6. It'll offer a file to download called **`GoogleService-Info.plist`** — click **Download**
7. Save this file somewhere you'll remember (like your Desktop) — this is the actual "key" file. Later, you drag this into your Xcode project.
8. You can skip the remaining setup steps shown on screen (they're for adding Firebase's code libraries — that part's already handled in the code I gave you) — just click **Next** through them, then **Continue to console**

---

## Step 5 — Enable billing (needed only for the WhatsApp/SMS reminders)

This step is **only required if you want the automatic WhatsApp/SMS reminder
feature**. Everything else (members, payments, attendance) works without this.

1. Left sidebar → gear icon → **Usage and billing**
2. Click **Modify plan** or **Upgrade**
3. Choose the **Blaze (Pay as you go)** plan
4. It'll ask for a credit/debit card — this is Google's standard requirement for this tier, but for a single gym's usage, you'll very likely stay within the free monthly allowance and pay ₹0. You're just unlocking the *option* to use more, not committing to a bill.

If you want to skip WhatsApp/SMS reminders for now, skip this step entirely — the rest of the app works fine without it, and you can always come back to this later.

---

## What you should have now

- [ ] A Firebase project created
- [ ] Firestore Database enabled (test mode)
- [ ] Email/Password authentication enabled
- [ ] `GoogleService-Info.plist` downloaded and saved somewhere you can find it
- [ ] Your bundle ID written down (e.g., `com.yourname.gymapp`)
- [ ] (Optional) Blaze billing enabled, only if you want WhatsApp/SMS reminders

That's genuinely the entire Firebase setup. You never write Firebase code —
the Swift files I gave you already know how to connect using that
`GoogleService-Info.plist` file. Your only job in Firebase was: **click these
buttons once**, and it runs itself after that.

---

## What happens automatically after this

Once your app is running (via Codemagic — see `WINDOWS_BUILD_GUIDE.md`), you
won't need to go back into the Firebase website for day-to-day gym use. But
it's useful to know you *can* peek in there any time:

- **Firestore Database tab** → browse actual data. If you add a member in the
  app, you can literally watch it appear here as a new document in the `members`
  folder. This is the best way to confirm "is my app actually saving data?"
- **Authentication tab** → see a list of every staff account that's signed up
- **Usage and billing tab** → check you're not accidentally running up charges (very unlikely at gym-scale usage)

---

## Common confusion points for first-timers

**"Do I need to write any Firebase code?"**
No. All the Firebase-related Swift code already exists in the files I gave
you (`AuthService.swift`, `MemberService.swift`, etc.). You're just supplying
the "key" (`GoogleService-Info.plist`) that lets that code connect to *your*
specific project instead of someone else's.

**"What's the difference between my Firebase project and my Xcode project?"**
- **Firebase project** = the backend (database + login system), lives on Google's servers, configured via the website
- **Xcode project** = the actual iPhone app code, lives in the `GymApp` folder I gave you
- They connect via that one `GoogleService-Info.plist` file

**"I set it to Test Mode — is that dangerous?"**
Test mode means anyone with your Firebase project's address could technically
read/write your database. This is fine while you're the only one building
and testing. Before you let real members' data live in there long-term, you
should lock this down — ask me and I'll write you the exact security rules
to paste in (it's a small text change, not a rebuild).

**"I don't see my data / the app shows nothing"**
Go to Firestore Database in the Firebase console and check if collections
like `members` actually have documents in them. If it's empty, the issue is
on the app side (not saving), not Firebase. If data IS there but not showing
in the app, that's an app-side display issue — tell me and I'll help debug
using the `RUNBOOK.md` troubleshooting section.

---

*Next step: once you have this checklist done, move to `WINDOWS_BUILD_GUIDE.md`
to get the actual app built and running on your phone.*
