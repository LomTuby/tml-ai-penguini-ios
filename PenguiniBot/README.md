# PenguiniBot (Gemma 4 Edition)

PenguiniBot is an offline AI chatbot for iOS featuring a cute, animated penguin. It listens for the keyword "Penguini", processes questions using the **Google Gemma 4 E4B** model locally on your device, and responds with a comical, high-pitched voice and expressive animations.

## Features

- **Keyword Spotting**: Listens for "Penguini" to start an interaction.
- **Offline LLM**: Uses MediaPipe Tasks GenAI with the **Gemma 4 E4B** model for advanced on-device reasoning and multimodal capabilities.
- **Animated Face**: A custom-drawn SwiftUI penguin with context-aware expressions.
- **Comical Voice**: TTS with adjusted pitch for a funny penguin persona.

## Prerequisites

- **Xcode 15.4+**
- **iOS 17.5+** (Optimized for iPhone 17 Pro)
- **CocoaPods** (to install MediaPipe dependencies)

## Setup Instructions

1.  **Clone the project** and navigate to the `PenguiniBot` directory.
2.  **Install Dependencies**:
    Create a `Podfile` in the root directory:
    ```ruby
    platform :ios, '17.5'
    use_frameworks!

    target 'PenguiniBot' do
      pod 'MediaPipeTasksGenAI'
    end
    ```
    Then run:
    ```bash
    pod install
    ```
3.  **Download the Gemma 4 Model**:
    - Visit [Hugging Face](https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm).
    - Download the `gemma-4-E4B-it.litertlm` file.
4.  **Add Model to Xcode**:
    - Open `PenguiniBot.xcworkspace` in Xcode.
    - Drag and drop the `gemma-4-E4B-it.litertlm` file into the `PenguiniBot` folder in the Project Navigator.
    - Ensure "Add to targets: PenguiniBot" and "Copy items if needed" are checked.
5.  **Run the App**:
    - Select your iPhone 17 Pro as the target device.
    - Build and Run (Cmd+R).

## How to Use

- Say **"Penguini"** to wake him up.
- Wait for him to look surprised (eyes wide, brows up).
- Ask your question.
- Penguini will think and then respond with voice and context-appropriate animations!
