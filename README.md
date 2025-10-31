# 🌤️ Flutter Climate App

A modern Flutter app that connects to a FastAPI backend for AI-powered climate pattern predictions.  
Built with Flutter and integrated with the **climate-ai-backend-new** Python service.

---

## 🚀 Features
- Compare AI predictions vs. live forecast data  
- Toggle AI visualization (`Show AI` option)  
- View 7-day prediction data  
- Built with Flutter + FastAPI + REST API  
- Works fully online — backend hosted on Render  

---

## 🧩 Project Structure
```
lib/ → main Dart code (UI, logic)
assets/ → images, icons, fonts, local JSONs
test/ → widget and unit tests
pubspec.yaml → dependencies and assets
```

---

## 🧠 Requirements
Before running, make sure you have:
- Flutter SDK (latest stable)
- Dart SDK (comes with Flutter)
- Android Studio or VS Code (with Flutter plugin)
- An Android emulator or a physical device connected

---

## ⚙️ Setup & Run Locally

### 1️⃣ Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/YOUR_FLUTTER_APP.git
cd YOUR_FLUTTER_APP
```

### 2️⃣ Install dependencies
```bash
flutter pub get
```

### 3️⃣ Run the app
```bash
flutter run
```

> 💡 If you have multiple devices/emulators, use `flutter devices` to list them.

---

## 🔌 Connect to Backend

This app expects a running FastAPI backend.  
Make sure you have the backend deployed (for example, on Render):

```
https://climate-ai-backend-new.onrender.com
```

In your Flutter app, open:
```
lib/services/api.dart
```

and set:
```dart
final api = BackendApi(baseUrl: 'https://climate-ai-backend-new.onrender.com');
```

---

## 🧱 Build APK for Android

To generate an installable APK:
```bash
flutter build apk --release
```

The built file will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Transfer it to your phone and install manually.

---

## 🧹 Recommended `.gitignore`
Already includes:
- `/build/`, `.dart_tool/`, `.vscode/`, `.idea/`
- `google-services.json`, `GoogleService-Info.plist`
- `.env`, `.keystore`, `.jks`, and binaries (`*.apk`, `*.aab`)

---

## 🪄 Future Improvements
- Integrate real AI climate models  
- Add offline caching for predictions  
- Theme switch (light/dark mode)  
- Firebase analytics & notifications  

---

## 🧑‍💻 Author
**Soumoparno Roy**  
Backend: FastAPI • Frontend: Flutter  
✨ GitHub: [@Kurse0718](https://github.com/Kurse0718)

---

## 📝 License
This project is licensed under the [MIT License](LICENSE).
