# PenguiniBot

PenguiniBot is an offline AI chatbot for iOS featuring a cute, animated penguin. It listens for the keyword "Penguini", processes questions using the Google Gemma model locally on your device, and responds with a comical, high-pitched voice and expressive animations.

## Features

- **Keyword Spotting**: Listens for "Penguini" to start an interaction.
- **Offline LLM**: Uses MediaPipe Tasks GenAI with the Gemma 2B model for private, on-device inference.
- **Animated Face**: A custom-drawn SwiftUI penguin with idle, thinking, happy, surprised, and confused expressions.
- **Comical Voice**: TTS with adjusted pitch and rate for a funny penguin persona.

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
3.  **Download the Gemma Model**:
    - Visit the [Gemma models on Kaggle](https://www.kaggle.com/models/google/gemma/mediapipe/gemma-2b-it-cpu-int4) or Hugging Face.
    - Download the `gemma-2b-it-cpu-int4.bin` (or `.task`) file.
    - Rename it to `gemma-2b-it-cpu-int4.bin` if necessary.
4.  **Add Model to Xcode**:
    - Open `PenguiniBot.xcworkspace` in Xcode.
    - Drag and drop the `gemma-2b-it-cpu-int4.bin` file into the `PenguiniBot` folder in the Project Navigator.
    - Ensure "Add to targets: PenguiniBot" and "Copy items if needed" are checked.
5.  **Run the App**:
    - Select your iPhone 17 Pro as the target device.
    - Build and Run (Cmd+R).

## How to Use

- Say **"Penguini"** to wake him up.
- Wait for him to look surprised/listening.
- Ask your question.
- Penguini will think and then respond with voice and animation!
