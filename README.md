# 🪙 Stack Tracker Pro

**Privacy-First Precious Metals Portfolio Tracker**

Track your silver and gold stack with complete privacy. Your data stays on YOUR device.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue.svg)]()
[![Privacy](https://img.shields.io/badge/Privacy-First-green.svg)]()

---

## 📱 Download

<p align="center">
  <a href="https://apps.apple.com/app/stack-tracker-pro/id000000000">
    <img src="docs/assets/app-store-badge.svg" alt="Download on App Store" height="50">
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.stacktracker.pro">
    <img src="docs/assets/google-play-badge.svg" alt="Get it on Google Play" height="50">
  </a>
</p>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📊 **Portfolio Tracking** | Track silver & gold holdings with real-time spot prices |
| 📷 **AI Receipt Scanner** | Photograph receipts for automatic data entry |
| 🔒 **Privacy-First** | All data stored locally with AES-256 encryption |
| 👆 **Biometric Lock** | Face ID / Touch ID / Fingerprint protection |
| 📈 **Numismatic Tracking** | Track collector premiums separately from melt value |
| 🧮 **Melt Calculator** | Calculate junk silver values instantly |
| 🔔 **Price Alerts** | Get notified when metals hit your targets |
| 📥 **CSV Export** | Export your complete portfolio for tax records |

---

## 🔒 Privacy Architecture

**We built Stack Tracker Pro so we CAN'T access your data, even if we wanted to.**

| ✅ What We Do | ❌ What We DON'T Do |
|---------------|---------------------|
| Store data locally on YOUR device | Store data on our servers |
| Encrypt with AES-256 | Send unencrypted data |
| Process receipt images in RAM only | Save receipt images anywhere |
| Use biometric authentication | Create user accounts |
| Delete images immediately after scanning | Track or profile users |
| Open source our code | Hide how we handle data |

### How Receipt Scanning Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   You take  │────▶│  Image sent │────▶│  AI extracts │
│   a photo   │     │  over HTTPS │     │  data in RAM │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
┌─────────────┐     ┌─────────────┐            │
│  Data saved │◀────│  JSON data  │◀───────────┘
│  on device  │     │  returned   │     Image deleted
└─────────────┘     └─────────────┘     (never stored)
```

---

## 🏗️ Project Structure

```
stack-tracker-pro/
├── mobile-app/              # React Native app (iOS & Android)
│   ├── App.js
│   ├── app.json
│   └── package.json
│
├── backend/                 # Privacy-focused API server
│   ├── server.js
│   ├── Dockerfile
│   └── package.json
│
├── web-preview/             # Browser preview version
│   └── stack-tracker-pro.jsx
│
├── docs/                    # Documentation & marketing
│   ├── PRIVACY.md
│   ├── DATA-HANDLING.md
│   └── app-store/
│       ├── description.md
│       ├── keywords.txt
│       └── screenshots/
│
└── README.md
```

---

## 🚀 Quick Start

### Run the Web Preview

```bash
# The .jsx file can be imported into any React project
# Or use it as a Claude Artifact for instant preview
```

### Run the Mobile App

```bash
cd mobile-app
npm install
npx expo start
```

### Run the Backend

```bash
cd backend
npm install
ANTHROPIC_API_KEY=your-key npm start
```

---

## 📦 Deployment

### Backend (Required for Receipt Scanning)

Deploy to any Node.js host:

```bash
# Docker
docker build -t stack-tracker-api ./backend
docker run -p 3000:3000 -e ANTHROPIC_API_KEY=your-key stack-tracker-api

# Or deploy to Railway, Render, Heroku, etc.
```

### Mobile App

```bash
cd mobile-app

# Build for iOS
eas build --platform ios

# Build for Android  
eas build --platform android

# Submit to stores
eas submit --platform ios
eas submit --platform android
```

---

## 💰 Monetization Model

| Feature | Free | Stacker ($4.99/mo) | Whale ($9.99/mo) |
|---------|------|-------------------|------------------|
| Manual entry | 10 items | Unlimited | Unlimited |
| Receipt scanning | ❌ | 5/month | Unlimited |
| Price alerts | 1 | 5 | Unlimited |
| CSV export | ❌ | ✅ | ✅ |
| Cloud sync | ❌ | ❌ | ✅ (E2E encrypted) |

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

- **Support:** support@stacktracker.app
- **Privacy:** privacy@stacktracker.app
- **Twitter:** [@StackTrackerApp](https://twitter.com/StackTrackerApp)

---

<p align="center">
  <strong>Stack safe. Stack private.</strong>
</p>
