<div align="center">

# خدمت — KHIDMAT

### *"Aapki khidmat mein, hamesha"*
**Always at your service**

[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Gemini](https://img.shields.io/badge/Google_Gemini-2.0_Flash-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 📱 About KHIDMAT

**KHIDMAT** is an **Agentic AI Service Orchestrator** for Pakistan's informal economy, built for the **Google Antigravity Hackathon — Challenge 2**.

It automates the end-to-end lifecycle of a service request — from natural-language user intent to a confirmed booking with follow-up — connecting users with trusted local service providers (plumbers, electricians, AC technicians, tutors, beauticians and more) through a transparent multi-agent AI pipeline.

> **Not a listing app** — KHIDMAT demonstrates *agentic automation*: reasoning, decision-making, action simulation, and traceable workflow execution.

---

## ✨ Features

- 🤖 **6 AI Agents** working in a structured pipeline, end-to-end
- 💬 **Natural Language Chat** — Urdu, Roman Urdu, English & code-switched input
- 🔍 **Smart Provider Discovery** — filters by category, proximity & availability
- 🛡️ **Trust Scoring (BHAROSA)** — verified completion data, not just star ratings
- 💰 **Auto Negotiation (MOL-BHAAV)** — market-rate-aware price negotiation
- 📋 **Booking Simulation** — digital receipt with booking ID & price breakdown
- 🔔 **Follow-Up Automation** — reminders, status updates & rating prompts
- 🧾 **Agent Trace Logs** — full reasoning & decision trace for every request

---

## 🤖 The Agentic Pipeline

| Agent | Urdu Name | Role |
|-------|-----------|------|
| **FAHAM** | فہم | Intent parsing — language detection + service/location/time/urgency extraction |
| **DHOOND** | ڈھونڈ | Provider discovery — category & location matching |
| **BHAROSA** | بھروسا | Trust scoring — `completion×0.4 + speed×0.3 + vouches×0.2 + rating×0.1` |
| **MOL-BHAAV** | مول بھاؤ | Price negotiation — 2-round market-rate negotiation |
| **BOOK** | بُک | Booking confirmation & receipt generation |
| **YAAD-DAHANI** | یاد دہانی | Reminders & follow-up automation |

**Flow:** `Intent → Discovery → Trust → Negotiation → Booking → Follow-up`

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| Flutter 3.27 | Cross-platform mobile UI framework |
| Dart 3.6 | Programming language |
| Google Gemini 2.0 Flash | LLM / NLP engine (free tier) |
| go_router | Declarative navigation |
| provider | State management |
| flutter_animate | Premium micro-animations |
| google_fonts | Typography (Inter + Noto Naskh Arabic) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.27 or newer
- Android Studio / Xcode, or a connected device

### Run

```bash
# 1. Clone the repository
git clone https://github.com/tatheer583/Khidmat-App.git
cd Khidmat-App

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device / emulator
flutter run
```

---

## 🔑 Gemini API Key (Optional)

KHIDMAT works **out of the box** with built-in fallback responses — no key required.

To enable enhanced Gemini-powered NLP:
1. Get a **free** API key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. In the app: tap the **⋮ menu → Set API Key** → paste your key

The app uses **`gemini-2.0-flash`**, which is available on Google's **free tier** (15 requests/min · 1,500 requests/day).

---

## 📦 Build

```bash
# Release APK (install directly on a device)
flutter build apk --release

# Android App Bundle (for Google Play)
flutter build appbundle --release
```

Outputs:
- APK → `build/app/outputs/flutter-apk/app-release.apk`
- AAB → `build/app/outputs/bundle/release/app-release.aab`

Latest APK (pre-built): [release/app-release.apk](release/app-release.apk)

---

## 📁 Project Structure

```
Khidmat-App/
├── lib/
│   ├── main.dart            # App entry point
│   ├── app.dart             # MaterialApp + GoRouter config
│   ├── theme/               # Colors & Material 3 theme
│   ├── models/              # Provider, ChatMessage, AgentLog models
│   ├── data/                # Mock provider DB & market rates
│   ├── agents/              # FAHAM, DHOOND, BHAROSA, MOL-BHAAV logic
│   ├── services/            # Gemini service + AppState orchestrator
│   ├── screens/             # 7 screens (splash → home → booking → logs)
│   └── widgets/             # Reusable UI components
├── android/                 # Android project
├── ios/                     # iOS project
├── test/                    # Widget tests
├── release/                 # Pre-built APK artifacts
└── pubspec.yaml
```

---

## 🎯 Hackathon — Challenge 2 Mapping

| Requirement | Implementation |
|-------------|----------------|
| Intent understanding (Urdu/Roman Urdu/English) | **FAHAM** agent + Gemini |
| Provider discovery | **DHOOND** agent over mock dataset |
| Matching & ranking | **BHAROSA** trust-score ranking |
| Decision & recommendation | Top-pick selection with explanation |
| Action simulation (booking) | **BOOK** agent — receipt + confirmation |
| Follow-up automation | **YAAD-DAHANI** agent |
| Agentic workflow & traceable logs | Agent Logs screen — full reasoning trace |

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

Made with ❤️ for Pakistan 🇵🇰

**KHIDMAT — خدمت**

</div>
