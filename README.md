# StrikeScore

Live Football Scores & Fixtures

## Overview

StrikeScore is a native iOS app built with SwiftUI that provides live football scores, fixtures, group standings, and editorial content. The app fetches data from football-data.org and allows manual content curation via Google Sheets.

## Features

- Live match scores with real-time updates
- World Cup 2026 group standings
- Upcoming fixtures
- Editorial content via Google Sheets CMS
- AdMob banner and rewarded ads
- GDPR consent management
- Offline caching
- Push notifications for match reminders

## Requirements

- iOS 16.0+
- Xcode 16.2+
- CocoaPods
- Bitrise CI/CD (optional)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/strikescore.git
cd strikescore
```

### 2. Install dependencies

```bash
pod install
```

### 3. Generate Xcode project

```bash
xcodegen generate
```

### 4. Open workspace

```bash
open StrikeScore.xcworkspace
```

### 5. Configure signing

- Update `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` if needed
- Set your Apple Developer Team in Xcode
- Configure signing certificates

### 6. Add your app icons

Place your icon files in:
```
Resources/Assets.xcassets/AppIcon.appiconset/
```

Required files:
- AppIcon-20@2x.png
- AppIcon-20@3x.png
- AppIcon-29@2x.png
- AppIcon-29@3x.png
- AppIcon-40@2x.png
- AppIcon-40@3x.png
- AppIcon@2x.png
- AppIcon@3x.png
- AppIcon~ios-marketing.png

### 7. Update AdMob ID

Replace the placeholder in `Sources/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-YOUR-APP-ID</string>
```

### 8. Build and run

Select the StrikeScore scheme and press Cmd+R.

## Google Sheets CMS

The app fetches editorial content from Google Sheets:

1. **Featured Matches**: `gid=792685785`
2. **Editorial**: `gid=600659522`
3. **App Config**: `gid=1758911275`

Update URLs in `Sources/AppConstants.swift` if needed.

## Bitrise CI/CD

The included `bitrise.yml` configures:
- CocoaPods installation
- Xcode project generation
- Archive and export
- App Store Connect upload

Set these environment variables in Bitrise:
- `APP_ID`
- `APPSTORE_CONNECT_USERNAME`
- `APPSTORE_CONNECT_PASSWORD`

## Architecture

```
StrikeScore/
├── Sources/
│   ├── Models/           # Data models (Match, Standing, etc.)
│   ├── Services/         # API and CMS services
│   ├── ViewModels/       # Business logic
│   ├── Views/            # SwiftUI views
│   ├── AdViews/          # AdMob integration
│   ├── GDPR/             # Privacy consent
│   └── Notifications/    # Push notifications
├── Resources/
│   ├── Assets.xcassets/  # App icons
│   └── PrivacyInfo.xcprivacy
└── project.yml           # XcodeGen configuration
```

## License

© 2026 kidblunt. All rights reserved.

## Contact

For support or inquiries: bluntentertainment1@gmail.com
