![Logo](Logo.png)

# Miraa — Russian Language Learning App

A Flutter mobile app for learning Russian through shadowing practice. The app fetches YouTube videos, translates Russian subtitles to English, and lets you practice speaking alongside native audio.

---

## 🧠 Thinking Orbs — A Story in Code

> "We read the [Thinking Orbs library](https://libraries.dev/orbs) on GitHub. It was MIT-licensed, beautifully animated, and perfectly suited for our AI-powered interface.
>
> Instead of depending on a package, we **ported the entire animation engine to Dart**. The result: a lightweight, dependency-free `thinking-orbs` component that lives in `lib/components/orbs/` and brings the same hand-tuned states to our app."

The orbs now render in the app without any external package. See the ported code in:

```
lib/components/orbs/
├── solving_engine.dart
├── soving_painter.dart
└── thinking_orb.dart
```

---

## 📦 What the App Does

| Feature | Description |
|---------|-------------|
| 📹 **Add YouTube videos** | Paste a URL, and the app extracts Russian subtitles. |
| 🇷🇺🇬🇧 **Subtitles** | Russian text on screen, English translation below. |
| 🔊 **TTS audio** | Silero TTS reads the Russian text aloud. |
| 🧠 **AI explanations** | Local Qwen3.8-9B model breaks down words, grammar, and meaning. |
| 💬 **Conversation mode** | The AI asks follow-up questions in Russian. |
| 📥 **Download** | Save subtitle files for offline study. |

---

## 🛠️ Tech Stack

- **Frontend:** Flutter + Dart
- **Backend:** Python FastAPI (FastAPI backend repository)
- **AI Model:** Qwen3.8-9B-Q4_K_M.gguf (local, CPU/GPU)
- **TTS:** Silero TTS (Russian voices)
- **Subtitles:** yt-dlp + Google Translate (via `googletrans`)

---

## 📁 Project Structure

```
Flutter/
├── lib/
│   ├── components/orbs/          # Thinking Orbs (MIT → Dart)
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── media_item.dart       # Video + subtitle metadata
│   │   └── subtitle_item.dart    # Subtitle segment
│   ├── screens/
│   │   ├── home_screen.dart      # Video list
│   │   ├── player_screen.dart    # Video player + subtitles
│   │   └── add_video_dialog.dart # "Add video" dialog
│   ├── services/
│   │   ├── api_service.dart      # HTTP calls to FastAPI backend
│   │   ├── download_service.dart # Subtitle file download
│   │   └── storage_service.dart  # Local DB / SQLite
│   ├── widgets/
│   │   ├── video_player_widget.dart
│   │   ├── subtitle_list_view.dart
│   │   ├── active_subtitle_card.dart
│   │   ├── bottom_player_controls.dart
│   │   ├── explanation_sheet.dart
│   │   └── shadowing_practice_sheet.dart
│   └── utils/
│       ├── app_theme.dart
│       └── time_formatter.dart
├── pubspec.yaml
├── analysis_options.yaml
└── .gitignore
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev) 3.x
- [Dart](https://dart.dev)
- [Backend API](../Request) running locally (FastAPI)

### Install dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run
```

Or build a release APK:

```bash
flutter build apk --release
```

---

## 🔌 API Endpoints (Backend)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/russian-tts` | `POST` | Generate Russian audio (Silero) |
| `/model` | `POST` | Analyze a word/phrase (Qwen3.8-9B) |
| `/model/video-explanation` | `POST` | Conversation mode |
| `/translate` | `POST` | Translate YouTube subtitles |

See the [backend README](../Request/README.md) for details.

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 👥 Credits

- **Thinking Orbs** — MIT, re-ported to Dart.
- **Silero TTS** — Russian voice synthesis.
- **Qwen3.8-9B** — Local LLM for analysis.
- **yt-dlp** — YouTube subtitle extraction.
