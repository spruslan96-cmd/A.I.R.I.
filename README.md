уя ез.# 🌬️ A.I.R.I – Artificial Intelligence, Real-Time, In-App

Welcome to **A.I.R.I**, the pocket-sized AI companion built to run powerful language models **locally on your smartphone**. Whether you want to chat or talk, A.I.R.I's got your back – no internet required! 

## 📱 What is A.I.R.I?
A.I.R.I (**Artificial Intelligence, Real-Time, In-App**) is a sleek and responsive mobile application developed using **Flutter**. It allows users to **download and run LLM models directly on their devices**, ensuring fast and private AI conversations.

### 💡 Current Model Support
As of now, A.I.R.I primarily supports **Llama models**. This is due to its reliance on the [`llama_cpp_dart`](https://pub.dev/packages/llama_cpp_dart) package, which provides the necessary bindings for efficient local inference with Llama architecture-based models. **We are incredibly thankful to the developers of the `llama_cpp_dart` package for enabling this crucial functionality within A.I.R.I.**

## ✨ Features
### 🤖 Local Model Hosting
- Download models from **Hugging Face** and run them locally on your phone.
- Choose between **multiple models** for different performance levels.
- Switch between models seamlessly from the dropdown menu.

### 💬 Chat Interface
- Text-based interaction with the model.
- Messages displayed as stylish chat bubbles.
- Automatically formats long responses with expandable previews.

### 🎙️ Talk Interface
- **Speech-to-Text**: Talk to A.I.R.I using your voice.
- **Text-to-Speech**: A.I.R.I talks back! Responses are read aloud using TTS.
- Smooth animations indicating listening, processing, and responding states.

### 🎨 Customization
- **Settings Page**:
  - Toggle between **Light and Dark Modes**.
  - Customize the app's **primary theme color**.
  - Real-time theme updates for a personalized experience.

### 📂 Model Management
- Browse, download, and delete models with a simple UI.
- Monitor download progress with a sleek progress indicator.
- Automatic model loading after download.

## 🚀 Getting Started
### Prerequisites
- Flutter SDK (v3.x or later)
- Dart (v2.x or later)
- Android/iOS emulator or a physical device

### Installation
1.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/agamairi/A.I.R.I.git](https://github.com/agamairi/A.I.R.I.git)
    ```
2.  **Navigate to the Project Directory**:
    ```bash
    cd A.I.R.I
    ```
3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the App**:
    ```bash
    flutter run
    ```

## 🛠️ Usage
-   **Download Models**: Select models from the dropdown list to download from Hugging Face. Remember, current support is primarily for **Llama models**.
-   **Chatting**: Type your message and receive responses in a stylish chat interface.
-   **Talking**: Tap the microphone, speak your query, and listen to A.I.R.I's response.
-   **Customize**: Personalize your experience via the settings page.

## 💡 Inspiration
A.I.R.I was built to provide **accessible and private AI interactions** on mobile devices. No servers, no privacy concerns – just pure AI magic right on your phone. ✨

## 📄 License
This project is licensed under the [MIT License](LICENSE).

## 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
