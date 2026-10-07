# SMS Shield AI — 100% On-Device ONNX Mobile App

A modern, serverless mobile application built with **Flutter** and **Dart** for instant real-time SMS spam detection, powered by native **ONNX Runtime** on-device machine learning.

---

## ✨ Key Highlights

* **100% On-Device Machine Learning**: Operates completely offline with zero network requests or server latency.
* **Native ONNX C++ Engine**: Loads [`sms_spam_pipeline.onnx`](file:///d:/MyFolder/nlp-project/sms-spam-detector/ml/sms_spam_pipeline.onnx) directly into `onnxruntime` native sessions.
* **Complete Privacy**: SMS message contents never leave your device.
* **Confidence Progress Meters**: Visual breakdown showing exact probability scores for Spam vs. Ham.
* **Suspicious Keyword Detector**: Flags high-risk triggers (e.g. `lottery`, `http://`, `verify bank`, `prize`).
* **Interactive Sample Templates**: Quick one-tap testing chips for common scams and legitimate message patterns.
* **Session Scan History**: Keep track of recent message checks during the active session.

---

## 📱 App Structure

```text
mobile_app/
├── assets/
│   └── models/
│       └── sms_spam_pipeline.onnx    # On-Device ONNX Model Asset
├── lib/
│   ├── main.dart                     # App entry point
│   ├── models/
│   │   └── prediction_result.dart    # Prediction & Keyword Data Model
│   ├── services/
│   │   ├── onnx_service.dart         # Native ONNX Runtime Model Loader & Inference Engine
│   │   └── api_service.dart          # Simple wrapper forwarding to OnnxService
│   ├── theme/
│   │   └── app_theme.dart            # Dark theme design system
│   ├── widgets/
│   │   ├── result_card.dart          # Visual result & probability progress card
│   │   ├── sample_chips.dart         # Quick preset sample chips
│   │   └── settings_dialog.dart      # ONNX Model Specifications dialog
│   └── screens/
│       └── home_screen.dart          # Main dashboard screen
└── pubspec.yaml                      # Dependencies (onnxruntime, path_provider, google_fonts, flutter_animate)
```

---

## 🚀 How to Run the App

In a terminal, navigate to the `mobile_app` directory:

```powershell
cd mobile_app
```

#### Run on Android Emulator / Connected Physical Device:
```powershell
flutter run
```

#### Run in Chrome (Web):
```powershell
flutter run -d chrome
```

#### Run as Windows Desktop App:
```powershell
flutter run -d windows
```

---

## 📦 Build Release APK

To build a standalone, offline Android APK file:

```powershell
flutter build apk --release
```

The compiled `.apk` file will be generated at:
`mobile_app/build/app/outputs/flutter-apk/app-release.apk`
