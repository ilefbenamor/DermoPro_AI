# DermoPro AI 🩺
**Next-Generation Dermatological Assistant powered by Gemini 3**

## 🚀 Vision
DermoPro AI empowers dermatologists with cutting-edge AI to track skin lesion evolution, automate medical reporting, and conduct real-time clinical research.

## ✨ Key Features
- **Multimodal Analysis:** Instant assessment of skin lesions using Gemini 3 Vision.
- **Evolution Mode:** Comparative AI analysis between historical and current images to detect subtle changes.
- **AI Medical Scribe:** Converts raw clinical notes into structured professional reports using Gemini reasoning.
- **AI Research Lab:** A dedicated hub for differential diagnosis and clinical consultation via Chat & Image scan.
- **PDF Export:** Professional clinical reports generated instantly for medical records.

## 🛠 Tech Stack
- **Frontend:** Flutter
- **Backend:** Firebase (Auth, Firestore)
- **AI Engine:** Google Gemini 3 API ( gemini-3-flash-preview)

## 💡 Gemini 3 Integration
We leveraged Gemini 3 for its **low-latency multimodal reasoning**. The ability to analyze two high-resolution images side-by-side in "Evolution Mode" allows for precise detection of dermatological changes that traditional algorithms might miss.

Note for Judges:
For security reasons, the .env file (containing the Gemini API Key) and firebase_options.dart are not included in this repository. To run the project:
1-Create a .env file with GEMINI_API_KEY=your_key.
2-Set up your own Firebase project and add the configuration files.
