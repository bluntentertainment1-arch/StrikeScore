# Bitrise Visual Workflow Setup Guide

This guide shows you how to configure StrikeScore in Bitrise's drag-and-drop Workflow Editor.

## Prerequisites

- Bitrise account connected to your GitHub repo
- Apple Developer account
- App Store Connect API key (for deployment)

---

## Step 1: Create New Workflow

1. Go to **Bitrise Dashboard** → Your App → **Workflow**
2. Click **"Manage Workflows"**
3. Click **"+ Create Workflow"**
4. Name it: `strikescore-deploy`
5. Base it on: `ios-deploy` (or blank)

---

## Step 2: Add Steps (Drag & Drop)

Add these steps IN ORDER from the step library:

### Step 1: Git Clone
- **Step**: `Git Clone Repository`
- **Default settings** — no changes needed

### Step 2: Cache:Pull
- **Step**: `Cache:Pull`
- **Purpose**: Speeds up builds by caching dependencies

### Step 3: Script — Install XcodeGen
- **Step**: `Script`
- **Title**: `Install XcodeGen`
- **Script content**:
```bash
#!/bin/bash
set -ex
if ! command -v xcodegen &> /dev/null; then
  brew install xcodegen
fi
xcodegen --version
```

### Step 4: Script — Generate Xcode Project
- **Step**: `Script`
- **Title**: `Generate Xcode Project`
- **Script content**:
```bash
#!/bin/bash
set -ex
cd $BITRISE_SOURCE_DIR
xcodegen generate
ls -la *.xcodeproj
```

### Step 5: Script — Install CocoaPods
- **Step**: `Script`
- **Title**: `Install CocoaPods`
- **Script content**:
```bash
#!/bin/bash
set -ex
cd $BITRISE_SOURCE_DIR
gem install cocoapods
pod install --repo-update
```

### Step 6: Xcode Archive & Export for iOS
- **Step**: `Xcode Archive & Export for iOS`
- **Configuration**:
  - **Project Path**: `StrikeScore.xcworkspace`
  - **Scheme**: `StrikeScore`
  - **Distribution method**: `app-store`
  - **Configuration**: `Release`

### Step 7: Deploy to iTunes Connect
- **Step**: `Deploy to iTunes Connect / App Store Connect (with fastlane deliver)`
- **OR**: `Deploy to iTunes Connect / App Store Connect (with Application Loader)`
- **Configuration**:
  - **Apple ID**: `$APPSTORE_CONNECT_USERNAME` (set in Secrets)
  - **Password**: `$APPSTORE_CONNECT_PASSWORD` (set in Secrets)
  - **App SKU / App ID**: `$APP_ID` (set in Secrets)

### Step 8: Cache:Push
- **Step**: `Cache:Push`
- **Purpose**: Save cache for next build

---

## Step 3: Set Environment Variables

Go to **App Settings** → **Env Vars**:

| Key | Value | Is Secret? |
|-----|-------|------------|
| `BITRISE_PROJECT_PATH` | `StrikeScore.xcworkspace` | No |
| `BITRISE_SCHEME` | `StrikeScore` | No |
| `BITRISE_EXPORT_METHOD` | `app-store` | No |

---

## Step 4: Set Secrets

Go to **App Settings** → **Secrets**:

| Key | Value | Is Protected? |
|-----|-------|---------------|
| `APPSTORE_CONNECT_USERNAME` | your-apple-id@email.com | Yes |
| `APPSTORE_CONNECT_PASSWORD` | your-app-specific-password | Yes |
| `APP_ID` | 1234567890 (your App Store app ID) | Yes |
| `SSH_RSA_PRIVATE_KEY` | (your GitHub deploy key) | Yes |

---

## Step 5: Configure Triggers

Go to **Triggers** tab:

| Trigger | Workflow | Branch |
|---------|----------|--------|
| Push | `strikescore-deploy` | `main` |
| Push | `strikescore-test` | `develop` |
| Pull Request | `strikescore-test` | `*` |

---

## Step 6: Stack Selection

Go to **Stack** tab:

- **Stack**: `Xcode 16.2.x, on macOS 14` (or latest)
- **Machine size**: `Standard` (or Elite for faster builds)

---

## Step 7: First Build

1. Push code to `main` branch
2. Bitrise auto-triggers the workflow
3. Monitor build logs
4. On success, app uploads to App Store Connect

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "xcodegen not found" | Check `brew install xcodegen` step ran successfully |
| "pod install failed" | Check CocoaPods version, try `pod repo update` |
| "signing failed" | Upload certificates in Bitrise **Code Signing** tab |
| "App Store upload failed" | Verify App Store Connect API credentials |

---

## Alternative: Test Workflow (No Deploy)

For PRs and testing, create a simpler workflow:

| Step | Purpose |
|------|---------|
| Git Clone | Pull code |
| Install XcodeGen | Install tool |
| Generate Xcode Project | Create .xcodeproj |
| Install CocoaPods | Install pods |
| Xcode Build for Testing | Build only, no archive |

No deploy step needed — just validates the build compiles.

---

## Contact

For issues: bluntentertainment1@gmail.com
