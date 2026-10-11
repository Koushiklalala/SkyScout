# 🌌 SkyScout — AI Stargazing & Cosmic Storyteller

> An intelligent, multi-modal stargazing observatory app built with Flutter, Mastra AI Agent, MongoDB Atlas, and automated voice narration.

---

## 🌟 Hackathon Tracks & Prize Eligibility
- 🚀 **Best Use of Render ($200)**: Backend AI runtime and static audio streaming service deployed on Render.
- 🤖 **Best Use of Mastra ($100)**: Orchestrates astronomy tools, spherical coordinate calculations, and multi-modal celestial synthesis.
- 🍃 **Best Use of MongoDB Atlas ($100)**: Stores rich astronomical datasets, mythology lore, and user stargazing session history.
- 🎙️ **Best Use of ElevenLabs ($100)**: Server-side audio voice synthesis generating spoken celestial narrations.

---

## ✨ Features
- **4K AR Camera Viewfinder**: High-resolution sky photography in native hardware resolution with responsive HUD telemetry.
- **Real-Time Sensor Lock**: Tracks device GPS latitude/longitude, magnetic compass azimuth (0–360°), and altitude tilt pitch.
- **360° 8-Octant Celestial Mapping**: Accurately maps coordinates to constellations (*Taurus, Orion, Ursa Major, Scorpius, Cassiopeia, Crux, Cygnus, Leo*).
- **Personalized Audio Narration**: Generates captivating mythological and astrophysical stories addressed to the user with audio waveform controls (`PLAY/PAUSE`, `REWIND 10s`, `MUTE`).
- **Persistent Mobile Local Storage**: Saves user session and profile via `shared_preferences`, automatically routing to the sky camera upon launch.
- **Secure Email OTP Authentication**: Passwordless sign-in with 6-digit OTP verification.

---

## 🏗️ Architecture & Project Structure
```
├── skyscout/              # Mobile Frontend (Flutter / Dart)
│   ├── lib/
│   │   ├── screens/       # HUD, Profile, Login, Profile Setup
│   │   ├── widgets/       # Holographic HUD, Viewfinder, Waveform Visualizer
│   │   └── services/      # ApiService with SharedPreferences persistence
│   └── pubspec.yaml
│
└── skyscout_backend/      # Backend AI Runtime (Node.js / Express / TypeScript)
    ├── src/
    │   ├── agent/         # Mastra Agent & 360° Constellation Lookup Tool
    │   ├── routes/        # Stargaze & Auth endpoints
    │   ├── utils/         # ElevenLabs / Google TTS voice synthesizer
    │   └── server.ts      # Express Server
    └── package.json
```

---

## 🚀 Getting Started

### 1. Backend Setup
```bash
cd skyscout_backend
npm install
cp .env.example .env
# Edit .env with your MongoDB Atlas URI
npm run dev
```

### 2. Mobile App Setup
```bash
cd skyscout
flutter pub get
flutter run
```

---

## 🌐 Deploying to Render
1. Create a new **Web Service** on [Render](https://render.com).
2. Set Root Directory: `skyscout_backend`
3. Build Command: `npm install && npm run build`
4. Start Command: `npx tsx src/server.ts`
5. Configure Environment Variables (`MONGODB_URI`, `JWT_SECRET`, `PORT=3000`).
6. Update `baseUrl` in `skyscout/lib/services/api_service.dart` to your Render URL.
