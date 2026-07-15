# Building This iOS App Entirely From Windows (No Mac Needed)

This guide gets you from "Swift code on Windows" to "app installed on an
iPhone / submitted to TestFlight" without ever touching a Mac yourself.

---

## The Workflow

```
You (Windows, VS Code)
      │
      │  write Swift code, git commit, git push
      ▼
GitHub (your repo)
      │
      │  triggers automatically on push
      ▼
Codemagic (cloud macOS build server — invisible to you)
      │
      │  compiles, signs, packages the .ipa
      ▼
TestFlight / Direct install link
      │
      ▼
Your iPhone
```

You only ever interact with the **top box** (your Windows machine) and the
**bottom box** (your phone, to test). Everything in between is automated.

---

## Step 1 — Editor setup (Windows)

1. Install **VS Code** (or any text editor)
2. Install the **Swift extension for VS Code** (from Swift Server Work Group) — gives you syntax highlighting and basic error checking for `.swift` files. It won't give you SwiftUI live previews (that genuinely requires macOS/Xcode), but it's enough to write and edit code confidently.
3. Install **Git for Windows** — [git-scm.com](https://git-scm.com)

## Step 2 — Put the code on GitHub

```bash
cd path\to\GymApp
git init
git add .
git commit -m "Initial commit: Phase 1 member management"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/gymapp.git
git push -u origin main
```

(Create the empty repo on github.com first, then run the above from a terminal
in your project folder.)

### A note on the Firebase console's "Add Firebase SDK" screen

When you register your iOS app in the Firebase console, it'll walk you
through a screen titled **"Add Firebase SDK"** that says things like *"In
Xcode, navigate to File > Add Packages..."* — **skip this entirely.** That
screen assumes you have Xcode open in front of you, which you don't.

Instead, this project includes a file called **`project.yml`** — this is a
plain text description of the exact same Firebase libraries that screen
would have had you click through manually. When Codemagic builds your app
(next step), it automatically runs a tool called **XcodeGen** that reads
`project.yml` and builds a real Xcode project with Firebase already wired
in — no Xcode UI interaction required, ever.

You only need to grab **one thing** from that Firebase console flow: the
`GoogleService-Info.plist` file it offers to download. Get that, skip the
rest of the SDK instructions, and continue to Step 3 below.

## Step 3 — Connect Codemagic

1. Go to [codemagic.io](https://codemagic.io) → **Sign up free** (free tier includes 500 build minutes/month — plenty for this project)
2. **Add application** → connect your GitHub account → select the `gymapp` repo
3. Codemagic will detect it's an iOS project
4. Upload the `codemagic.yaml` file I created (drop it in your project root, alongside `GymApp.xcodeproj`) — it defines exactly how the build runs
5. In **Codemagic → App settings → Environment variables**, you'll eventually add:
   - Your Apple Developer account connection (needed for code signing — see Step 4)
   - Firebase config if it needs to differ per environment

## Step 4 — Apple Developer account (the one unavoidable requirement)

Even with zero Mac usage, you **do** still need an **Apple Developer account**
($99/year) to sign and distribute the app — this is an Apple business
requirement, not a technical one, and applies no matter how you build.

1. Sign up at [developer.apple.com](https://developer.apple.com)
2. In Codemagic, go to **Team settings → Code signing identities → iOS**
3. Use Codemagic's **automatic code signing** — you just log in with your Apple ID and it handles certificates/provisioning profiles for you (no manual Xcode cert wrangling needed)

## Step 5 — Trigger a build

Once connected, every `git push` to `main` automatically:
1. Spins up a macOS cloud instance
2. Builds your app
3. Signs it
4. Produces a downloadable `.ipa`, or auto-uploads to TestFlight if configured

You'll get an email (configured in `codemagic.yaml`) when it's done.

## Step 6 — Install on your iPhone

**Easiest path: TestFlight**
1. In `codemagic.yaml`, uncomment the `app_store_connect` publishing block
2. Set up an **App Store Connect API key** (Codemagic has a guided flow for this)
3. Builds auto-upload to TestFlight
4. Install the **TestFlight app** on your iPhone → accept the invite → install your app like any App Store app

This is the smoothest way to test on a real device without ever plugging into a Mac.

---

## What you lose vs. having a Mac (be aware of this trade-off)

- **No live SwiftUI preview** — you won't see UI changes instantly as you type. You'll write code, push, wait ~5-10 min for a build, then check TestFlight.
- **Slower debugging loop** — no breakpoints/step-through debugging like Xcode gives you locally. Crash logs come through Codemagic/TestFlight after the fact.
- **Build minutes are metered** — free tier is generous for solo dev, but heavy iteration could hit limits (paid tiers start ~$0.05-0.10/build minute if you exceed it)

If this loop feels too slow once you're actually building, revisit the cloud
Mac rental option (MacinCloud) just for active development sessions — you can
always mix approaches (Codemagic for CI, occasional cloud Mac session for a
tricky UI bug).

---

## Immediate next steps for you

1. Push the `GymApp` folder (from the last message) to a new GitHub repo
2. Sign up for Codemagic, connect the repo
3. Add `codemagic.yaml` to the project root (already created for you)
4. Get an Apple Developer account if you don't have one yet ($99/year — required regardless of build method)
5. Trigger your first build and confirm it compiles

Let me know once you've got the repo up, or if you want me to also set up the **GitHub Actions** alternative (works similarly, slightly more manual config, but no Codemagic account needed).
